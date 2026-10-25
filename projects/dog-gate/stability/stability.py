#!/usr/bin/env python3
"""How hard it is to tip the dog gate over, by rigid-body statics.

For each variant and direction, from its mass, centre of mass and the edge it
tips over (gate.py, from dog-gate.scad):

  force    the steady push that tips it, at the top edge and at mid-height:
           F = W · b / H (b: centre of mass to the tipping edge, horizontally)
  angle    how far it can be tilted before it falls on its own: atan(b / h)
  energy   what it takes to lift its centre of mass over the edge:
           E = W · (√(b² + h²) − h); a tap or a bump that gives it less, it
           rocks back
  impulse  the shortest tap at the top that tips it: J = √(2 · I · E) / H,
           I its moment of inertia about the edge (the edge does not slip)
  slides   the steady push that slides it instead, μ · W, for μ = 0.4 (bare
           ABS on stone or varnished wood) and 0.7 (rubber pads): whichever of
           tipping and sliding needs less force happens first

Backwards on the stair it leans onto the riser's top edge and, pushed
harder, levers over it and lies back on the steps above: the same figures
with that edge as the pivot. On a flat floor it tips over the shoe's back.

usage: python stability.py [-D name=value ...]   (OpenSCAD overrides)
"""
import argparse, json, math, os

import gate

HERE = os.path.dirname(os.path.abspath(__file__))
MU = (0.4, 0.7)


def metrics(g, edge_y, push_h, edge_z=0.0):
    cy, cz = g.com
    b = abs(cy - edge_y)
    hz = cz - edge_z
    w = g.mass * gate.G
    e = w * (math.hypot(b, hz) - hz)
    i = g.inertia_about(edge_y, edge_z)
    return dict(
        b_mm=b * 1000,
        f_top=w * b / (push_h - edge_z), f_mid=w * b / (push_h / 2 - edge_z),
        angle=math.degrees(math.atan2(b, hz)),
        energy=e,
        impulse=math.sqrt(2 * i * e) / (push_h - edge_z),
        slide=[mu * w for mu in MU],
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-D", dest="defs", action="append", default=[])
    args = ap.parse_args()
    d = args.defs
    p = gate.scad_params(d)
    top = (p["board_h"] + p["lip"]) / 1000
    board_kg = p["board_w"] * p["board_h"] * p["board_t"] * 1e-9 * p["board_density"]

    variants = [
        ("**Project: one side, lean 5°, shoe**", gate.one_sided(d)),
        ("lean 0°", gate.one_sided(d + ["lean=0"])),
        ("lean 3°", gate.one_sided(d + ["lean=3"])),
        ("lean 8°", gate.one_sided(d + ["lean=8"])),
        ("lean 12°", gate.one_sided(d + ["lean=12"])),
        ("board 30 % holes", gate.one_sided(d, perforated=0.3)),
        ("birch board (680 kg/m³)", gate.one_sided(d + ["board_density=680"])),
        ("+ 5 kg ballast on the feet", gate.one_sided(d, ballast_kg=5.0)),
        ("brackets both faces, middle of the tread (140 mm)", gate.symmetric_base(0.140, 0.34, board_kg)),
        ("discs Ø230 with a U", gate.symmetric_base(0.115, 0.50, board_kg)),
    ]
    rows, out = [], {}
    for name, g in variants:
        fwd = metrics(g, g.toe_y, top)
        back = metrics(g, g.back_y, top)
        stair_back = metrics(g, g.riser_y, top, g.riser_z) if g.riser_y is not None else None
        out[name] = dict(mass=g.mass, com=g.com, forward=fwd, backward=back, stair_backward=stair_back, note=g.note)
        rows.append((name, g, fwd, back, stair_back))

    print(f"Push heights: top {top * 1000:.0f} mm, mid {top * 500:.0f} mm. μ = {MU}.\n")
    print("| Variant | Mass | Forwards (downhill): top / mid | angle | energy | tap at top | Backwards, flat floor: top | angle | energy | Backwards on the stair, over the riser: top | energy |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for name, g, f, b, sb in rows:
        sbt = f"{sb['f_top']:.1f} N | {sb['energy']:.3f} J" if sb else "as on a flat floor | "
        print(f"| {name} | {g.mass:.2f} kg | {f['f_top']:.1f} / {f['f_mid']:.1f} N | {f['angle']:.0f}° | {f['energy']:.2f} J | {f['impulse']:.2f} N·s "
              f"| {b['f_top']:.1f} N | {b['angle']:.0f}° | {b['energy']:.3f} J | {sbt} |")
    g = rows[0][1]
    print(f"\nSliding (project): {MU[0]} → {rows[0][2]['slide'][0]:.0f} N, {MU[1]} → {rows[0][2]['slide'][1]:.0f} N. "
          f"A steady push slides it rather than tips it when pushed below "
          f"{rows[0][2]['b_mm'] / MU[0]:.0f} mm (μ {MU[0]}) / {rows[0][2]['b_mm'] / MU[1]:.0f} mm (μ {MU[1]}).")
    print(f"Project: {g.note}; total {g.mass:.2f} kg, centre of mass y {g.com[0] * 1000:.0f} mm, z {g.com[1] * 1000:.0f} mm.")
    json.dump(out, open(os.path.join(HERE, "stability.json"), "w"), indent=1, default=float)


if __name__ == "__main__":
    main()
