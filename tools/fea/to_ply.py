"""CalculiX results -> coloured PLY surfaces for Blender, plus colour bars.

usage: python to_ply.py <run dir> <job> <deformation scale> [vm max MPa] [axis] [axis max MPa]
Reads <run>/<job>.inp and <run>/<job>.frd (C3D10 mesh, *NODE FILE U and
*EL FILE S). Writes <run>/vm.ply (von Mises, 0..vm max) and, with an axis
(x, y or z), <run>/s<axis>.ply: the normal stress along that axis, -max..max,
red in tension. Use the axis that runs across the print layers to see the
stress the layers have to carry. The surface is deformed by <scale>; each
PLY gets its colour bar as <name>-legend.png.
"""
import sys, os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

run, job, scale = sys.argv[1], sys.argv[2], float(sys.argv[3])
VM_MAX = float(sys.argv[4]) if len(sys.argv) > 4 else 10.0
AXIS = sys.argv[5] if len(sys.argv) > 5 else None
S_MAX = float(sys.argv[6]) if len(sys.argv) > 6 else VM_MAX / 2

# nodes and corner nodes of the elements, from the input deck
nodes, els, mode = {}, [], None
for line in open(os.path.join(run, job + '.inp')):
    if line.startswith('*'):
        mode = 'n' if line.startswith('*NODE,') else 'e' if line.startswith('*ELEMENT') and 'C3D10' in line else None
        continue
    v = line.split(',')
    if mode == 'n':
        nodes[int(v[0])] = np.array(list(map(float, v[1:4])))
    elif mode == 'e':
        els.append([int(x) for x in v[1:5]])

# nodal displacements and stresses, from the .frd
U, S, block = {}, {}, None
for line in open(os.path.join(run, job + '.frd')):
    if line.startswith(' -4'):
        block = line.split()[1]
        continue
    if line.startswith(' -3'):
        block = None
        continue
    if block in ('DISP', 'STRESS') and line.startswith(' -1'):
        n = int(line[3:13])
        vals = [float(line[13 + 12 * i:25 + 12 * i]) for i in range((len(line.rstrip()) - 13) // 12)]
        (U if block == 'DISP' else S)[n] = np.array(vals)

# boundary faces of the tetrahedra, oriented outwards
count = {}
for e in els:
    for f, opp in (((e[0], e[1], e[2]), e[3]), ((e[0], e[3], e[1]), e[2]), ((e[1], e[3], e[2]), e[0]), ((e[2], e[3], e[0]), e[1])):
        k = tuple(sorted(f))
        count.setdefault(k, []).append((f, opp))
faces = []
for k, v in count.items():
    if len(v) != 1:
        continue
    f, opp = v[0]
    a, b, c = (nodes[i] for i in f)
    if np.dot(np.cross(b - a, c - a), nodes[opp] - a) > 0:
        f = (f[0], f[2], f[1])
    faces.append(f)
used = sorted({i for f in faces for i in f})
where = {n: i for i, n in enumerate(used)}
print('%d surface triangles, %d vertices' % (len(faces), len(used)))

s = np.array([S[n] for n in used])
sxx, syy, szz, sxy, syz, szx = s.T
vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + syz ** 2 + szx ** 2))
P = np.array([nodes[n] + scale * U[n] for n in used])


def write(name, values, cmap, lo, hi, label):
    rgb = (np.array(plt.get_cmap(cmap)(np.clip((values - lo) / (hi - lo), 0, 1)))[:, :3] * 255).astype(int)
    with open(os.path.join(run, name + '.ply'), 'w') as f:
        f.write('ply\nformat ascii 1.0\nelement vertex %d\nproperty float x\nproperty float y\nproperty float z\n'
                'property uchar red\nproperty uchar green\nproperty uchar blue\nelement face %d\n'
                'property list uchar int vertex_indices\nend_header\n' % (len(P), len(faces)))
        for p, c in zip(P, rgb):
            f.write('%.4f %.4f %.4f %d %d %d\n' % (*p, *c))
        for a, b, c in faces:
            f.write('3 %d %d %d\n' % (where[a], where[b], where[c]))
    fig, ax = plt.subplots(figsize=(1.6, 6), dpi=150)
    fig.colorbar(matplotlib.cm.ScalarMappable(matplotlib.colors.Normalize(lo, hi), cmap), cax=ax)
    ax.set_ylabel(label, fontsize=11)
    fig.subplots_adjust(left=0.05, right=0.35, top=0.97, bottom=0.03)
    fig.savefig(os.path.join(run, name + '-legend.png'), transparent=True)
    plt.close(fig)


write('vm', vm, 'turbo', 0, VM_MAX, 'von Mises (MPa)')
print('von Mises max on the surface %.1f MPa (colours stop at %g)' % (vm.max(), VM_MAX))
if AXIS:
    sa = {'x': sxx, 'y': syy, 'z': szz}[AXIS]
    write('s' + AXIS, sa, 'coolwarm', -S_MAX, S_MAX, 'normal stress along %s (MPa)' % AXIS)
    print('s%s range %.1f .. %.1f MPa (colours stop at +-%g)' % (AXIS, sa.min(), sa.max(), S_MAX))
