"""Board-level FEA of the dog gate: the plywood board as an orthotropic shell
(CalculiX S8R) on each support scheme, under the dog's load cases.

It answers "where is the board held" before any printed part is sized: how far
the board bends, how hard the plywood works, and the force on every support,
which then becomes the load case of each printed part.

Coordinates (mm): x across the stair, 0 at the wall, W at the railing; y along
the stair, + uphill; z up, 0 on the tread the board stands on. The board's
mid-plane is y = 0, in the middle of the tread (nosing at y = -T/2, riser of
the next step at y = +T/2).

Supports (all one-sided ones solved by iteration: a support that pulls is
released, a released one that is crossed is put back):
  tread      every bottom-edge node, held down only
  feet       the brackets ("escuadras"), rigid on the board over FOOT_W x FOOT_H;
             their toes rest on the tread (down only), the uphill toe also
             bears on the riser of the next step (+y only). Friction ignored.
  rail       a clamp on each railing bar, rigid on the board over the channel;
             the bar is a hinge: free along the bar and turning about it,
             held across it (in the vertical plane and sideways)
  wall_ch    U channels screwed to the wall: the wall edge held in y over their length
  wall_pad   pads pressed on the wall (no holes): held in y at two points; the
             reaction must stay under mu x preload, checked afterwards
  props      battens from the board to the next tread up and down, compression only

usage: python board_fea.py <out dir> [variant ...]
"""
import sys, os, subprocess, math, json
import numpy as np

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

# ----------------------------------------------------------------- geometry
W, H, TH = 780.0, 1000.0, 10.0          # board
T, R = 300.0, 175.0                     # step going and rise
SLOPE = math.atan2(R, T)
RAIL_TOP, RAIL_MID = 900.0, 450.0       # bar axes above the nosing line, vertically
NOSING_Z = T / 2 * math.tan(SLOPE)      # nosing line above the tread at the board
BAR_X = W + 40.0                        # bar axis, beside the board's railing edge
CH_W, CH_H = 80.0, 100.0                # clamp channel: depth into the board, length
FOOT_X = (100.0, W - 100.0)             # bracket centres
FOOT_W, FOOT_H, TOE = 40.0, 200.0, T / 2 - 5
WALL_CH = ((50.0, 250.0), (800.0, 1000.0))   # wall channel spans (z)
WALL_PAD = (250.0, 800.0)                    # wall pad heights
PROP_Z = 800.0                               # where the props meet the board
PROP_UP = (T + T - 10.0 - T / 2, R)          # foot (y, z): back of the next tread, against its riser
PROP_DN = (-T / 2 - T / 2, -R)               # foot: middle of the tread below
PROP_A, PROP_E = 30.0 * 30.0, 10000.0        # 30 x 30 pine batten
BATTEN = (60.0, 20.0, 20.0, W)               # top-edge batten: height, thickness, x from, x to (into the clamp)
E_PINE, FM_PINE = 10000.0, 24.0              # along the grain; C24 bending strength

# ----------------------------------------------------------------- plywood, worst case
# 10 mm softwood / poplar plywood, low end of EN 12369-2-type values. The grain
# direction of the face plies is unknown, so both are run.
E_PAR, E_PERP, G12, G_ROLL, NU12 = 5000.0, 2500.0, 350.0, 50.0, 0.08
FM_PAR, FM_PERP = 20.0, 12.0            # characteristic bending strength, MPa
RHO = 450e-12                           # t/mm^3 (light: the worst case for tipping)

# ----------------------------------------------------------------- loads (dog 35 kg)
DOG = 35 * 9.81
PAW = 100.0
CASES = {   # name: list of (x centre, z centre, patch w, patch h, force N)
    'lean':        [(240, 950, PAW, PAW, 0.3 * DOG), (540, 950, PAW, PAW, 0.3 * DOG)],
    'strike_mid':  [(390, 950, PAW, PAW, 2.0 * DOG)],
    'strike_wall': [(60, 950, PAW, PAW, 2.0 * DOG)],
    'strike_rail': [(720, 950, PAW, PAW, 2.0 * DOG)],
    'push_low':    [(390, 400, 200, 200, 0.5 * DOG)],
}

VARIANTS = {
    'B0_rail':        dict(feet=True, rail=True, grip=True),
    'B1_wall':        dict(feet=True, rail=True, grip=True, wall_ch=True),
    'B1_wall_free':   dict(feet=True, rail=True, wall_ch=True),
    'B1_wall_top':    dict(feet=True, rail='top', grip=True, wall_ch=True),
    'B1_wall_bat':    dict(feet=True, rail=True, grip=True, wall_ch=True, batten=True),
    'B1_wall_nofeet': dict(rail=True, grip=True, wall_ch=True, batten=True),
    'B2_pad':         dict(feet=True, rail=True, grip=True, wall_pad=True),
    'B2_pad_bat':     dict(feet=True, rail=True, grip=True, wall_pad=True, batten=True),
}

h = 20.0                                 # element size
nx, nz = int(W / h), int(H / h)


def build_mesh():
    """One layer of 20-node bricks (C3D20R) through the thickness: a shell in all
    but name, which CalculiX lets rigid bodies grab (its own S8R shells cannot).
    Local (xi, eta, zeta) = (x, z, -y), right-handed."""
    ids, xyz = {}, []
    def nid(i, j, k):                       # k: 0 at y = +t/2, 1 mid, 2 at y = -t/2
        if (i, j, k) not in ids:
            ids[i, j, k] = len(xyz) + 1
            xyz.append((i * h / 2, TH / 2 - k * TH / 2, j * h / 2))
        return ids[i, j, k]
    els = []
    for j in range(nz):
        for i in range(nx):
            a, b = 2 * i, 2 * j
            c = [(a, b), (a + 2, b), (a + 2, b + 2), (a, b + 2)]
            m = [(a + 1, b), (a + 2, b + 1), (a + 1, b + 2), (a, b + 1)]
            els.append([nid(*p, 0) for p in c] + [nid(*p, 2) for p in c] +
                       [nid(*p, 0) for p in m] + [nid(*p, 2) for p in m] + [nid(*p, 1) for p in c])
    return np.array(xyz), els, ids


XYZ, ELS, IDS = build_mesh()
NN = len(XYZ)


def nodes_in(x0, x1, z0, z1):
    m = (XYZ[:, 0] >= x0 - 1e-6) & (XYZ[:, 0] <= x1 + 1e-6) & (XYZ[:, 2] >= z0 - 1e-6) & (XYZ[:, 2] <= z1 + 1e-6)
    return list(np.nonzero(m)[0] + 1)


def els_in(x0, x1, z0, z1):
    out = []
    for k, e in enumerate(ELS):
        c = XYZ[np.array(e[:8]) - 1].mean(0)
        if x0 <= c[0] <= x1 and z0 <= c[2] <= z1:
            out.append(k + 1)
    return out


MODEL_BATTEN = []


def model(var, grain):
    """Extra nodes, rigid bodies, fixed dofs, one-sided supports and trusses for a variant."""
    extra, rigid, fixed, uni, truss, trans, stiff, links, soft = [], [], [], [], [], [], [], [], []
    nid = [NN]

    def nearest(p):
        return int(np.argmin(((XYZ - np.array(p)) ** 2).sum(1))) + 1

    def node(p):
        nid[0] += 1
        extra.append((nid[0], p))
        return nid[0]

    # tread under the bottom edge: z down blocked
    for n in nodes_in(0, W, 0, 0):
        uni.append((n, 3, +1, 'tread'))
    if not var.get('feet'):
        fixed.append((nodes_in(0, 0, 0, 0)[0], 1))          # nothing else holds x
    if var.get('feet'):
        for k, fx in enumerate(FOOT_X):
            up, dn = node((fx, TOE, 0)), node((fx, -TOE, 0))
            # the bracket as stiff struts from each toe to the board where it is bolted: the foot
            # along the tread to the bottom bolt, the gusset up to the top one (CalculiX does not
            # let truss ends sit in a rigid body)
            for toe, face in ((up, TH / 2), (dn, -TH / 2)):
                for zb in (20.0, FOOT_H):
                    for dx in (-FOOT_W / 2, FOOT_W / 2):
                        stiff.append((toe, nearest((fx + dx, face, zb)), f'foot{k}'))
                fixed.append((toe, 1))
            uni += [(up, 3, +1, f'foot{k}_up_z'), (dn, 3, +1, f'foot{k}_dn_z'), (up, 2, -1, f'foot{k}_riser')]
    if var.get('rail'):
        a = (0.0, math.cos(SLOPE), math.sin(SLOPE))
        bars = (('rail_mid', RAIL_MID + NOSING_Z), ('rail_top', RAIL_TOP + NOSING_Z))
        for name, zbar in bars[1:] if var.get('rail') == 'top' else bars:
            # the clamp: a hub on the bar axis tied by stiff struts to the board over the channel
            # (both faces), a pin joint, so no turning stiffness from the saddle is counted
            hub = node((BAR_X, 0, zbar))
            z0, z1 = max(0, zbar - CH_H / 2), min(H, zbar + CH_H / 2)
            for nn in nodes_in(W - CH_W, W, z0, z1):
                if abs(abs(XYZ[nn - 1][1]) - TH / 2) < 1e-6:      # both faces, every node
                    stiff.append((hub, nn, name))
            # the bar holds it across the bar (n): a stiff link to ground, whose force is the
            # clamp's load. Along the bar it is free, and the board slides in x in the channel
            # (slotted pin), so the clamp takes no sideways force
            n = (0.0, -math.sin(SLOPE), math.cos(SLOPE))
            g = node((BAR_X + 100 * n[0], 100 * n[1], zbar + 100 * n[2]))
            fixed += [(g, 1), (g, 2), (g, 3)]
            links.append((hub, g, f'{name}_n'))
            if var.get('grip'):
                # the clamp gripping the bar by friction: also held along the bar, and the
                # force it takes there is what the grip must hold
                a = (0.0, math.cos(SLOPE), math.sin(SLOPE))
                g = node((BAR_X + 100 * a[0], 100 * a[1], zbar + 100 * a[2]))
                fixed += [(g, 1), (g, 2), (g, 3)]
                links.append((hub, g, f'{name}_along'))
            # x: free at the bar; held by a soft spring so the hub is not a mechanism
            gx = node((BAR_X + 100, 0, zbar))
            fixed += [(gx, 1), (gx, 2), (gx, 3)]
            soft.append((hub, gx))
    if var.get('wall_ch'):
        for k, (z0, z1) in enumerate(WALL_CH):
            for n in nodes_in(0, 0, z0, z1):
                fixed.append((n, 2, f'wall_ch{k}'))
    if var.get('wall_pad'):
        for k, z in enumerate(WALL_PAD):
            for n in nodes_in(0, 20, z - 20, z + 20):
                fixed.append((n, 2, f'wall_pad{k}'))
    if var.get('props'):
        for k, fx in enumerate(FOOT_X):
            # the fitting: a hub off the board's downhill face, tied to a 60 x 80 patch of both faces
            top = node((fx, -40.0, PROP_Z))
            for dx in (-30, 30):
                for dz in (-40, 40):
                    for face in (TH / 2, -TH / 2):
                        stiff.append((top, nearest((fx + dx, face, PROP_Z + dz)), f'fit{k}'))
            for tag, (fy, fz) in (('up', PROP_UP), ('dn', PROP_DN)):
                foot = node((fx, fy, fz))
                fixed += [(foot, 1, f'prop{k}_{tag}'), (foot, 2, f'prop{k}_{tag}'), (foot, 3, f'prop{k}_{tag}')]
                truss.append((top, foot, f'prop{k}_{tag}'))
    bat = []
    if var.get('batten'):
        bh, bt, bx0, bx1 = BATTEN
        bn = {}
        def bnode(i, j, k):                  # k: 1 mid, 2 outer face
            if (i, j, k) not in bn:
                bn[i, j, k] = node((i * h / 2, TH / 2 + k * bt / 2, j * h / 2))
            return bn[i, j, k]
        i0, i1, j0 = int(bx0 / h), int(bx1 / h), int((H - bh) / h)
        for j in range(j0, nz):
            for i in range(i0, i1):
                a, b = 2 * i, 2 * j
                c = [(a, b), (a + 2, b), (a + 2, b + 2), (a, b + 2)]
                m = [(a + 1, b), (a + 2, b + 1), (a + 1, b + 2), (a, b + 1)]
                bat.append([bnode(*p, 2) for p in c] + [IDS[p + (0,)] for p in c] +
                           [bnode(*p, 2) for p in m] + [IDS[p + (0,)] for p in m] + [bnode(*p, 1) for p in c])
    MODEL_BATTEN[:] = bat
    held = {n for ns, _, _ in rigid for n in ns}      # a rigid body's nodes take no other support
    fixed = [f for f in fixed if f[0] not in held]
    uni = [u for u in uni if u[0] not in held or u[3] != 'tread']
    return extra, rigid, fixed, uni, truss + [t + ('stiff',) for t in stiff] + [t + ('link',) for t in links] + [t + ('x', 'soft') for t in soft], trans


def deck(var, grain, case, sign, active_uni, active_truss):
    extra, rigid, fixed, uni, truss, trans = model(var, grain)
    L = ['*NODE']
    L += [f'{i + 1},{p[0]:.4f},{p[1]:.4f},{p[2]:.4f}' for i, p in enumerate(XYZ)]
    L += [f'{n},{p[0]:.4f},{p[1]:.4f},{p[2]:.4f}' for n, p in extra]
    L.append('*ELEMENT,TYPE=C3D20R,ELSET=BOARD')
    L += [f'{k + 1},' + ','.join(map(str, e[:15])) + ',\n' + ','.join(map(str, e[15:])) for k, e in enumerate(ELS)]
    tr = [t for t in truss if len(t) == 3 and t[2] in active_truss]
    st = [t for t in truss if len(t) == 4 and t[3] == 'stiff']
    sf = [t for t in truss if len(t) == 4 and t[3] == 'soft']
    if sf:
        L.append('*ELEMENT,TYPE=T3D2,ELSET=SOFT')
        L += [f'{400000 + k},{t[0]},{t[1]}' for k, t in enumerate(sf)]
        L += ['*MATERIAL,NAME=SOFT', '*ELASTIC', '1.,0.3', '*SOLID SECTION,ELSET=SOFT,MATERIAL=SOFT', '1.']
    lk = [t for t in truss if len(t) == 4 and t[3] == 'link']
    if lk:
        L.append('*ELEMENT,TYPE=T3D2,ELSET=LINKS')
        L += [f'{300000 + k},{t[0]},{t[1]}' for k, t in enumerate(lk)]
        L += ['*MATERIAL,NAME=STEEL', '*ELASTIC', '210000.,0.3', '*SOLID SECTION,ELSET=LINKS,MATERIAL=STEEL', '1000.']
    if tr:
        L.append('*ELEMENT,TYPE=T3D2,ELSET=PROPS')
        L += [f'{100000 + k},{a},{b}' for k, (a, b, _) in enumerate(tr)]
    if st:
        L.append('*ELEMENT,TYPE=T3D2,ELSET=BRACKETS')
        L += [f'{200000 + k},{t[0]},{t[1]}' for k, t in enumerate(st)]
        L += ['*MATERIAL,NAME=ABS', '*ELASTIC', '2000.,0.35', '*SOLID SECTION,ELSET=BRACKETS,MATERIAL=ABS', '400.']
    if MODEL_BATTEN:
        L.append('*ELEMENT,TYPE=C3D20R,ELSET=BATTEN')
        L += [f'{50000 + k},' + ','.join(map(str, e[:15])) + ',\n' + ','.join(map(str, e[15:])) for k, e in enumerate(MODEL_BATTEN)]
        L += ['*MATERIAL,NAME=PINE', '*ELASTIC,TYPE=ENGINEERING CONSTANTS',
              f'{E_PINE},400.,400.,0.4,0.4,0.4,600.,600.,', '60.,0.', '*DENSITY', f'{RHO}',
              '*SOLID SECTION,ELSET=BATTEN,MATERIAL=PINE,ORIENTATION=OR']
    e1, e2 = (E_PAR, E_PERP) if grain == 'x' else (E_PERP, E_PAR)
    L += ['*MATERIAL,NAME=PLY', '*ELASTIC,TYPE=ENGINEERING CONSTANTS',
          f'{e1},{e2},500.,{NU12},0.3,0.3,{G12},{G_ROLL},', f'{G_ROLL},0.',
          '*DENSITY', f'{RHO}',
          '*ORIENTATION,NAME=OR', '1.,0.,0.,0.,0.,1.',
          '*SOLID SECTION,ELSET=BOARD,MATERIAL=PLY,ORIENTATION=OR']
    if tr:
        L += ['*MATERIAL,NAME=WOOD', '*ELASTIC', f'{PROP_E},0.3', '*SOLID SECTION,ELSET=PROPS,MATERIAL=WOOD', f'{PROP_A}']
    for k, (ns, ref, rot) in enumerate(rigid):
        L += [f'*NSET,NSET=RB{k}'] + [str(n) for n in ns]
        L.append(f'*RIGID BODY,NSET=RB{k},REF NODE={ref},ROT NODE={rot}')
    for k, (ns, a, _) in enumerate(trans):
        L += [f'*NSET,NSET=TR{k}'] + [str(n) for n in ns]
        L += [f'*TRANSFORM,NSET=TR{k},TYPE=R', f'{a[0]},{a[1]},{a[2]},1.,0.,0.']
    L += ['*STEP', '*STATIC', '*BOUNDARY']
    L += [f'{f[0]},{f[1]},{f[1]},0.' for f in fixed]
    L += [f'{n},{d},{d},0.' for (n, d, s, _) in uni if (n, d) in active_uni]
    L += ['*DLOAD', 'BOARD,GRAV,9810.,0.,0.,-1.'] + (['BATTEN,GRAV,9810.,0.,0.,-1.'] if MODEL_BATTEN else []) + ['*DLOAD']
    for (cx, cz, pw, ph, F) in CASES[case]:
        es = els_in(cx - pw / 2, cx + pw / 2, cz - ph / 2, cz + ph / 2)
        p = F / (len(es) * h * h)
        # face 1 is the y = +t/2 face (pressure pushes towards -y), face 2 the y = -t/2 one
        L += [f'{e},P{1 if sign < 0 else 2},{p:.6f}' for e in es]
    L += ['*NSET,NSET=EVERY,GENERATE', f'1,{NN + len(extra)}', '*NODE PRINT,NSET=EVERY', 'U', '*NODE PRINT,NSET=EVERY', 'RF',
          '*EL PRINT,ELSET=BOARD', 'S'] + (['*EL PRINT,ELSET=BATTEN', 'S'] if MODEL_BATTEN else [])
    if tr:
        L += ['*EL PRINT,ELSET=PROPS', 'S']
    if lk:
        L += ['*EL PRINT,ELSET=LINKS', 'S']
    L += ['*NODE FILE', 'U', '*END STEP']
    return '\n'.join(L) + '\n', (extra, rigid, fixed, uni, truss, trans)


def parse_dat(path):
    global SB
    U, RF, S, ST = {}, {}, [], {}
    SB = []
    mode = None
    for line in open(path):
        t = line.split()
        if not t:
            continue
        if line.strip().startswith('displacements'):
            mode = 'U'; continue
        if line.strip().startswith('forces'):
            mode = 'RF'; continue
        if line.strip().startswith('stresses'):
            mode = 'S'; continue
        if t[-1] == 'OR':                    # stresses in the orientation's axes: 1 = x, 2 = z, 3 = -y
            t = t[:-1]
        try:
            vals = [float(v) for v in t]
        except ValueError:
            continue
        if mode == 'U' and len(vals) == 4:
            U[int(vals[0])] = vals[1:]
        elif mode == 'RF' and len(vals) == 4:
            RF[int(vals[0])] = vals[1:]
        elif mode == 'S' and len(vals) == 8:
            if vals[0] >= 100000:
                ST[int(vals[0])] = vals[2]
            elif vals[0] >= 50000:
                SB.append(vals[2:])
            else:
                S.append(vals[2:])
    return U, RF, np.array(S), ST


def axial(U, P, a, b, EA):
    """Tension (+) in a straight 2-node truss from its end displacements."""
    d = np.array(P[b]) - np.array(P[a])
    L = np.linalg.norm(d)
    return EA / L * float(np.dot(np.array(U[b]) - np.array(U[a]), d / L))


def run(vname, grain, case, sign):
    var = VARIANTS[vname]
    _, _, _, uni, truss, _ = model(var, grain)
    active = {(n, d) for (n, d, s, _) in uni}
    act_tr = {t[2] for t in truss if len(t) == 3}
    job = f'{vname}_{grain}_{case}_{"up" if sign > 0 else "dn"}'
    for it in range(30):
        text, (extra, rigid, fixed, uni, truss, trans) = deck(var, grain, case, sign, active, act_tr)
        open(os.path.join(OUT, job + '.inp'), 'w').write(text)
        r = subprocess.run(['ccx', '-i', job], cwd=OUT, stdout=open(os.path.join(OUT, job + '.log'), 'w'))
        dat = os.path.join(OUT, job + '.dat')
        if r.returncode or not os.path.exists(dat) or os.path.getsize(dat) == 0:
            return job, None
        U, RF, S, ST = parse_dat(dat)
        if not U:
            return job, None
        P = {i + 1: tuple(p) for i, p in enumerate(XYZ)}
        P.update({n: p for n, p in extra})
        changed = False
        for (n, d, s, _) in uni:
            if (n, d) in active:
                if RF.get(n, [0, 0, 0])[d - 1] * s < -1e-3:
                    active.discard((n, d)); changed = True
            else:
                if U[n][d - 1] * s < -1e-4:
                    active.add((n, d)); changed = True
        tr = [t for t in truss if len(t) == 3 and t[2] in act_tr]
        for k, (a, b, name) in enumerate(tr):
            if axial(U, P, a, b, PROP_E * PROP_A) > 1e-3:          # tension: a batten resting on a tread cannot pull
                act_tr.discard(name); changed = True
        if os.environ.get('TRACE'):
            print(it, len(active), sorted(act_tr), file=sys.stderr)
        if not changed:
            break
    uy = np.array([U[n][1] for n in range(1, NN + 1)])
    iu = int(np.abs(uy).argmax())
    is_ = int(np.abs(S[:, :2]).max(1).argmax()) // 8
    ce = XYZ[np.array(ELS[is_][:8]) - 1].mean(0)
    res = dict(job=job, iters=it + 1, at_u=[round(float(v)) for v in XYZ[iu][[0, 2]]], at_s=[round(float(v)) for v in ce[[0, 2]]],
               uy_max=float(np.abs(uy).max()),
               sx=float(np.abs(S[:, 0]).max()), sz=float(np.abs(S[:, 1]).max()))
    res['s_batten'] = float(np.abs(np.array(SB)[:, 0]).max()) if SB else 0.0
    fx, fz = (FM_PAR, FM_PERP) if grain == 'x' else (FM_PERP, FM_PAR)
    res['util'] = max(res['sx'] / fx, res['sz'] / fz)
    # support forces (force of the support on the board), summed per support
    sup = {}
    for f in fixed:
        if len(f) == 3:
            sup.setdefault(f[2], np.zeros(3))
    for f in fixed:
        if len(f) == 3:
            sup[f[2]][f[1] - 1] += RF.get(f[0], [0, 0, 0])[f[1] - 1]
    for (n, d, s, name) in uni:
        if name != 'tread' and (n, d) in active:
            sup.setdefault(name, np.zeros(3))[d - 1] += RF.get(n, [0, 0, 0])[d - 1]
    sup['tread'] = np.array([0, 0, sum(RF.get(n, [0, 0, 0])[2] for (n, d, s, nm) in uni if nm == 'tread' and (n, d) in active)])
    lk = [t for t in truss if len(t) == 4 and t[3] == 'link']
    for k, t in enumerate(lk):
        # link stress x area = tension; the force on the board is along the link, towards ground if in tension
        sup[t[2]] = np.array([0, 0, axial(U, P, t[0], t[1], 210000.0 * 1000.0)])
    res['supports'] = {k: [round(float(v), 1) for v in vec] for k, vec in sup.items()}
    tr = [t for t in truss if len(t) == 3 and t[2] in act_tr]
    res['props'] = {name: round(axial(U, P, a, b, PROP_E * PROP_A), 1) for (a, b, name) in tr}
    return job, res


if __name__ == '__main__':
    names = sys.argv[2:] or list(VARIANTS)
    allres = {}
    for v in names:
        for grain in os.environ.get('GRAINS', 'x,z').split(','):
            for case in CASES:
                for sign in (+1, -1):
                    job, res = run(v, grain, case, sign)
                    allres[job] = res
                    if res is None:
                        print(f'{job:40s} FAILED (mechanism or solver error)')
                    else:
                        print(f'{job:40s} it={res["iters"]:2d} uy={res["uy_max"]:7.1f}@{res["at_u"]} s@{res["at_s"]} sx={res["sx"]:5.1f} sz={res["sz"]:5.1f} bat={res["s_batten"]:5.1f} util={res["util"]:.2f} {res["supports"]} {res["props"]}', flush=True)
    json.dump(allres, open(os.path.join(OUT, 'results.json'), 'w'), indent=1)
