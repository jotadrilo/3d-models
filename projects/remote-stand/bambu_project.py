#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the remote stands.

v1 (ribbed) and v2 (channelled) are alternatives, so each gets its own plate:
print whichever one you want. Both stand upright on their base, with the seam
at the back.

    python3 bambu_project.py [-o remote-stand-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "remote-stand-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Remote stand",
        process="0.20mm Standard @BBL X1C",
        filaments=[Filament(PLA_BASIC, "#1B1B1B")],
        process_overrides={"seam_position": "back"},
    )
    for name, scad in [("Remote stand v1 (ribbed)", "remote-stand.scad"),
                       ("Remote stand v2 (channelled)", "remote-stand-v2.scad")]:
        proj.plate(name).add(name, load_scad(os.path.join(HERE, scad), defs=args.defs, colour=False))
    proj.write(args.output)


if __name__ == "__main__":
    main()
