"""Static FEA of one hooked bracket (dog-gate-hook.scad) under the leaning dog, fTetWild + CalculiX.

Second link of a chain (tools/fea, "Chain of parts"): board_fea.py gives the forces at the bracket's
toe, hook and strap for the leaning dog (variant F45x30, the board with its 3-layer battens; lean case:
2 x 103 N on the top edge, down the stair). Here the bracket rests on them, and the board and batten push on its shoe:
  toe     the foot's underside over its last 30 mm rests on the tread: held vertically, and along
          the stair by friction (the gate's 103 N down the stair per bracket, against 0.7 x 417 N
          with rubber pads)
  hook    the lip's top under the flange's edge (held vertically)
  bolts   the two M6 bolts through lip, board, batten and leg: steel bars from the lip's hole to
          the leg's, each end spread over its hole (distributing coupling)
  shoe    the board's push: forwards on the leg's upper 40 mm, back on the lip's lower 25 mm, the
          two sized so the bracket is in equilibrium with the reactions (contact only, the bolts
          left out: the pessimistic end), and the board's weight on the shoe's floor

Print coordinates (the STL as exported): x = u (from the leg's face towards the toe, which is down
the stair), y = v (up), z = across the bracket, which is the print Z: szz is the stress ACROSS the
layers. ABS, Bambu TDS V3.0: E 2200 MPa (X-Y), tensile 33 MPa in the layers; across them derated to
30 % (CLAUDE.md §2.3), 10 MPa.

usage: python bracket_fea.py <out dir> <mesh size mm>
"""
import sys, os, re, subprocess, hashlib, math
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, '..', 'dog-gate-hook.scad')
out, hmesh = sys.argv[1], float(sys.argv[2])
os.makedirs(out, exist_ok=True)

E, NU = 2200.0, 0.35
ALONG, ACROSS = 33.0, 0.30 * 33.0

# forces on ONE bracket from board_fea.py, F45x30, lean (N); u is down the stair
TOE_V, HOOK_V, STRAP_U, BOARD_V = 398.0, -376.0, -103.0, -22.0


def params():
    vals = {}
    for line in open(SCAD):
        m = re.match(r"(\w+)\s*=\s*([-\d.]+)\s*;", line)
        if m:
            vals[m.group(1)] = float(m.group(2))
        m = re.match(r"bolt_z\s*=\s*\[([-\d.]+),\s*([-\d.]+)\]", line)
        if m:
            vals['bolt_z0'], vals['bolt_z1'] = float(m.group(1)), float(m.group(2))
    r = subprocess.run(['openscad', '-D', 'part="bracket"', '-o', os.path.join(out, 'bracket.stl'), SCAD],
                       capture_output=True, text=True).stderr
    g = dict(re.findall(r"(\w+)=([-\d.e]+)", re.search(r'ECHO: "GEOM ([^"]*)"', r).group(1)))
    vals.update({k: float(v) for k, v in g.items()})
    return vals


P = params()
reach, h, w, m = P['reach'], P['bracket_h'], P['bracket_w'], P['member']
shoe, lip = P['shoe'], P['lip']
heel = P['tread'] / 2 - P['leg_y']
k = math.tan(math.radians(-P['lean']))           # board_bracket's shear: u shifts by -v * k
back = -heel - P['hook_clear']                   # the strap's face on the flange
lip_top = -P['edge_h'] - P['hook_clear']


def mesh_stl(stl, h, env=0.03):   # as projects/onigiri-rice-scoop/fea/scoop_fea.py (tools/fea, case 4)
    import meshio, pytetwild
    opt = dict(stop_energy=30.0, num_opt_iter=20)
    key = hashlib.md5(open(stl, 'rb').read() + repr((h, env, opt)).encode()).hexdigest()
    cache = os.path.expanduser('~/.cache/fea-mesh/%s.npz' % key)
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    if not os.path.exists(cache):
        mm = meshio.read(stl)
        V, F = np.unique(mm.points[mm.cells_dict['triangle']].reshape(-1, 3), axis=0, return_inverse=True)
        v, t4 = pytetwild.tetrahedralize(V.astype(np.float64), F.reshape(-1, 3).astype(np.int32), edge_length_abs=h,
                                         epsilon=env / np.linalg.norm(V.max(0) - V.min(0)), **opt)
        a, b, c, d = (v[t4[:, i]] for i in range(4))
        flip = np.einsum('ij,ij->i', np.cross(b - a, c - a), d - a) < 0
        t4[flip] = t4[flip][:, [0, 2, 1, 3]]
        edges, mids = {}, []
        def mid(i, j):
            kk = (i, j) if i < j else (j, i)
            if kk not in edges:
                edges[kk] = len(v) + len(mids)
                mids.append((v[i] + v[j]) / 2)
            return edges[kk]
        el = np.array([[i, j, kk, l, mid(i, j), mid(j, kk), mid(kk, i), mid(i, l), mid(j, l), mid(kk, l)]
                       for i, j, kk, l in t4]) + 1
        np.savez(cache, X=np.vstack([v, np.array(mids)]), el=el)
    z = np.load(cache)
    X, el = z['X'], z['el']
    p = [X[el[:, i] - 1] for i in range(4)]
    vol = np.einsum('ij,ij->i', np.cross(p[1] - p[0], p[2] - p[0]), p[3] - p[0]) / 6
    longest = np.max([np.linalg.norm(p[i] - p[j], axis=1) for i in range(4) for j in range(i + 1, 4)], axis=0)
    return X, el[vol / longest ** 3 > 1e-4]


X, el = mesh_stl(os.path.join(out, 'bracket.stl'), hmesh)
TOL = 0.15
print('nodes %d, elements %d, bbox %s %s' % (len(X), len(el), np.round(X.min(0), 1).tolist(), np.round(X.max(0), 1).tolist()), flush=True)

FACES = {1: (0, 1, 2), 2: (0, 3, 1), 3: (1, 3, 2), 4: (2, 3, 0)}
OPP = {1: 3, 2: 2, 3: 0, 4: 1}
count = {}
for e in el:
    for f, ix in FACES.items():
        kk = tuple(sorted(e[list(ix)]))
        count[kk] = count.get(kk, 0) + 1
bfaces = []
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


def pick(pred):
    return [b for b in bfaces if pred(b[2], b[4])]


# shoe faces: the leg's face on the slot (outward normal -u) and the lip's face on it (+u), sheared
leg = pick(lambda c, n: n[0] < -0.9 and abs(c[0] - (-c[1] * k)) < 0.5 and h - 45 < c[1] < h - 5)
lipf = pick(lambda c, n: n[0] > 0.9 and abs(c[0] - (-shoe - c[1] * k)) < 0.5 and lip < c[1] < lip + 25)
floor = pick(lambda c, n: n[1] > 0.9 and abs(c[1] - lip) < 0.3 and -shoe + 1 < c[0] < -1)
toe = [i + 1 for i, p in enumerate(X) if p[1] < TOL and p[0] > reach - 30]
hook = [i + 1 for i, p in enumerate(X) if abs(p[1] - lip_top) < TOL and back - 0.1 < p[0] < back + 4]
strap = [i + 1 for i, p in enumerate(X) if abs(p[0] - back) < TOL and lip_top + 2 < p[1] < -2]
print('faces: leg %d, lip %d, floor %d; nodes: toe %d, hook %d, strap %d' % (len(leg), len(lipf), len(floor), len(toe), len(hook), len(strap)))


def resultant(faces):
    """Force and its point for a unit pressure (pushing against the outward normal)."""
    F = sum(-a * n for _, _, _, a, n in faces)
    c = sum(a * cc for _, _, cc, a, _ in faces) / sum(a for _, _, _, a, _ in faces)
    return F, c


# reactions' moment about the origin (z), from where they act
toe_c, hook_c, strap_c = X[np.array(toe) - 1].mean(0), X[np.array(hook) - 1].mean(0), X[np.array(strap) - 1].mean(0)
Ff, cf = resultant(floor)
pf = BOARD_V / Ff[1]
Mr = toe_c[0] * TOE_V + hook_c[0] * HOOK_V - strap_c[1] * STRAP_U + cf[0] * pf * Ff[1]
Fl, cl = resultant(leg)        # unit pressure: pushes +u
Fp, cp = resultant(lipf)       # pushes -u
# pl * Fl_u + pp * Fp_u = -STRAP_U ; moments: -(cl_v * pl * Fl_u) - (cp_v * pp * Fp_u) = -Mr
A = np.array([[Fl[0], Fp[0]], [-cl[1] * Fl[0], -cp[1] * Fp[0]]])
pl, pp = np.linalg.solve(A, [-STRAP_U, -Mr])
print('shoe: forwards on the leg %.0f N (%.3f MPa) at v %.0f, back on the lip %.0f N (%.3f MPa) at v %.0f; floor %.0f N'
      % (pl * Fl[0], pl, cl[1], -pp * Fp[0], pp, cp[1], pf * Ff[1]))

env = dict(os.environ, OMP_NUM_THREADS='8', CCX_NPROC_EQUATION_SOLVER='8')
job = 'bracket_lean'


# bolt holes: nodes round each bolt's axis (along u at v = bolt_z), in the lip and in the leg. Each bolt
# is a bundle of steel bars from the lip's hole nodes to the leg's facing ones, their areas adding up
# to the M6's stress area (20.1 mm2): it holds the lip and the leg together as the bolt does.
BOLTS = []
corner_nodes = np.unique(el[:, :4])
for vz in (P['bolt_z0'], P['bolt_z1']):
    rr = np.hypot(X[corner_nodes - 1, 1] - vz, X[corner_nodes - 1, 2] - w / 2)
    on_hole = corner_nodes[np.abs(rr - P['bolt_d'] / 2) < 0.6]
    uu = X[on_hole - 1, 0] + vz * k
    a = on_hole[(uu > -shoe - lip - 1) & (uu < -shoe + 0.5)]
    b_ = on_hole[(uu > -0.5) & (uu < m + 1)]
    pairs = []
    for n in a:
        q = X[n - 1]
        j = np.argmin(np.sum((X[b_ - 1, 1:] - q[1:]) ** 2, axis=1))
        pairs.append((n, b_[j]))
    BOLTS.append((vz, pairs))
    print('bolt at v %.0f: %d bars, lip %d nodes, leg %d nodes' % (vz, len(pairs), len(a), len(b_)))


def solve():
    with open(os.path.join(out, job + '.inp'), 'w') as f:
        f.write('*NODE, NSET=NALL\n')
        for i, q in enumerate(X):
            f.write('%d, %.6f, %.6f, %.6f\n' % (i + 1, *q))
        f.write('*ELEMENT, TYPE=C3D10, ELSET=BR\n')
        for i, e in enumerate(el):
            f.write('%d, %s\n' % (i + 1, ', '.join(str(int(n)) for n in e)))
        eid = len(el)
        for j, (vz, pairs) in enumerate(BOLTS):
            f.write('*ELEMENT, TYPE=T3D2, ELSET=BOLT%d\n' % j)
            for a, b_ in pairs:
                eid += 1
                f.write('%d, %d, %d\n' % (eid, a, b_))
        for name, ns in (('TOE', toe), ('HOOK', hook)):
            f.write('*NSET, NSET=%s\n' % name + '\n'.join(map(str, ns)) + '\n')
        f.write('*MATERIAL, NAME=ABS\n*ELASTIC\n%g, %g\n*SOLID SECTION, ELSET=BR, MATERIAL=ABS\n' % (E, NU))
        f.write('*MATERIAL, NAME=STEEL\n*ELASTIC\n210000., 0.3\n')
        for j, (vz, pairs) in enumerate(BOLTS):
            f.write('*SOLID SECTION, ELSET=BOLT%d, MATERIAL=STEEL\n%.5f\n' % (j, 20.1 / len(pairs)))
        f.write('*BOUNDARY\nTOE, 1, 3\nHOOK, 2, 2\n*STEP\n*STATIC\n*DLOAD\n')
        for faces, p in ((leg, pl), (lipf, pp), (floor, pf)):
            for e, fc, _, _, _ in faces:
                f.write('%d, P%d, %.6f\n' % (e, fc, p))
        f.write('*NODE PRINT, NSET=NALL\nU\n*NODE PRINT, NSET=TOE, TOTALS=ONLY\nRF\n*NODE PRINT, NSET=HOOK, TOTALS=ONLY\nRF\n'
                '*EL PRINT, ELSET=BR\nS\n*NODE FILE\nU\n*EL FILE\nS\n*END STEP\n')
    subprocess.run(['ccx', '-i', job], cwd=out, check=True, env=env, stdout=open(os.path.join(out, job + '.log'), 'w'))


solve()

U, S, RF, mode = [], [], [], None
for line in open(os.path.join(out, job + '.dat')):
    if 'displacements' in line:
        mode = 'U'; continue
    if 'stresses' in line:
        mode = 'S'; continue
    if 'total force' in line:
        mode = 'RF'; continue
    v = line.split()
    if not v:
        continue
    if mode == 'RF' and len(v) == 3:
        RF.append(list(map(float, v))); mode = None; continue
    if not v[0].isdigit():
        continue
    if mode == 'U' and len(v) == 4:
        U.append(list(map(float, v[1:])))
    elif mode == 'S' and len(v) == 8:
        S.append([int(v[0])] + list(map(float, v[2:])))
U, S = np.array(U), np.array(S)
S = S[S[:, 0] <= len(el)]
for vz, pairs in BOLTS:   # tension from the bars' stretch
    t = sum(210000.0 * 20.1 / len(pairs) / np.linalg.norm(X[b_ - 1] - X[a - 1]) *
            np.dot(U[b_ - 1] - U[a - 1], (X[b_ - 1] - X[a - 1]) / np.linalg.norm(X[b_ - 1] - X[a - 1])) for a, b_ in pairs)
    print('bolt at v %.0f: tension %.0f N' % (vz, t))
print('reactions (toe, hook), N:', np.round(RF, 1).tolist(), ' expected toe u %.0f v %.0f, hook v %.0f'
      % (STRAP_U, TOE_V, HOOK_V))
sxx, syy, szz, sxy, sxz, syz = S[:, 1:].T
vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + sxz ** 2 + syz ** 2))
inl = np.sqrt(0.5 * ((sxx - syy) ** 2 + sxx ** 2 + syy ** 2) + 3 * sxy ** 2)   # von Mises of the in-layer stresses
c = X[el[S[:, 0].astype(int) - 1][:, :4] - 1].mean(axis=1)
print('largest movement %.3f mm' % np.linalg.norm(U, axis=1).max())
near = np.zeros(len(c), bool)          # leave out the elements on the supports' edges (singular peaks)
for ns in (toe, hook):
    pts = X[np.array(ns) - 1]
    lo, hi = pts.min(0) - 2.5, pts.max(0) + 2.5
    near |= np.all((c > lo) & (c < hi), axis=1)
regions = {
    'hook (strap and lip)': (c[:, 1] < -1) & ~near,
    'heel arm': (c[:, 1] >= -1) & (c[:, 0] < -shoe - lip - 1 - c[:, 1] * k),
    'shoe (lip, floor)': (c[:, 0] >= -shoe - lip - 1 - c[:, 1] * k) & (c[:, 0] < -c[:, 1] * k),
    'leg, foot, brace': (c[:, 0] >= -c[:, 1] * k) & ~near,
}
for rn, msk in regions.items():
    j = np.argmax(np.where(msk, inl, -1))
    kk = np.argmax(np.where(msk, np.abs(szz), -1))
    a99, z99 = np.percentile(inl[msk], 99.5), np.percentile(np.abs(szz[msk]), 99.5)
    print('  %-22s in layers p99.5 %5.2f max %5.2f at %s | across (szz) p99.5 %5.2f max %5.2f MPa | margin %4.1fx in, %4.1fx across'
          % (rn, a99, inl[j], np.round(c[j], 1).tolist(), z99, np.abs(szz[kk]), ALONG / a99, ACROSS / max(z99, 1e-6)))
