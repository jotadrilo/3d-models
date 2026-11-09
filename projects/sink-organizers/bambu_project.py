#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the sink organizers.

Plate 1: the lower part of the soap caddy's body standing on its floor (its
dovetail tails along Z), turned a quarter beside the wall plate, and its wall
plate flat on its back (the keyholes' slots and the housings' flanks in XY).
Above SLOW_Z its walls print slower. The body is in two parts: printed
whole, 209 mm standing, its walls swayed under the nozzle at the top.
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
Plates 11 and 12: the installation jigs, for the suction cups.
Plate 13: the adhesive mount (mount="tape", for walls where suction cups let
go): an adapter per keyhole, a button head on a piece of foam tape, three
with a square and five with a round, for both pieces.
Plate 14: the upper part of the soap caddy's body, standing on its cut, a
closed tube with the thumb window in its front.
Plate 15: the fit test for the cut: the upper part's foot and the lower
part's top with its collar at three plays; and three tail strips with
dt_tail_play 0.025, 0.05 and 0.075, to slide into a wall plate already printed.

Black PETG (Basic, HF with --hf or Matte with --matte) on 0.20mm Standard with gyroid infill, the seam at the back,
a scarf seam and precise walls: they hang in plain sight.

    python3 bambu_project.py [--printer p1s|x2d] [-o out.3mf] [--hf | --matte] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PRINTERS, Filament, Project, load_scad  # noqa: E402

SOAP = os.path.join(HERE, "soap-caddy.scad")
DRAINER = os.path.join(HERE, "cutlery-drainer.scad")
FLAT = (-90, 0, 0)   # the plates and trays on their backs
SLOW_Z = 100         # the soap caddy body's walls print slower above this
SLOW = {"outer_wall_speed": "60", "inner_wall_speed": "80"}
# The sway test's stabilizer fins: their tabs are one line wide: Classic walls drop them (no room
# for a loop in and out), Arachne prints them as a single bead
FINS = {"wall_generator": "arachne"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--printer", choices=sorted(PRINTERS), default="p1s")
    ap.add_argument("-o", "--output")
    kind = ap.add_mutually_exclusive_group()
    kind.add_argument("--hf", action="store_true", help="PETG HF instead of PETG Basic")
    kind.add_argument("--matte", action="store_true", help="PETG Matte instead of PETG Basic")
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()
    pr = PRINTERS[args.printer]

    title, petg, suffix = ("Sink organizers (PETG HF)", "Bambu PETG HF", "-hf") if args.hf else \
        ("Sink organizers (PETG Matte)", "Bambu PETG Matte", "-matte") if args.matte else \
        ("Sink organizers", "Bambu PETG Basic", "")
    process, overrides = pr.process("0.20mm Standard")
    proj = Project(
        title,
        process=process,
        filaments=[Filament(pr.preset("filament", petg), "#000000")],
        printer=pr,
        process_overrides={
            **overrides,
            "sparse_infill_pattern": "gyroid",
            "seam_position": "back",
            "precise_outer_wall": "1",
            "override_filament_scarf_seam_setting": "1",
            "seam_slope_type": "external",
            "seam_slope_conditional": "1",
            "reduce_crossing_wall": "1",     # no travel across the slotted walls: PETG strings there
        },
    )

    # The X2D cannot use the left 20.5 mm: the widest plates move right, and the towel handle,
    # the rack and the drainer's jig (up to 239 mm wide) turn a quarter (still flat, the same
    # loads in XY)
    x2d = pr.tag == "x2d"
    turn = (0, 0, 90) if x2d else (0, 0, 0)

    def soap(name, extra=(), **kw):
        return load_scad(SOAP, name, args.defs + list(extra), colour=False, **kw)

    def drainer(name, extra=(), **kw):
        return load_scad(DRAINER, name, args.defs + list(extra), colour=False, **kw)

    p = proj.plate("Soap caddy - lower body and wall plate")
    p.add("Soap caddy body, lower part", soap("body_lower", rotate=(0, 0, 90)), 81 if x2d else 75, 128,
          ranges=[(SLOW_Z, 250, SLOW)])
    p.add("Soap caddy wall plate", soap("plate", rotate=FLAT), 198 if x2d else 192, 128)

    p = proj.plate("Soap caddy - tray, box and buttons")
    p.add("Soap caddy tray", soap("tray", rotate=FLAT), 128, 95)
    p.add("Soap caddy box", soap("box"), 128, 175)
    button = soap("button")
    for i, x in enumerate((92, 116, 140, 164)):
        p.add(f"Soap caddy button {i + 1}", button, x, 40)

    p = proj.plate("Cutlery drainer - body and wall plate")
    x = 137 if x2d else 128
    p.add("Cutlery drainer body", drainer("body"), x, 74)
    p.add("Cutlery drainer wall plate", drainer("plate", rotate=FLAT), x, 190)

    p = proj.plate("Cutlery drainer - tray")
    p.add("Cutlery drainer tray", drainer("tray", rotate=FLAT), 128, 128)

    p = proj.plate("Cutlery drainer - rack, handle and buttons")
    if x2d:
        p.add("Cutlery drainer rack", drainer("rack", rotate=turn), 125, 128)
        p.add("Towel handle", drainer("handle", rotate=turn), 50, 128)
        for i, y in enumerate((80, 104, 128, 152)):
            p.add(f"Cutlery drainer button {i + 1}", button, 195, y)
    else:
        p.add("Cutlery drainer rack", drainer("rack"), 128, 160)
        p.add("Towel handle", drainer("handle"), 128, 80)
        for i, x in enumerate((92, 116, 140, 164)):
            p.add(f"Cutlery drainer button {i + 1}", button, x, 40)

    p = proj.plate("Cutlery drainer - bins")
    bin_ = drainer("bin")
    columns = (60, 135, 210) if x2d else (52, 128, 204)
    for i, x in enumerate(columns):
        p.add(f"Cutlery drainer bin {i + 1}", bin_, x, 128)

    p = proj.plate("Cutlery drainer - risers")
    for i, (x, name) in enumerate(((90, "teaspoons"), (166, "table cutlery"))):
        p.add(f"Cutlery drainer riser {i + 1} ({name})", drainer("riser", extra=[f"riser_n={i}"]), x, 128)

    p = proj.plate("Cutlery drainer - bin fit test")
    for x, fit in zip(columns, ("0.05", "0.1", "0.15")):
        p.add(f"Bin fit {fit}", drainer("test_bin", extra=[f"bin_fit={fit}"]), x, 128)

    p = proj.plate("Fit tests")
    p.add("Keyhole pad", soap("test_keyhole", rotate=FLAT), 45, 60)
    p.add("Test buttons", soap("test_buttons", rotate=(0, 0, 90)), 225, 160)
    p.add("Dovetail housing", soap("test_dovetail_housing"), 110, 60)
    p.add("Dovetail tail", soap("test_dovetail_tail"), 140, 60)
    p.add("Handle pin test", drainer("test_pin"), 200, 60)
    p.add("Soap caddy width test", soap("test_width"), 108, 170)

    p = proj.plate("Sway test")
    p.add("Sway test", soap("test_sway"), 128, 128, settings=FINS)

    p = proj.plate("Soap caddy - installation jig")
    p.add("Soap caddy jig", soap("jig", rotate=FLAT), 128, 136)

    p = proj.plate("Cutlery drainer - installation jig")
    jig = drainer("jig", rotate=(FLAT[0], 0, turn[2]))   # on its back, then the quarter turn
    p.add("Cutlery drainer jig", jig, 128, 128)

    # The adhesive mount (mount="tape"): an adapter per keyhole, stuck to the
    # wall with foam tape, a square at the keyholes the pieces pull (1 on the
    # soap caddy, 2 on the drainer) and a round at the others. They are the
    # same for both pieces.
    p = proj.plate("Adhesive adapters")
    for i, x in enumerate((60, 110, 160)):
        p.add(f"Adapter, square {i + 1}", soap("adapter", extra=['tape="square"']), x, 160)
    for i, x in enumerate((50, 90, 130, 170, 210)):
        p.add(f"Adapter, round {i + 1}", soap("adapter", extra=['tape="round"']), x, 95)
    # The soap caddy body's upper part, a closed tube standing on its cut (appended, so the
    # plates above keep their numbers), and the fit test for the cut between the two parts
    p = proj.plate("Soap caddy - upper body")
    p.add("Soap caddy body, upper part", soap("body_upper", rotate=(0, 0, 90)), 128, 128)

    p = proj.plate("Soap caddy - split fit test")
    p.add("Split upper ring", soap("test_split_upper"), 74, 70)
    for (x, y), k in zip(((186, 70), (74, 175), (186, 175)), range(3)):
        p.add(f"Split lower ring, play {('0.05', '0.1', '0.15')[k]}", soap("test_split_lower", extra=[f"test_split_k={k}"]), x, y)
    # the tails' extra play: three tail strips to slide into the wall plate already printed
    for k, x in enumerate((100, 128, 156)):
        p.add(f"Tail, extra play {('0.025', '0.05', '0.075')[k]}", soap("test_dovetail_tail_play", extra=[f"test_tail_k={k}"],
              rotate=(0, 0, 90)), x, 122)
    proj.write(args.output or os.path.join(HERE, f"sink-organizers-{pr.tag}{suffix}.3mf"))


if __name__ == "__main__":
    main()
