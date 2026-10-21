#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the soap caddy.

Plate 1: the frame, lying on its back (side walls and ledges become upright
walls, so nothing needs support).
Plate 2: the tray lying on its back, the box standing on its floor and the
four buttons on their flanges.
Plate 3: fit tests, minutes and a few grams before the big plates: a keyhole
pad with a button (screw it onto a cup first), and a strip of the frame with
a bar as wide as the tray and the box.

Black PETG Basic on 0.20mm Standard with gyroid infill, the seam at the back,
a scarf seam and precise walls: it hangs in plain sight.

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

    frame = proj.plate("Frame")
    frame.add("Frame", part("frame", rotate=(-90, 0, 0)), 128, 140)

    parts = proj.plate("Tray, box and buttons")
    parts.add("Tray", part("tray", rotate=(-90, 0, 0)), 128, 95)
    parts.add("Bottle box", part("box"), 128, 175)
    button = part("button")
    for i, x in enumerate((92, 116, 140, 164)):
        parts.add(f"Button {i + 1}", button, x, 40)

    test = proj.plate("Fit tests")
    test.add("Width test", part("test_width"), 128, 150)
    test.add("Keyhole pad", part("test_keyhole", rotate=(-90, 0, 0)), 112, 95)
    test.add("Test button", button, 146, 95)
    proj.write(args.output)


if __name__ == "__main__":
    main()
