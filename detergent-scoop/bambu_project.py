#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the detergent scoop.

One single-colour part on one plate, printed upside down (rim and handle on
the bed) so the cup needs no supports.

    python3 bambu_project.py [-o detergent-scoop-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "detergent-scoop-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Detergent scoop",
        process="0.20mm Standard @BBL X1C",
        filaments=[Filament(PLA_BASIC, "#F2F2F2")],
        # The 2 mm walls are solid anyway; gyroid only fills the handle and the collar.
        process_overrides={"sparse_infill_pattern": "gyroid"},
    )
    scoop = load_scad(os.path.join(HERE, "detergent-scoop.scad"), "scoop", args.defs, rotate=(180, 0, 0), colour=False)
    proj.plate("Detergent scoop").add("Detergent scoop", scoop)
    proj.write(args.output)


if __name__ == "__main__":
    main()
