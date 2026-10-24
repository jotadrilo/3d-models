"""CalculiX results -> a .vtu for ParaView.

usage: python frd_to_vtu.py <run dir> <job>
Reads <run>/<job>.inp (C3D10 elements, one *ELEMENT block per part) and
<run>/<job>.frd (the last increment's U and S). Writes <run>/<job>.vtu with
point data U, von_Mises, sxx..szx and max_principal, and cell data `part`
(the order of the *ELEMENT blocks), to show, hide or clip parts.
(ccx2paraview 3.x crashes with current numpy on the principal stresses.)
"""
import sys, os
import numpy as np
import meshio

run, job = sys.argv[1], sys.argv[2]
nodes, cells, part, names, mode = {}, [], [], [], None
for line in open(os.path.join(run, job + '.inp')):
    if line.startswith('*'):
        mode = None
        if line.startswith('*NODE,'):
            mode = 'n'
        elif line.startswith('*ELEMENT') and 'C3D10' in line:
            mode = 'e'
            names.append(line.split('ELSET=')[1].strip() if 'ELSET=' in line else 'part%d' % len(names))
        continue
    v = line.split(',')
    if mode == 'n':
        nodes[int(v[0])] = list(map(float, v[1:4]))
    elif mode == 'e':
        cells.append([int(x) for x in v[1:11]])
        part.append(len(names) - 1)

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
        (U if block == 'DISP' else S)[n] = vals[:6] if block == 'STRESS' else vals[:3]

ids = sorted(nodes)
where = {n: i for i, n in enumerate(ids)}
pts = np.array([nodes[n] for n in ids])
u = np.array([U.get(n, [0, 0, 0]) for n in ids])
s = np.array([S.get(n, [0] * 6) for n in ids])
sxx, syy, szz, sxy, syz, szx = s.T
vm = np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + syz ** 2 + szx ** 2))
t = np.zeros((len(ids), 3, 3))
t[:, 0, 0], t[:, 1, 1], t[:, 2, 2] = sxx, syy, szz
t[:, 0, 1] = t[:, 1, 0] = sxy
t[:, 1, 2] = t[:, 2, 1] = syz
t[:, 0, 2] = t[:, 2, 0] = szx
pmax = np.linalg.eigvalsh(t)[:, -1]
conn = np.array([[where[n] for n in c] for c in cells])      # C3D10 and VTK share the node order
m = meshio.Mesh(pts, [('tetra10', conn)],
                point_data={'U': u, 'von_Mises': vm, 'max_principal': pmax,
                            'sxx': sxx, 'syy': syy, 'szz': szz, 'sxy': sxy, 'syz': syz, 'szx': szx},
                cell_data={'part': [np.array(part)]})
out = os.path.join(run, job + '.vtu')
m.write(out, binary=True)
print('%s: %d nodes, %d elements, parts %s' % (out, len(ids), len(cells), ', '.join('%d %s' % (i, n) for i, n in enumerate(names))))
