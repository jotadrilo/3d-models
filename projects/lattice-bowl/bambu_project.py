#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the lattice bowl.

One single-colour part on one plate, standing on its flat base. It uses
0.16 mm layers: the flared wall and the diamond edges are shallow slopes, where
thinner layers show less stepping and hold the overhangs better.

    python3 bambu_project.py [-o lattice-bowl-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "lattice-bowl-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Lattice bowl",
        process="0.16mm Optimal @BBL X1C",
        filaments=[Filament(PLA_BASIC, "#1B1B1B")],
        process_overrides={"precise_outer_wall": "1"},
    )
    bowl = load_scad(os.path.join(HERE, "lattice_bowl.scad"), defs=args.defs, colour=False)
    proj.plate("Lattice bowl").add("Lattice bowl", bowl)
    proj.write(args.output)


if __name__ == "__main__":
    main()
