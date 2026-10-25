"""The cutlery drainer on the wall as an FEA model: meshes, surfaces, loads and
the wall (fTetWild + CalculiX). Meshing, the .frd and .dat readers come from
caddy_model.py.

Parts: the plate, body, tray, rack and towel handle, in place, as OpenSCAD STL
(cutlery-drainer.scad, the handle from drainer_dims.scad). The bins are not
meshed: each bin and what is in it press on the rack floor under its
footprint. The dimensions come from drainer_dims.scad (dims()), with a
variant's -D overrides.
"""
import os, math, subprocess, json, tempfile
import numpy as np
import caddy_model as cm

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, '..', 'cutlery-drainer.scad')
DIMS = os.path.join(HERE, 'drainer_dims.scad')
PARTS = ('plate', 'body', 'tray', 'rack', 'handle')
CUP_NAMES = ['left, lower', 'left, upper', 'right, lower', 'right, upper']
TOL = 0.2                      # the STL meshes keep the surface within 0.1 mm
E, NU, RHO = cm.E, cm.NU, cm.RHO
D = {}


def dims(defs=()):
    """The dimensions drainer_dims.scad echoes, with OpenSCAD -D overrides."""
    out = tempfile.mktemp(suffix='.echo')
    subprocess.run(['openscad', '-o', out] + [a for d in defs for a in ('-D', d)] + [DIMS], check=True, capture_output=True)
    d = {}
    for line in open(out):
        if line.startswith('ECHO: "FEA"'):
            k, v = line.split(',', 2)[1:]
            d[k.strip().strip('"')] = json.loads(v.strip())
    d['TAN'] = math.tan(math.radians(d['TRAY_SLOPE']))
    return d


def export(out, defs=()):
    """Every part's STL, in place, into out; and the volume of one bin (mm3)."""
    jobs = [(p, ['-D', 'part="%s"' % p], SCAD) for p in PARTS if p != 'handle'] + [('handle', ['-D', 'fea_part="handle"'], DIMS),
                                                                                    ('bin', ['-D', 'part="bin"'], SCAD)]
    procs = [subprocess.Popen(['openscad', '-o', os.path.join(out, p + '.stl')] + a + [x for d in defs for x in ('-D', d)] + [s],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for p, a, s in jobs]
    for p in procs:
        p.wait()
    return stl_volume(os.path.join(out, 'bin.stl'))


def stl_volume(path):
    import meshio
    m = meshio.read(path)
    t = m.points[m.cells_dict['triangle']]
    return abs(np.einsum('ij,ij->i', t[:, 0], np.cross(t[:, 1], t[:, 2])).sum()) / 6


def mesh_parts(src, h, threads=4):
    """Mesh every part's STL at once into caddy_model's cache, so Model() only reads them."""
    from concurrent.futures import ProcessPoolExecutor
    with ProcessPoolExecutor(len(PARTS)) as ex:
        jobs = [ex.submit(cm.mesh_stl, os.path.join(src, p + '.stl'), h.get(p, h['default']), (0, 0, 0), 0.1, threads) for p in PARTS]
        for j in jobs:
            j.result()


class Model:
    def __init__(self, src, h, d):
        """src: a folder of <part>.stl from export(); h: {part: mesh size} with a 'default';
        d: the dimensions from dims()."""
        D.update(d)
        self.parts, self.X = {}, {}
        nid0 = eid0 = 0
        for name in PARTS:
            tags, coords, el = cm.mesh_stl(os.path.join(src, name + '.stl'), h.get(name, h['default']))
            tags, el = tags + nid0, el + nid0
            for t, p in zip(tags, coords):
                self.X[int(t)] = p
            eids = np.arange(eid0 + 1, eid0 + 1 + len(el))
            seen = {}
            for e, row in zip(eids, el):
                for f, (a, b, c) in cm.FACES.items():
                    seen.setdefault(tuple(sorted((row[a], row[b], row[c]))), []).append((int(e), f, (row[a], row[b], row[c]), row))
            bfaces = [v[0] for v in seen.values() if len(v) == 1]
            self.parts[name] = dict(tags=tags, el=el, eids=eids, bfaces=bfaces)
            print('%-6s nodes %7d elements %7d surface faces %7d' % (name, len(tags), len(el), len(bfaces)), flush=True)
            nid0, eid0 = int(tags.max()), int(eids.max())
        self.max_eid = eid0

        T, X = TOL, self.X
        tb = lambda y: d['LEDGE_H'] + (y - d['TRAY_Y1']) * d['TAN']
        on_ledge = lambda p: d['IX'] - d['LEDGE_W'] - T <= abs(p[0]) <= d['IX'] + T
        z_rt = d['Z_R'] + d['RACK_T']                            # the rack floor's top: the bins stand on it
        z_bt = d['ARM_Z'] + d['HANDLE_S'] / 2                    # the handle bar's top
        y_bb = d['BAR_Y'] + d['HANDLE_S'] / 2                    # the bar's back face, towards the wall
        bar = lambda p: p[1] <= y_bb + T                         # the bar, not the arms
        x_in = d['SPAN'] / 2                                     # the arms' inner faces, where the pins start
        diamond = d['PIN_S'] / math.sqrt(2) + 2.0                # the pins and sockets' half diagonal, with the socket's lead-in
        in_socket = lambda p: abs(p[1] - d['PIN_Y']) + abs(p[2] - d['ARM_Z']) <= diamond
        self.surf = {
            # joints: slave (first), master (second)
            'TRAY_BOTTOM': self.faces('tray', lambda p: abs(p[2] - tb(p[1])) < T and abs(p[0]) >= d['IX'] - d['LEDGE_W'] - 1.0),
            'TRAY_LEDGES': self.faces('body', lambda p: abs(p[2] - tb(p[1])) < T and on_ledge(p) and p[2] < d['Z_R'] - 5),
            'RACK_BOTTOM': self.faces('rack', lambda p: abs(p[2] - d['Z_R']) < T and abs(p[0]) >= d['IX'] - d['LEDGE_W'] - 1.0),
            'RACK_LEDGES': self.faces('body', lambda p: abs(p[2] - d['Z_R']) < T and on_ledge(p)),
            # the tails, but not the stepped lead-ins at their ends: their steps stand up to a few
            # tenths off the housing, and a tie across that gap does not carry the moment through
            'TAILS': self.faces('body', lambda p: abs(abs(p[0]) - d['HOUSE_X']) <= d['CAV_X1'] + T and p[1] >= -d['BACK_T'] - d['DT_D'] - T
                                and (abs(p[2]) < 0.05 or 1.0 < p[2] < d['TOP'] - 1.0)),
            'HOUSINGS': self.faces('plate', lambda p: abs(abs(p[0]) - d['HOUSE_X']) <= d['CAV_X1'] + T
                                   and -d['BACK_T'] - d['HOUSE_D'] - T <= p[1] <= -d['BACK_T'] + T and p[2] >= -T),
            'PINS': self.faces('handle', lambda p: x_in - d['PIN_LEN'] - T <= abs(p[0]) < x_in - 0.05 and in_socket(p)),
            'SOCKETS': self.faces('body', lambda p: abs(p[0]) >= d['HX'] - d['PIN_LEN'] - 3 and in_socket(p)),
        }
        self.loads = {'BIN%d' % i: self.faces('rack', lambda p, x=x: abs(p[2] - z_rt) < T and abs(p[0] - x) <= d['BIN_W'] / 2
                                              and d['BIN_Y1'] <= p[1] <= d['BIN_Y0'])
                      for i, x in enumerate(d['BIN_XS'])}
        self.loads.update({
            'TOWEL': self.faces('handle', lambda p: abs(p[2] - z_bt) < T and bar(p) and abs(p[0]) <= 85),
            # a pull on the towel, down and forward: on the bar's top and its back face,
            # in the middle or at the right-hand end, next to the arm's inner corner
            'PULL_C_TOP': self.faces('handle', lambda p: abs(p[2] - z_bt) < T and bar(p) and abs(p[0]) <= 15),
            'PULL_C_BACK': self.faces('handle', lambda p: abs(p[1] - y_bb) < T and abs(p[0]) <= 15),
            'PULL_E_TOP': self.faces('handle', lambda p: abs(p[2] - z_bt) < T and bar(p) and x_in - 40 <= p[0] <= x_in - 10),
            'PULL_E_BACK': self.faces('handle', lambda p: abs(p[1] - y_bb) < T and x_in - 40 <= p[0] <= x_in - 10),
        })
        for k, v in list(self.surf.items()) + list(self.loads.items()):
            print('surface %-12s %6d faces %8.1f mm2' % (k, len(v), self.area(v)), flush=True)

        # the wall: per cup, the button clamps its pad between the flange and the head, so the
        # button is a rigid body on the shank's bearing (the top of the slot) and the flange's
        # disc on the plate's back face, with the stud and the cup's hub out to the wall. The cup
        # holds it where it meets the wall, in every direction, but lets it tilt: a suction cup
        # hardly resists a turn, it peels. (Holding those nodes
        # fixed let each cup take a moment, about half the drainer's, and halved the pull on
        # the upper cups.)
        self.cups = []
        for cx, cz in d['CUPS']:
            shank, flange = [], []
            for t in self.parts['plate']['tags']:
                p = X[int(t)]
                r = math.hypot(p[0] - cx, p[2] - cz)
                if -(d['PAD_T'] - d['CONE']) - T <= p[1] <= T and abs(r - d['SHANK_R']) < T and p[2] >= cz - T:
                    shank.append(int(t))
                if abs(p[1]) < T and d['SHANK_R'] - T <= r <= d['FLANGE_R']:
                    flange.append(int(t))
            flange = sorted(set(flange) | set(shank))
            self.cups.append((shank, flange))
        n0 = max(self.X)
        self.refs = [(n0 + 2 * i + 1, n0 + 2 * i + 2, (cx, d['WALL_GAP'], cz)) for i, (cx, cz) in enumerate(d['CUPS'])]

    def faces(self, part, pred):
        out = []
        for e, f, ns, row in self.parts[part]['bfaces']:
            ps = [self.X[int(n)] for n in ns]
            if all(pred(p) for p in ps):
                out.append((e, f, ps, ns))
        return out

    @staticmethod
    def area(fs):
        return sum(0.5 * np.linalg.norm(np.cross(p[1] - p[0], p[2] - p[0])) for _, _, p, _ in fs)

    def write_mesh(self, f):
        """Nodes, elements, surfaces, wall sets, material and the wall's boundary conditions."""
        f.write('*NODE, NSET=NALL\n')
        for t in sorted(self.X):
            f.write('%d, %.6f, %.6f, %.6f\n' % (t, *self.X[t]))
        for name, p in self.parts.items():
            f.write('*ELEMENT, TYPE=C3D10, ELSET=%s\n' % name.upper())
            for e, row in zip(p['eids'], p['el']):
                f.write('%d, %s\n' % (e, ', '.join(str(int(n)) for n in row)))
        f.write('*ELSET, ELSET=EALL\n%s\n' % ', '.join(n.upper() for n in PARTS))
        for k, v in list(self.surf.items()) + list(self.loads.items()):
            f.write('*SURFACE, NAME=%s, TYPE=ELEMENT\n' % k)
            for e, fc, _, _ in v:
                f.write('%d, S%d\n' % (e, fc))
        for i, (shank, flange) in enumerate(self.cups):
            f.write('*NSET, NSET=SHANK%d\n%s\n' % (i + 1, '\n'.join(map(str, shank))))
            f.write('*NSET, NSET=RING%d\n%s\n' % (i + 1, '\n'.join(map(str, flange))))
        f.write('*NODE\n')
        for a, b, c in self.refs:
            f.write('%d, %.6f, %.6f, %.6f\n%d, %.6f, %.6f, %.6f\n' % (a, *c, b, *c))
        for i, (a, b, c) in enumerate(self.refs):
            f.write('*NSET, NSET=FLANGE%d\n%d\n*RIGID BODY, NSET=RING%d, REF NODE=%d, ROT NODE=%d\n' % (i + 1, a, i + 1, a, b))
        f.write('*MATERIAL, NAME=PETG\n*ELASTIC\n%g, %g\n*DENSITY\n%g\n' % (E, NU, RHO))
        f.write('*SOLID SECTION, ELSET=EALL, MATERIAL=PETG\n')
        f.write('*BOUNDARY\n')
        for i in range(len(self.cups)):
            f.write('FLANGE%d, 1, 3\n' % (i + 1))

    def write_loads(self, f, loads):
        """*DLOAD lines: own weight and {surface: force in N}, spread evenly over it,
        pressing into the part (down on a top face, forward on the bar's back face)."""
        f.write('*DLOAD, OP=NEW\nEALL, GRAV, 9810., 0., 0., -1.\n')
        for k, F in loads.items():
            fs = self.loads[k]
            p = F / self.area(fs)
            for e, fc, _, _ in fs:
                f.write('%d, P%d, %.6f\n' % (e, fc, p))

    def write_output(self, f):
        for i in range(len(self.cups)):
            f.write('*NODE PRINT, NSET=FLANGE%d, TOTALS=ONLY\nRF\n' % (i + 1))
        f.write('*NODE FILE\nU\n*EL FILE\nS\n')


def print_cups(tot):
    print('reaction at each cup (the wall on the plate, N); y < 0: presses on the wall, y > 0: pulls off it')
    for i, n in enumerate(CUP_NAMES):
        r = tot['FLANGE%d' % (i + 1)]
        print('  %-13s down %6.2f  sideways %6.2f  y %7.2f' % (n, r[2], r[0], r[1]))
    print('  total down %.2f N' % sum(tot['FLANGE%d' % (i + 1)][2] for i in range(4)))
