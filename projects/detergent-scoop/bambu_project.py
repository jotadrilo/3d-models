#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the detergent scoop.

One single-colour part on one plate, printed upside down (rim and handle on
the bed) so the cup needs no supports.

    python3 bambu_project.py [--printer p1s|x2d] [-o out.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PRINTERS, Filament, Project, load_scad  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--printer", choices=sorted(PRINTERS), default="p1s")
    ap.add_argument("-o", "--output")
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()
    pr = PRINTERS[args.printer]

    process, overrides = pr.process("0.20mm Standard")
    proj = Project(
        "Detergent scoop",
        process=process,
        filaments=[Filament(pr.preset("filament", "Bambu PLA Matte"), "#A3D8E1")],  # Ice Blue
        # The 2 mm walls are solid anyway; gyroid only fills the handle and the collar.
        process_overrides={**overrides, "sparse_infill_pattern": "gyroid"},
        printer=pr,
    )
    scoop = load_scad(os.path.join(HERE, "detergent-scoop.scad"), "scoop", args.defs, rotate=(180, 0, 0), colour=False)
    proj.plate("Detergent scoop").add("Detergent scoop", scoop)
    proj.write(args.output or os.path.join(HERE, f"detergent-scoop-{pr.tag}.3mf"))


if __name__ == "__main__":
    main()
