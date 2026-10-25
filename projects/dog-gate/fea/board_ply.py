"""board_fea.py results -> a coloured PLY of the board and its battens, deformed, for render_ply.py.

usage: python board_ply.py <run dir> <job> <deformation scale> <out.ply> [grain x|z] [colour max %]

Each brick (C3D20R, one through the board's thickness, more in the battens) is drawn as a box,
coloured by how much of the plywood's strength it uses: the larger of |s_x| / f_x and |s_z| / f_z at
its integration points (board_fea.py's worst-case plywood, f along and across the face grain;
battens along their grain). Writes <out>-legend.png with the colour bar.
"""
import sys, os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

run, job, scale, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
grain = sys.argv[5] if len(sys.argv) > 5 else 'z'
CMAX = float(sys.argv[6]) / 100 if len(sys.argv) > 6 else 1.0
FM_PAR, FM_PERP = 20.0, 12.0
fx, fz = (FM_PAR, FM_PERP) if grain == 'x' else (FM_PERP, FM_PAR)

nodes, els, mode, eset, cont = {}, {}, None, None, None
for line in open(os.path.join(run, job + '.inp')):
    if line.startswith('*'):
        up = line.upper()
        mode = 'N' if up.startswith('*NODE') and 'PRINT' not in up and 'FILE' not in up else (
            'E' if up.startswith('*ELEMENT') and 'C3D20R' in up else None)
        eset = 'RIBS' if 'RIBS' in up else ('BOARD' if 'BOARD' in up else eset)
        cont = None
        continue
    v = [x for x in line.strip().split(',') if x.strip()]
    if mode == 'N':
        nodes[int(v[0])] = np.array(list(map(float, v[1:4])))
    elif mode == 'E':
        if cont is None:
            cont = [int(x) for x in v]
            if not line.rstrip().endswith(','):
                els[cont[0]] = cont[1:]; cont = None
        else:
            cont += [int(x) for x in v]
            els[cont[0]] = cont[1:]; cont = None

U, S, mode = {}, {}, None
for line in open(os.path.join(run, job + '.dat')):
    if 'displacements' in line:
        mode = 'U'; continue
    if 'stresses' in line:
        mode = 'S'; continue
    if line.strip().startswith('forces'):
        mode = None
    t = line.split()
    if t and t[-1] == 'OR':
        t = t[:-1]
    if mode == 'U' and len(t) == 4 and t[0].isdigit():
        U[int(t[0])] = np.array(list(map(float, t[1:])))
    elif mode == 'S' and len(t) == 8 and t[0].isdigit():
        e = int(t[0])
        s1, s2 = abs(float(t[2])), abs(float(t[3]))     # orientation axes: 1 = x, 2 = z
        rib = e >= 60000
        u = s2 / FM_PAR if rib else max(s1 / fx, s2 / fz)   # battens: along their grain (z)
        S[e] = max(S.get(e, 0.0), u)

cmap = plt.get_cmap('turbo')
verts, faces, cols = [], [], []
QUADS = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
for e, con in els.items():
    if e not in S:
        continue
    c = (np.array(cmap(min(S[e] / CMAX, 1.0))[:3]) * 255).astype(int)
    p = [nodes[n] + scale * U.get(n, 0) for n in con[:8]]
    base = len(verts)
    verts += p
    cols += [c] * 8
    for q in QUADS:
        faces += [(base + q[0], base + q[1], base + q[2]), (base + q[0], base + q[2], base + q[3])]

with open(out, 'w') as f:
    f.write('ply\nformat ascii 1.0\nelement vertex %d\nproperty float x\nproperty float y\nproperty float z\n'
            'property uchar red\nproperty uchar green\nproperty uchar blue\nelement face %d\n'
            'property list uchar int vertex_indices\nend_header\n' % (len(verts), len(faces)))
    for p, c in zip(verts, cols):
        f.write('%.3f %.3f %.3f %d %d %d\n' % (*p, *c))
    for a, b, c in faces:
        f.write('3 %d %d %d\n' % (a, b, c))

fig, ax = plt.subplots(figsize=(1.6, 5))
fig.colorbar(matplotlib.cm.ScalarMappable(norm=matplotlib.colors.Normalize(0, 100 * CMAX), cmap=cmap), cax=ax,
             label='strength used (%)')
fig.savefig(os.path.splitext(out)[0] + '-legend.png', dpi=150, bbox_inches='tight', transparent=True)
umax = max(np.linalg.norm(U[n]) for n in nodes if n in U)
print('%d elements, largest use %.0f %%, largest movement %.1f mm' % (len(S), 100 * max(S.values()), umax))
