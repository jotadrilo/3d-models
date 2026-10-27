"""How far the soap caddy's body gives under the nozzle while it prints
standing (tools/fea/README.md, "Print stiffness").

For each variant and each cut height z: the body as it stands on the bed with
the nozzle at z (body_cut.scad), fixed at the bed, and a 1 N sideways force
on a small patch of its top layer, in x and in y, at a few points along the
side wall and the front. The result is the compliance (mm per N) at each
point: how far the top layer moves away from the nozzle. Linear, so any
nozzle force scales it.

usage: python print_sway.py <out dir> [variant ...]
       PIECE=drainer python print_sway.py <out dir>      # the cutlery drainer's body
       PIECE=bin CUTS=60,100,140,170,200 python print_sway.py <out dir>   # its bins and risers
"""
import sys, os, subprocess, json, time
import numpy as np
import caddy_model as cm

VARIANTS = {                      # one change per variant from the reference
    'R as printed (2026-10, rough above ~165 mm)': ['fin_w=0'],
    'A walls 2.52': ['fin_w=0', 'side_add=0.84'],
    'B walls 3.36': ['fin_w=0', 'side_add=1.68'],
    'C frame 2.52': ['fin_w=0', 'frame_t=2.52'],
    'D walls 2.52 above the step': ['fin_w=0', 'side_add=0.84', 'side_add_z=60'],
    'E back wall 1.68': ['fin_w=0', 'back_wall=1.68'],
    'F sacrificial fins 20 mm, tabs 0.84 x 1.6 every 10': ['tab_w=0.84', 'tab_h=1.6', 'tab_pitch=10'],
    'F2 fins 20 mm, tabs 0.42 x 0.4 every 20 (the default)': [],
    # Fins with no tabs, a gap and a flange: the walls rest on them only once they lean their
    # way, so one side at a time, tabs standing in for the contact (LEFT=1: the left wall
    # pushed +x leans onto them too)
    'G fins 20 mm + flange 12, contact': ['fin_sides=[1]', 'fin_flange=12', 'tab_w=0.84', 'tab_h=1.6', 'tab_pitch=10'],
    'H fins 12 mm + flange 12, contact': ['fin_sides=[1]', 'fin_flange=12', 'tab_w=0.84', 'tab_h=1.6', 'tab_pitch=10', 'fin_w=12'],
}
CUTS = [int(c) for c in os.environ.get('CUTS', '60,100,130,150,170,190,209').split(',')]
H = 2.0
PIECE = os.environ.get('PIECE', 'soap')
SCAD = os.path.join(cm.HERE, {'soap': 'body_cut.scad', 'drainer': 'drainer_body_cut.scad', 'strip': 'sway_test_cut.scad', 'bin': 'bin_cut.scad'}[PIECE])
if PIECE == 'drainer':
    VARIANTS = {'R as it is': []}
if PIECE == 'bin':               # the 200 mm bins, one wall thickness per variant, and the tall riser
    VARIANTS = {'W126 bin walls 1.26 (3 lines)': ['bin_wall=1.26'], 'W168 bin walls 1.68 (4 lines)': ['bin_wall=1.68'],
                'W210 bin walls 2.10 (5 lines)': ['bin_wall=2.1'], 'R120 riser 120, walls 1.26': ['bin_wall=1.26', 'fea_riser=120']}
if PIECE == 'strip':             # the sway test (test_sway), its bare strip and the one with fins
    VARIANTS = {'S120 strips 120 mm (the default)': [], 'S100 strips 100 mm': ['test_sway_h=100']}
PATCH_R = 3.0                     # radius of the loaded patch, the nozzle's reach
LAYER = 0.4                       # the top layer's nodes: within this of the cut


def export(defs, cut, stl):
    echo = stl[:-4] + '.echo'
    args = [a for d in defs + ['cut=%g' % cut] for a in ('-D', d)]
    subprocess.run(['openscad', '-o', stl] + args + [SCAD], check=True, capture_output=True)
    subprocess.run(['openscad', '-o', echo] + args + [SCAD], check=True, capture_output=True)
    d = {}
    for line in open(echo):
        if line.startswith('ECHO: "FEA"'):
            k, v = line.split(',', 2)[1:]
            d[k.strip().strip('"')] = json.loads(v.strip())
    return d


def points_auto(X, top):
    """For a piece without the soap caddy's names: on the top layer, the right
    side wall's back edge, middle and front, and the front's middle."""
    T = X[top]
    xr = T[:, 0].max()
    wall = T[T[:, 0] > xr - 1.0]
    yb, yf = wall[:, 1].max(), wall[:, 1].min()
    front = T[T[:, 1] < T[:, 1].min() + 1.0]
    return {'wall back': (xr - 0.84, yb - 3), 'wall middle': (xr - 0.84, (yb + yf) / 2),
            'wall front': (xr - 0.84, yf + 3), 'front middle': (front[np.argmin(np.abs(front[:, 0])), 0], T[:, 1].min() + 0.8)}


def points_strip(d):
    """The sway test: each strip's free end and middle."""
    dx, l = d['STRIP_DX'], d['STRIP_L']
    return {'bare end': (0, 1), 'bare middle': (0, l / 2), 'fins end': (dx, 1), 'fins middle': (dx, l / 2)}


def points(d, z):
    """The loaded points on the top layer: along the right wall's middle line
    (back edge, middle, front), the front return's tip and the front's middle."""
    xw = d['HX'] - 0.84
    yb, yf = -d['BODY_BACK'] - 3, -d['UD'] + 1
    pts = {'wall back': (xw, yb), 'wall middle': (xw, (yb + yf) / 2), 'wall front': (xw, yf)}
    if z > 125:                   # the front returns and the bar stand above the box ledges
        pts['return tip'] = (d['OPEN_HW'] + 2, -d['UD'] + 0.8)
        pts['front middle'] = (0, -d['UD'] + 0.8)
    if os.environ.get('LEFT'):    # the left wall too: pushed +x, it leans onto right-hand fins
        for k in ('wall back', 'wall middle', 'wall front'):
            pts['left ' + k] = (-pts[k][0], pts[k][1])
    if d.get('FIN_W', 0) > 0 and os.environ.get('FIN_TOP'):
        pts['fin top'] = (d['FIN_X1'], d['FIN_Y'])     # the front right fin's flange, as it prints
    return pts


def run(d, out, cut, threads):
    tags, X, el = cm.mesh_stl(os.path.join(out, 'body.stl'), H, env=0.1, threads=threads)
    zmax = X[:, 2].max()
    top = np.where(X[:, 2] > zmax - LAYER)[0]
    base = tags[X[:, 2] < 1e-2 + 0.05]
    cases = []
    pts = points(d, cut) if 'UD' in d else points_strip(d) if 'STRIP_DX' in d else points_auto(X, top)
    for name, (px, py) in pts.items():
        r = np.hypot(X[top, 0] - px, X[top, 1] - py)
        sel = top[r < PATCH_R]
        if len(sel) == 0:
            sel = top[np.argsort(r)[:3]]
            if np.hypot(*(X[sel[0], :2] - (px, py))) > 2 * PATCH_R:
                continue          # nothing printed there at this height
        for ax in (0, 1):
            cases.append((name, 'xy'[ax], tags[sel], ax + 1))
    with open(os.path.join(out, 'sway.inp'), 'w') as f:
        f.write('*NODE, NSET=NALL\n')
        for t, x in zip(tags, X):
            f.write('%d, %.5f, %.5f, %.5f\n' % (t, *x))
        f.write('*ELEMENT, TYPE=C3D10, ELSET=EALL\n')
        for i, e in enumerate(el):
            f.write('%d, %s\n' % (i + 1, ', '.join(map(str, e))))
        f.write('*NSET, NSET=BASE\n%s\n' % ',\n'.join(map(str, base)))
        f.write('*MATERIAL, NAME=PETG\n*ELASTIC\n%g, %g\n' % (cm.E, cm.NU))
        f.write('*SOLID SECTION, ELSET=EALL, MATERIAL=PETG\n*BOUNDARY\nBASE, 1, 3\n')
        for k, (_, _, sel, dof) in enumerate(cases):
            f.write('*NSET, NSET=P%d\n%s\n' % (k, ',\n'.join(map(str, sel))))
        for k, (_, _, sel, dof) in enumerate(cases):
            f.write('*STEP\n*STATIC\n*CLOAD, OP=NEW\n')
            for t in sel:
                f.write('%d, %d, %.6g\n' % (t, dof, 1.0 / len(sel)))
            f.write('*NODE PRINT, NSET=P%d\nU\n*END STEP\n' % k)
    env = dict(os.environ, OMP_NUM_THREADS=str(threads), CCX_NPROC_EQUATION_SOLVER=str(threads))
    subprocess.run(['ccx', '-i', 'sway'], cwd=out, check=True, env=env, stdout=open(os.path.join(out, 'sway.log'), 'w'))
    # one displacement block per step, in order
    blocks, cur = [], None
    for line in open(os.path.join(out, 'sway.dat')):
        if line.strip().startswith('displacements'):
            cur = []
            blocks.append(cur)
        elif cur is not None and line.split() and line.split()[0].isdigit():
            cur.append([float(v) for v in line.split()[1:4]])
    res = {}
    for (name, ax, sel, dof), u in zip(cases, blocks):
        res[(name, ax)] = float(np.mean(np.array(u)[:, dof - 1]))      # mm per N
    return res


def main():
    out = sys.argv[1]
    names = [v for v in VARIANTS if not sys.argv[2:] or v.split()[0] in sys.argv[2:]]
    threads = int(os.environ.get("THREADS", 6))
    rows = {}
    for name in names:
        key = name.split()[0]
        for cut in CUTS:
            d = os.path.join(out, key, 'z%03d' % cut)
            os.makedirs(d, exist_ok=True)
            t0 = time.time()
            dims = export(VARIANTS[name], cut, os.path.join(d, 'body.stl'))
            cut_z = min(cut, dims['TOP'])
            res = run(dims, d, cut_z, threads)
            rows[(key, cut)] = res
            worst = max(res.items(), key=lambda kv: kv[1])
            print('%-3s z %3d  worst %.4f mm/N (%s, %s)  %s  [%.0f s]' % (
                key, cut, worst[1], worst[0][0], worst[0][1],
                '  '.join('%s %s %.4f' % (n, a, v) for (n, a), v in sorted(res.items())), time.time() - t0), flush=True)
            json.dump({'%s|%s' % k: v for k, v in res.items()}, open(os.path.join(d, 'result.json'), 'w'))


if __name__ == '__main__':
    main()
