#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the sink organizers.

Plate 1: the soap caddy's body standing on its floor (its dovetail tails
along Z), turned a quarter so its printing fins fit beside the wall plate,
and its wall plate flat on its back (the keyholes' slots and the housings'
flanks in XY). Above SLOW_Z the body's walls print slower: its thin walls
sway under the nozzle up there (fea/README.md, "Print stiffness").
Plate 2: the soap caddy's tray on its back, the box on its floor and the four
buttons on their flanges.
Plate 3: the cutlery drainer's body standing and its wall plate flat.
Plate 4: the cutlery drainer's tray on its back, alone: it stands 103 mm
and the rest of its old plate 17, so the nozzle crossed the bed between
seven parts for 87 layers and the PETG strung across it.
Plate 5: the cutlery drainer's rack on its floor, the towel handle flat (the
towel's weight bends it along XY) and the four buttons, close together.
Plate 6: the cutlery drainer's three 200 mm bins on their floors, a few mm
apart.
Plate 7: the risers (false bottoms) on their floors.
Plate 8: the bins' fit test: the bin's foot at three bin_fit values.
Plate 9: fit tests, minutes and a few grams before the big plates: a keyhole
pad with a button (screw it onto a cup first), a strip of plate with a
dovetail housing and a strip of wall with its tail, a slice of the soap
caddy's body with the bottom of its box, and the handle's pins in a block.
Plate 10: the sway test, two strips of the soap caddy's side wall as flexible
as its body where it printed rough, one bare and one held by stabilizer fins.

Black PETG (Basic, HF with --hf or Matte with --matte) on 0.20mm Standard with gyroid infill, the seam at the back,
a scarf seam and precise walls: they hang in plain sight.

    python3 bambu_project.py [-o sink-organizers-p1s.3mf] [--hf | --matte] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PETG_BASIC, PETG_HF, PETG_MATTE, Filament, Project, load_scad  # noqa: E402

SOAP = os.path.join(HERE, "soap-caddy.scad")
DRAINER = os.path.join(HERE, "cutlery-drainer.scad")
FLAT = (-90, 0, 0)   # the plates and trays on their backs
SLOW_Z = 100         # the soap caddy body's walls print slower above this
SLOW = {"outer_wall_speed": "60", "inner_wall_speed": "80"}
# The stabilizer fins' tabs are one line wide: Classic walls drop them (no room
# for a loop in and out), Arachne prints them as a single bead
FINS = {"wall_generator": "arachne"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "sink-organizers-p1s.3mf"))
    kind = ap.add_mutually_exclusive_group()
    kind.add_argument("--hf", action="store_true", help="PETG HF instead of PETG Basic")
    kind.add_argument("--matte", action="store_true", help="PETG Matte instead of PETG Basic")
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    title, petg = ("Sink organizers (PETG HF)", PETG_HF) if args.hf else \
        ("Sink organizers (PETG Matte)", PETG_MATTE) if args.matte else ("Sink organizers", PETG_BASIC)
    proj = Project(
        title,
        process="0.20mm Standard @BBL X1C",
        filaments=[Filament(petg, "#000000")],
        process_overrides={
            "sparse_infill_pattern": "gyroid",
            "seam_position": "back",
            "precise_outer_wall": "1",
            "override_filament_scarf_seam_setting": "1",
            "seam_slope_type": "external",
            "seam_slope_conditional": "1",
            "reduce_crossing_wall": "1",     # no travel across the slotted walls: PETG strings there
        },
    )

    def soap(name, **kw):
        return load_scad(SOAP, name, args.defs, colour=False, **kw)

    def drainer(name, extra=(), **kw):
        return load_scad(DRAINER, name, args.defs + list(extra), colour=False, **kw)

    p = proj.plate("Soap caddy - body and wall plate")
    p.add("Soap caddy body", soap("body", rotate=(0, 0, 90)), 75, 128, settings=FINS, ranges=[(SLOW_Z, 250, SLOW)])
    p.add("Soap caddy wall plate", soap("plate", rotate=FLAT), 192, 128)

    p = proj.plate("Soap caddy - tray, box and buttons")
    p.add("Soap caddy tray", soap("tray", rotate=FLAT), 128, 95)
    p.add("Soap caddy box", soap("box"), 128, 175)
    button = soap("button")
    for i, x in enumerate((92, 116, 140, 164)):
        p.add(f"Soap caddy button {i + 1}", button, x, 40)

    p = proj.plate("Cutlery drainer - body and wall plate")
    p.add("Cutlery drainer body", drainer("body"), 128, 74)
    p.add("Cutlery drainer wall plate", drainer("plate", rotate=FLAT), 128, 190)

    p = proj.plate("Cutlery drainer - tray")
    p.add("Cutlery drainer tray", drainer("tray", rotate=FLAT), 128, 128)

    p = proj.plate("Cutlery drainer - rack, handle and buttons")
    p.add("Cutlery drainer rack", drainer("rack"), 128, 160)
    p.add("Towel handle", drainer("handle"), 128, 80)
    for i, x in enumerate((92, 116, 140, 164)):
        p.add(f"Cutlery drainer button {i + 1}", button, x, 40)

    p = proj.plate("Cutlery drainer - bins")
    bin_ = drainer("bin")
    for i, x in enumerate((52, 128, 204)):
        p.add(f"Cutlery drainer bin {i + 1}", bin_, x, 128)

    p = proj.plate("Cutlery drainer - risers")
    for i, (x, name) in enumerate(((90, "teaspoons"), (166, "table cutlery"))):
        p.add(f"Cutlery drainer riser {i + 1} ({name})", drainer("riser", extra=[f"riser_n={i}"]), x, 128)

    p = proj.plate("Cutlery drainer - bin fit test")
    for x, fit in ((52, "0.05"), (128, "0.1"), (204, "0.15")):
        p.add(f"Bin fit {fit}", drainer("test_bin", extra=[f"bin_fit={fit}"]), x, 128)

    p = proj.plate("Fit tests")
    p.add("Keyhole pad", soap("test_keyhole", rotate=FLAT), 45, 60)
    p.add("Test buttons", soap("test_buttons", rotate=(0, 0, 90)), 225, 160)
    p.add("Dovetail housing", soap("test_dovetail_housing"), 110, 60)
    p.add("Dovetail tail", soap("test_dovetail_tail"), 140, 60)
    p.add("Handle pin test", drainer("test_pin"), 200, 60)
    p.add("Soap caddy width test", soap("test_width"), 108, 178, settings=FINS)

    p = proj.plate("Sway test")
    p.add("Sway test", soap("test_sway"), 128, 128, settings=FINS)

    p = proj.plate("Soap caddy - installation jig")
    p.add("Soap caddy jig", soap("jig", rotate=FLAT), 128, 136)

    p = proj.plate("Cutlery drainer - installation jig")
    p.add("Cutlery drainer jig", drainer("jig", rotate=FLAT), 128, 128)
    proj.write(args.output)


if __name__ == "__main__":
    main()
