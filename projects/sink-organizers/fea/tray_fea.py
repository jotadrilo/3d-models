"""Static FEA of the soap caddy tray (sink-organizers) with gmsh + CalculiX.

Load: a hand pressing the sponge, 30 N spread over the slat tops under the
sponge. Supports: the tray's underside resting on the body's two side ledges
(uz fixed), and a couple of nodes held in x and y against rigid motion.
Material: PETG Basic, Bambu TDS V2.0: E 1460 MPa (X-Y), nu 0.38.

usage: python tray_fea.py <tray.step | tray.stl> <out dir> <mesh size mm>
A STEP is meshed by gmsh; an OpenSCAD STL by fTetWild (pytetwild).
"""
import sys, os, subprocess, math
import numpy as np
import gmsh

stl, out, h = sys.argv[1], sys.argv[2], float(sys.argv[3])
os.makedirs(out, exist_ok=True)

# Geometry, from common.scad / soap-caddy.scad defaults
Z_S = 24.099            # slat tops
IX, LEDGE_W = 48.93, 3.36
SPONGE = (-45.0, 45.0)  # x range of the sponge (90 mm)
F_TOTAL = 30.0          # N
E, NU = 1460.0, 0.38

# ---------------------------------------------------------------- mesh
if stl.lower().endswith(('.step', '.stp')):
    # exact geometry: gmsh, 10-node tetrahedra
    TOL = 1e-3
    gmsh.initialize()
    gmsh.option.setNumber('General.Terminal', 0)
    gmsh.option.setString('Geometry.OCCTargetUnit', 'MM')
    gmsh.model.occ.importShapes(stl)
    gmsh.model.occ.synchronize()
    gmsh.option.setNumber('Mesh.MeshSizeMax', h)
    gmsh.option.setNumber('Mesh.MeshSizeMin', h / 4)
    gmsh.option.setNumber('Mesh.ElementOrder', 2)
    gmsh.option.setNumber('Mesh.Algorithm3D', 10)
    gmsh.model.mesh.generate(3)
    tags, coords, _ = gmsh.model.mesh.getNodes()
    X = coords.reshape(-1, 3)
    etypes, etags, enodes = gmsh.model.mesh.getElements(3)
    el = np.array(enodes[list(etypes).index(11)], dtype=np.int64).reshape(-1, 10)
    gmsh.finalize()
    el = el[:, [0, 1, 2, 3, 4, 5, 6, 7, 9, 8]]   # gmsh -> CalculiX C3D10 order
else:
    # an OpenSCAD STL: fTetWild fills it with 4-node tetrahedra (it copes with the STL's
    # self-intersections, which gmsh refuses), keeping the surface within ENV mm; then
    # a node at the middle of every edge makes them 10-node tetrahedra
    import pytetwild
    ENV = 0.03
    TOL = 2 * ENV
    import meshio
    stl_mesh = meshio.read(stl)                     # OpenSCAD writes ASCII STL
    V, F = np.unique(stl_mesh.points[stl_mesh.cells_dict['triangle']].reshape(-1, 3), axis=0, return_inverse=True)
    v, t4 = pytetwild.tetrahedralize(V.astype(np.float64), F.reshape(-1, 3).astype(np.int32), edge_length_abs=h,
                                     epsilon=ENV / np.linalg.norm(V.max(0) - V.min(0)))
    # CalculiX wants (b - a) x (c - a) . (d - a) > 0; fTetWild numbers them the other way round
    a_, b_, c_, d_ = (v[t4[:, i]] for i in range(4))
    flip = np.einsum('ij,ij->i', np.cross(b_ - a_, c_ - a_), d_ - a_) < 0
    t4[flip] = t4[flip][:, [0, 2, 1, 3]]
    edges = {}
    mids = []
    def mid(a, b):
        k = (a, b) if a < b else (b, a)
        if k not in edges:
            edges[k] = len(v) + len(mids)
            mids.append((v[a] + v[b]) / 2)
        return edges[k]
    el = np.array([[a, b, c, d, mid(a, b), mid(b, c), mid(c, a), mid(a, d), mid(b, d), mid(c, d)] for a, b, c, d in t4]) + 1
    X = np.vstack([v, np.array(mids)])
    tags = np.arange(1, len(X) + 1)
print('bbox', np.round(X.min(0), 2).tolist(), np.round(X.max(0), 2).tolist())
idx = {int(t): i for i, t in enumerate(tags)}
print('nodes %d, elements %d' % (len(tags), len(el)), flush=True)

# ---------------------------------------------------------------- sets
P = lambda n: X[idx[n]]
zmin = X[:, 2].min()
# loaded faces: element faces whose corners lie on the slat tops, under the sponge
FACES = {1: (0, 1, 2), 2: (0, 3, 1), 3: (1, 3, 2), 4: (2, 3, 0)}
loaded, area = [], 0.0
under_sponge = lambda p: SPONGE[0] <= p[0] <= SPONGE[1]
for i, e in enumerate(el):
    for f, (a, b, c) in FACES.items():
        pa, pb, pc = P(e[a]), P(e[b]), P(e[c])
        if all(abs(p[2] - Z_S) < TOL and under_sponge(p) for p in (pa, pb, pc)):
            loaded.append((i + 1, f))
            area += 0.5 * np.linalg.norm(np.cross(pb - pa, pc - pa))
pressure = F_TOTAL / area
# supports: the tray's sloping underside where it rests on the side ledges
TRAY_Y1, TAN = -110.5, math.tan(math.radians(6))
tb = lambda y: 4.0 + (y - TRAY_Y1) * TAN
support = [int(t) for t, p in zip(tags, X) if abs(p[0]) >= IX - LEDGE_W - 1e-6 and abs(p[2] - tb(p[1])) < TOL]
anchor = [support[0], support[len(support) // 2]]
print('slat-top area %.1f mm2 -> pressure %.4f MPa; %d support nodes' % (area, pressure, len(support)))

# ---------------------------------------------------------------- input deck
inp = os.path.join(out, 'tray.inp')
with open(inp, 'w') as f:
    f.write('*NODE, NSET=NALL\n')
    for t, p in zip(tags, X):
        f.write('%d, %.6f, %.6f, %.6f\n' % (t, *p))
    f.write('*ELEMENT, TYPE=C3D10, ELSET=EALL\n')
    for i, e in enumerate(el):
        f.write('%d, %s\n' % (i + 1, ', '.join(str(int(n)) for n in e)))
    f.write('*NSET, NSET=SUPPORT\n' + '\n'.join(str(n) for n in support) + '\n')
    f.write('*NSET, NSET=ANCHOR\n' + '\n'.join(str(n) for n in anchor) + '\n')
    f.write('*MATERIAL, NAME=PETG\n*ELASTIC\n%g, %g\n' % (E, NU))
    f.write('*SOLID SECTION, ELSET=EALL, MATERIAL=PETG\n')
    f.write('*BOUNDARY\nSUPPORT, 3, 3\nANCHOR, 1, 2\n')
    f.write('*STEP\n*STATIC\n*DLOAD\n')
    for e, fc in loaded:
        f.write('%d, P%d, %.6f\n' % (e, fc, pressure))
    f.write('*NODE PRINT, NSET=NALL\nU\n*EL PRINT, ELSET=EALL\nS\n*NODE FILE\nU\n*EL FILE\nS\n*END STEP\n')

# ---------------------------------------------------------------- solve
subprocess.run(['ccx', '-i', 'tray'], cwd=out, check=True, stdout=open(os.path.join(out, 'ccx.log'), 'w'))

# ---------------------------------------------------------------- results
U, S = {}, []
mode = None
for line in open(os.path.join(out, 'tray.dat')):
    if 'displacements' in line:
        mode = 'u'; continue
    if 'stresses' in line:
        mode = 's'; continue
    v = line.split()
    if not v or not v[0].lstrip('-').isdigit():
        continue
    if mode == 'u' and len(v) == 4:
        U[int(v[0])] = np.array(list(map(float, v[1:])))
    elif mode == 's' and len(v) == 8:
        S.append([int(v[0])] + list(map(float, v[2:])))
S = np.array(S)
sxx, syy, szz, sxy, sxz, syz = S[:, 1:].T
vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + sxz ** 2 + syz ** 2))
# principal stresses per integration point
pmax = []
for r in S[:, 1:]:
    m = np.array([[r[0], r[3], r[4]], [r[3], r[1], r[5]], [r[4], r[5], r[2]]])
    pmax.append(np.linalg.eigvalsh(m)[-1])
pmax = np.array(pmax)
uz = np.array([u[2] for u in U.values()])
centroid = lambda e: X[[idx[n] for n in el[e - 1][:4]]].mean(axis=0)
i_vm, i_p = int(np.argmax(vm)), int(np.argmax(pmax))
print('max |u|      %.3f mm (uz min %.3f)' % (max(np.linalg.norm(u) for u in U.values()), uz.min()))
print('max von Mises %.2f MPa at %s' % (vm[i_vm], np.round(centroid(int(S[i_vm, 0])), 1)))
print('max principal %.2f MPa at %s' % (pmax[i_p], np.round(centroid(int(S[i_p, 0])), 1)))
print('99.9th percentile von Mises %.2f MPa (ignores single-point peaks)' % np.percentile(vm, 99.9))
np.save(os.path.join(out, 'vm.npy'), np.c_[S[:, 0], vm, pmax])

# where: the node that sags most, and the stress by region
nmax = max(U, key=lambda n: -U[n][2])
print('largest sag at', np.round(P(nmax), 1))
cent = np.array([centroid(int(e)) for e in S[:, 0]])
regions = {
    'slats (|x| < 44, above the floor)': (np.abs(cent[:, 0]) < 44) & (cent[:, 2] > 17.5),
    'side rims (|x| > 44)': np.abs(cent[:, 0]) > 44,
    'floor (z < 17.5, |x| < 44)': (np.abs(cent[:, 0]) < 44) & (cent[:, 2] <= 17.5),
}
for name, m in regions.items():
    j = np.argmax(vm * m)
    print('%-36s vM max %6.2f  p99.5 %5.2f  principal max %6.2f MPa at %s' % (
        name, vm[j], np.percentile(vm[m], 99.5), (pmax * m).max(), np.round(cent[j], 1)))

# direction of the tension in the slats: syy runs along the slats, which the
# tray prints along Z (on its back), so syy is across the layers
m = regions['slats (|x| < 44, above the floor)']
for comp, v in (('sxx (along x, in the layers)', sxx), ('syy (along y, ACROSS the layers)', syy), ('szz', szz)):
    j = np.argmax(v * m)
    print('slats max tension %-34s %6.2f MPa at %s;  p99.5 %5.2f' % (comp, v[j], np.round(cent[j], 1), np.percentile(v[m], 99.5)))
mr = regions['side rims (|x| > 44)']
for comp, v in (('sxx', sxx), ('syy (across the layers)', syy), ('szz', szz)):
    print('rims  p99.5 tension %-26s %5.2f MPa' % (comp, np.percentile(v[mr], 99.5)))
