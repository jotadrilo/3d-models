#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the K120 keyboard leg.

Plate 1, "Colour samples": two legs in each of the four PETG filaments in the
AMS, printed by object (each leg whole, one after another), so the plate costs
three filament changes instead of one every layer, and no prime tower.
Plate 2, "Pair": the two legs a keyboard needs, in one filament.

Both lie flat, the plate face on the bed: the pins and the leg's length in
XY, the strong way for their shear and compression.

    python3 bambu_project.py [-o keyboard-leg-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PETG_BASIC, PETG_HF, PETG_MATTE, Filament, Mesh, Project, load_scad  # noqa: E402

PETG_TRANSLUCENT = "Bambu PETG Translucent @BBL X1C"   # also the P1S 0.4 preset

# One per AMS slot, in slot order. The colours only tell the filaments apart
# (and colour the renders), as the AMS reads them from the spools' tags.
FILAMENTS = [
    ("Blue", Filament(PETG_HF, "#002E96")),
    ("Clear", Filament(PETG_TRANSLUCENT, "#E8EEF2")),
    ("Matte black", Filament(PETG_MATTE, "#000000")),
    ("Black", Filament(PETG_BASIC, "#1B1B1B")),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "keyboard-leg-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "K120 keyboard leg",
        # Fine layers for the 2 mm pins and the snap ridge; the rails are solid walls anyway.
        process="0.12mm Fine @BBL X1C",
        filaments=[f for _, f in FILAMENTS],
        process_overrides={
            "wall_loops": "4",
            "sparse_infill_density": "40%",
            "sparse_infill_pattern": "gyroid",
            "seam_position": "back",          # the seam at the foot end, off the pins and the tongue
            "enable_prime_tower": "0",        # by object allows no prime tower
        },
    )
    leg = load_scad(os.path.join(HERE, "keyboard-leg.scad"), "leg", args.defs, colour=False)
    (data,) = leg.by_colour.values()

    # By object: the toolhead (57 mm clearance radius) must clear the legs already
    # printed, so they sit 85 mm apart, front first, leaving the back-right corner
    # free; the slicer prints them in this order.
    samples = proj.plate("Colour samples", print_sequence="by object")
    spots = [(x, y) for y in (30, 115, 200) for x in (40, 125, 210)][:8]
    for i, (name, f) in enumerate(FILAMENTS):
        for j in range(2):
            x, y = spots[2 * i + j]
            samples.add(f"Leg {name} {j + 1}", Mesh({f.colour: data}), x, y)

    pair = proj.plate("Pair")
    for j, x in enumerate((113, 143)):
        pair.add(f"Leg {j + 1}", Mesh({FILAMENTS[2][1].colour: data}), x, 128)
    proj.write(args.output)


if __name__ == "__main__":
    main()
