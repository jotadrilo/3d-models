"""After an assembly FEA: did any part go into another? (tools/fea/README.md,
Assembly.) A model only keeps apart the surfaces it was told about; this
finds the places it was not, at real scale.

usage: python penetration.py <job.vtu> [tolerance mm]
Reads a .vtu from frd_to_vtu.py (points, U, 10-node tetrahedra, `part` per
cell), moves every node by U, and for each pair of parts checks each
surface node of one against the other's surface: the closest point on its
nearest triangles, inside when the node lies behind that triangle's
outward face by more than the tolerance (0.1 mm by default). Reports zones
(nodes within 4 mm of each other) with their depth. The surface is the
tetrahedra's flat corner triangles, so curved faces are off by a little:
look at a section (section.py) to be sure.
"""
import sys
import numpy as np
import meshio
from scipy.spatial import cKDTree

path = sys.argv[1]
tol = float(sys.argv[2]) if len(sys.argv) > 2 else 0.1
m = meshio.read(path)
X = m.points + m.point_data['U'] * 1.0
tets = m.cells_dict['tetra10'][:, :4]
part = m.cell_data['part'][0]
FACES = ((0, 1, 2), (0, 3, 1), (1, 3, 2), (2, 3, 0))

surf = {}
for p in np.unique(part):
    T = tets[part == p]
    count = {}
    for t in T:
        for f in FACES:
            tri = tuple(t[list(f)])
            count.setdefault(tuple(sorted(tri)), []).append((tri, t[[i for i in range(4) if i not in f][0]]))
    tris = []
    for v in count.values():
        if len(v) == 1:
            (i, j, k), opp = v[0]
            a, b, c = X[[i, j, k]]
            if np.dot(np.cross(b - a, c - a), X[opp] - a) > 0:
                j, k = k, j                     # outward: counter-clockwise seen from outside
            tris.append((i, j, k))
    tris = np.array(tris)
    surf[int(p)] = (np.unique(tris), tris)


def closest_on_triangles(P, A, B, C):
    """Closest points on triangles ABC to points P (rows), Ericson's method."""
    ab, ac, ap = B - A, C - A, P - A
    d1, d2 = np.einsum('ij,ij->i', ab, ap), np.einsum('ij,ij->i', ac, ap)
    bp = P - B
    d3, d4 = np.einsum('ij,ij->i', ab, bp), np.einsum('ij,ij->i', ac, bp)
    cp = P - C
    d5, d6 = np.einsum('ij,ij->i', ab, cp), np.einsum('ij,ij->i', ac, cp)
    va, vb, vc = d3 * d6 - d5 * d4, d5 * d2 - d1 * d6, d1 * d4 - d3 * d2
    den = va + vb + vc
    den[den == 0] = 1e-30
    v, w = vb / den, vc / den
    Q = A + ab * v[:, None] + ac * w[:, None]                    # inside the face
    with np.errstate(divide='ignore', invalid='ignore'):
        rules = [
            (d1 <= 0) & (d2 <= 0), A,
            (d3 >= 0) & (d4 <= d3), B,
            (d6 >= 0) & (d5 <= d6), C,
            (vc <= 0) & (d1 >= 0) & (d3 <= 0), A + ab * (d1 / (d1 - d3))[:, None],
            (vb <= 0) & (d2 >= 0) & (d6 <= 0), A + ac * (d2 / (d2 - d6))[:, None],
            (va <= 0) & ((d4 - d3) >= 0) & ((d5 - d6) >= 0), B + (C - B) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))[:, None],
        ]
    done = np.zeros(len(P), bool)
    for m, q in zip(rules[0::2], rules[1::2]):
        m = m & ~done
        Q[m] = q[m]
        done |= m
    return Q


def zones(pts, link=4.0):
    parent = np.arange(len(pts))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for i, j in cKDTree(pts).query_pairs(link, output_type='ndarray'):
        ri, rj = find(i), find(j)
        if ri != rj:
            parent[ri] = rj
    return np.array([find(x) for x in range(len(pts))])


found = 0
K = 8
for a, (na, _) in surf.items():
    for b, (_, tb) in surf.items():
        if a == b:
            continue
        A, B, C = X[tb[:, 0]], X[tb[:, 1]], X[tb[:, 2]]
        nrm = np.cross(B - A, C - A)
        nrm /= np.linalg.norm(nrm, axis=1)[:, None]
        tree = cKDTree((A + B + C) / 3)
        d, k = tree.query(X[na], k=K, distance_upper_bound=8.0)
        best = np.full(len(na), np.inf)
        depth = np.zeros(len(na))
        for j in range(K):
            ok = np.isfinite(d[:, j])
            if not ok.any():
                continue
            P, t = X[na[ok]], k[ok, j]
            Q = closest_on_triangles(P, A[t], B[t], C[t])
            dist = np.linalg.norm(P - Q, axis=1)
            sgn = np.einsum('ij,ij->i', P - Q, nrm[t])
            idx = np.where(ok)[0]
            better = dist < best[idx]
            best[idx[better]] = dist[better]
            depth[idx[better]] = -sgn[better]
        inside = np.where(np.isfinite(best) & (depth > tol) & (best < 5.0))[0]
        if len(inside) < 3:
            continue
        pts, dep = X[na[inside]], depth[inside]
        lab = zones(pts)
        for r in np.unique(lab):
            s_ = lab == r
            if s_.sum() < 3:
                continue
            found += 1
            lo, hi = pts[s_].min(axis=0), pts[s_].max(axis=0)
            print('part %d into part %d: %4d nodes, up to %.2f mm deep, from %s to %s'
                  % (a, b, s_.sum(), dep[s_].max(), np.round(lo, 1).tolist(), np.round(hi, 1).tolist()))
print('%d zones where a part went into another by more than %g mm' % (found, tol) if found
      else 'no part goes into another by more than %g mm' % tol)
