#!/usr/bin/env python3
"""Build the ready-to-print Bambu Studio projects for the dog gate, both versions, for the P1S or
the X2D (`--printer`).

A bracket only fits a bed by itself, lying on its side and turned to fit (the leg, the foot and
the brace bend within the layers), so each version has one plate, printed twice (the two brackets
are the same part):
  Simple bracket (print 2)       dog-gate.scad: the one-sided bracket that stands the board on the tread
  Reinforced bracket (print 2)   dog-gate-hook.scad: the bracket hooked under the tray tread's back flange
  Hook tests                     slices of the reinforced bracket's hook, one per flange depth (30 to
                                 70 mm): print them first, keep the one that slides on and sits flat (edge_h)
ABS: it takes the summer heat on the stair.

    python3 bambu_project.py [--printer p1s|x2d] [-o out.3mf] [-D var=val ...]
"""
import argparse, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
from bambu3mf import PRINTERS, Filament, Project, load_scad  # noqa: E402

SIMPLE = os.path.join(HERE, "dog-gate.scad")
HOOKED = os.path.join(HERE, "dog-gate-hook.scad")
EDGES = [30, 40, 50, 60, 70]
# per printer: (turn, bed centre) for each bracket, worked out against the bed's keep-clear areas,
# and the hook tests' positions
LAYOUT = {
    "p1s": dict(simple=(54, (136, 133)), hooked=(34, (128, 140.5)),
                tests=[(50, 205), (115, 205), (180, 205), (82, 100), (147, 100)]),
    "x2d": dict(simple=(140, (136.75, 128)), hooked=(126, (136.75, 128)),
                tests=[(60, 205), (125, 205), (190, 205), (92, 100), (157, 100)]),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--printer", choices=sorted(PRINTERS), default="p1s")
    ap.add_argument("-o", "--output")
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()
    pr = PRINTERS[args.printer]
    lay = LAYOUT[args.printer]
    out = args.output or os.path.join(HERE, f"dog-gate-{pr.tag}.3mf")

    # 0.20mm Strength (6 walls, 25 %): the members are walls, not infill. The X2D has no Strength
    # preset: its Standard with the same walls and infill
    strength = {"sparse_infill_pattern": "gyroid"}
    try:
        process = pr.preset("process", "0.20mm Strength")
    except SystemExit:
        process = pr.preset("process", "0.20mm Standard")
        strength.update({"wall_loops": "6", "sparse_infill_density": "25%"})
    proj = Project(
        "Dog gate brackets",
        process=process,
        filaments=[Filament(pr.preset("filament", "Bambu ABS"), "#8A8D8F")],
        process_overrides=strength,
        printer=pr,
    )
    turn, (x, y) = lay["simple"]
    simple = load_scad(SIMPLE, "bracket", args.defs, rotate=(0, 0, turn), colour=False)
    proj.plate("Simple bracket (print 2)").add("Simple bracket", simple, x, y)
    turn, (x, y) = lay["hooked"]
    hooked = load_scad(HOOKED, "bracket", args.defs, rotate=(0, 0, turn), colour=False)
    proj.plate("Reinforced bracket (print 2)").add("Reinforced bracket", hooked, x, y)
    plate = proj.plate("Hook tests")
    for e, (x, y) in zip(EDGES, lay["tests"]):
        plate.add(f"Hook test, flange {e} mm", load_scad(HOOKED, "hook_test", args.defs + [f"edge_h={e}"], colour=False), x, y)
    proj.write(out)


if __name__ == "__main__":
    main()
