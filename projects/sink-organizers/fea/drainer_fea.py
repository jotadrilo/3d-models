"""The cutlery drainer on the wall, bonded, under its load cases (fea/README.md,
"Cutlery drainer"), for each design variant: one table line per variant and
case, and the cups' reactions.

usage: python drainer_fea.py <out dir> [variant ...] [--cases=daily,pull_end]
"""
import sys, os, subprocess, time
import numpy as np
import caddy_model as cm
import drainer_model as dm

VARIANTS = {                      # one change per experiment from the variant named in the comment
    'V0 as is': [],
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
}
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
        defs = VARIANTS[name]
        d = os.path.join(out, name.split()[0])
        os.makedirs(d, exist_ok=True)
        t0 = time.time()
        bin_n = dm.export(d, defs) * dm.RHO * 9810
        dims = dm.dims(defs)
        dm.mesh_parts(d, H)
        model = dm.Model(d, H, dims)
        vol = dm.stl_volume(os.path.join(d, 'plate.stl'))
        print('%s: plate %.0f mm3, an empty bin %.2f N' % (name, vol, bin_n), flush=True)
        for case, loads in cases(bin_n).items():
            if only and case not in only[0]:
                continue
            with open(os.path.join(d, case + '.inp'), 'w') as f:
                model.write_mesh(f)
                for i, (slave, master) in enumerate(TIES):
                    f.write('*TIE, NAME=T%d, POSITION TOLERANCE=0.25, ADJUST=NO\n%s, %s\n' % (i + 1, slave, master))
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
            dm.print_cups(tot)
            sys.stdout.flush()


if __name__ == '__main__':      # the meshing workers re-import this file (macOS spawns them)
    main()
