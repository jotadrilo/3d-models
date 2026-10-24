"""Where do the parts of an assembly come close? The scan to run before an
assembly FEA (tools/fea/README.md, Assembly): every place two parts are
within <max gap> of each other, with its gap, so each one can be bonded,
given a contact, or left out on purpose.

usage: python proximity.py <max gap mm> <part.step> [<part.step> ...] [--h <mm>]
Parts are named after their files. Each is surface-meshed with gmsh
(h = 1 mm by default); for each pair, the surface nodes of one closer than
<max gap> to the other's are grouped into zones (nodes within 5 mm of each
other). Gaps are node-to-node, so they read up to about h/2 high.
Things that are not meshed (a wall, a screw, a button) are not seen: list
those by hand.
"""
import sys, os, math
import numpy as np
import gmsh
from scipy.spatial import cKDTree

args = sys.argv[1:]
h = 1.0
if '--h' in args:
    i = args.index('--h')
    h = float(args[i + 1])
    del args[i:i + 2]
max_gap, steps = float(args[0]), args[1:]


def surface(step):
    gmsh.initialize()
    gmsh.option.setNumber('General.Terminal', 0)
    gmsh.option.setString('Geometry.OCCTargetUnit', 'MM')
    gmsh.model.occ.importShapes(step)
    gmsh.model.occ.synchronize()
    gmsh.option.setNumber('Mesh.MeshSizeMax', h)
    gmsh.model.mesh.generate(2)
    _, coords, _ = gmsh.model.mesh.getNodes()
    gmsh.finalize()
    return coords.reshape(-1, 3)


def zones(pts, link):
    """Connected groups of points closer than link: a label per point."""
    parent = np.arange(len(pts))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for p, q in cKDTree(pts).query_pairs(link, output_type='ndarray'):
        rp, rq = find(p), find(q)
        if rp != rq:
            parent[rp] = rq
    return np.array([find(x) for x in range(len(pts))])


parts = {os.path.splitext(os.path.basename(s))[0]: surface(s) for s in steps}
trees = {k: cKDTree(v) for k, v in parts.items()}
names = list(parts)
rows = []
for i, a in enumerate(names):
    for b in names[i + 1:]:
        d, _ = trees[b].query(parts[a], distance_upper_bound=max_gap)
        close = np.where(np.isfinite(d))[0]
        P, G = parts[a][close], d[close]
        band = np.digitize(G, [0.6, 2.5])
        for k in np.unique(band):
            pts, gaps = P[band == k], G[band == k]
            roots = zones(pts, 4.0)
            for r in np.unique(roots):
                m = roots == r
                if m.sum() < 30:
                    continue
                lo, hi = pts[m].min(axis=0), pts[m].max(axis=0)
                rows.append((a, b, gaps[m].min(), np.median(gaps[m]), int(m.sum()), lo, hi))

rows.sort(key=lambda r: (r[0], r[1], r[2]))
print('%d zones where two parts are within %g mm (surface mesh h = %g mm)' % (len(rows), max_gap, h))
print('%-8s %-8s %8s %8s %6s   %-26s %-26s' % ('part', 'near', 'gap min', 'median', 'nodes', 'from (x, y, z)', 'to (x, y, z)'))
for a, b, gmin, gmed, n, lo, hi in rows:
    print('%-8s %-8s %8.2f %8.2f %6d   %-26s %-26s' % (a, b, gmin, gmed, n, np.round(lo, 1).tolist(), np.round(hi, 1).tolist()))
