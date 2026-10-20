# Cosmere tracker

Health, Focus and Investiture tracker for the Cosmere RPG. Each stat counts
00–99 and **reads the same from both sides of the table**: the player sees it
from the front, everyone else from the back.

![Cosmere tracker](renders/cosmere-tracker-hero.webp)

Each wheel is an outer ring (tens) around an inner disc (units), with digits
on both faces. The front window sits at 9 o'clock and the back one at
3 o'clock, so both sides read tens on the left and units on the right. Turn
the ring by its ridged edge on top and the disc by the knob on the front.

```sh
make project                                # -> cosmere-tracker-p1s.3mf (Bambu Studio, ready to print)
make report                                 # rebuild it, slice it, print time and filament
make                                        # -> frame.3mf front.3mf wheels.3mf stand.3mf
make DEFS='-D show_investiture=false'       # only Health and Focus
make DEFS='-D digit_h=6'                    # smaller (and narrower) tracker
make stl                                    # single-colour STLs instead
make preview                                # -> cosmere-tracker-front.png / -back.png (OpenSCAD, quick look; not committed)
make render                                 # -> renders/*.webp, studio views with Blender
```

The default is about 200 × 59 × 8 mm (plus the knobs) with 7 mm digits;
`digit_h` scales the wheels and the whole housing. The console prints the
size.

## Parameters

All lengths in mm. Override any of them with `make DEFS='-D name=value'` (also
`make project`, `make report` and `make render`). Lists and strings need
quotes inside `DEFS`, for example
`make DEFS="-D 'labels=[\"VIDA\",\"MANÁ\"]'"`.

| Parameter | Default | What it does |
|---|---|---|
| **Stats** | | |
| `show_investiture` | true | Third wheel; false leaves only the first two stats |
| `labels` | `["SALUD", "CONCENTRACIÓN", "INVESTIDURA"]` | Text printed under each window, one per wheel |
| **Colours** | | |
| `body_color` | `#1b1b1b` | Housing, wheels and stand |
| `digit_color` | `#f2f2f2` | Digits on the wheels |
| `label_colors` | `["#e0b040", "#e0b040", "#e0b040"]` | One colour per label |
| `rim_color` | `#f2f2f2` | Frame around each window |
| **Digits** | | |
| `digit_h` | 7 | Digit height; scales the wheels and the whole housing |
| `font` | `Liberation Sans:style=Bold` | Font for digits and labels |
| `label_h` | 5.5 | Label letter height (strokes must stay wider than a first-layer line) |
| `ink_depth` | 0.6 | Inlay thickness (3 layers at 0.2 mm) |
| `window_rim` | 1.2 | Width of the coloured frame around each window (0 = none) |
| **Wheels** | | |
| `wheel_t` | 3.2 | Ring and disc thickness |
| `gap_z` | 0.3 | Play between a wheel face and a plate |
| `wheel_gap` | 0.5 | Radial play between disc and ring |
| `hub_r` | 5.5 | Radius of the disc knob that goes through the front plate |
| `hub_play` | 0.25 | Radial play around the knob |
| `knob_h` | 4 | How far the knob sticks out of the front plate |
| `grip` | 5 | How far the ring sticks out of the top edge |
| `ridges` | 60 | Number of ridges on the ring edge |
| `ridge_r` | 0.6 | Ridge radius |
| `ring_play` | 0.4 | Radial play between the ring ridges and the housing |
| **Housing** | | |
| `plate_t` | 2 | Front and back plate thickness |
| `side_wall` | 6 | Wall at the left and right ends |
| `bottom_wall` | 4 | Wall below the wheels |
| `between` | 3 | Narrowest wall between two wheels |
| `corner_r` | 4 | Corner radius of the housing |
| `peg_d` | 3 | Alignment peg diameter |
| `peg_h` | 1.5 | Alignment peg height |
| `peg_play` | 0.1 | Clearance of the peg holes |
| **Stand** | | |
| `stand_depth` | 40 | Depth of the base |
| `stand_h` | 7 | Height of the base |
| `slot_depth` | 5 | How deep the tracker sits in the base |
| `slot_play` | 0.3 | Clearance of the slot |
| **Render** | | |
| `part` | `assembly` | `assembly`, `frame`, `front`, `wheels`, `ring`, `disc` or `stand` |
| `explode` | 0 | Spreads the assembly along Z (preview only) |

## Variations

Any set of two or three 00–99 counters that both sides of a table should read.
Sizes from the console.

| Use | Parameters | Result |
|---|---|---|
| Cosmere RPG, Radiant (default) | — | 200 × 59 × 8 mm, three stats |
| Cosmere RPG, no Investiture | `-D show_investiture=false` | 137 × 59 × 8 mm, Health and Focus |
| Compact | `-D digit_h=6` | 185 × 54 × 8 mm with 6 mm digits |
| **Magic: The Gathering** life and poison | `-D show_investiture=false -D 'labels=["VIDA","VENENO"]' -D 'label_colors=["#c0392b","#27ae60"]'` | Life up to 99 (Commander's 40 fits). Four filaments: one AMS |
| D&D / any RPG | `-D 'labels=["PV","PV TEMP","CA"]'` | Hit points, temporary HP and armour class |
| Board game score keeper | `-D show_investiture=false -D 'labels=["EQUIPO A","EQUIPO B"]'` | Two team scores, readable from both sides |
| One colour per stat | `-D 'label_colors=["#c0392b","#2e86c1","#e0b040"]'` | Red, blue and gold labels. That is five filaments, more than one AMS holds: keep it to two stats, or reuse the digit colour for one label |

`bambu_project.py` places the parts at fixed positions sized for the default
tracker: above `digit_h=7` with three stats the plate no longer fits, so use
`make` and lay out the parts yourself.

## Printing (multi-colour, e.g. Bambu P1S + AMS)

`make project` builds `cosmere-tracker-p1s.3mf`, a Bambu Studio project with
every part on one plate (3 rings, 3 discs, front, frame and stand) and each
colour already assigned to a filament: P1S 0.4 nozzle, *0.20mm Standard*
with the Arachne wall generator and no elephant foot compensation (so the
thin strokes of the first-layer labels survive), Textured PEI plate, Bambu PLA Basic in slots 1 (body), 2 (labels) and 3
(digits and rims). Colours only change in the first three layers and in the
top three of the wheels, so one plate costs about ten filament changes:
roughly 3 h 30 min and 112 g. Map the three slots to your AMS when sending
it. It needs Bambu Studio installed (its CLI fills in the full presets).

To build your own plate instead:

Digits, labels and window rims are 0.6 mm flush inlays (3 layers at 0.2 mm),
exported as separate coloured objects. In Bambu Studio open each 3MF, answer
**Yes** to loading it as a single object with multiple parts, and give each
part its filament. The default uses three: body `#1b1b1b`, digits and rims
`#f2f2f2`, labels `#e0b040` — change `label_colors` for one colour per stat.

| file         | what                                   | orientation            |
|--------------|----------------------------------------|------------------------|
| `frame.3mf`  | back plate + walls + alignment pegs    | back face on the bed   |
| `front.3mf`  | front plate                            | front face on the bed  |
| `wheels.3mf` | 3 rings (tens) + 3 discs with knob     | as laid out            |
| `stand.3mf`  | base with a slot                       | as laid out            |

No supports needed. The colour changes only happen in the first and last
layers of each part, so purge waste is small.

## Renders

`make render` builds the project and renders studio views of the assembled tracker (OpenSCAD's `assembly`
part, each colour in its filament) and of the print plate with Blender
(`../../tools/render_studio.py`), in the project's filaments and with layer lines
at its layer height. 2400 x 1800 WebP, ready for MakerWorld's model images;
add `RENDER_FLAGS="--samples 32 --scale 0.25"` for a quick draft.
The parts print flat, so on the assembly the layer lines run across the
thickness (`--layer-axis y`).

| | Hero | Front | Side | Top | Back |
|---|---|---|---|---|---|
| Assembly | ![](renders/cosmere-tracker-hero.webp) | ![](renders/cosmere-tracker-front.webp) | ![](renders/cosmere-tracker-side.webp) | ![](renders/cosmere-tracker-top.webp) | ![](renders/cosmere-tracker-back.webp) |

| Plate, hero | Plate, top |
|---|---|
| ![](renders/cosmere-tracker-parts-hero.webp) | ![](renders/cosmere-tracker-parts-top.webp) |


## Assembly

1. Drop each disc into its ring, knob up, and both into a round pocket of the
   frame.
2. Press the front plate on, with the knobs through the holes. The pegs are a
   snug fit; add a drop of glue if they are loose.
3. Stand it in the base.

Tune `gap_z`, `wheel_gap`, `hub_play` and `ring_play` if the wheels bind or
spin too freely on your printer.
