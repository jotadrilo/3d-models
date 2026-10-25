"""A C3D10 result (bracket_fea.py) cut at z = <z> -> a coloured PLY of the cut face, for render_ply.py.

usage: python cut_ply.py <run dir> <job> <z of the cut> <component> <max MPa> <out.ply> [scale]

Draws the exact section of the mesh by the plane, coloured by the stress interpolated from the
nodes (element values averaged to the corners): <component> szz (across the print layers, -max..max, red in tension) or inl
(von Mises of the in-layer stresses, 0..max). The print Z runs across the bracket, so a cut at half
its width shows the stress inside, which on the side faces is zero. Deformed by U x scale. Writes
<out>-legend.png.
"""
import sys, os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

run, job, zc, comp, vmax, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4], float(sys.argv[5]), sys.argv[6]
scale = float(sys.argv[7]) if len(sys.argv) > 7 else 1.0

nodes, els, mode = {}, [], None
for line in open(os.path.join(run, job + '.inp')):
    if line.startswith('*'):
        up = line.upper()
        mode = 'N' if up.startswith('*NODE') and 'PRINT' not in up and 'FILE' not in up else ('E' if 'C3D10' in up else None)
        continue
    v = line.split(',')
    if mode == 'N':
        nodes[int(v[0])] = np.array(list(map(float, v[1:4])))
    elif mode == 'E':
        els.append([int(x) for x in v[:11]])
U, S, mode = {}, {}, None
for line in open(os.path.join(run, job + '.dat')):
    if 'displacements' in line:
        mode = 'U'; continue
    if 'stresses' in line:
        mode = 'S'; continue
    if line.strip().startswith(('forces', 'total')):
        mode = None
    t = line.split()
    if mode == 'U' and len(t) == 4 and t[0].isdigit():
        U[int(t[0])] = np.array(list(map(float, t[1:])))
    elif mode == 'S' and len(t) == 8 and t[0].isdigit():
        S.setdefault(int(t[0]), []).append(list(map(float, t[2:])))

# element values (averaged over the integration points), then averaged to the corner nodes
val_e = {}
for e in els:
    if e[0] in S:
        s = np.mean(S[e[0]], axis=0)
        sxx, syy, szz, sxy = s[0], s[1], s[2], s[3]
        val_e[e[0]] = szz if comp == 'szz' else np.sqrt(0.5 * ((sxx - syy) ** 2 + sxx ** 2 + syy ** 2) + 3 * sxy ** 2)
acc, cnt = {}, {}
for e in els:
    if e[0] in val_e:
        for n in e[1:5]:
            acc[n] = acc.get(n, 0.0) + val_e[e[0]]
            cnt[n] = cnt.get(n, 0) + 1
val_n = {n: acc[n] / cnt[n] for n in acc}
cmap = plt.get_cmap('coolwarm' if comp == 'szz' else 'turbo')
norm = (lambda v: 0.5 + 0.5 * v / vmax) if comp == 'szz' else (lambda v: v / vmax)
colour = lambda v: (np.array(cmap(float(np.clip(norm(v), 0, 1)))[:3]) * 255).astype(int)

# the exact section of each tetrahedron (its corners) by the plane z = zc: a triangle or a quad
verts, tris = [], []
EDGES = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
for e in els:
    if e[0] not in val_e:
        continue
    cn = e[1:5]
    P = [nodes[n] + scale * U.get(n, 0) for n in cn]
    Z = [nodes[n][2] - zc for n in cn]
    if min(Z) >= 0 or max(Z) <= 0:
        continue
    pts = []
    for a, b in EDGES:
        if (Z[a] < 0) != (Z[b] < 0):
            t = Z[a] / (Z[a] - Z[b])
            pts.append((P[a] + t * (P[b] - P[a]), val_n[cn[a]] + t * (val_n[cn[b]] - val_n[cn[a]])))
    if len(pts) == 4:   # order the quad round its centre
        c = np.mean([p for p, _ in pts], axis=0)
        pts.sort(key=lambda q: np.arctan2(q[0][1] - c[1], q[0][0] - c[0]))
    base = len(verts)
    for p, v in pts:
        verts.append((np.array([p[0], p[1], zc]), colour(v)))
    tris.append((base, base + 1, base + 2))
    if len(pts) == 4:
        tris.append((base, base + 2, base + 3))

with open(out, 'w') as f:
    f.write('ply\nformat ascii 1.0\nelement vertex %d\nproperty float x\nproperty float y\nproperty float z\n'
            'property uchar red\nproperty uchar green\nproperty uchar blue\nelement face %d\n'
            'property list uchar int vertex_indices\nend_header\n' % (len(verts), len(tris)))
    for p, c in verts:
        f.write('%.3f %.3f %.3f %d %d %d\n' % (*p, *c))
    for a, b, c in tris:
        f.write('3 %d %d %d\n' % (a, b, c))
fig, ax = plt.subplots(figsize=(1.6, 5))
lo = -vmax if comp == 'szz' else 0
fig.colorbar(matplotlib.cm.ScalarMappable(norm=matplotlib.colors.Normalize(lo, vmax), cmap=cmap), cax=ax,
             label='across the layers (MPa), red: tension' if comp == 'szz' else 'in the layers, von Mises (MPa)')
fig.savefig(os.path.splitext(out)[0] + '-legend.png', dpi=150, bbox_inches='tight', transparent=True)
print('section at z %.1f: %d triangles' % (zc, len(tris)))
