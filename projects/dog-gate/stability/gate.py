"""The dog gate as rigid bodies, for stability.py and sim.py.

Everything comes from dog-gate.scad (its echo and a bracket STL), so the
analysis follows the model: change a parameter there, or pass it here as an
OpenSCAD override, and both scripts see it.

Display coordinates as in the .scad: y along the stair (+ uphill), z up, the
tread the gate stands on at z = 0, the board leaning over the feet by `lean`.
Work in the y-z plane: the gate is symmetric across the stair.
"""
import math, os, re, subprocess, tempfile
from dataclasses import dataclass, field

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "..", "dog-gate.scad")
OPENSCAD = os.environ.get("OPENSCAD", "openscad")
G = 9.81
ABS_DENSITY = 1050.0          # kg/m³
BRACKET_FILL = 0.67           # sliced grams / solid: 115 g from `make report` over the 164 cm³ of the mesh


def scad_values(defs=()):
    """Run the .scad and read its echoes: the GEOM line and the parameters we need."""
    with tempfile.TemporaryDirectory() as tmp:
        stl = os.path.join(tmp, "b.stl")
        args = [OPENSCAD, "-D", 'part="bracket"', "-o", stl, SCAD]
        for d in defs:
            args[1:1] = ["-D", d]
        out = subprocess.run(args, capture_output=True, text=True).stderr
        tri = read_stl(stl)
    geom = dict(re.findall(r"(\w+)=([-\d.e]+)", re.search(r'ECHO: "GEOM ([^"]*)"', out).group(1)))
    return {k: float(v) for k, v in geom.items()}, tri


def read_stl(path):
    txt = open(path).read()
    v = np.array(re.findall(r"vertex\s+(\S+)\s+(\S+)\s+(\S+)", txt), float)
    return v.reshape(-1, 3, 3)


def solid_props(tri):
    """Volume (mm³), centroid and inertia tensor about the centroid (per unit density, mm⁵) of a closed mesh."""
    a, b, c = tri[:, 0], tri[:, 1], tri[:, 2]
    v6 = np.einsum("ij,ij->i", a, np.cross(b, c))
    vol = v6.sum() / 6
    cen = ((a + b + c) * v6[:, None]).sum(0) / (24 * vol)
    # second moments by the tetrahedron formula
    s = np.zeros((3, 3))
    for i in range(3):
        for j in range(3):
            s[i, j] = (v6 * (2 * (a[:, i] * a[:, j] + b[:, i] * b[:, j] + c[:, i] * c[:, j])
                             + a[:, i] * b[:, j] + a[:, j] * b[:, i] + a[:, i] * c[:, j] + a[:, j] * c[:, i]
                             + b[:, i] * c[:, j] + b[:, j] * c[:, i])).sum() / 120
    s -= vol * np.outer(cen, cen)
    inertia = np.trace(s) * np.eye(3) - s
    return vol, cen, inertia


@dataclass
class Body:
    name: str
    mass: float               # kg
    y: float                  # centre of mass, m
    z: float
    ixx: float                # about its own centre of mass, around x (across the stair), kg·m²


@dataclass
class Gate:
    name: str
    bodies: list
    toe_y: float              # forward tipping edge (downhill), m
    back_y: float             # backward tipping edge, m
    riser_y: float = None     # the riser behind, if any: tipping backwards, the gate pivots on its top edge
    riser_z: float = None
    note: str = ""

    @property
    def mass(self):
        return sum(b.mass for b in self.bodies)

    @property
    def com(self):
        m = self.mass
        return (sum(b.mass * b.y for b in self.bodies) / m, sum(b.mass * b.z for b in self.bodies) / m)

    def inertia_about(self, py, pz):
        return sum(b.ixx + b.mass * ((b.y - py) ** 2 + (b.z - pz) ** 2) for b in self.bodies)


def board_body(kg, w, h, t, foot_y, foot_z, lean_deg):
    """The board leaning over the feet (towards -y) about its foot."""
    a = math.radians(lean_deg)
    return Body("board", kg, foot_y - h / 2 * math.sin(a), foot_z + h / 2 * math.cos(a), kg * (h * h + t * t) / 12)


def one_sided(defs=(), board_kg=None, ballast_kg=0.0, perforated=0.0, name="one-sided brackets"):
    """The project's gate: two brackets on the downhill face, the board in their shoes."""
    p = scad_params(defs)
    geom, tri = scad_values(defs)
    vol, cen, inertia = solid_props(tri)          # print coordinates: x = u (from the leg), y = v (up), z = across
    mb = vol * 1e-9 * ABS_DENSITY * BRACKET_FILL
    leg_y = geom["leg_y"] / 1000
    br_y, br_z = leg_y - cen[0] / 1000, cen[1] / 1000
    ib = inertia[2, 2] * 1e-15 * ABS_DENSITY * BRACKET_FILL     # about the print z = across the stair
    kg = board_kg if board_kg is not None else p["board_w"] * p["board_h"] * p["board_t"] * 1e-9 * p["board_density"]
    kg *= 1 - perforated
    bodies = [board_body(kg, p["board_h"] / 1000, p["board_h"] / 1000, p["board_t"] / 1000, geom["board_y"] / 1000,
                         p["lip"] / 1000, p["lean"])]
    bodies += [Body("bracket", 2 * mb, br_y, br_z, 2 * ib)]
    if ballast_kg:
        # on the feet, a third of the way from the leg to the toe, 4 cm high
        reach = (geom["leg_y"] - geom["toe_y"]) / 1000
        bodies.append(Body("ballast", ballast_kg, leg_y - reach / 3, 0.0084 + 0.02, 0.0))
    return Gate(name, bodies, toe_y=geom["toe_y"] / 1000, back_y=geom["lip_y"] / 1000,
                riser_y=(geom["lip_y"] + p["head_gap"]) / 1000, riser_z=p["rise"] / 1000,
                note=f"bracket {mb * 1000:.0f} g each, centre of mass {cen[0]:.0f} mm in front of the leg, {cen[1]:.0f} up")


def symmetric_base(half_span, base_kg, board_kg, h=1.0, t=0.010, name="symmetric base"):
    """A board standing upright in the middle of a base reaching half_span each way (a disc, or brackets on both faces)."""
    bodies = [Body("board", board_kg, 0.0, h / 2, board_kg * (h * h + t * t) / 12),
              Body("base", base_kg, 0.0, 0.01, 0.0)]
    return Gate(name, bodies, toe_y=-half_span, back_y=half_span)


def scad_params(defs=()):
    """Literal parameters from the top of the .scad, with overrides."""
    vals = {}
    for line in open(SCAD):
        m = re.match(r"(\w+)\s*=\s*([-\d.]+)\s*;", line)
        if m:
            vals[m.group(1)] = float(m.group(2))
    for d in defs:
        k, v = d.split("=", 1)
        try:
            vals[k.strip()] = float(v)
        except ValueError:
            pass
    return vals
