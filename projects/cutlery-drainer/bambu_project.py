#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the cutlery drainer.

Plate 1: the frame, lying on its back (the side walls, the ledges and the
handle's bosses become upright walls, so nothing needs support).
Plate 2: the tray on its back, the three bins on their floors, the towel
handle flat (the towel's weight bends it along XY) and the four buttons on
their flanges.
Plate 3: a fit test for the handle's pins in their sockets.
Black PETG Basic on 0.20mm Standard with gyroid infill, the seam at the
back, a scarf seam and precise walls: it hangs in plain sight.

    python3 bambu_project.py [-o cutlery-drainer-p1s.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PETG_BASIC, Filament, Project, load_scad  # noqa: E402

SCAD = os.path.join(HERE, "cutlery-drainer.scad")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "cutlery-drainer-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    proj = Project(
        "Cutlery drainer",
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

    proj.plate("Frame").add("Frame", part("frame", rotate=(-90, 0, 0)), 128, 140)

    plate = proj.plate("Tray, bins and handle")
    plate.add("Tray", part("tray", rotate=(-90, 0, 0)), 128, 215)
    bin_ = part("bin")
    for i, x in enumerate((55, 128, 201)):
        plate.add(f"Bin {i + 1}", bin_, x, 125)
    plate.add("Towel handle", part("handle"), 128, 50)
    button = part("button")
    for i, x in enumerate((30, 48, 208, 226)):
        plate.add(f"Button {i + 1}", button, x, 22 if i in (0, 3) else 22)

    proj.plate("Handle fit test").add("Block and handle", part("test_pin"), 128, 128)
    proj.write(args.output)


if __name__ == "__main__":
    main()
