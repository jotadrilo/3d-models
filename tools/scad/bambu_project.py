#!/usr/bin/env python3
"""Build a Bambu Studio project with one sample of every library piece.

One plate, every sample and its mate in print orientation, grey PLA Basic
on 0.20mm Standard: print it to check the library's fits on your printer.

    python3 bambu_project.py [-o catalog-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from bambu3mf import PLA_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "catalog.scad")
# sample -> (object name, x, y). Pairs sit side by side.
SAMPLES = {
    "house_box": ("House box", 50, 205),
    "holes": ("Holes", 125, 215),
    "screw_plate": ("Screw plate", 190, 210),
    "peg_block": ("Peg block", 232, 215),
    "tongue_female": ("Tongue female", 45, 160),
    "tongue_male": ("Tongue male", 95, 160),
    "diamond_female": ("Diamond female", 140, 160),
    "diamond_male": ("Diamond male", 190, 160),
    "lead_in_female": ("Lead-in female", 45, 110),
    "lead_in_male": ("Lead-in male", 75, 110),
    "keyhole_pad": ("Keyhole pad", 110, 110),
    "keyhole_button": ("Keyhole button", 140, 110),
    "standoff_peg": ("Standoff peg", 165, 110),
    "handle_block": ("Handle block", 200, 110),
    "handle": ("Handle", 200, 65),
    "dovetail_housing": ("Dovetail housing", 60, 60),
    "dovetail_tail": ("Dovetail tail", 100, 60),
}

BOARD_SAMPLES = {
    "board_bracket": ("Board bracket", 90, 128),
    "board_bracket_hook": ("Board bracket with hook", 180, 128),
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
    # Board holders: bigger samples, on their own plate
    plate = proj.plate("Board holders")
    for part, (name, x, y) in BOARD_SAMPLES.items():
        plate.add(name, load_scad(SCAD, part, args.defs, colour=False), x, y)
    proj.write(args.output)


if __name__ == "__main__":
    main()
