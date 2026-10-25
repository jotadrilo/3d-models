"""Static FEA of the onigiri rice scoop with fTetWild + CalculiX (tools/fea).

The hand holds the onigiri handle: the nodes on its top and underside faces
beyond the nori's start are clamped (thumb on top, fingers below). Load cases
from daily use, taking rice out of a jar (no knocking or scraping), each one
linear run (scale them: the model is linear):

  lift   a full scoop lifted: 100 g of rice + the cup, 1.3 N down on the inside
  dig    pushing it into packed rice: 20 N back along the handle on the front of the cup

The geometry is the in-use orientation (rim up, z up); the scoop prints upside
down, so in-use z is the print Z: szz is the stress ACROSS the layers.
Stresses do not depend on E here (a cantilever held at one end, ν nearly the
same), so one run per case serves PLA Pure and PETG; deflections scale by 1/E.

usage: python scoop_fea.py <scoop.stl> <out dir> <mesh size mm>
"""
import sys, os, subprocess, hashlib
import numpy as np

stl, out, h = sys.argv[1], sys.argv[2], float(sys.argv[3])
os.makedirs(out, exist_ok=True)

# From onigiri-rice-scoop.scad (basmati, defaults); the console echo lists them.
H = 45.5657               # rim (and handle top)
HANDLE_T = 5.0
X_WALL = 30.3006          # the cup's flat back, outside
X_PAD = X_WALL + 12       # the onigiri's bottom edge, where the stick meets it
GRIP_X = X_PAD + 6        # clamped beyond here: the fingers hold the onigiri, not the nori edge
NU = 0.36
MATERIALS = {             # E (X-Y), strength along the layers, allowable across them
    'PLA Pure': (2481.0, 51.5, 0.50 * 51.5),   # Bambu TDS V1.0 (tools/materials); CLAUDE.md §2.3 derate 50 %
    'PETG Basic': (2780.0, 51.0, 0.40 * 51.0), # Bambu TDS V3.0 (tools/materials); derate 40 %
}
E_RUN = MATERIALS['PLA Pure'][0]

# ---------------------------------------------------------------- mesh (as tools/fea, case 4)
def mesh_stl(stl, h, env=0.03):
    import meshio, pytetwild
    opt = dict(stop_energy=30.0, num_opt_iter=20)
    key = hashlib.md5(open(stl, 'rb').read() + repr((h, env, opt)).encode()).hexdigest()
    cache = os.path.expanduser('~/.cache/fea-mesh/%s.npz' % key)
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    if not os.path.exists(cache):
        m = meshio.read(stl)
        V, F = np.unique(m.points[m.cells_dict['triangle']].reshape(-1, 3), axis=0, return_inverse=True)
        v, t4 = pytetwild.tetrahedralize(V.astype(np.float64), F.reshape(-1, 3).astype(np.int32), edge_length_abs=h,
                                         epsilon=env / np.linalg.norm(V.max(0) - V.min(0)), **opt)
        a, b, c, d = (v[t4[:, i]] for i in range(4))
        flip = np.einsum('ij,ij->i', np.cross(b - a, c - a), d - a) < 0
        t4[flip] = t4[flip][:, [0, 2, 1, 3]]
        edges, mids = {}, []
        def mid(i, j):
            k = (i, j) if i < j else (j, i)
            if k not in edges:
                edges[k] = len(v) + len(mids)
                mids.append((v[i] + v[j]) / 2)
            return edges[k]
        el = np.array([[i, j, k, l, mid(i, j), mid(j, k), mid(k, i), mid(i, l), mid(j, l), mid(k, l)]
                       for i, j, k, l in t4]) + 1
        np.savez(cache, X=np.vstack([v, np.array(mids)]), el=el)
    z = np.load(cache)
    X, el = z['X'], z['el']
    p = [X[el[:, i] - 1] for i in range(4)]
    vol = np.einsum('ij,ij->i', np.cross(p[1] - p[0], p[2] - p[0]), p[3] - p[0]) / 6
    longest = np.max([np.linalg.norm(p[i] - p[j], axis=1) for i in range(4) for j in range(i + 1, 4)], axis=0)
    return X, el[vol / longest ** 3 > 1e-4]

X, el = mesh_stl(stl, h)
TOL = 0.08
print('nodes %d, elements %d, bbox %s %s' % (len(X), len(el), np.round(X.min(0), 1).tolist(), np.round(X.max(0), 1).tolist()), flush=True)

# ---------------------------------------------------------------- boundary faces with outward normals
FACES = {1: (0, 1, 2), 2: (0, 3, 1), 3: (1, 3, 2), 4: (2, 3, 0)}
OPP = {1: 3, 2: 2, 3: 0, 4: 1}
count = {}
for e in el:
    for f, ix in FACES.items():
        k = tuple(sorted(e[list(ix)]))
        count[k] = count.get(k, 0) + 1
bfaces = []   # (element, face, centroid, area, outward unit normal)
for i, e in enumerate(el):
    for f, ix in FACES.items():
        if count[tuple(sorted(e[list(ix)]))] != 1:
            continue
        pa, pb, pc = (X[e[j] - 1] for j in ix)
        n = np.cross(pb - pa, pc - pa)
        a = np.linalg.norm(n) / 2
        n = n / (2 * a)
        if np.dot(n, X[e[OPP[f]] - 1] - pa) > 0:
            n = -n
        bfaces.append((i + 1, f, (pa + pb + pc) / 3, a, n))
print('%d boundary faces' % len(bfaces), flush=True)

def pick(pred):
    return [b for b in bfaces if pred(b[2], b[4])]

# Load cases: faces, and the direction whose component of the resultant is F.
CASES = {
    'dig': (pick(lambda c, n: c[0] < -15 and n[0] < -0.5 and 0 < c[2] < H - 1),  # outside front of the cup
            np.array([1.0, 0, 0]), 20.0),
}
# a full scoop: every face inside the cavity that faces up (floor and 45° walls)
CASES['lift'] = (pick(lambda c, n: c[0] < X_WALL - 1.8 and c[2] < H - 0.5 and n[2] > 0.3),
                 np.array([0, 0, -1.0]), 1.3)

grip = [i + 1 for i, p in enumerate(X) if p[0] > GRIP_X and
        (abs(p[2] - H) < TOL or abs(p[2] - (H - HANDLE_T)) < TOL)]
print('grip nodes %d' % len(grip))

# ---------------------------------------------------------------- one job per case
# (frd_to_vtu.py and to_ply.py read a job's last step: one case per job)
env = dict(os.environ, OMP_NUM_THREADS='8', CCX_NPROC_EQUATION_SOLVER='8')
cent_el = X[el[:, :4] - 1].mean(axis=1)
for name, (faces, d, F) in CASES.items():
    job = 'scoop_' + name
    res = sum(-a * n for _, _, _, a, n in faces)          # resultant of a unit pressure
    p = F / np.dot(res, d)
    print('%-6s %4d faces, %.0f mm2, pressure %.4f MPa, resultant %s N' % (
        name, len(faces), sum(b[3] for b in faces), p, np.round(p * res, 2).tolist()), flush=True)
    with open(os.path.join(out, job + '.inp'), 'w') as f:
        f.write('*NODE, NSET=NALL\n')
        for i, q in enumerate(X):
            f.write('%d, %.6f, %.6f, %.6f\n' % (i + 1, *q))
        f.write('*ELEMENT, TYPE=C3D10, ELSET=SCOOP\n')
        for i, e in enumerate(el):
            f.write('%d, %s\n' % (i + 1, ', '.join(str(int(n)) for n in e)))
        f.write('*NSET, NSET=GRIP\n' + '\n'.join(map(str, grip)) + '\n')
        f.write('*MATERIAL, NAME=M\n*ELASTIC\n%g, %g\n*SOLID SECTION, ELSET=SCOOP, MATERIAL=M\n' % (E_RUN, NU))
        f.write('*BOUNDARY\nGRIP, 1, 3\n*STEP\n*STATIC\n*DLOAD\n')
        for e, fc, _, _, _ in faces:
            f.write('%d, P%d, %.6f\n' % (e, fc, p))
        f.write('*NODE PRINT, NSET=NALL\nU\n*EL PRINT, ELSET=SCOOP\nS\n*NODE FILE\nU\n*EL FILE\nS\n*END STEP\n')
    subprocess.run(['ccx', '-i', job], cwd=out, check=True, env=env, stdout=open(os.path.join(out, job + '.log'), 'w'))

    U, S, mode = [], [], None
    for line in open(os.path.join(out, job + '.dat')):
        if 'displacements' in line:
            mode = 'U'; continue
        if 'stresses' in line:
            mode = 'S'; continue
        v = line.split()
        if not v or not v[0].isdigit():
            continue
        if mode == 'U' and len(v) == 4:
            U.append(list(map(float, v[1:])))
        elif mode == 'S' and len(v) == 8:
            S.append([int(v[0])] + list(map(float, v[2:])))
    U, S = np.array(U), np.array(S)
    sxx, syy, szz, sxy, sxz, syz = S[:, 1:].T
    vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + sxz ** 2 + syz ** 2))
    c = cent_el[S[:, 0].astype(int) - 1]
    umax = np.linalg.norm(U, axis=1).max()
    print('== %s: largest movement %.3f mm with PLA Pure, %.3f mm with PETG' % (
        name, umax, umax * E_RUN / MATERIALS['PETG Basic'][0]))
    regions = {
        'stick (neck)': (c[:, 0] > X_WALL - 0.5) & (c[:, 0] < X_PAD + 2),
        'cup': c[:, 0] <= X_WALL - 0.5,
        'onigiri handle': c[:, 0] >= X_PAD + 2,
    }
    inl = np.maximum(np.abs(sxx), np.abs(syy))   # along the layers: the larger in-plane stress
    for rn, m in regions.items():
        j = np.argmax(np.where(m, vm, -1))
        k = np.argmax(np.where(m, np.abs(szz), -1))
        print('  %-15s vM p99.5 %5.2f max %5.2f at %s | in layers p99.5 %5.2f | across (szz) p99.5 %5.2f max %5.2f at %s MPa' % (
            rn, np.percentile(vm[m], 99.5), vm[j], np.round(c[j], 1).tolist(),
            np.percentile(inl[m], 99.5), np.percentile(np.abs(szz[m]), 99.5), np.abs(szz[k]), np.round(c[k], 1).tolist()))
        for mat, (E, along, across) in MATERIALS.items():
            print('      %-10s margin in layers %4.1fx, across %4.1fx' % (
                mat, along / np.percentile(inl[m], 99.5), across / np.percentile(np.abs(szz[m]), 99.5)))
