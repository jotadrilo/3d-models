#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the soap caddy.

Plate 1: the upper piece standing on its floor, the lower piece lying on its
back (the sloping tray, slats and side walls become upright walls, so nothing
needs support), the four buttons on their flanges and the two pegs on their collars. Black PETG Basic on
0.20mm Standard with gyroid infill, the seam at the back, a scarf seam and
precise walls: it hangs in plain sight.

Plate 2: a keyhole fit test, one pad and one button.

    python3 bambu_project.py [-o soap-caddy-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PETG_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "soap-caddy.scad")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "soap-caddy-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Soap caddy",
        process="0.20mm Standard @BBL X1C",
        filaments=[Filament(PETG_BASIC, "#000000")],
        process_overrides={
            "sparse_infill_pattern": "gyroid",
            "seam_position": "back",
            "precise_outer_wall": "1",
            "override_filament_scarf_seam_setting": "1",
            "seam_slope_type": "external",
            "seam_slope_conditional": "1",
        },
    )
    def part(name, **kw):
        return load_scad(SCAD, name, args.defs, colour=False, **kw)

    plate = proj.plate("Soap caddy")
    plate.add("Lower (sponge tray)", part("lower", rotate=(-90, 0, 0)), 72, 150)
    plate.add("Upper (bottle box)", part("upper"), 186, 150)
    button = part("button")
    for i, x in enumerate((78, 102, 126, 150)):
        plate.add(f"Button {i + 1}", button, x, 60)
    peg = part("peg")
    for i, x in enumerate((176, 196)):
        plate.add(f"Peg {i + 1}", peg, x, 60)

    test = proj.plate("Keyhole fit test")
    test.add("Keyhole pad", part("test_keyhole", rotate=(-90, 0, 0)), 115, 128)
    test.add("Test button", button, 148, 128)
    proj.write(args.output)


if __name__ == "__main__":
    main()
