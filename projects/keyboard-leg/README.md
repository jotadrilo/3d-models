# Keyboard leg (Logitech K120)

Replacement tilt leg for the **Logitech K120** keyboard (also sold as *K120 for
Business*, M/N Y-U0009). The leg folds into a recess under the keyboard's back
edge: two Ø2 mm pins at its hinge end turn in the recess, and a sprung tongue
between two slots clicks it open or shut with the ridge on its tip.

The K120 is sold with two legs; a broken one is the usual reason to print this.

```sh
make project      # -> keyboard-leg-p1s.3mf (Bambu Studio, ready to print)
make report       # rebuild it, slice it, print time and filament per plate
make              # -> keyboard-leg.stl
make DEFS='-D pin_d=1.9'   # thinner pins, if they bind in the recess
make render       # -> renders/*.webp, studio views with Blender
```

## Where the dimensions come from

No drawing of the original part is published. The geometry was measured (height
maps and sections of the meshes) from two free community models that users
report fit the K120, and that agree to within 0.1 mm:

- [Logitech K120 Keyboard Feet/Legs](https://www.printables.com/model/697383) (Printables 697383, CC0 public domain)
- [Logitech K120 Foot](https://www.printables.com/model/548129) (Printables 548129, CC BY-NC)

It was then rebuilt here as a parametric OpenSCAD model, with two print changes:
the pins have a 0.2 mm flat underneath so they print without supports (both
references are round and their pages recommend supports), and their tips have a
0.3 mm chamfer as a lead-in.

| Feature | Size (mm) |
|---|---|
| Body | 15 wide × 25 long × 4 thick |
| Side rails | 2 wide, full thickness, round at the hinge end (r 2), a quarter circle (r 4) at the foot end |
| Plate between the rails | 2 thick |
| Pins | Ø2, 2.5 long each side, axis 1.8 from the hinge end, at mid-thickness |
| Slots | 2 wide, 9.5 long from the hinge end |
| Tongue | 7 wide, with a ridge to full thickness on its first 2 mm |
| Rib across the plate | 0.84 wide, 3 tall, 20.25 from the hinge end |

## Parameters

All lengths in mm. Override any of them with `make DEFS='-D name=value'` (also
`make project`, `make report` and `make render`).

| Parameter | Default | What it does |
|---|---|---|
| `width` | 15 | Body width, without the pins |
| `length` | 25 | Hinge end to foot end: a longer leg tilts the keyboard more |
| `thick` | 4 | Overall thickness (the rails) |
| `plate_t` | 2 | Plate between the rails |
| `rail_w` | 2 | Side rail width |
| `foot_r` | 4 | Radius of the rounded foot end |
| `bed_chamfer` | 0.4 | 45° chamfer under the sides and the foot end (hides elephant foot) |
| `pin_d` | 2 | Pin diameter |
| `pin_len` | 2.5 | How far each pin sticks out |
| `pin_y` | 1.8 | Pin axis from the hinge end |
| `pin_flat` | 0.2 | Flat under the pins so they print unsupported (0 = round) |
| `pin_tip` | 0.3 | Chamfer on the pin tips |
| `slot_w` | 2 | Width of the slots beside the tongue |
| `slot_len` | 9.5 | Slot length: a longer slot makes a softer click |
| `ridge_back` | 2 | Length of the ridge on the tongue's tip |
| `rib_y`, `rib_w`, `rib_h` | 20.25, 0.84, 3 | Rib across the plate (`rib_y=0`: none) |

## Printing (Bambu P1S)

`make project` builds `keyboard-leg-p1s.3mf` on a Textured PEI plate, P1S 0.4
nozzle, *0.12mm Fine* (fine layers for the 2 mm pins), 4 walls, 40 % gyroid,
the seam at the foot end. The legs lie flat, the plate face on the bed. No
supports.

| Plate | What | Filaments (AMS slot) | Time | Filament |
|---|---|---|---|---|
| 1 Colour samples | 8 legs, 2 per filament, printed **by object** (each leg whole, one after another): 3 filament changes and no prime tower, instead of 4 colours on every layer | 1 PETG HF blue, 2 PETG Translucent, 3 PETG Matte black, 4 PETG Basic black | 1 h 06 min | 9.7 g |
| 2 Pair | the 2 legs a keyboard needs | 3 PETG Matte black | 16 min | 2.3 g |

By object needs the legs far enough apart for the toolhead (57 mm clearance
radius) to clear those already printed, so they sit 85 mm apart; plate 1 keeps
the back-right spot free. To print a pair in another filament, change the
filament of plate 2 in Bambu Studio. PETG on the textured plate: a glue stick as
release layer (CLAUDE.md §5.3), and let it cool before taking the legs off.

## Strength and orientation

| Load | Path | Orientation | Margin |
|---|---|---|---|
| Keyboard weight and typing on the back edge, ≈10 N per leg at most | compression along the leg (38 mm² of section) | along Y, in the layers | ≈0.3 MPa against 30–40 MPa: ≫ 5× |
| The same load into the recess through the pins | shear and bending of two Ø2 cantilevers 2.5 long | pins lie in XY, the strong way | bending ≈8 MPa (5 N per pin at mid-length) against 43 MPa (PETG Matte X-Y): ≈5×; shear ≈1.6 MPa: > 10× |
| Clicking open and shut | the tongue bends as a snap arm, 2 thick and ≈9.5 long | flat, deflection in Z | ε = 1.5·t·δ/L² ≈ 1.7 % for 0.5 mm, within PETG's 2 % for a snap used now and then |

## Analyses

- **FEA**: not run. The pins' margin is ≈5× by hand, on the threshold, but the
  load is a worst case (all of a hard typing force on one pin) and the same
  geometry has hundreds of downloads printed in PLA, which is stiffer and
  weaker in elongation than the PETG used here.
- **Print stiffness**: not needed (4 mm tall).
- **Stability**: not applicable (the leg is held by the keyboard).
- **Fit**: the pins and the tongue's ridge are what has to fit the recess. Plate
  1 doubles as the fit test: if the pins bind, reprint with `pin_d=1.9`; if the
  leg does not stay open, lengthen `ridge_back` a little.
