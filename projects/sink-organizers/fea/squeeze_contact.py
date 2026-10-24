"""Squeezing the bottle towards the wall (tools/fea/README.md, Load cases),
with the one contact that case needs, for plate variants from variants.py.

The joints stay bonded (the trays and the box on their ledges, the tails in
the housings). Only the box's back wall gets contact, frictionless, with what
it can close on: the heads of the upper buttons (rigid discs, 12 mm, 1.9 mm
behind it, held in space as their cups hold them) and the plate's front
faces (pads, plate, the housings' lips). Loads: the bottle on its seat
(6.5 N), 30 N pushing it towards the wall on the inside of the box's back
wall, own weight.

usage: python squeeze_contact.py <out dir> [variant ...]   (names as in variants.py)
"""
import sys, os, subprocess, time, math
import numpy as np
import gmsh
import caddy_model as cm
from variants import VARIANTS, H, SCAD

TIES = [('TRAY_BOTTOM', 'TRAY_LEDGES'), ('BOX_BOTTOM', 'BOX_LEDGES'), ('TAILS', 'HOUSINGS')]
LOADS = {'SEAT': (6.5, True), 'SQUEEZE': (30.0, False)}
HEAD_R, HEAD_CYL, SHANK_PLAY = 6.0, 1.2, 0.1


def heads(nid0, eid0):
    """The upper buttons' heads, as discs in front of their keyholes."""
    gmsh.initialize()
    gmsh.option.setNumber('General.Terminal', 0)
    y1 = -(cm.PAD_T + SHANK_PLAY + HEAD_CYL)            # the heads' front faces
    for cx, cz in cm.CUPS[2:]:
        gmsh.model.occ.addCylinder(cx, -cm.PAD_T, cz, 0, y1 + cm.PAD_T, 0, HEAD_R)
    gmsh.model.occ.synchronize()
    gmsh.option.setNumber('Mesh.MeshSizeMax', 1.0)
    gmsh.option.setNumber('Mesh.ElementOrder', 2)
    gmsh.model.mesh.generate(3)
    tags, coords, _ = gmsh.model.mesh.getNodes()
    et, _, en = gmsh.model.mesh.getElements(3)
    el = np.array(en[list(et).index(11)], dtype=np.int64).reshape(-1, 10)[:, [0, 1, 2, 3, 4, 5, 6, 7, 9, 8]]
    gmsh.finalize()
    idx = {int(t): i for i, t in enumerate(tags)}
    X = coords.reshape(-1, 3)
    el = np.vectorize(lambda t: idx[int(t)] + 1)(el)
    nodes = {nid0 + i + 1: X[i] for i in range(len(X))}
    els = [(eid0 + k + 1, row + nid0) for k, row in enumerate(el)]
    # their front faces
    front = []
    for e, row in els:
        for f, (a, b, c) in cm.FACES.items():
            if all(abs(nodes[int(row[i])][1] - y1) < 1e-3 for i in (a, b, c)):
                front.append((e, f))
    return nodes, els, front, y1


def main():
    out = sys.argv[1]
    names = [v for v in VARIANTS if not sys.argv[2:] or v.split()[0] in sys.argv[2:]]
    env = dict(os.environ, OMP_NUM_THREADS='12', CCX_NPROC_EQUATION_SOLVER='12', CCX_NPROC_RESULTS='12')
    for name in names:
        defs = VARIANTS[name]
        d = os.path.join(out, name.split()[0])
        os.makedirs(d, exist_ok=True)
        t0 = time.time()
        procs = [subprocess.Popen(['openscad', '-o', os.path.join(d, p + '.stl'), '-D', 'part="%s"' % p]
                                  + [a for x in defs for a in ('-D', x)] + [SCAD], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                 for p in cm.PARTS]
        for p in procs:
            p.wait()
        cm.configure(cm.dims(defs), tol=0.2)
        cm.mesh_parts(d, H)
        model = cm.Model(d, H)
        T = cm.TOL
        back = model.faces('box', lambda p: abs(p[1] - cm.TRAY_Y0) < T)
        wall_side = model.faces('plate', lambda p: p[2] >= cm.Z_SEAT - 2 and (
            abs(p[1] + cm.BACK_T) < T or abs(p[1] + cm.PAD_T) < T or abs(p[1] + cm.BACK_T + cm.HOUSE_D) < T))
        hn, he, hfront, y1 = heads(max(model.X), model.max_eid + 1000)
        print('box back %d faces, plate front %d faces, head fronts %d faces' % (len(back), len(wall_side), len(hfront)), flush=True)
        with open(os.path.join(d, 'squeeze.inp'), 'w') as f:
            model.write_mesh(f)
            f.write('*NODE, NSET=HEADN\n')
            for t, p in hn.items():
                f.write('%d, %.6f, %.6f, %.6f\n' % (t, *p))
            f.write('*ELEMENT, TYPE=C3D10, ELSET=HEADS\n')
            for e, row in he:
                f.write('%d, %s\n' % (e, ', '.join(str(int(n)) for n in row)))
            f.write('*SURFACE, NAME=BOX_BACK_ALL, TYPE=ELEMENT\n' + ''.join('%d, S%d\n' % (e, fc) for e, fc, _, _ in back))
            f.write('*SURFACE, NAME=WALL_SIDE, TYPE=ELEMENT\n' + ''.join('%d, S%d\n' % (e, fc) for e, fc, _, _ in wall_side)
                    + ''.join('%d, S%d\n' % (e, fc) for e, fc in hfront))
            f.write('*MATERIAL, NAME=RIGID\n*ELASTIC\n200000., 0.3\n*SOLID SECTION, ELSET=HEADS, MATERIAL=RIGID\n')
            f.write('*BOUNDARY\nHEADN, 1, 3\n')
            for i, (slave, master) in enumerate(TIES):
                f.write('*TIE, NAME=T%d, POSITION TOLERANCE=0.6, ADJUST=NO\n%s, %s\n' % (i + 1, slave, master))
            f.write('*SURFACE INTERACTION, NAME=SI\n*SURFACE BEHAVIOR, PRESSURE-OVERCLOSURE=LINEAR\n5000.\n')
            f.write('*CONTACT PAIR, INTERACTION=SI, TYPE=SURFACE TO SURFACE\nBOX_BACK_ALL, WALL_SIDE\n')
            f.write('*STEP, INC=100\n*STATIC\n0.25, 1.0, 1e-4, 0.25\n')
            model.write_loads(f, LOADS)
            model.write_output(f)
            f.write('*NODE PRINT, NSET=HEADN, TOTALS=ONLY\nRF\n*CONTACT FILE\nCDIS, CSTR\n*END STEP\n')
        subprocess.run(['ccx', '-i', 'squeeze'], cwd=d, check=True, env=env, stdout=open(os.path.join(d, 'squeeze.log'), 'w'))
        U, S = cm.read_frd(os.path.join(d, 'squeeze.frd'))
        tot = cm.cup_reactions(os.path.join(d, 'squeeze.dat'))
        bt = [t for t in model.parts['box']['tags'] if int(t) in S]
        s = np.array([S[int(t)] for t in bt])
        sxx, syy, szz, sxy, syz, szx = s.T
        vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + syz ** 2 + szx ** 2))
        Pb = np.array([model.X[int(t)] for t in bt])
        uy = max(U[int(t)][1] for t in bt if abs(model.X[int(t)][1] - cm.TRAY_Y0) < T)
        pt = [t for t in model.parts['plate']['tags'] if int(t) in S]
        plate_u = max(np.linalg.norm(U[int(t)]) for t in pt)
        hy = tot.get('HEADN', np.zeros(3))[1]
        print('%-30s box back moves %.2f mm towards the wall (gap to the heads %.2f); box p99 %.2f, peak %.2f MPa '
              '(szz, across its layers, max %.2f); plate moves %.2f mm; the heads take %.1f N (%.0f s)'
              % (name, uy, y1 - cm.TRAY_Y0, np.percentile(vm, 99), vm.max(), szz.max(), plate_u, -hy, time.time() - t0),
              flush=True)


if __name__ == '__main__':
    main()
