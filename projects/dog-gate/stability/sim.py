#!/usr/bin/env python3
"""Rigid-body simulation of the dog gate (MuJoCo): pushes and taps that tip it.

The gate is one free rigid body (the board and its two brackets, built from
gate.py's geometry) standing on the stair (a tread, the riser behind it, the
tread below) or on a flat floor, with Coulomb friction. Two experiments, each
forwards (downhill, over the toes) and backwards (uphill on the stair, where
the riser stops it):

  ramp   a horizontal force at the middle of the top edge, growing 2 N/s:
         the force at which it lifts off its edge (tips) or slides, to check
         stability.py's static figures and see which happens first
  tap    a 50 ms half-sine push at the same point: the smallest one that
         makes it fall (it rocks back from anything less), as force peak and
         impulse, to check the energy figures

It also compares the project with a symmetric base (brackets on both faces in
the middle of the tread, or discs), modelled as boxes of the same span.

usage: python sim.py [--mu 0.4] [--video out_dir]
Needs mujoco (micromamba env `physics`, see README).
"""
import argparse, json, math, os

import mujoco
import numpy as np

import gate

HERE = os.path.dirname(os.path.abspath(__file__))
DT = 0.0005


def stair_xml(flat, tread=0.300, rise=0.175):
    if flat:
        return '<geom name="floor" type="plane" size="2 2 0.1" rgba=".8 .8 .8 1"/>'
    # the tread as a plane (as the flat floor, so the two differ only by the steps above), and
    # three steps above it: falling back, the gate lies on them
    w = 0.6
    steps = "".join(f'<geom name="step_up{i}" type="box" pos="0.39 {tread * (i + 1)} {rise * (i + 1) / 2}" '
                    f'size="{w} {tread / 2} {rise * (i + 1) / 2}" rgba=".75 .73 .7 1"/>' for i in range(3))
    return f'<geom name="tread" type="plane" size="2 2 0.1" rgba=".8 .8 .8 1"/>' + steps


def box(name, a, b, half_t, rgba, mass):
    """A box from point a to b in the y-z plane (its length), half_t thick in that plane, across the x span given by a[0]."""
    x, (y0, z0), (y1, z1) = a[0], a[1:3], b[1:3]
    L = math.hypot(y1 - y0, z1 - z0)
    ang = math.atan2(z1 - z0, y1 - y0)
    return (f'<geom name="{name}" type="box" pos="{x} {(y0 + y1) / 2} {(z0 + z1) / 2}" '
            f'size="{a[3]} {L / 2} {half_t}" euler="{math.degrees(ang)} 0 0" rgba="{rgba}" mass="{mass}"/>')


def project_gate_xml(defs=(), perforated=0.0, ballast=0.0):
    """The project's gate as geoms, in metres, from gate.py's numbers."""
    p = gate.scad_params(defs)
    geom, _ = gate.scad_values(defs)
    g = gate.one_sided(defs, perforated=perforated, ballast_kg=ballast)
    mb = next(b.mass for b in g.bodies if b.name == "bracket") / 2
    lean = math.radians(p["lean"])
    W, H, T = p["board_w"] / 1000, p["board_h"] / 1000, p["board_t"] / 1000
    leg_y, toe_y, lip_y = geom["leg_y"] / 1000, geom["toe_y"] / 1000, geom["lip_y"] / 1000
    m, lip, bh = p["member"] / 1000, p["lip"] / 1000, p["bracket_h"] / 1000
    kb = (1 - perforated) * W * H * T * p["board_density"]
    s, c = math.sin(lean), math.cos(lean)
    # the board, leaning over the feet about its foot (its downhill face at leg_y, on the shoe's floor)
    by, bz = geom["board_y"] / 1000, lip
    xml = [f'<geom name="board" type="box" pos="{W / 2} {by - H / 2 * s} {bz + H / 2 * c}" size="{W / 2} {T / 2} {H / 2}" '
           f'euler="{p["lean"]} 0 0" rgba=".85 .72 .54 1" mass="{kb}"/>']
    hw = p["bracket_w"] / 2000
    for k, x in enumerate([p["bracket_inset"] / 1000, W - p["bracket_inset"] / 1000]):
        rg = ".55 .56 .57 1"
        top = (leg_y - bh * s, bh * c)           # top of the leg, leaning over the foot
        parts = [  # (a, b, half thickness, share of the bracket's mass)
            ((x, toe_y, m / 2, hw), (x, leg_y + lip + T, m / 2, hw), m / 2, 0.40),            # foot, and the shoe's floor
            ((x, leg_y - m / 2, 0, hw), (x, top[0] - m / 2, top[1], hw), m / 2, 0.20),        # leg
            ((x, toe_y + 0.01, m, hw), (x, top[0] - m, top[1] - 0.005, hw), m / 2, 0.30),     # brace
            ((x, lip_y - lip / 2, 0, hw), (x, lip_y - lip / 2 - bh * s, bh * c, hw), lip / 2, 0.10),   # lip
        ]
        for j, (a, b, ht, share) in enumerate(parts):
            xml.append(box(f"br{k}_{j}", a, b, ht, rg, mb * share))
        for z in [v / 1000 for v in (25, 62)]:   # bolt heads on the lip's back: what touches the riser
            xml.append(f'<geom name="bolt{k}_{z}" type="box" pos="{x} {lip_y + 0.0021 - z * s} {z * c}" size="0.005 0.0021 0.005" '
                       f'rgba=".3 .3 .3 1" mass="0.01"/>')
    if ballast:
        reach = leg_y - toe_y
        xml.append(f'<geom name="ballast" type="box" pos="{W / 2} {leg_y - reach / 3} {m + 0.02}" size="{W / 2} 0.04 0.02" '
                   f'rgba=".3 .3 .6 1" mass="{ballast}"/>')
    top_pt = (W / 2, by - H * s, bz + H * c)
    return "\n".join(xml), top_pt, (toe_y, lip_y)


def symmetric_gate_xml(half_span, base_kg, board_kg, y0=0.0, H=1.0, T=0.010, W=0.78):
    """A board upright in the middle of a base half_span each way (both-face brackets or discs), as boxes."""
    xml = [f'<geom name="board" type="box" pos="{W / 2} {y0} {0.008 + H / 2}" size="{W / 2} {T / 2} {H / 2}" rgba=".85 .72 .54 1" mass="{board_kg}"/>']
    for k, x in enumerate([0.1, W - 0.1]):
        xml.append(f'<geom name="base{k}" type="box" pos="{x} {y0} 0.004" size="0.015 {half_span} 0.004" rgba=".55 .56 .57 1" mass="{base_kg / 2}"/>')
    return "\n".join(xml), (W / 2, y0, 0.008 + H), (y0 - half_span, y0 + half_span)


def build(gate_xml, top_pt, flat, mu):
    xml = f"""
<mujoco>
  <option timestep="{DT}" gravity="0 0 -9.81" integrator="implicitfast"><flag multiccd="enable"/></option>
  <default><geom friction="{mu} 0.005 0.0001" condim="3" solref="0.004 1" solimp="0.95 0.99 0.001"/></default>
  <visual><global offwidth="1280" offheight="960"/></visual>
  <worldbody>
    <light pos="0.4 -2 3" dir="0 0.6 -0.8"/>
    {stair_xml(flat)}
    <body name="gate">
      <freejoint/>
      {gate_xml}
      <site name="push" pos="{top_pt[0]} {top_pt[1]} {top_pt[2]}" size="0.01"/>
    </body>
  </worldbody>
</mujoco>"""
    model = mujoco.MjModel.from_xml_string(xml)
    return model


def tilt(data):
    """The gate's rotation about x (across the stair), degrees, + forwards (downhill, top towards -y)."""
    q = data.qpos[3:7]
    w, x = q[0], q[1]
    return math.degrees(2 * math.atan2(x, w))


def settle(model, data, t=1.5):
    mujoco.mj_resetData(model, data)
    for _ in range(int(t / DT)):
        mujoco.mj_step(model, data)


def push(model, data, f):
    """Apply a horizontal force f (N, along y) at the push site."""
    data.qfrc_applied[:] = 0
    if f:
        pt = data.site_xpos[model.site("push").id]
        mujoco.mj_applyFT(model, data, np.array([0, f, 0]), np.zeros(3), pt, model.body("gate").id, data.qfrc_applied)


def ramp(model, sign, rate=2.0, fmax=80.0):
    """Grow the push until it falls or slides; return the force at lift-off (0.5°), at the fall (15°) and
    at sliding (3 mm before 0.3° of tilt). Backwards on the stair it lifts until the bolt heads meet the
    riser, and then holds."""
    data = mujoco.MjData(model)
    settle(model, data)
    t0, y0 = tilt(data), data.qpos[1]
    f_lift = f_fall = f_slide = None
    t = 0.0
    while True:
        f = rate * t
        push(model, data, sign * f)
        mujoco.mj_step(model, data)
        t += DT
        a = abs(tilt(data) - t0)
        if f_lift is None and a > 0.5:
            f_lift = f
        if f_slide is None and abs(data.qpos[1] - y0) > 0.003 and a < 0.3:
            f_slide = f
        if a > 15:
            f_fall = f
            break
        if f > fmax or (f_slide and f > f_slide + 5):
            break
    return f_lift, f_fall, f_slide


def tap_falls(model, sign, peak, dur=0.05, settle_t=1.5, watch=4.0):
    """Tap it and watch: which way it falls ("push" the way it was pushed, "back" the other way), or None."""
    data = mujoco.MjData(model)
    settle(model, data, settle_t)
    t0 = tilt(data)
    t = 0.0
    while t < watch:
        f = peak * math.sin(math.pi * t / dur) if t < dur else 0.0
        push(model, data, sign * f)
        mujoco.mj_step(model, data)
        t += DT
        a = tilt(data) - t0          # + forwards
        if abs(a) > 40:
            return "push" if (a < 0) == (sign > 0) else "back"
    return None


def min_tap(model, sign, way=None, hi=400.0):
    """Smallest tap peak that makes it fall: the way it was pushed (way="push") or either way (None)."""
    hit = lambda p: (tap_falls(model, sign, p) == way) if way else tap_falls(model, sign, p) is not None
    if not hit(hi):
        return None
    lo = 0.0
    for _ in range(14):
        mid = (lo + hi) / 2
        if hit(mid):
            hi = mid
        else:
            lo = mid
    return hi


def video(model, sign, peak, path, dur=0.05, secs=3.0, fps=30):
    import imageio
    data = mujoco.MjData(model)
    settle(model, data)
    r = mujoco.Renderer(model, 720, 960)
    cam = mujoco.MjvCamera()
    cam.lookat[:] = [0.39, -0.05, 0.35]
    cam.distance, cam.azimuth, cam.elevation = 2.8, 180, -8   # from the side, downhill on the left
    frames, t, next_frame = [], 0.0, 0.0
    while t < secs:
        f = peak * math.sin(math.pi * t / dur) if t < dur else 0.0
        push(model, data, sign * f)
        mujoco.mj_step(model, data)
        t += DT
        if t >= next_frame:
            r.update_scene(data, cam)
            frames.append(r.render())
            next_frame += 1 / fps
    imageio.mimsave(path, frames, fps=fps)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mu", type=float, default=0.4)
    ap.add_argument("--video", default="")
    args = ap.parse_args()
    p = gate.scad_params()
    board_kg = p["board_w"] * p["board_h"] * p["board_t"] * 1e-9 * p["board_density"]
    variants = {
        "project": project_gate_xml(),
        "lean 0": project_gate_xml(["lean=0"]),
        "lean 8": project_gate_xml(["lean=8"]),
        "lean 12": project_gate_xml(["lean=12"]),
        "+5 kg ballast": project_gate_xml(ballast=5.0),
        "both faces 140": symmetric_gate_xml(0.140, 0.34, board_kg),
        "discs 230": symmetric_gate_xml(0.115, 0.50, board_kg),
    }
    res = {}
    for name, (gx, top, edges) in variants.items():
        for flat in (False, True):
            if not flat and not name.startswith(("project", "lean", "+5")):
                continue   # the symmetric bases stand in the middle of the tread: the same as a flat floor
            model = build(gx, top, flat, args.mu)
            where = "flat" if flat else "stair"
            for sign, d in ((-1, "forwards"), (1, "backwards")):
                lift, fall, slide = ramp(model, sign)
                peak = min_tap(model, sign)                 # falls either way
                peak_push = min_tap(model, sign, "push")    # falls the way it was pushed
                imp = lambda p: p and round(2 * p * 0.05 / math.pi, 2)
                key = f"{name} | {where} | {d}"
                res[key] = dict(lift=lift, fall=fall, slide=slide, tap_any=peak, tap_any_impulse=imp(peak),
                                tap_push=peak_push, tap_push_impulse=imp(peak_push))
                print(f"{key:40s} ramp: lifts {lift and round(lift, 1)} N, falls {fall and round(fall, 1)} N, slides {slide and round(slide, 1)} N; "
                      f"tap: falls at {peak and round(peak, 1)} N ({imp(peak)} N·s), the way pushed at {peak_push and round(peak_push, 1)} N ({imp(peak_push)} N·s)", flush=True)
                if args.video and name == "project" and peak:
                    os.makedirs(args.video, exist_ok=True)
                    for lab, k in (("falls", 1.05), ("rocks", 0.9)):
                        video(model, sign, peak * k, os.path.join(args.video, f"{where}-{d}-{lab}.mp4"))
                    if peak_push and peak_push > peak * 1.1:
                        video(model, sign, peak_push * 1.05, os.path.join(args.video, f"{where}-{d}-falls-the-way-pushed.mp4"))
    json.dump(res, open(os.path.join(HERE, f"sim-mu{args.mu}.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
