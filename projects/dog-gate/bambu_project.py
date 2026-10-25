#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the dog gate's brackets.

Two brackets, one per plate: each is 280 mm long, so it lies on its side
turned 54° to fit the bed, and the leg, the foot and the brace bend within
the layers. ABS: it takes the summer heat on the stair without softening.

    python3 bambu_project.py [-o dog-gate-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "dog-gate.scad")
ABS = "Bambu ABS @BBL P1S 0.4 nozzle"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "dog-gate-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Dog gate brackets",
        process="0.20mm Strength @BBL X1C",   # 6 walls: the brace and the leg are walls, not infill
        filaments=[Filament(ABS, "#8A8D8F")],
        process_overrides={"sparse_infill_pattern": "gyroid"},
    )
    bracket = load_scad(SCAD, "bracket", args.defs, rotate=(0, 0, 54), colour=False)
    for name in ["Bracket 1", "Bracket 2"]:
        proj.plate(name).add(name, bracket, 136, 133)
    proj.write(args.output)


if __name__ == "__main__":
    main()
