#!/usr/bin/env python3
"""Build a Bambu Studio project with one sample of every library piece.

One plate, every sample in print orientation, grey PLA Basic on 0.20mm
Standard: print it to check the library's fits on your printer.

    python3 bambu_project.py [-o catalog-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "catalog.scad")
# sample -> (object name, x, y)
SAMPLES = {
    "house_box": ("House box", 70, 180),
    "holes": ("Holes", 170, 190),
    "sockets": ("Sockets", 170, 150),
    "keys": ("Keys", 170, 115),
    "keyhole_pad": ("Keyhole pad", 50, 110),
    "keyhole_button": ("Keyhole button", 90, 110),
    "standoff_peg": ("Standoff peg", 115, 110),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "catalog-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Library catalog",
        process="0.20mm Standard @BBL X1C",
        filaments=[Filament(PLA_BASIC, "#8E9089")],
        process_overrides={"sparse_infill_pattern": "gyroid"},
    )
    plate = proj.plate("Library samples")
    for part, (name, x, y) in SAMPLES.items():
        plate.add(name, load_scad(SCAD, part, args.defs, colour=False), x, y)
    proj.write(args.output)


if __name__ == "__main__":
    main()
