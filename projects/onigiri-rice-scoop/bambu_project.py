#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the onigiri rice scoops.

Both scoops (basmati and brown rice) go on one plate, upside down (rim and
handle on the bed): the face, the nori and the cheeks are inlays in the first
three layers, so the two share the same few filament changes.

    python3 bambu_project.py [-o onigiri-rice-scoop-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "onigiri-rice-scoop.scad")

# (object name, rice, bed centre x, y); the plate is 256 x 256.
LAYOUT = [
    ("Basmati scoop", "basmati", 128, 175),
    ("Integral scoop", "integral", 128, 80),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "onigiri-rice-scoop-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Onigiri rice scoop",
        process="0.20mm Standard @BBL X1C",   # 0.2 mm layers: the 0.6 mm inlays are 3 layers
        filaments=[
            Filament(PLA_BASIC, "#FFFFFF"),   # rice: the body
            Filament(PLA_BASIC, "#000000"),   # nori, eyes and mouth
            Filament(PLA_BASIC, "#F55A74"),   # cheeks
        ],
        # The face is printed in the first layers: Arachne keeps the thin strokes and
        # elephant foot compensation would shrink them. Gyroid fills the solid foot.
        process_overrides={
            "wall_generator": "arachne",
            "elefant_foot_compensation": "0",
            "sparse_infill_pattern": "gyroid",
        },
    )
    plate = proj.plate("Onigiri rice scoops", prime_tower=(20, 30))
    part_name = lambda c: {"#FFFFFF": "rice", "#000000": "nori", "#F55A74": "cheeks"}.get(c, c)
    for name, rice, x, y in LAYOUT:
        mesh = load_scad(SCAD, "scoop", args.defs + [f'rice="{rice}"'], rotate=(180, 0, 0))
        plate.add(name, mesh, x, y, part_name=part_name)
    proj.write(args.output)


if __name__ == "__main__":
    main()
