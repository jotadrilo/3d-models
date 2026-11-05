#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the lattice bowl.

One single-colour part on one plate, standing on its flat base. It uses
0.16 mm layers: the flared wall and the diamond edges are shallow slopes, where
thinner layers show less stepping and hold the overhangs better.

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

    process, overrides = pr.process("0.16mm Optimal")
    proj = Project(
        "Lattice bowl",
        process=process,
        filaments=[Filament(pr.preset("filament", "Bambu PLA Basic"), "#1B1B1B")],
        process_overrides={**overrides, "precise_outer_wall": "1"},
        printer=pr,
    )
    bowl = load_scad(os.path.join(HERE, "lattice_bowl.scad"), defs=args.defs, colour=False)
    proj.plate("Lattice bowl").add("Lattice bowl", bowl)
    proj.write(args.output or os.path.join(HERE, f"lattice-bowl-{pr.tag}.3mf"))


if __name__ == "__main__":
    main()
