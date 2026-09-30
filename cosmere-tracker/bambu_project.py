#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the Cosmere tracker.

Every part goes on one P1S plate: colours only change in the first three
layers and in the top three of the wheels, so sharing a plate costs about ten
filament changes in total.

    python3 bambu_project.py [-o cosmere-tracker-p1s.3mf] [-D var=val ...]
"""
import argparse, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "cosmere-tracker.scad")

# (object name, OpenSCAD part, bed centre x, y); the plate is 256 x 256.
LAYOUT = [
    ("Tens ring 1", "ring", 90, 36),
    ("Tens ring 2", "ring", 154, 36),
    ("Tens ring 3", "ring", 218, 36),
    ("Front plate", "front", 104, 102),
    ("Units disc 1", "disc", 230, 102),
    ("Back frame", "frame", 104, 166),
    ("Units disc 2", "disc", 230, 166),
    ("Stand", "stand", 109, 221),
    ("Units disc 3", "disc", 234, 221),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "cosmere-tracker-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    layout = LAYOUT
    if any(re.fullmatch(r"\s*show_investiture\s*=\s*false\s*", d) for d in args.defs):
        layout = [o for o in LAYOUT if not o[0].endswith(" 3")]

    meshes = {p: load_scad(SCAD, p, args.defs) for p in {p for _, p, _, _ in layout}}
    # Filament 1 is the body: the colour with the most triangles in the frame.
    frame = meshes["frame"].by_colour
    body = max(frame, key=lambda c: len(frame[c][1]))
    inks = sorted({c for m in meshes.values() for c in m.colours()} - {body})

    proj = Project(
        "Cosmere tracker",
        process="0.20mm Standard @BBL X1C",   # 0.2 mm layers: the 0.6 mm inlays are 3 layers
        filaments=[Filament(PLA_BASIC, c) for c in [body] + inks],
        # Labels and digits are printed in the first layer: Arachne keeps thin strokes
        # that Classic would drop, and elephant foot compensation would shrink them.
        process_overrides={"wall_generator": "arachne", "elefant_foot_compensation": "0"},
    )
    plate = proj.plate("Cosmere tracker", prime_tower=(20, 30))
    part_name = lambda c: f"{'body' if c == body else 'inlay'} {c}"
    for name, part, x, y in layout:
        plate.add(name, meshes[part], x, y, part_name=part_name)
    proj.write(args.output)


if __name__ == "__main__":
    main()
