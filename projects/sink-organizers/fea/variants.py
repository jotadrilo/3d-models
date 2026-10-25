"""Design variants of the soap caddy's wall plate, each exported from OpenSCAD
with its -D overrides and solved as the bonded assembly in daily use
(tools/fea/README.md, case 4).

usage: python variants.py <out dir> [variant ...]
"""
import sys, os, subprocess, time, math
import numpy as np
import caddy_model as cm

VARIANTS = {                      # one change per experiment from the variant named in the comment
    'V0 as is': [],
    'S0 the slotted plate (as it was before WH0i20)': ['plate_window=[]', 'plate_window_inset=0'],
    'W upper windows, 50 mm tall': ['plate_window=[1]', 'plate_window_inset=14'],                     # H1
    'T1 plate 1.26 mm': ['back_t=1.26'],                                                              # V0
    'T2 plate 2.1 mm': ['back_t=2.1'],                                                                # V0
    'H1 upper windows': ['plate_window=[1]'],                                                         # V0
    'H0 lower window': ['plate_window=[0]'],                                                          # V0
    'C1 no slots by the upper pads': ['plate_slot_clear=4.3'],                                        # V0
    'B1 bridges 3.4 mm': ['plate_bridge=0.8'],                                                        # V0
    'L1 slots at most 22 mm': ['plate_slot_max_len=22'],                                              # V0
    'WH0 W + lower window': ['plate_window=[0,1]', 'plate_window_inset=[0,14]'],                     # W
    'WH0i8 upper bands 8 mm': ['plate_window=[0,1]', 'plate_window_inset=[0,8]'],                    # WH0
    'WH0i20 upper bands 20 mm': ['plate_window=[0,1]', 'plate_window_inset=[0,20]'],                 # WH0
    'WH0i11 upper bands 11 mm': ['plate_window=[0,1]', 'plate_window_inset=[0,11]'],                 # WH0
    'WH0i26 upper bands 26 mm': ['plate_window=[0,1]', 'plate_window_inset=[0,26]'],                 # WH0
}
H = {'default': 2.5, 'plate': 1.5}
CASES = {'daily': {'SEAT': (6.5, True), 'HAND': (30.0, False)},    # bottle on its seat + hand on the sponge
         'bottle': {'SEAT': (6.5, True)}}                          # the permanent load
TIES = [('TRAY_BOTTOM', 'TRAY_LEDGES'), ('BOX_BOTTOM', 'BOX_LEDGES'), ('TAILS', 'HOUSINGS')]
SCAD = os.path.join(cm.HERE, '..', 'soap-caddy.scad')

def main():
    out = sys.argv[1]
    names = [v for v in VARIANTS if not sys.argv[2:] or v.split()[0] in sys.argv[2:]]
    env = dict(os.environ, OMP_NUM_THREADS='12', CCX_NPROC_EQUATION_SOLVER='12', CCX_NPROC_RESULTS='12')
    rows = []
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
        cm.configure(cm.dims(defs), tol=0.2)        # the meshes keep the surface within 0.1 mm
        cm.mesh_parts(d, H)
        model = cm.Model(d, H)
        import meshio
        m = meshio.read(os.path.join(d, 'plate.stl'))
        tri = m.points[m.cells_dict['triangle']]
        vol = abs(np.einsum('ij,ij->i', tri[:, 0], np.cross(tri[:, 1], tri[:, 2])).sum()) / 6
        for case, loads in CASES.items():
            with open(os.path.join(d, case + '.inp'), 'w') as f:
                model.write_mesh(f)
                for i, (slave, master) in enumerate(TIES):
                    f.write('*TIE, NAME=T%d, POSITION TOLERANCE=0.25, ADJUST=NO\n%s, %s\n' % (i + 1, slave, master))
                f.write('*STEP\n*STATIC\n')
                model.write_loads(f, loads)
                model.write_output(f)
                f.write('*END STEP\n')
            subprocess.run(['ccx', '-i', case], cwd=d, check=True, env=env, stdout=open(os.path.join(d, case + '.log'), 'w'))
            U, S = cm.read_frd(os.path.join(d, case + '.frd'))
            tot = cm.cup_reactions(os.path.join(d, case + '.dat'))
            tags = [t for t in model.parts['plate']['tags'] if int(t) in S]   # nodes of left-out flat tetrahedra have no results
            P = np.array([model.X[int(t)] for t in tags])
            s = np.array([S[int(t)] for t in tags])
            sxx, syy, szz, sxy, syz, szx = s.T
            vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + syz ** 2 + szx ** 2))
            # the slotted field: back face, above the box seat, between the housings
            field = (np.abs(P[:, 1]) < cm.TOL) & (P[:, 2] > cm.Z_SEAT - 5) & (np.abs(P[:, 0]) < cm.HOUSE_X - cm.HOUSE_HW - 1)
            j = np.argmax(vm * field)
            n = max(U, key=lambda k: np.linalg.norm(U[k]))
            plate_u = max(np.linalg.norm(U[int(t)]) for t in tags)
            up = [tot['FLANGE3'][1], tot['FLANGE4'][1]]
            p99, largest, secs = np.percentile(vm[field], 99), np.linalg.norm(U[n]), time.time() - t0
            rows.append((name, case, vol, plate_u, vm[j], p99, largest, up))
            print('%-34s %-6s plate %6.0f mm3, moves %.3f mm; slot field peak %5.2f MPa at x %6.1f z %6.1f, p99 %4.2f; '
                  'largest deflection %.3f mm; upper cups pull %.2f / %.2f N (%.0f s)'
                  % (name, case, vol, plate_u, vm[j], P[j][0], P[j][2], p99, largest, up[0], up[1], secs), flush=True)


if __name__ == '__main__':      # the meshing workers re-import this file (macOS spawns them)
    main()
