"""The soap caddy on the wall, nonlinear, with contact on every joint and on
everything that guides or stops the loose parts (tools/fea/README.md,
Assembly). Daily-use load case only, to compare with assembly_tie.py.

Contacts (slave, master), linear penalty; friction 0.3 where the tray and
the box stand on their sloping or flat ledges (frictionless, the tray would
slide down its 6 deg ledges: tan 6 deg = 0.11 < 0.3 holds it), frictionless
elsewhere:
  tray underside on its ledges      box floor on its ledges
  tails in the housings (closing the 0.025 mm play)
  tray and box sides on the body's side walls (0.25 mm play)
  box front on the returns          box back on the housings' lips (0.5 mm)
  tray back on the housings' lips   tray front corners on the ledges' bumps (6-14 mm)

usage: python assembly_contact.py <dir of STEP or OpenSCAD STL parts> <out dir> <mesh size mm> [check]
"""
import sys, os, subprocess, time
import numpy as np
from caddy_model import *

src, out, h = sys.argv[1], sys.argv[2], float(sys.argv[3])
os.makedirs(out, exist_ok=True)
PAIRS = [('TRAY_BOTTOM', 'TRAY_LEDGES', 0, 'SIF'), ('BOX_BOTTOM', 'BOX_LEDGES', 0, 'SIF'), ('TAILS', 'HOUSINGS', 0.05),
         ('TRAY_SIDES', 'TRAY_WALLS', 0), ('BOX_SIDES', 'BOX_WALLS', 0), ('BOX_FRONT', 'RETURNS', 0),
         ('BOX_BACK', 'HOUSING_FRONTS', 0), ('TRAY_BACK', 'HOUSING_FRONTS_LOW', 0), ('TRAY_FRONT', 'BUMPS', 0)]

import caddy_model
if not os.path.exists(os.path.join(src, 'plate.step')):
    # OpenSCAD STLs (make stl): the caddy's dimensions from the .scad, and a tolerance for
    # fTetWild's surface, which stays within 0.1 mm of the STL
    caddy_model.configure(caddy_model.dims(), tol=0.2)
model = Model(src, h)
if sys.argv[4:] == ['check']:
    sys.exit(0)
with open(os.path.join(out, 'daily.inp'), 'w') as f:
    model.write_mesh(f)
    # weak springs to ground on the loose parts: the first iteration, before the
    # contacts carry anything, is not singular (0.01 N/mm: negligible)
    sid = model.max_eid + 1
    soft = []
    f.write('*ELEMENT, TYPE=SPRING1, ELSET=SOFT\n')
    for name in ('body', 'tray', 'box'):
        tags = model.parts[name]['tags']
        for t in tags[:: max(1, len(tags) // 4)][:4]:
            for dof in (1, 2, 3):
                soft.append((sid, dof))
                f.write('%d, %d\n' % (sid, int(t)))
                sid += 1
    for dof in (1, 2, 3):
        f.write('*ELSET, ELSET=SOFT%d\n%s\n' % (dof, '\n'.join(str(s) for s, d in soft if d == dof)))
        f.write('*SPRING, ELSET=SOFT%d\n%d\n0.01\n' % (dof, dof))
    f.write('*SURFACE INTERACTION, NAME=SI\n*SURFACE BEHAVIOR, PRESSURE-OVERCLOSURE=LINEAR\n5000.\n')
    f.write('*SURFACE INTERACTION, NAME=SIF\n*SURFACE BEHAVIOR, PRESSURE-OVERCLOSURE=LINEAR\n5000.\n'
            '*FRICTION\n0.3, 2000.\n')
    for pair in PAIRS:
        slave, master, adjust = pair[:3]
        si = pair[3] if len(pair) > 3 else 'SI'
        f.write('*CONTACT PAIR, INTERACTION=%s, TYPE=SURFACE TO SURFACE%s\n%s, %s\n'
                % (si, ', ADJUST=%g' % adjust if adjust else '', slave, master))
    f.write('*STEP, INC=200\n*STATIC\n0.25, 1.0, 1e-4, 0.25\n')
    model.write_loads(f, {'SEAT': (6.5, True), 'HAND': (30.0, False)})
    model.write_output(f)
    f.write('*CONTACT FILE\nCDIS, CSTR\n*END STEP\n')

t = time.time()
env = dict(os.environ, OMP_NUM_THREADS='12', CCX_NPROC_EQUATION_SOLVER='12', CCX_NPROC_RESULTS='12')
subprocess.run(['ccx', '-i', 'daily'], cwd=out, check=True, env=env, stdout=open(os.path.join(out, 'daily.log'), 'w'))
U, S = read_frd(os.path.join(out, 'daily.frd'))
print('\n=== daily, contact (%.0f s)' % (time.time() - t))
print_cups(cup_reactions(os.path.join(out, 'daily.dat')))
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
