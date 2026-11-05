#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the remote stands.

v1 (ribbed) and v2 (channelled) are alternatives, so each gets its own plate:
print whichever one you want. Both stand upright on their base, with the seam
at the back.

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
        "Remote stand",
        process=process,
        filaments=[Filament(pr.preset("filament", "Bambu PLA Basic"), "#1B1B1B")],
        process_overrides={**overrides, "seam_position": "back"},
        printer=pr,
    )
    for name, scad in [("Remote stand v1 (ribbed)", "remote-stand.scad"),
                       ("Remote stand v2 (channelled)", "remote-stand-v2.scad")]:
        proj.plate(name).add(name, load_scad(os.path.join(HERE, scad), defs=args.defs, colour=False))
    proj.write(args.output or os.path.join(HERE, f"remote-stand-{pr.tag}.3mf"))


if __name__ == "__main__":
    main()
