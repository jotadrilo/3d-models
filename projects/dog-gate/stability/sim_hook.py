#!/usr/bin/env python3
"""Rigid-body simulation (MuJoCo) of the hooked gate (dog-gate-hook.scad) on an open stair of
tray treads: does the hook hold it, and how hard does it pull on the flange?

The gate is one rigid body (board, battens, brackets with their shoes, heel arms and hooks) as
boxes from the model's numbers, on tray treads (a plate with its front and back flanges, open
below; the next one up overlapping by `overlap`), Coulomb friction μ 0.4. Two cases at the middle
of the top edge, down the stair:

  lean   a leaning dog: the push grows to 206 N in 1 s and stays 2 s (fea/ uses the same 206 N)
  hit    a hard blow: a 50 ms half-sine of 690 N (twice the dog's weight), then 3 s to settle

It prints the tilt, how far the gate slides, and the contact force between the hooks and the
flange (compare with fea/board_fea.py's ~370-410 N per hook), and writes a clip of each case.

usage: python sim_hook.py [--video out_dir] [--mu 0.4]
"""
import argparse, math, os, re, subprocess, tempfile

import mujoco
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "..", "dog-gate-hook.scad")
DT = 0.0005


def scad():
    vals = {}
    for line in open(SCAD):
        m = re.match(r"(\w+)\s*=\s*([-\d.]+)\s*;", line)
        if m:
            vals[m.group(1)] = float(m.group(2))
    with tempfile.TemporaryDirectory() as tmp:
        err = subprocess.run(["openscad", "-D", 'part="bracket"', "-o", os.path.join(tmp, "b.stl"), SCAD],
                             capture_output=True, text=True).stderr
    g = re.search(r'ECHO: "GEOM ([^"]*)"', err).group(1)
    vals.update({k: float(v) for k, v in re.findall(r"(\w+)=([-\d.e]+)", g)})
    return {k: v / 1000 if k not in ("lean", "board_density") else v for k, v in vals.items()}


def b(name, c, half, rgba, mass=None, euler=None):
    e = f' euler="{euler[0]} {euler[1]} {euler[2]}"' if euler else ""
    ms = f' mass="{mass}"' if mass is not None else ""
    return (f'<geom name="{name}" type="box" pos="{c[0]:.5f} {c[1]:.5f} {c[2]:.5f}" '
            f'size="{half[0]:.5f} {half[1]:.5f} {half[2]:.5f}" rgba="{rgba}"{ms}{e}/>')


def tray(name, y0, z0, p):
    w, t, s, eh = p["board_w"] + 0.2, p["tread"], p["sheet"], p["edge_h"]
    st = ".24 .25 .28 1"
    return "\n".join([
        b(f"{name}_plate", (p["board_w"] / 2, y0 + t / 2, z0 - s / 2), (w / 2, t / 2, s / 2), st),
        b(f"{name}_front", (p["board_w"] / 2, y0 + s / 2, z0 - eh / 2), (w / 2, s / 2, eh / 2), st),
        b(f"{name}_back", (p["board_w"] / 2, y0 + t - s / 2, z0 - eh / 2), (w / 2, s / 2, eh / 2), st)])


def gate(p):
    W, H, T = p["board_w"], p["board_h"], p["board_t"]
    lean = math.radians(p["lean"])
    s, c = math.sin(lean), math.cos(lean)
    leg_y, lip_y, toe_y = p["leg_y"], p["lip_y"], p["toe_y"]
    lip, m, bh, bw = p["lip"], p["member"], p["bracket_h"], p["bracket_w"] / 2
    pivot = (leg_y, 0.0)

    def lean_pt(y, z):   # a point of the board and battens, leaning over the feet about the leg's foot
        dy, dz = y - pivot[0], z - pivot[1]
        return pivot[0] + dy * c - dz * s, pivot[1] + dy * s + dz * c

    kb = W * H * T * p["board_density"]
    wood, br = ".85 .72 .54 1", ".55 .56 .57 1"
    by = p["board_y"]
    cy, cz = lean_pt(by, lip + H / 2)
    xml = [b("board", (W / 2, cy, cz), (W / 2, T / 2, H / 2), wood, kb, (p["lean"], 0, 0))]
    bat_h = H - p["batten_top"]
    bat_y = by - T / 2 - p["batten_t"] / 2
    for k, x in enumerate([p["bracket_inset"], W - p["bracket_inset"]]):
        cy, cz = lean_pt(bat_y, lip + bat_h / 2)
        xml.append(b(f"batten{k}", (x, cy, cz), (p["batten_w"] / 2, p["batten_t"] / 2, bat_h / 2), wood,
                     p["batten_w"] * p["batten_t"] * bat_h * 450, (p["lean"], 0, 0)))
        heel_end = p["tread"] / 2 + p["hook_clear"] + p["hook_t"]
        low = -p["edge_h"] - p["hook_clear"]
        ty, tz = lean_pt(leg_y - m / 2, bh / 2)
        parts = [
            ("foot", (x, (toe_y + leg_y) / 2, m / 2), (bw, (leg_y - toe_y) / 2, m / 2), None, 0.06),
            ("leg", (x, ty, tz), (bw, m / 2, bh / 2), (p["lean"], 0, 0), 0.03),
            ("brace", (x, (toe_y + leg_y) / 2, bh / 2), (bw, math.hypot(leg_y - toe_y, bh) / 2, m / 2),
             (math.degrees(math.atan2(bh, leg_y - toe_y)), 0, 0), 0.05),   # rising from the toe to the leg's top
            ("floor", (x, (leg_y + lip_y) / 2, lip / 2), (bw, (lip_y - leg_y) / 2, lip / 2), None, 0.02),
            ("shoelip", (x, lip_y - lip / 2, bh / 2), (bw, lip / 2, bh / 2), None, 0.02),
            ("arm", (x, (lip_y + heel_end) / 2, p["heel_h"] / 2), (bw, (heel_end - lip_y) / 2, p["heel_h"] / 2), None, 0.04),
            ("strap", (x, heel_end - p["hook_t"] / 2, (low - p["hook_t"]) / 2), (bw, p["hook_t"] / 2, (p["hook_t"] - low) / 2), None, 0.02),
            ("hooklip", (x, (heel_end - p["hook_t"] + p["tread"] / 2 - p["hook_lip"]) / 2, low - p["hook_t"] / 2),
             (bw, (p["hook_t"] + p["hook_clear"] + p["hook_lip"]) / 2, p["hook_t"] / 2), None, 0.01),
        ]
        for name, cc, half, eu, mass in parts:
            xml.append(b(f"{name}{k}", cc, half, br, mass, eu))
    ty, tz = lean_pt(by, lip + H)
    return "\n".join(xml), (W / 2, ty, tz)


def build(p, mu):
    g, top = gate(p)
    t, o = p["tread"], p["overlap"]
    treads = "\n".join([tray("t0", -t / 2, 0, p), tray("t1", p["next_y"], p["rise"], p),
                        tray("t2", p["next_y"] + t - o, 2 * p["rise"], p), tray("tm1", -t / 2 - t + o, -p["rise"], p)])
    xml = f"""
<mujoco>
  <option timestep="{DT}" gravity="0 0 -9.81" integrator="implicitfast"><flag multiccd="enable"/></option>
  <default><geom friction="{mu} 0.005 0.0001" condim="3" solref="0.004 1" solimp="0.95 0.99 0.001"/></default>
  <visual><global offwidth="1280" offheight="960"/></visual>
  <worldbody>
    <light pos="0.4 -2 3" dir="0 0.6 -0.8"/>
    <geom name="ground" type="plane" pos="0 0 -1" size="3 3 0.1" rgba=".8 .8 .8 1"/>
    {treads}
    <body name="gate">
      <freejoint/>
      {g}
      <site name="push" pos="{top[0]} {top[1]} {top[2]}" size="0.01"/>
    </body>
  </worldbody>
</mujoco>"""
    return mujoco.MjModel.from_xml_string(xml)


def tilt(data):
    q = data.qpos[3:7]
    return math.degrees(2 * math.atan2(q[1], q[0]))


def hook_force(model, data):
    """Total normal force between the hooks' lips and the tread's back flange, N."""
    f6 = np.zeros(6)
    tot = 0.0
    back = model.geom("t0_back").id
    for i in range(data.ncon):
        con = data.contact[i]
        names = {model.geom(con.geom1).name, model.geom(con.geom2).name}
        if back in (con.geom1, con.geom2) and any(n.startswith("hooklip") for n in names):
            mujoco.mj_contactForce(model, data, i, f6)
            tot += abs(f6[0])
    return tot


def run(model, force_of_t, secs, video=None):
    data = mujoco.MjData(model)
    for _ in range(int(1.0 / DT)):     # settle, hooked
        mujoco.mj_step(model, data)
    t0, y0 = tilt(data), data.qpos[1]
    frames, r, cam = [], None, None
    if video:
        r = mujoco.Renderer(model, 720, 960)
        cam = mujoco.MjvCamera()
        cam.lookat[:] = [0.2, 0.02, 0.15]
        cam.distance, cam.azimuth, cam.elevation = 1.1, 0, -5   # from the side (-x): the bracket, the hook and the flange in profile
    t, nf, peak_hook, peak_tilt = 0.0, 0.0, 0.0, 0.0
    sid, bid = model.site("push").id, model.body("gate").id
    while t < secs:
        f = force_of_t(t)
        data.qfrc_applied[:] = 0
        if f:
            mujoco.mj_applyFT(model, data, np.array([0, -f, 0]), np.zeros(3), data.site_xpos[sid], bid, data.qfrc_applied)
        mujoco.mj_step(model, data)
        t += DT
        peak_hook = max(peak_hook, hook_force(model, data))
        peak_tilt = max(peak_tilt, abs(tilt(data) - t0))
        if r and t >= nf:
            r.update_scene(data, cam)
            frames.append(r.render())
            nf += 1 / 30
    if r:
        import imageio
        imageio.mimsave(video, frames, fps=30)
    return dict(peak_tilt=peak_tilt, end_tilt=tilt(data) - t0, slide_mm=(data.qpos[1] - y0) * 1000,
                peak_hook=peak_hook, end_hook=hook_force(model, data))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mu", type=float, default=0.4)
    ap.add_argument("--video", default="")
    args = ap.parse_args()
    p = scad()
    model = build(p, args.mu)
    print(f"gate {sum(model.body_mass):.2f} kg")
    cases = {
        "lean": (lambda t: 206.0 * min(t, 1.0), 3.0),
        "hit": (lambda t: 690.0 * math.sin(math.pi * t / 0.05) if t < 0.05 else 0.0, 3.0),
    }
    for name, (f, secs) in cases.items():
        vid = os.path.join(args.video, f"hook-{name}.mp4") if args.video else None
        if vid:
            os.makedirs(args.video, exist_ok=True)
        res = run(model, f, secs, vid)
        print(f"{name:5s} tilt peak {res['peak_tilt']:.2f}°, end {res['end_tilt']:.2f}°; slides {res['slide_mm']:.1f} mm; "
              f"hooks on the flange: peak {res['peak_hook']:.0f} N, end {res['end_hook']:.0f} N (both hooks)")


if __name__ == "__main__":
    main()
