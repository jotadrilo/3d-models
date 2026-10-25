"""The cutlery drainer on the wall, bonded, under its load cases (fea/README.md,
"Cutlery drainer"), for each design variant: one table line per variant and
case, and the cups' reactions.

usage: python drainer_fea.py <out dir> [variant ...] [--cases=daily,pull_end]
"""
import sys, os, subprocess, time
import numpy as np
import caddy_model as cm
import drainer_model as dm

# The study's variants are written against the drainer as it was before it (V0); OLD puts those
# defaults back under each of them. F is the drainer as it is now: SPW4 + RX24.
OLD = ['cup_span=120', 'cup_pitch=55', 'plate_window=[]', 'plate_window_inset=0', 'rack_t=1.6', 'rack_slots_across=false']
VARIANTS = {                      # one change per experiment from the variant named in the comment
    'F the drainer as it is now (SPW4 + RX24)': [],
    'V0 as it was': [],
    'S150 cups 150 mm apart': ['cup_span=150'],                                 # V0
    'S175 cups 175 mm apart': ['cup_span=175'],                                 # V0
    'P75 cup rows 75 mm apart': ['cup_pitch=75'],                               # V0
    'T2 plate 2.1 mm': ['back_t=2.1'],                                          # V0
    'W windows, 20 mm bands': ['plate_window=[0]', 'plate_window_inset=20'],    # V0
    'SP75 S175 + rows 75 mm apart': ['cup_span=175', 'cup_pitch=75'],           # S175
    'SP80 S175 + rows 80 mm apart': ['cup_span=175', 'cup_pitch=80'],           # S175
    'SW20 S175 + window, 20 mm bands': ['cup_span=175', 'plate_window=[0]', 'plate_window_inset=20'],   # S175
    'SW10 S175 + window, 10 mm bands': ['cup_span=175', 'plate_window=[0]', 'plate_window_inset=10'],   # S175
    'SPW10 SP80 + window, 10 mm bands': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=10'],   # SP80
    'SPW4 SP80 + window, 4 mm bands': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4'],      # SPW10
    # the rack, from SPW4 (B: the same drainer, the bins meshed and bonded to the rack)
    'B SPW4, bins meshed': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4'],                 # SPW4
    'RT24 rack floor 2.4 mm': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_t=2.4'],  # SPW4
    'FH25 rack fences 25 mm': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'fence_h=25'],  # SPW4
    'RX rack slots front to back': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_slots_across=true'],  # SPW4
    'BE SPW4, bin loads under their walls': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4'],  # SPW4
    'RXE RX, bin loads under their walls': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_slots_across=true'],  # BE
    'RX20 RX + rack floor 2.0 mm': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_slots_across=true', 'rack_t=2.0'],          # RX
    'RX24 RX + rack floor 2.4 mm': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_slots_across=true', 'rack_t=2.4'],          # RX
    'RX20E RX20, bin loads under their walls': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_slots_across=true', 'rack_t=2.0'],   # RXE
    'RX24E RX24, bin loads under their walls': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4', 'rack_slots_across=true', 'rack_t=2.4'],   # RXE
    'BC SPW4, bins resting on the rack (contact)': ['cup_span=175', 'cup_pitch=80', 'plate_window=[0]', 'plate_window_inset=4'],  # B
}
MESH_BINS = ('B', 'BC')           # variants that mesh the bins
CONTACT = ('BC',)                 # of those, the bins rest on the rack (frictional contact): it did not converge
BIN_EDGES = ('BE', 'RXE', 'RX20E', 'RX24E')         # variants that put each bin's load under its walls
H = {'default': 2.5, 'plate': 1.5, 'handle': 1.5}
G = 9.81e-3                       # N per g
CUTLERY = 350 * G                 # a meal for four, spread over the three bins
END = 600 * G                     # all the knives in one end bin: four table knives, a chef's and a paring knife
TOWEL = 300 * G                   # a soaked dish towel, folded over the bar
PULL = 20.0 / np.sqrt(2)          # 20 N on the towel, down and forward at 45°
TIES = [('TRAY_BOTTOM', 'TRAY_LEDGES'), ('RACK_BOTTOM', 'RACK_LEDGES'), ('TAILS', 'HOUSINGS'), ('PINS', 'SOCKETS')]
# across the layers, per part: the plate prints on its back (y), the rest with z up
ACROSS = {'plate': 1, 'body': 2, 'tray': 1, 'rack': 2, 'handle': 2}


def cases(bin_n):
    """The load cases, from one empty bin's weight in N."""
    daily = {'BIN0': bin_n + CUTLERY, 'BIN1': bin_n + CUTLERY, 'BIN2': bin_n + CUTLERY, 'TOWEL': TOWEL}
    return {
        'daily': daily,
        'end': {'BIN0': bin_n + END, 'BIN1': bin_n, 'BIN2': bin_n, 'TOWEL': TOWEL},
        'pull_mid': dict(daily, PULL_C_TOP=PULL, PULL_C_BACK=PULL),
        'pull_end': dict(daily, PULL_E_TOP=PULL, PULL_E_BACK=PULL),
    }


def von_mises(s):
    sxx, syy, szz, sxy, syz, szx = s.T
    return np.sqrt(0.5 * ((sxx - syy) ** 2 + (syy - szz) ** 2 + (szz - sxx) ** 2) + 3 * (sxy ** 2 + syz ** 2 + szx ** 2))


def main():
    out = sys.argv[1]
    only = [a.split('=', 1)[1].split(',') for a in sys.argv[2:] if a.startswith('--cases=')]
    picked = [a for a in sys.argv[2:] if not a.startswith('--')]
    names = [v for v in VARIANTS if not picked or v.split()[0] in picked]
    env = dict(os.environ, OMP_NUM_THREADS='12', CCX_NPROC_EQUATION_SOLVER='12', CCX_NPROC_RESULTS='12')
    for name in names:
        defs = VARIANTS[name] if name.startswith('F ') else OLD + VARIANTS[name]
        d = os.path.join(out, name.split()[0])
        os.makedirs(d, exist_ok=True)
        t0 = time.time()
        dm.MESH_BINS = name.split()[0] in MESH_BINS
        dm.BIN_EDGES = name.split()[0] in BIN_EDGES
        bin_n = 0.0 if dm.MESH_BINS else dm.export(d, defs) * dm.RHO * 9810   # a meshed bin weighs itself
        if dm.MESH_BINS:
            dm.export(d, defs)
        dims = dm.dims(defs)
        dm.mesh_parts(d, H)
        model = dm.Model(d, H, dims)
        vol = dm.stl_volume(os.path.join(d, 'plate.stl'))
        print('%s: plate %.0f mm3, rack %.0f mm3, an empty bin %.2f N' % (name, vol, dm.stl_volume(os.path.join(d, 'rack.stl')), bin_n), flush=True)
        contact = name.split()[0] in CONTACT
        ties = TIES + ([('BINS_BOTTOM', 'RACK_TOP')] if dm.MESH_BINS and not contact else [])
        for case, loads in cases(bin_n).items():
            if only and case not in only[0]:
                continue
            with open(os.path.join(d, case + '.inp'), 'w') as f:
                model.write_mesh(f)
                for i, (slave, master) in enumerate(ties):
                    f.write('*TIE, NAME=T%d, POSITION TOLERANCE=0.25, ADJUST=NO\n%s, %s\n' % (i + 1, slave, master))
                if contact:
                    # weak springs to ground on each bin, so the first iteration is not singular
                    # before the contact carries anything (0.01 N/mm: negligible), and friction
                    # 0.3 on the rack, as on the soap caddy's ledges
                    sid = model.max_eid + 1
                    soft = []
                    f.write('*ELEMENT, TYPE=SPRING1, ELSET=SOFT\n')
                    tags = model.parts['bins']['tags']
                    for x in dims['BIN_XS']:
                        mine = [t for t in tags if abs(model.X[int(t)][0] - x) < dims['BIN_W'] / 2]
                        for t in mine[:: max(1, len(mine) // 4)][:4]:
                            for dof in (1, 2, 3):
                                soft.append((sid, dof))
                                f.write('%d, %d\n' % (sid, int(t)))
                                sid += 1
                    for dof in (1, 2, 3):
                        f.write('*ELSET, ELSET=SOFT%d\n%s\n' % (dof, '\n'.join(str(e) for e, k in soft if k == dof)))
                        f.write('*SPRING, ELSET=SOFT%d\n%d\n0.01\n' % (dof, dof))
                    f.write('*SURFACE INTERACTION, NAME=SIF\n*SURFACE BEHAVIOR, PRESSURE-OVERCLOSURE=LINEAR\n5000.\n'
                            '*FRICTION\n0.3, 2000.\n*CONTACT PAIR, INTERACTION=SIF, TYPE=SURFACE TO SURFACE\nBINS_BOTTOM, RACK_TOP\n')
                    f.write('*STEP, INC=200\n*STATIC\n0.25, 1.0, 1e-4, 0.25\n')
                else:
                    f.write('*STEP\n*STATIC\n')
                model.write_loads(f, loads)
                model.write_output(f)
                f.write('*END STEP\n')
            subprocess.run(['ccx', '-i', case], cwd=d, check=True, env=env, stdout=open(os.path.join(d, case + '.log'), 'w'))
            U, S = cm.read_frd(os.path.join(d, case + '.frd'))
            tot = cm.cup_reactions(os.path.join(d, case + '.dat'))
            print('%-10s %-9s (%.0f s)' % (name.split()[0], case, time.time() - t0), flush=True)
            for part, ax in ACROSS.items():
                tags = [t for t in model.parts[part]['tags'] if int(t) in S]   # nodes of left-out slivers have no results
                s = np.array([S[int(t)] for t in tags])
                vm = von_mises(s)
                u = max(np.linalg.norm(U[int(t)]) for t in tags)
                j = np.argmax(vm)
                P = model.X[int(tags[j])]
                print('  %-6s moves %.3f mm; von Mises p99 %5.2f, p99.9 %5.2f, peak %5.2f MPa at (%.0f, %.0f, %.0f); '
                      'across its layers p99.9 %5.2f, peak %5.2f MPa'
                      % (part, u, np.percentile(vm, 99), np.percentile(vm, 99.9), vm[j], *P,
                         np.percentile(s[:, ax], 99.9), s[:, ax].max()), flush=True)
            # the rack's own sag: its lowest point against where it rests on its ledges
            rb = {int(n) for _, _, _, ns in model.surf['RACK_BOTTOM'] for n in ns}
            rt = [t for t in model.parts['rack']['tags'] if int(t) in U]
            uz = np.array([U[int(t)][2] for t in rt])
            print('  rack sags %.2f mm (its floor, against its ledges)' % (np.mean([U[n][2] for n in rb if n in U]) - uz.min()), flush=True)
            dm.print_cups(tot)
            sys.stdout.flush()


if __name__ == '__main__':      # the meshing workers re-import this file (macOS spawns them)
    main()
