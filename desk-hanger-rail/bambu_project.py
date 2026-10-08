#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the desk hanger rail.

Plate 1: the two brackets lying on their outer face (socket up) and the bar
lying on its keel. PETG Basic on 0.20mm Strength, printed solid: the brackets
work in bending at the lip and around the socket, where sparse infill would be
the weak spot.

Plate 2: a quick fit test of the bar in its socket, with the same settings: a
ring with the socket profile at bar_play and a short bar for it.

Plate 3: a thin slice of the C, to try the grip on the desk.

    python3 bambu_project.py [-o desk-hanger-rail-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
from bambu3mf import PETG_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "desk-hanger-rail.scad")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "desk-hanger-rail-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Desk hanger rail",
        process="0.20mm Strength @BBL X1C",
        filaments=[Filament(PETG_BASIC, "#000000")],
        process_overrides={
            "sparse_infill_density": "100%",
            "sparse_infill_pattern": "zig-zag",
            "seam_position": "back",
        },
    )
    plate = proj.plate("Desk hanger rail")
    plate.add("Left bracket", load_scad(SCAD, "bracket_left", args.defs, colour=False), 80, 100)
    plate.add("Right bracket", load_scad(SCAD, "bracket_right", args.defs, colour=False), 176, 100)
    plate.add("Bar", load_scad(SCAD, "bar", args.defs, colour=False), 128, 215)

    test = proj.plate("Socket fit test")
    test.add("Socket test", load_scad(SCAD, "test_socket", args.defs, colour=False), 113, 128)
    test.add("Test bar", load_scad(SCAD, "test_bar", args.defs, colour=False), 143, 128)

    proj.plate("Clip fit test").add("Clip test", load_scad(SCAD, "test_clip", args.defs, colour=False))
    proj.write(args.output)


if __name__ == "__main__":
    main()
