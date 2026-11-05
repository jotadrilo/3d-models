#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the Cosmere tracker.

Every part goes on one plate: colours only change in the first three
layers and in the top three of the wheels, so sharing a plate costs about ten
filament changes in total.

    python3 bambu_project.py [--printer p1s|x2d] [-o out.3mf] [-D var=val ...]
"""
import argparse, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PRINTERS, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "cosmere-tracker.scad")

# Per printer: (object name, OpenSCAD part, bed centre x, y, turn about Z), and the prime tower.
# The plate is 256 x 256. The X2D cannot use the left 20.5 mm, so the 200 mm long front plate,
# frame and stand stand turned a quarter, side by side, with the rings in a column beside them.
LAYOUT = {
    "p1s": dict(tower=(20, 30), objects=[
        ("Tens ring 1", "ring", 90, 42, 0),
        ("Tens ring 2", "ring", 154, 42, 0),
        ("Tens ring 3", "ring", 218, 42, 0),
        ("Front plate", "front", 104, 102, 0),
        ("Units disc 1", "disc", 230, 102, 0),
        ("Back frame", "frame", 104, 166, 0),
        ("Units disc 2", "disc", 230, 166, 0),
        ("Stand", "stand", 109, 221, 0),
        ("Units disc 3", "disc", 234, 221, 0),
    ]),
    "x2d": dict(tower=(195, 200), objects=[
        ("Tens ring 1", "ring", 220, 34, 0),
        ("Tens ring 2", "ring", 220, 98, 0),
        ("Tens ring 3", "ring", 220, 162, 0),
        ("Front plate", "front", 50.5, 104, 90),
        ("Back frame", "frame", 113.3, 104, 90),
        ("Stand", "stand", 166.7, 109, 90),
        ("Units disc 1", "disc", 40, 225, 0),
        ("Units disc 2", "disc", 80, 225, 0),
        ("Units disc 3", "disc", 120, 225, 0),
    ]),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--printer", choices=sorted(PRINTERS), default="p1s")
    ap.add_argument("-o", "--output")
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()
    pr = PRINTERS[args.printer]

    layout = LAYOUT[pr.tag]["objects"]
    if any(re.fullmatch(r"\s*show_investiture\s*=\s*false\s*", d) for d in args.defs):
        layout = [o for o in layout if not o[0].endswith(" 3")]

    meshes = {(p, t): load_scad(SCAD, p, args.defs, rotate=(0, 0, t)) for p, t in {(p, t) for _, p, _, _, t in layout}}
    # Filament 1 is the body: the colour with the most triangles in the frame.
    frame = next(m for (p, _), m in meshes.items() if p == "frame").by_colour
    body = max(frame, key=lambda c: len(frame[c][1]))
    inks = sorted({c for m in meshes.values() for c in m.colours()} - {body})

    process, overrides = pr.process("0.20mm Standard")
    proj = Project(
        "Cosmere tracker",
        process=process,   # 0.2 mm layers: the 0.6 mm inlays are 3 layers
        filaments=[Filament(pr.preset("filament", "Bambu PLA Basic"), c) for c in [body] + inks],
        # Labels and digits are printed in the first layer: Arachne keeps thin strokes
        # that Classic would drop, and elephant foot compensation would shrink them.
        process_overrides={**overrides, "wall_generator": "arachne", "elefant_foot_compensation": "0"},
        printer=pr,
    )
    plate = proj.plate("Cosmere tracker", prime_tower=LAYOUT[pr.tag]["tower"])
    part_name = lambda c: f"{'body' if c == body else 'inlay'} {c}"
    for name, part, x, y, turn in layout:
        plate.add(name, meshes[(part, turn)], x, y, part_name=part_name)
    proj.write(args.output or os.path.join(HERE, f"cosmere-tracker-{pr.tag}.3mf"))


if __name__ == "__main__":
    main()
