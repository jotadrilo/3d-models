"""The soap caddy on the wall, linear, its joints bonded (*TIE), one run per
load case (tools/fea/README.md, Load cases):

  daily    the bottle on its 45 deg neck seat (6.5 N), the hand on the sponge (30 N)
  squeeze  the bottle on its seat, 30 N pushing it towards the wall on the
           inside of the box's back wall; the box's back corners bonded to
           the housings' lips 0.5 mm behind (they close that gap and press)
  bottle   the bottle on its seat alone: the permanent load

All with the parts' own weight. For each case it prints the cup reactions,
the largest deflection, stress levels per part, and whether any bonded
joint is in tension (which the real joint, made to push only, could not
carry). For the squeeze case it also prints how far the box's back wall
moves at the upper buttons, against their 1.9 mm gap.

usage: python assembly_tie.py <dir of STEP or OpenSCAD STL parts> <out dir> <mesh size mm>[,part=size,...] [case ... | check]
(e.g. 2.5,plate=1.0 refines the plate only)
"""
import sys, os, subprocess, time
import numpy as np
from caddy_model import *

src, out = sys.argv[1], sys.argv[2]
h = dict(default=float(sys.argv[3].split(',')[0]),
         **{k: float(v) for k, v in (kv.split('=') for kv in sys.argv[3].split(',')[1:])})
cases = sys.argv[4:] or ['daily', 'squeeze', 'bottle']
os.makedirs(out, exist_ok=True)

TIES = [('TRAY_BOTTOM', 'TRAY_LEDGES'), ('BOX_BOTTOM', 'BOX_LEDGES'), ('TAILS', 'HOUSINGS')]
LOADS = {
    'daily': {'SEAT': (6.5, True), 'HAND': (30.0, False)},
    'squeeze': {'SEAT': (6.5, True), 'SQUEEZE': (30.0, False)},
    'bottle': {'SEAT': (6.5, True)},
}

import caddy_model
if not os.path.exists(os.path.join(src, 'plate.step')):
    # OpenSCAD STLs (make stl): the caddy's dimensions from the .scad, and a tolerance for
    # fTetWild's surface, which stays within 0.1 mm of the STL
    caddy_model.configure(caddy_model.dims(), tol=0.2)
model = Model(src, h)
if cases == ['check']:       # mesh and pick the surfaces only
    sys.exit(0)
env = dict(os.environ, OMP_NUM_THREADS='12', CCX_NPROC_EQUATION_SOLVER='12', CCX_NPROC_RESULTS='12')
for case in cases:
    ties = TIES + ([('BOX_BACK', 'HOUSING_FRONTS')] if case == 'squeeze' else [])
    with open(os.path.join(out, case + '.inp'), 'w') as f:
        model.write_mesh(f)
        for i, (slave, master) in enumerate(ties):
            f.write('*TIE, NAME=T%d, POSITION TOLERANCE=0.6, ADJUST=NO\n%s, %s\n' % (i + 1, slave, master))
        f.write('*STEP\n*STATIC\n')
        model.write_loads(f, LOADS[case])
        model.write_output(f)
        f.write('*END STEP\n')
    t = time.time()
    subprocess.run(['ccx', '-i', case], cwd=out, check=True, env=env, stdout=open(os.path.join(out, case + '.log'), 'w'))
    U, S = read_frd(os.path.join(out, case + '.frd'))
    print('\n=== %s (%.0f s)' % (case, time.time() - t))
    print_cups(cup_reactions(os.path.join(out, case + '.dat')))
    n = max(U, key=lambda k: np.linalg.norm(U[k]))
    print('largest deflection %.2f mm at %s' % (np.linalg.norm(U[n]), np.round(model.X[n], 1)))
    for name in PARTS:
        tags = model.parts[name]['tags']
        s = np.array([S[int(t)] for t in tags])
        sxx, syy, szz, sxy, syz, szx = s.T
        vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + syz ** 2 + szx ** 2))
        j = int(np.argmax(vm))
        print('  %-6s von Mises p99.5 %5.2f MPa, peak %5.2f at %s' % (name, np.percentile(vm, 99.5), vm[j],
                                                                   np.round(model.X[int(tags[j])], 1)))
    for slave, master in ties:
        frac, smax, smin = joint_tension(model, S, slave)
        print('  joint %-11s -> %-14s in tension over %5.1f %% of its area (max %+.2f MPa, min %+.2f MPa)'
              % (slave, master, 100 * frac, smax, smin))
    if case == 'squeeze':
        # the box's back wall at the upper buttons (x = 0, at their heads' heights)
        gap = []
        for cx, cz in CUPS[2:]:
            near = [t for t in model.parts['box']['tags'] if abs(model.X[int(t)][1] - TRAY_Y0) < TOL
                    and abs(model.X[int(t)][0] - cx) < 6 and abs(model.X[int(t)][2] - cz) < 6]
            if near:
                gap.append(max(U[int(t)][1] for t in near))
        print('  box back wall at the upper buttons moves %s mm towards the wall (gap 1.9 mm)' % np.round(gap, 2))
