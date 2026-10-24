"""The soap caddy on the wall as an FEA model: meshes, surfaces, loads, the
wall, and the checks the assembly runs share (gmsh or fTetWild + CalculiX).

Parts: the plate, body, tray and box, in place, as STEP (meshed by gmsh) or
as OpenSCAD STL (meshed by fTetWild). The values below are the soap-caddy.scad
defaults; configure() replaces them with a variant's, read from
soap_dims.scad (dims()).
"""
import os, math
import numpy as np
import gmsh

# soap caddy defaults
IX, LEDGE_W, BACK_T = 48.93, 3.36, 1.68
HOUSE_X, CAV_X1, HOUSE_HW, HOUSE_D, DT_D = 49.77, 2.545, 4.225, 5.26, 4.0
Z_SEAT, FLOOR_T, COLLAR_T, WALL_T, Z_S = 119.099, 2.0, 4.0, 1.68, 24.099
TRAY_Y0, TRAY_Y1, TAN = -7.44, -110.5, math.tan(math.radians(6))
BOX_HW, Y_BC, HOLE_R, SEAT = 48.68, -35.62, 17.5, 2.5
CUPS = [(-28.0, 35.399), (28.0, 35.399), (0.0, 143.399), (0.0, 198.399)]
CUP_NAMES = ['lower left', 'lower right', 'upper, lower one', 'upper, top one']
SHANK_R, PAD_T, CONE, FLANGE_R = 3.8, 4.2, 2.5, 8.0
E, NU, RHO = 1460.0, 0.38, 1.27e-9
PARTS = ('plate', 'body', 'tray', 'box')
TOL = 2e-3
LEDGE_H, BOX_FRONT_Y = 4.0, -63.8
tb = lambda y: LEDGE_H + (y - TRAY_Y1) * TAN
HERE = os.path.dirname(os.path.abspath(__file__))


def dims(defs=()):
    """The dimensions soap_dims.scad echoes, with OpenSCAD -D overrides."""
    import subprocess, json, tempfile
    out = tempfile.mktemp(suffix='.echo')
    cmd = ['openscad', '-o', out] + [a for d in defs for a in ('-D', d)] + [os.path.join(HERE, 'soap_dims.scad')]
    subprocess.run(cmd, check=True, capture_output=True)
    d = {}
    for line in open(out):
        if line.startswith('ECHO: "FEA"'):
            k, v = line.split(',', 2)[1:]
            d[k.strip().strip('"')] = json.loads(v.strip())
    return d


def configure(d, tol=None):
    """Use a variant's dimensions (from dims()) and, for STL meshes, a looser tolerance."""
    g = globals()
    for k, v in d.items():
        g[k] = v
    g['CUPS'] = [tuple(c) for c in d['CUPS']]
    g['TAN'] = math.tan(math.radians(d['TRAY_SLOPE']))
    if tol:
        g['TOL'] = tol


def mesh_stl(stl, h, offset=(0, 0, 0), env=0.1, threads=0):
    """An OpenSCAD STL filled with tetrahedra by fTetWild (its surface within env mm),
    made 10-node by a node at the middle of every edge. Cached by the STL's content
    (~/.cache/fea-mesh), so a part a variant leaves unchanged is not meshed again."""
    import meshio, pytetwild, hashlib
    # fTetWild's optimisation, capped: uncapped, the plate's thin slotted mesh ran over 40 min
    # on one core; capped, 1.5 min
    opt = dict(stop_energy=30.0, num_opt_iter=20)
    key = hashlib.md5(open(stl, 'rb').read() + repr((h, offset, env, opt)).encode()).hexdigest()
    cache = os.path.expanduser('~/.cache/fea-mesh/%s.npz' % key)
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    if os.path.exists(cache):
        z = np.load(cache)
        return z['tags'], z['X'], drop_flat(z['X'], z['el'])
    m = meshio.read(stl)
    V, F = np.unique(m.points[m.cells_dict['triangle']].reshape(-1, 3), axis=0, return_inverse=True)
    V = V + np.array(offset)
    v, t4 = pytetwild.tetrahedralize(V.astype(np.float64), F.reshape(-1, 3).astype(np.int32), edge_length_abs=h,
                                     epsilon=env / np.linalg.norm(V.max(0) - V.min(0)), num_threads=threads, **opt)
    a, b, c, d = (v[t4[:, i]] for i in range(4))
    flip = np.einsum('ij,ij->i', np.cross(b - a, c - a), d - a) < 0     # CalculiX's corner order
    t4[flip] = t4[flip][:, [0, 2, 1, 3]]
    edges, mids = {}, []

    def mid(i, j):
        k = (i, j) if i < j else (j, i)
        if k not in edges:
            edges[k] = len(v) + len(mids)
            mids.append((v[i] + v[j]) / 2)
        return edges[k]
    el = np.array([[i, j, k, l, mid(i, j), mid(j, k), mid(k, i), mid(i, l), mid(j, l), mid(k, l)] for i, j, k, l in t4]) + 1
    X = np.vstack([v, np.array(mids)])
    tags = np.arange(1, len(X) + 1)
    np.savez(cache, tags=tags, X=X, el=el)
    return tags, X, drop_flat(X, el)


def drop_flat(X, el, qmin=1e-4):
    """Leave out sliver tetrahedra: volume / (longest edge)^3 under qmin (a regular one is
    0.118). With its optimisation capped, fTetWild leaves a few (about 1 in 1500), next to
    no volume, and CalculiX stops on them (nonpositive jacobian)."""
    p = [X[el[:, i] - 1] for i in range(4)]
    vol = np.einsum('ij,ij->i', np.cross(p[1] - p[0], p[2] - p[0]), p[3] - p[0]) / 6
    longest = np.max([np.linalg.norm(p[i] - p[j], axis=1) for i in range(4) for j in range(i + 1, 4)], axis=0)
    keep = vol / longest ** 3 > qmin
    if (~keep).any():
        print('  left out %d sliver tetrahedra (%.4f mm3)' % ((~keep).sum(), vol[~keep].sum()), flush=True)
    return el[keep]


FACES = {1: (0, 1, 2), 2: (0, 3, 1), 3: (1, 3, 2), 4: (2, 3, 0)}


def mesh_step(step, h):
    gmsh.initialize()
    gmsh.option.setNumber('General.Terminal', 0)
    gmsh.option.setString('Geometry.OCCTargetUnit', 'MM')
    gmsh.model.occ.importShapes(step)
    gmsh.model.occ.synchronize()
    gmsh.option.setNumber('Mesh.MeshSizeMax', h)
    gmsh.option.setNumber('Mesh.MeshSizeMin', h / 4)
    gmsh.option.setNumber('Mesh.ElementOrder', 2)
    gmsh.option.setNumber('Mesh.Algorithm3D', 10)
    gmsh.model.mesh.generate(3)
    tags, coords, _ = gmsh.model.mesh.getNodes()
    et, _, en = gmsh.model.mesh.getElements(3)
    el = np.array(en[list(et).index(11)], dtype=np.int64).reshape(-1, 10)
    gmsh.finalize()
    return tags.astype(np.int64), coords.reshape(-1, 3), el[:, [0, 1, 2, 3, 4, 5, 6, 7, 9, 8]]


def mesh_parts(src, h, threads=4):
    """Mesh every part's STL at once, each with a few threads, into the cache, so
    Model() then only reads them."""
    from concurrent.futures import ProcessPoolExecutor
    jobs = []
    with ProcessPoolExecutor(len(PARTS)) as ex:
        for name in PARTS:
            stl = os.path.join(src, name + '.stl')
            if os.path.exists(stl):
                hp = h.get(name, h['default']) if isinstance(h, dict) else h
                jobs.append(ex.submit(mesh_stl, stl, hp, (0, 0, Z_SEAT) if name == 'box' else (0, 0, 0), 0.1, threads))
        for j in jobs:
            j.result()


class Model:
    def __init__(self, src, h):
        """src: a folder of <part>.step or <part>.stl (OpenSCAD, the box in print
        orientation, moved up to its seat); h: mesh size in mm, or {part: size}
        with a 'default'."""
        self.parts, self.X = {}, {}
        nid0 = eid0 = 0
        for name in PARTS:
            hp = h.get(name, h['default']) if isinstance(h, dict) else h
            step = os.path.join(src, name + '.step')
            if os.path.exists(step):
                tags, coords, el = mesh_step(step, hp)
            else:
                tags, coords, el = mesh_stl(os.path.join(src, name + '.stl'), hp, (0, 0, Z_SEAT) if name == 'box' else (0, 0, 0))
            tags, el = tags + nid0, el + nid0
            for t, p in zip(tags, coords):
                self.X[int(t)] = p
            eids = np.arange(eid0 + 1, eid0 + 1 + len(el))
            seen = {}
            for e, row in zip(eids, el):
                for f, (a, b, c) in FACES.items():
                    seen.setdefault(tuple(sorted((row[a], row[b], row[c]))), []).append((int(e), f, (row[a], row[b], row[c]), row))
            bfaces = [v[0] for v in seen.values() if len(v) == 1]
            self.parts[name] = dict(tags=tags, el=el, eids=eids, bfaces=bfaces)
            print('%-6s nodes %7d elements %7d surface faces %7d' % (name, len(tags), len(el), len(bfaces)), flush=True)
            nid0, eid0 = int(tags.max()), int(eids.max())
        self.max_eid = eid0

        X = self.X
        on_ledge = lambda p: IX - LEDGE_W - TOL <= abs(p[0]) <= IX + TOL
        cone = lambda p: (abs(math.hypot(p[0], p[1] - Y_BC) - (HOLE_R + p[2] - (Z_SEAT + COLLAR_T - SEAT))) < max(0.02, TOL)
                          and Z_SEAT + COLLAR_T - SEAT - TOL <= p[2] <= Z_SEAT + COLLAR_T + TOL)
        self.surf = {
            # joints: slave (first), master (second)
            'TRAY_BOTTOM': self.faces('tray', lambda p: abs(p[2] - tb(p[1])) < TOL and abs(p[0]) >= IX - LEDGE_W - 1.0),
            'TRAY_LEDGES': self.faces('body', lambda p: abs(p[2] - tb(p[1])) < TOL and on_ledge(p)),
            'BOX_BOTTOM': self.faces('box', lambda p: abs(p[2] - Z_SEAT) < TOL and abs(p[0]) >= IX - LEDGE_W - 1.0),
            'BOX_LEDGES': self.faces('body', lambda p: abs(p[2] - Z_SEAT) < TOL and on_ledge(p)),
            'TAILS': self.faces('body', lambda p: abs(abs(p[0]) - HOUSE_X) <= CAV_X1 + TOL and p[1] >= -BACK_T - DT_D - TOL),
            'HOUSINGS': self.faces('plate', lambda p: abs(abs(p[0]) - HOUSE_X) <= CAV_X1 + TOL
                                   and -BACK_T - HOUSE_D - TOL <= p[1] <= -BACK_T + TOL and p[2] >= -TOL),
            # the box's back corners, 0.5 mm in front of the housings' lips
            'BOX_BACK': self.faces('box', lambda p: abs(p[1] - TRAY_Y0) < TOL and abs(p[0]) >= HOUSE_X - HOUSE_HW - TOL),
            'HOUSING_FRONTS': self.faces('plate', lambda p: abs(p[1] - (-BACK_T - HOUSE_D)) < TOL
                                         and HOUSE_X - HOUSE_HW - TOL <= abs(p[0]) <= BOX_HW + 0.5 and p[2] >= Z_SEAT - 1),
        }
        # what guides the loose parts sideways and stops them front and back, with its play
        # (only the contact model needs them: a bonded joint already holds every direction)
        self.surf.update({
            'BOX_SIDES': self.faces('box', lambda p: abs(abs(p[0]) - BOX_HW) < TOL),
            'BOX_WALLS': self.faces('body', lambda p: abs(abs(p[0]) - IX) < TOL and p[2] >= Z_SEAT - 1),
            'TRAY_SIDES': self.faces('tray', lambda p: abs(abs(p[0]) - BOX_HW) < TOL),
            'TRAY_WALLS': self.faces('body', lambda p: abs(abs(p[0]) - IX) < TOL and p[2] <= 40),
            'BOX_FRONT': self.faces('box', lambda p: abs(p[1] - BOX_FRONT_Y) < TOL),
            'RETURNS': self.faces('body', lambda p: abs(p[1] - BOX_FRONT_Y) < TOL and p[2] >= Z_SEAT - LEDGE_W - 4.5),
            'TRAY_BACK': self.faces('tray', lambda p: abs(p[1] - TRAY_Y0) < TOL and abs(p[0]) >= HOUSE_X - HOUSE_HW - TOL),
            'HOUSING_FRONTS_LOW': self.faces('plate', lambda p: abs(p[1] - (-BACK_T - HOUSE_D)) < TOL
                                             and HOUSE_X - HOUSE_HW - TOL <= abs(p[0]) <= BOX_HW + 0.5 and p[2] <= 30),
            # the tray's rounded front corners, low down, 6-14 mm behind the ledges' bumps
            'TRAY_FRONT': self.faces('tray', lambda p: p[1] <= TRAY_Y1 + 16 and abs(p[0]) >= IX - LEDGE_W - 1.0 and p[2] <= 7),
            'BUMPS': self.faces('body', lambda p: abs(p[1] - (TRAY_Y1 - 0.5)) < TOL and on_ledge(p)),
        })
        self.loads = {
            'HAND': self.faces('tray', lambda p: abs(p[2] - Z_S) < TOL and abs(p[0]) <= 45.0),
            'SEAT': self.faces('box', cone),
            'SQUEEZE': self.faces('box', lambda p: abs(p[1] - (TRAY_Y0 - WALL_T)) < TOL and abs(p[0]) <= 35.0
                                  and Z_SEAT + 20 <= p[2] <= Z_SEAT + 85),
        }
        for k, v in list(self.surf.items()) + list(self.loads.items()):
            print('surface %-15s %6d faces %8.1f mm2' % (k, len(v), self.area(v)), flush=True)

        # the wall: per cup, the shank on the top of the slot, the flange and head round it
        self.cups = []
        for cx, cz in CUPS:
            shank, flange = [], []
            for t in self.parts['plate']['tags']:
                p = X[int(t)]
                r = math.hypot(p[0] - cx, p[2] - cz)
                if -(PAD_T - CONE) - TOL <= p[1] <= TOL and abs(r - SHANK_R) < max(0.05, TOL) and p[2] >= cz - TOL:
                    shank.append(int(t))
                if abs(p[1]) < TOL and SHANK_R - TOL <= r <= FLANGE_R:
                    flange.append(int(t))
            self.cups.append((shank, flange))

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
            f.write('*NSET, NSET=FLANGE%d\n%s\n' % (i + 1, '\n'.join(map(str, flange))))
        f.write('*MATERIAL, NAME=PETG\n*ELASTIC\n%g, %g\n*DENSITY\n%g\n' % (E, NU, RHO))
        f.write('*SOLID SECTION, ELSET=EALL, MATERIAL=PETG\n')
        f.write('*BOUNDARY\n')
        for i in range(len(self.cups)):
            f.write('SHANK%d, 1, 1\nSHANK%d, 3, 3\nFLANGE%d, 2, 2\n' % (i + 1, i + 1, i + 1))

    def write_loads(self, f, loads):
        """*DLOAD lines: own weight and {surface: (vertical or total force, cone)}."""
        f.write('*DLOAD, OP=NEW\nEALL, GRAV, 9810., 0., 0., -1.\n')
        for k, (F, on_cone) in loads.items():
            fs = self.loads[k]
            p = F / (self.area(fs) * (math.cos(math.radians(45)) if on_cone else 1.0))
            for e, fc, _, _ in fs:
                f.write('%d, P%d, %.6f\n' % (e, fc, p))

    def write_output(self, f):
        for i in range(len(self.cups)):
            f.write('*NODE PRINT, NSET=SHANK%d, TOTALS=ONLY\nRF\n*NODE PRINT, NSET=FLANGE%d, TOTALS=ONLY\nRF\n' % (i + 1, i + 1))
        f.write('*NODE FILE\nU\n*EL FILE\nS\n')


def cup_reactions(dat):
    """The last total force per node set in a .dat file."""
    tot, cur = {}, None
    for l in open(dat):
        if 'total force' in l and 'set' in l:
            cur = l.split('set')[1].split()[0]
        elif cur and l.strip():
            tot[cur] = np.array(list(map(float, l.split()[:3])))
            cur = None
    return tot


def print_cups(tot):
    print('reaction at each cup (the wall on the plate, N); y < 0: presses on the wall, y > 0: pulls off it')
    for i, n in enumerate(CUP_NAMES):
        s, fl = tot['SHANK%d' % (i + 1)], tot['FLANGE%d' % (i + 1)]
        print('  %-17s down %6.2f  sideways %6.2f  y %7.2f' % (n, s[2], s[0], fl[1]))
    print('  total down %.2f N' % sum(tot['SHANK%d' % (i + 1)][2] for i in range(4)))


def read_frd(path):
    """Nodal U and S of the last increment in a .frd."""
    U, S, block = {}, {}, None
    for line in open(path):
        if line.startswith(' -4'):
            block = line.split()[1]
            continue
        if line.startswith(' -3'):
            block = None
            continue
        if block in ('DISP', 'STRESS') and line.startswith(' -1'):
            n = int(line[3:13])
            v = [float(line[13 + 12 * i:25 + 12 * i]) for i in range((len(line.rstrip()) - 13) // 12)]
            (U if block == 'DISP' else S)[n] = np.array(v[:3] if block == 'DISP' else v[:6])
    return U, S


def joint_tension(model, S, surface):
    """Normal stress across a joint, on its slave faces: compression < 0. Returns
    (area fraction in tension over 0.05 MPa, largest tension, largest compression)."""
    tens = tot = 0.0
    smax, smin = -1e9, 1e9
    for e, fc, ps, ns in model.surf[surface]:
        a = 0.5 * np.linalg.norm(np.cross(ps[1] - ps[0], ps[2] - ps[0]))
        n = np.cross(ps[1] - ps[0], ps[2] - ps[0])
        n /= np.linalg.norm(n)
        # outward normal of the slave part: away from the element's fourth corner
        row = next(r for r in [model.parts[p]['el'][e - model.parts[p]['eids'][0]] for p in PARTS
                               if model.parts[p]['eids'][0] <= e <= model.parts[p]['eids'][-1]])
        other = [int(x) for x in row[:4] if int(x) not in [int(m) for m in ns]][0]
        if np.dot(n, model.X[other] - ps[0]) > 0:
            n = -n
        sn = []
        for node in ns:
            s = S[int(node)]
            t = np.array([[s[0], s[3], s[5]], [s[3], s[1], s[4]], [s[5], s[4], s[2]]])
            sn.append(n @ t @ n)
        v = float(np.mean(sn))
        tot += a
        if v > 0.05:
            tens += a
        smax, smin = max(smax, v), min(smin, v)
    return tens / tot, smax, smin
