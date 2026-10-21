# CLAUDE.md — 3d-models

Parametric models to print on a **Bambu Lab P1S** (0.4 nozzle, AMS, **Textured PEI plate**).
This file holds the repo conventions and the design and print practices every new project must
follow.

Setting names are given as they appear in the Bambu Studio UI, followed by the config key written
to the 3MF (`key`).

---

## 1. Repository rules (mandatory)

1. **Language: everything written in the repo is in English.** That covers code, comments, READMEs,
   commit messages, object and plate names inside the Bambu projects, and this file. The only
   exception is text that is part of the printed object itself (labels on the model), which follows
   what the user asks for. Conversation with the user is in Spanish.
2. **Modelling tool: OpenSCAD.** Use something else only when it is clearly better, and say so in
   the README:
   - **build123d / CadQuery** (Python on the OCCT kernel): fillets and chamfers on arbitrary
     edges, or when STEP output is needed.
   - **Blender**: organic or sculpted shapes.
   - OpenSCAD suits prismatic, CSG, parametric parts, which is almost everything here.
3. **Every project ships with a Bambu Studio project** (`<project>-p1s.3mf`) built by
   `make project`. It must be ready to print: parts oriented, laid out on plates, filaments
   assigned per part and colour, process preset chosen, per-object settings applied. See §3.
4. **Repository layout: projects in `projects/`, shared components and scripts in `tools/`.**
   Every model is a folder `projects/<project>/`; nothing project-specific goes in `tools/`, and
   no functional component is designed only inside a project (§4.6).
   **Project folder layout**:
   ```
   projects/<project>/
     <project>.scad        # parametric model, Customizer parameters at the top
     Makefile              # all / stl / 3mf / project / report / render / clean / help (+ check)
     bambu_project.py      # builds <project>-p1s.3mf with tools/bambu3mf.py (§3)
     README.md             # what it is, make commands, parts table, how to print, assembly
     .gitignore            # *.stl, assembly.3mf (exports are not committed; the Bambu projects and renders are)
     <project>-*.3mf       # the Bambu Studio project(s), `make project`, committed
     renders/<name>-<view>.webp   # studio renders, `make render` (§3.3), linked from the README
   ```
   The root `.gitignore` already ignores macOS metadata (`.DS_Store`, `._*`) everywhere.
   Add the project to the root `README.md` as one table row: its hero render as a 240 px
   thumbnail linking to the folder, then the link and a one-line description. Shared code lives
   in `tools/`; shared OpenSCAD components in `tools/scad/` (§4.6). From a project folder, both
   are at `../../tools/`.
5. **Makefile**:
   - `OPENSCAD ?= openscad`, `OPENSCAD_FLAGS ?=` and `DEFS ?=` for overrides
     (`make DEFS='-D x=1'`), combined in `SCAD = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)`.
   - **Every target is `.PHONY` and always regenerates its files**, even when they already exist
     on disk. Targets are named by what they do (`stl`, `3mf`, `project`, `render`, `check`),
     not by the file they produce. No pattern rules (`%.stl`) and no `FORCE` prerequisites:
     hardcode the file names in the recipe, or loop over a variable
     (`for p in $(PARTS)` in `cosmere-tracker`).
   - **Every Makefile has a `help` target**. Each target line carries a `## description`
     comment, and `help` prints them in colour with awk, plus a usage line and examples. Copy it
     from an existing Makefile.
   - `clean` removes exported files only, never the committed Bambu projects (`*.3mf` from
     `make project`) or `renders/`.
   - `render` depends on `project` and calls Blender through
     `BLENDER ?= blender`, `RENDER_FLAGS ?=` and
     `RENDER = $(BLENDER) -b -P ../../tools/render_studio.py --` (§3.3).
   - Select each part with `-D 'part="name"'`. Multi-colour exports use
     `--enable=lazy-union -O export-3mf/color-mode=model`.
6. **Commits**: one commit per project or change, in the style
   "Add parametric <thing> (OpenSCAD) with …".

### Local environment (verified)
| Tool | Version / path |
|---|---|
| OpenSCAD | 2026.09.23 (snapshot). **Manifold is the default backend**; `--backend=Manifold` forces it |
| Bambu Studio | 02.08.02.61, `/Applications/BambuStudio.app/Contents/MacOS/BambuStudio` |
| Blender | 5.2.2 LTS, `/Applications/Blender.app` (`blender` on the PATH); Cycles on Metal |
| System presets | `/Applications/BambuStudio.app/Contents/Resources/profiles/BBL/{machine,process,filament}` |
| Printer | `Bambu Lab P1S 0.4 nozzle`: bed 256×256, height 250, excluded area front-left `0..18 × 0..28`; the start G-code draws its nozzle load line along the front edge (`y 1..11`), so parts keep clear of `y < 12` |
| Other printer | `Bambu Lab X2D 0.4 nozzle` (`printer=X2D` in `bambu3mf.py`): bed 256×256, height 261, two nozzles; layouts keep clear the 20.5 mm left strip the right nozzle cannot reach ("Left nozzle only area"); its own `@BBL X2D` presets |
| Processes compatible with the P1S 0.4 | the `@BBL X1C` ones (0.08 Extra Fine/High Quality, 0.12 Fine/HQ, 0.16 Optimal/HQ, 0.20 Standard/Strength, 0.24 Draft, 0.28 Extra Draft) |
| Filaments | `Bambu PLA Basic @BBL P1S 0.4 nozzle`, `… PLA Matte …`, `… PLA Silk+ …`, `… PETG HF …`, `Bambu PETG Basic @BBL X1C` (the P1S uses the X1C preset), `… ABS …`, `Bambu TPU 95A HF @BBL P1S` |

---

## 2. Choosing settings by goal

### 2.1 Process preset
| Goal | Base preset | Changes on top of the base |
|---|---|---|
| General use / prototype | 0.20mm Standard | — |
| Quick prototype | 0.24mm Draft / 0.28mm Extra Draft | — |
| Visible part, balanced | 0.16mm Optimal | scarf seam, Precise wall |
| **Fine finish / display** | **0.12mm or 0.16mm High Quality** (outer wall 60 mm/s, accel 4000/2000, gyroid) | ironing on the top face, scarf seam, Precise wall |
| Miniatures / fine Z detail | 0.08mm Extra Fine / High Quality (≈2× the time of 0.20) | Arachne if there are thin strokes |
| **Functional / strong** | 0.20mm Strength (6 walls, 25 %) | suitable material (§8); temperature at the top of its range |
| Multi-colour with many changes | the thickest acceptable layer (0.20–0.28) | every extra layer is one more change (§6) |
| Vase / lampshade | Spiral vase (`spiral_mode`) + Smooth Spiral | 1 wall, no infill, no top |

### 2.2 Infill
**Walls add more strength than infill.** In CNC Kitchen's tests, 5 walls at 10 % infill were ≈22 %
stronger than 2 walls at 42 % for the same weight. Raise walls first (3–4 on functional parts), then
density. Above 40 % there is almost nothing to gain.

| Use | Density | Pattern (`sparse_infill_pattern`) |
|---|---|---|
| Decorative | 5–15 % | **Lightning** or Support Cubic (they only hold up the top skin), or gyroid at 10 % |
| General | 15–20 % | **Gyroid** or **Cross Hatch** (they never cross lines within a layer, so no nozzle scraping or vibration) |
| Functional | 25–40 % | Gyroid, Cubic or Adaptive Cubic (isotropic); Triangles or Tri-hexagon when the load is in XY |
| Maximum strength | 100 % | Rectilinear / Monotonic |
| TPU / flexible | 10–25 % | Concentric or gyroid |
| Translucent / visual effect | — | Concentric, Hilbert, Archimedean or Octagram (decorative) |

- **Grid is the presets' default and the worst for noise and scraping**, because it crosses lines
  within a layer. Switch it to gyroid or cross hatch for anything beyond a prototype.
- `infill_combination` (combine infill every N layers) saves time with gyroid or cross hatch.
- Top skin **≥0.8–1.0 mm** (`top_shell_thickness`) to avoid pillowing. Parts thinner than two
  skins plus a little infill end up solid anyway.

### 2.3 Strength and orientation (orient by load)
**Z (across the layers) is the weak direction, and every functional part is oriented for its main
load before anything else.** Design with the figures from real parts, not the data sheets: Bambu's
coupons give Z ≈ 80–90 % of XY for PLA and PETG, but CNC Kitchen's hooks printed upright held
**55 % (PLA), 46 % (PETG) and 29 % (ASA)** of the same hook printed flat. Derate anything loaded
across the layers to **50 % (PLA), 40 % (PETG), 25–30 % (ABS/ASA and any CF grade)**, and expect
about half the elongation, so it breaks suddenly. Carbon fibre adds nothing in Z (the fibres lie in
the layer), and wet nylon loses about 45 % more.

| Load | Orient so that… | Notes |
|---|---|---|
| Tension (straps, links) | the load axis lies in XY | |
| Bending, cantilevers (hooks, brackets, shelf arms, clips) | the beam and its bending plane lie in XY: hooks and brackets **on their side**, outline on the bed | The root carries the peak stress: no layer line across it. On edge is stiffer than flat |
| Wall-mounted arm with hanging weight | the plane from wall to load lies in XY (on its side) | Flat on its back puts every layer across the root, unless the arm is a short, thick plate with tiny loads (check the numbers) |
| Torsion (shafts, knobs) | a long part's axis lies in XY; a short, fat one can stand | More walls help more than orientation |
| Compression (feet, spacers, stand-offs) | any orientation | Angled loads turn into shear along the layers |
| Snap-fit | arm and deflection in XY | In Z, halve the allowed strain. Root fillet ≥0.5 × thickness, tapered arm, PETG/ABS |
| Living hinge | 2–3 flat layers, lines across the hinge axis | PETG or PP, 0.4–0.8 mm; a modifier makes the lines run across it |
| Pins, pegs, dowels in shear | lying in XY, with a flat on the bed | An upright pin snaps at a layer. If it must stand: ≥6 mm Ø, or a metal pin through it |
| Press fits, bolt holes in bearing, heat-set inserts | the hole's axis vertical | Hoop and bearing stress stay in XY. ≥2 × Ø of material to the edge, ≥4 walls. A horizontal hole splits along a layer |
| Screw pulled along its axis | the boss lying so the pull is in XY, or an insert | A vertical boss pulled up tears out between layers |
| Keyholes, hanging slots | the slot's lip loaded in XY where possible | The lip ≥2 mm; ribs behind it if the head pulls along Z |
| Impact | the blow crossing the lines, in XY | PETG/ABS over PLA, more walls, no sharp inner corners |

Inside the layer (§2.2: walls beat infill):
- Walls along the stress: 4–6 walls on functional parts. Lines along the load are far stronger
  than lines across it (Ahn 2002), so use concentric modifiers on rings, straps and hinges.
- Line width ≈0.5–0.6 mm (≈150 % of the nozzle) gives the best layer bonding. Layer height
  ≤0.2 mm; at 0.3 mm upright hooks held about half.
- Printing hotter bonds the layers: **PLA ≈230 °C, PETG ≈245 °C** for strength; the low end of
  the range for looks.
- Seams start cracks: keep them off the tension face and the root of a cantilever.
- Fillet every loaded root (≥0.5 × thickness) on vertical and top edges; bottom edges stay
  chamfered (§4.1).
- Annealing PLA adds nothing in Z and warps the part up to 10 %. Change material instead.

When the strong orientation fights printability:
1. Chamfer the overhang (45°) or add a sacrificial flat so the part can lie in the strong way.
2. **Split the part** and join it (pins, dovetails, screws, §4.6) so each piece prints strong.
3. Tilt it 30–45°: the cross-layer coupon went from 31 to 40 MPa. Below 30° it gains little.
4. If the load still crosses layers: derate (above), add ribs or gussets in XY, thicken the
  root, or run a screw or metal pin across the layers.

Every functional project's README says, per loaded part, which load it carries, how the part is
oriented for it, and the margin when the load crosses the layers.

---

## 3. The Bambu Studio project (`make project`)

Every project's `bambu_project.py` is a short description built on the shared module
`tools/bambu3mf.py`: `Project` (title, process preset, `process_overrides`, `Filament`s), one
`plate()` per plate, and `plate.add(name, load_scad(...), x, y, settings=...)` per object.
- `load_scad(scad, part, defs, rotate=(rx, ry, rz), colour=True)` exports from OpenSCAD with
  `lazy-union`, groups the triangles by colour, applies the print orientation and centres the part
  on z = 0. Pass `colour=False` for single-colour models: otherwise OpenSCAD tags uncoloured faces
  with its preview colours (#F9D72C, #9DCB51).
- Each colour becomes one *part* of the Bambu object, printed with the filament of the same colour
  (or the one given in `colour_map`).
- `plate.add()` without a position centres the object on the plate. `write()` refuses layouts
  that leave the bed, overlap each other or touch the excluded corner.
- Full settings come from running the Bambu Studio CLI on a dummy model with the system presets.
  Bed type, filament colours, flush matrix and prime tower position (per plate) are set on top.
- Plates are placed on Bambu's plate grid, so multi-plate projects open and slice correctly
  (`remote-stand` has two).
- `make report` (`python3 ../../tools/bambu3mf.py report <project>-p1s.3mf`) slices every plate with the
  CLI and prints time and grams per plate and slot. Use it for the figures in the README.

Examples: `cosmere-tracker` (multi-colour, 9 objects on one plate, explicit layout),
`remote-stand` (one plate per alternative version), `detergent-scoop` (flipped for printing).

### 3.1 How to lay out plates
- **One plate per set of filaments that share layers.** Putting parts on the same plate only
  saves when they change colour **at the same heights**. In the documented case, three striped
  parts cost 22 g printed separately and 72 g together.
- **Single-colour parts go on their own plate**, with no prime tower. If they share a colour with
  the multi-colour plate but rise above its last change, the tower has to be built up to their
  height.
- **Several identical copies on one plate amortise the changes**: changes and purge are the same
  for 1 copy as for 9.
- **Every part on a plate with a prime tower must have the same layer-height profile.** Do not mix
  variable layer height with multi-colour on the same plate.
- **Each plate with its own bed type** (`curr_bed_type` = `Textured PEI Plate`) and **By layer**
  sequence. By object does not allow a prime tower. On the P1S it also requires everything except
  the last object to be under 34 mm (rod) or 90 mm (lid), with ~68 mm spacing.
- **Prime tower outside the excluded area** (`0..18 × 0..28`) and away from tall parts.
  `cosmere-tracker` puts it at (20, 30).
- **Orient every part in the script itself**: largest flat face down; colour inlays face down
  (§6.2); no supports if the design allows it.
- **Per-object settings** go in `Metadata/model_settings.config`, inside `<object>` or `<part>`, as
  `<metadata key="<key>" value="…"/>`. Examples: more walls only on the functional part,
  `flush_into_objects` on a filler part, ironing only on the lid.
- Give objects and plates descriptive names (`plater_name`).
- In the README, list which AMS slot each filament uses, plus time and grams per plate (from
  `make report`).

### 3.2 Bambu 3MF layout (reference)
| File | Content |
|---|---|
| `3D/3dmodel.model` | objects with `<components>` pointing at `3D/Objects/object_N.model`; `<build><item transform>` = position on the plate |
| `Metadata/model_settings.config` | `<object id>` → `name`, `extruder`, per-object settings. `<part id subtype="normal_part\|modifier_part\|negative_part\|support_blocker\|support_enforcer">` → `extruder` (1-based filament) and settings. `<plate>` → `plater_id`, `plater_name`, `locked`, `bed_type`, `print_sequence`, `first_layer_print_sequence`, `other_layers_print_sequence`, `spiral_mode`, plus one `<model_instance>` per object |
| `Metadata/project_settings.config` | JSON with the full preset: `filament_colour`, `flush_volumes_matrix` (N×N mm³, row-major), `flush_multiplier`, `enable_prime_tower`, `wipe_tower_x/y`, `curr_bed_type`… |
| `Metadata/layer_heights_profile.txt` | variable layer height per object |
| `Metadata/layer_config_ranges.xml` | height-range modifiers: `<range min_z max_z><option opt_key>` |
| `Metadata/custom_gcode_per_layer.xml` | manual pauses and filament changes per layer |
| `Metadata/filament_sequence.json` | filament order per plate |

Bambu Studio usually **ignores the standard 3MF colours** exported by OpenSCAD: it splits the parts
but does not assign filaments. That is why the script sets `extruder` explicitly. Using hex colours
that match Bambu filaments makes automatic matching more likely to work.

### 3.3 Renders (Blender only)
**Every image of a model is a Blender render from `make render`** (`renders/<name>-<view>.webp`,
committed and linked from the README). No OpenSCAD renders (`openscad -o x.png`): not in the
repo, not in a README, not as a sketch to show the user. They look poor; while designing, render a
draft instead (`RENDER_FLAGS="--samples 16 --scale 0.3"`, seconds).

**Drafts first, final renders after the user confirms.** After every change to a model, render
quick drafts (`--samples 16 --scale 0.4`, seconds each) of the views that show the change into a
scratch folder, never `renders/`, and open them for the user to check by hand. Run the final
`make render` and commit `renders/` only once the user has confirmed the design: a full render
takes many minutes and is wasted if the design still changes.

What used to need a flat OpenSCAD picture is a Blender render of an OpenSCAD colour export
(`--model`):
- **Sections**: a `section` (or `cut`) parameter in the `.scad` that intersects every top-level
  object with a half-space, rendered looking at the cut face (`soap-caddy`: `--front=+x --views
  front`). A quarter cut keeps the outline and shows the inside (`tools/scad` samples).
- **In context**: the piece with what it holds or hangs on (bottle, wall, suction cups) as
  `color()`ed top-level objects. Colours that match a project filament render as that filament;
  any other colour renders as plain context with no layer lines, clear if its alpha is < 1, and
  left out of the exposure.
- **Library components** (anchors and inserts: keyholes, sockets, grooves, pegs, screws): a
  section of the parts **assembled**, cut through the side or sides where they engage, with the
  mate and the hardware (`tools/scad/catalog.scad`, `demo=`). That one image replaces a hero view.
- **Projects**: a section only when it shows how the model goes together or how its anchors
  work in the whole piece (soap-caddy on the wall, the rail's socket).
- **Profiles**: the `side` or `front` view, or `--front` set so the profile faces the camera.

`tools/render_studio.py` reads the project 3MF, so the renders match what gets printed with no
colour or layer height chosen by hand:
- **Colour and finish** from the filament each part is assigned to (`filament_colour`; Matte, Silk,
  PETG, Translucent… from the preset name; Translucent presets render clear). Multi-colour parts
  keep one material per filament.
- **Layer lines** as a sine bump with the project's `layer_height`, along the print Z.
- **Exposure and backdrop** follow the filament brightness, so black and white parts keep their
  detail.
- **Views**: hero (3/4 front), front, side, top (front edge at the bottom) and back (3/4 back).
  2400×1800 (4:3, what MakerWorld recommends), WebP at quality 90: about 30–600 KB a view, a third
  less than JPEG. ~3 min per model at 256 samples on Metal.

Options, all passed from the Makefile:
- `--plate N` (default 1) and `--objects A,B`: what to render. One plate per alternative version
  (`remote-stand`).
- `--rotate RX,RY,RZ`: from the print orientation back to the display one (`detergent-scoop` prints
  upside down: `180,0,0`). Layer lines stay with the print Z.
- `--front=-y|+y|-x|+x`: which side faces the viewer; the default `-y` is OpenSCAD's front. Write
  it with `=` (`--front=+x`), since `-x` alone reads as an option. Check the hero and top views
  of every new model.
- `--model assembly.3mf --layer-axis y`: render an OpenSCAD colour export (lazy-union) instead of a
  plate, with each colour mapped to the project filament of the same colour (other colours are
  context, above). Use it for assemblies of flat-printed parts (`cosmere-tracker`), sections and
  scenes in context, and render the plate too (`--views hero,top`).
- `RENDER_FLAGS="--samples 32 --scale 0.25"` for a draft in seconds before the final render.

MakerWorld needs **real photos** for its covers and for the ≥3 required "real photos" (front,
side, top). The renders go in "Model images".

---

## 4. Designing for FDM in OpenSCAD

### 4.1 Printable geometry
- **Overhangs ≤45°.** Good cooling reaches 55–60°, but design for 45°.
- **Bridges ≤10 mm** as a rule. The P1S usually manages 20–30 mm, but test before relying on it.
- **Slots and windows in a wall that prints standing run along the print Z, or at ≥45° to the
  bed.** A slot lying horizontal roofs over its whole length as one bridge: the soap caddy's
  side walls (frame on its back, slots across Z) came out with sagging, blobby ribs while the
  slots in the plate on the bed were clean. `wall_slots_tilted()` (`tools/scad/style.scad`)
  fills such a wall with 45° slots.
- **No slot longer than ~30 mm in a wall that prints standing** (`max_len` in `wall_slot()` and
  `wall_slots_tilted()`). The rib between two slots grows as a free column a couple of mm
  across, and its stiffness drops with the cube of its height: the soap caddy box's 76 mm slots
  came out clean up to ~35 mm and rough and stringy above, where the nozzle pushed the ribs about.
- **Tie open-fronted walls across the front.** Two side walls joined only by a back plate spread,
  and whatever rests on ledges between them drops or slides out (the soap caddy's frame). When
  the part prints on its back, a front bar is a long bridge: tie them with a plate that is
  horizontal in use (it prints as an upright wall) slotted at 45°, and stop sliding parts
  with 45° gussets in plan.
- **Horizontal holes as teardrops** (45° tip) or flat-topped teardrops. BOSL2 has `teardrop()`.
- **Bottom edges get a 45° chamfer of 0.4–0.6 mm, not a fillet.** A fillet at the bed is an
  overhang, and the chamfer hides elephant foot. Fillets go on top and vertical edges.
- **Holes that start in mid-air** (counterbores, screw heads face down): model a one-layer
  (0.2 mm) **sacrificial layer** over the hole and open it afterwards. Alternatively, Bambu's
  option to bridge counterbore holes.
- A part that does not fit the bed or would need supports: **split it** and join it with pins
  (0.1–0.2 mm clearance), dovetails or BOSL2 `joiner`.
- Avoid supports by design: chamfers, teardrops, sacrificial layers, splitting the part, and
  resting it on its largest face.

### 4.2 Dimensions tied to the nozzle and the layer
- **Wall thickness = multiple of the line width** (0.42 mm in Bambu presets): 0.84 · 1.26 ·
  1.68 mm… Avoid values in between, which produce gap fill. Minimum 0.8 mm; 1.2 mm recommended.
- **Heights and Z clearances = multiples of the layer height** (0.2 mm by default). For example,
  colour inlays of 0.6 mm = 3 layers.
- Smallest feature ≈ 2.5 × nozzle = **1.0 mm**. Below ~0.45 mm nothing prints.

### 4.3 Clearances and fits (per side)
| Fit | Clearance |
|---|---|
| Press | 0.0–0.1 mm |
| Slip (M3 → Ø3.2) | 0.2 mm |
| Running / loose | 0.3–0.5 mm (a part sliding between printed walls: 0.25; 0.4 per side measured ≈0.5 in PETG) |
| Print-in-place hinge | 0.3–0.4 mm radial; Z gap a whole number of layers (+0.1 if it is a bridge) |
| Snap-fit | 0.5 mm; arm ≥1 mm thick, ≥5 mm wide, fillet at the root; PETG/ABS/PA, never PLA |
| M3 heat-set insert | hole **Ø4.2 mm** as printed, ≥1 mm deeper than the insert, ≥1.6 mm wall around it |

- **Vertical holes print small** (≈0.25 mm). Use polyholes: `n = max(round(2*d), 3)` sides and
  radius `r / cos(180/n)`. Or add 0.1–0.3 mm. For critical fits, drill afterwards.
- Always make clearances parameters (`*_play`, `*_clearance`) so they can be tuned without
  touching the code.
- If a fit is critical, print a **clearance test piece** in 0.1 mm steps first.

### 4.4 Text
| Kind | Minimum stroke | Depth or height | Letter height |
|---|---|---|---|
| Engraved | 0.5 mm (better ≥0.8) | ≥0.5 mm | ≥5 mm |
| Embossed | 1.0 mm (better 1.5) | 0.6–0.8 mm | ≥6 mm |
| Colour inlay | ≥0.8 mm (2 lines) | 0.6 mm (3 layers) | ≥5 mm |

Use bold sans-serif fonts (`"Liberation Sans:style=Bold"`) with `halign/valign = "center"`. An
`offset(0.1)` on the 2D text thickens the strokes.

### 4.5 OpenSCAD practices
- Export resolution: `$fa = 1; $fs = 0.4;`. Use lower values in preview, driven by a parameter.
  With `$fn`, use multiples of 4 and no more than ~128.
- **Avoid coincident faces**: cutters stick out by `eps = 0.01`.
- **Customizer**: literal parameters at the top, grouped in `/* [Section] */`, internals in
  `/* [Hidden] */`. Document each parameter with a unit or range comment (`// [min:step:max]`).
- **Part selection**: `part = "all"; // [all, base, lid]` and an `if/else` over modules. The
  Makefile passes `-D 'part="lid"'`.
- **Multi-colour**: each colour must be a separate **top-level object** with its own `color()`, not
  wrapped in a shared transform, so `lazy-union` exports them separately.
- **Performance**: avoid 3D `minkowski()`. For rounded boxes use 2D `offset()` plus
  `linear_extrude()`, or `hull()` of cylinders. With Manifold renders take seconds.
- Use `offset(delta = clearance)` on the 2D profile of the mating part.
- `echo` the overall size and derived values to the console, so they can be checked without opening
  the model. If the part has a verifiable quantity (capacity, volume), add `make check` (see
  `detergent-scoop`).
- BOSL2 is useful for threads, `teardrop`, `cuboid(rounding=…)`, hinges and dovetails. If you use it,
  document the dependency in the README.
- Images come from Blender only (§3.3), never `openscad -o x.png`.

### 4.6 Functional components (`tools/scad/`)
Functional components (mounts and anchors, joints, holes and fasteners, springs, hinges,
latches, snap-fits…) are designed once, in `tools/scad/`, and used by the projects. A project
designs its own shape, never its own component.

- **Before designing one, look in `tools/scad/`** (index in
  [tools/README.md](tools/README.md#scad-the-openscad-library)): keyholes and suction-cup buttons,
  stand-off pegs, countersunk screws, diamond keys, tongues, lead-in sockets, polyholes,
  teardrops, chamfered prisms and the house style for wall pieces.
- **A component that is not there yet** (a spring, a new anchor, a hinge, a latch…) goes through
  three steps before the project uses it:
  1. **Research** how it works when printed: the geometry that works, the material, the
     orientation for its load (§2.3), clearances, fatigue and creep, and what fails first.
     Prefer tests (CNC Kitchen, papers, data sheets) to forum advice, and say which is which.
  2. **Record it in this file**: a short subsection under §4.7 with the rules, the numbers and
     the sources, so the next project starts from them.
  3. **Design it in `tools/scad/`** as parametric modules (sizes as arguments, defaults from the
     research), and its mate: every socket gets its key, every hole its pin or screw. Add both as
     printable samples to `catalog.scad`, plus a `demo` rendered **assembled and cut** through the plane
     that shows it seated, with its mate, hardware and wall (outside it is just a block on a
     block), add
     it to the tools README, and run `make render` and `make report` there. If the fit matters,
     the sample doubles as its fit test.
- Load with `use <../../tools/scad/<file>.scad>`. Modules take sizes as arguments; pass the
  project's Customizer parameters, and wrap them under another name if the project needs a
  shorthand (a project module with the library's name hides the library one).
- When a component changes, every project using it must export the same geometry as before
  (same volume and triangle count per part), or get the change on purpose and its project rebuilt.

### 4.7 Component notes
Research behind each component in `tools/scad/`, one entry per component.

- **Sliding dovetail** (`joints.scad`, from sink-organizers): a tail on a wall's edge slides
  along z into a housing on a plate and rests on its closed bottom; the wall can neither pull
  off the plate nor move along it. It hangs a body (printed standing, so it can have a front
  wall and vertical slots) on a wall plate (printed flat, the keyholes' best orientation). No
  published test of a printed sliding dovetail exists (only short dovetails in tension, which
  hold 0.5–2 kN in PLA: Demirel & Manav 2025, a Ljubljana thesis), so the defaults come from
  fit guides, this repo's measured clearances and statics; the fit test decides.
  - **Flanks at 45°**: the steepest the flat-printed housing takes as an overhang, and the
    wedge then pushes the housing apart with no more than the pull (woodworking's 10° gives
    5.7×, and turns 0.25 play into 1.4 mm of lift).
  - **Play**: 0.25 per side on the flanks (0.2–0.3 in Sovol's and Hubs' guides) and 0.35 at
    the floor came out **loose** in PETG (sink-organizers fit test, 2026-10): the tail rocked.
    Now 0.2 at the floor and the flank play from a ladder test (0.05–0.20 in one strip); the
    default 0.1 is a guess until it is printed.
  - **Head**: widening 1.26 per side, 3 deep, printed standing, came out round (outer and
    inner perimeters meet, the 45° corners fill in), so it caught little of the lip. Now 1.68
    per side (4 lines), 4 deep. Neck = the wall (1.68); lip in front of the flanks ≥1.26,
    housing wall beside the tail ≥1.68.
  - 0.8 mm 45° lead-in on the tail's tip (which also takes up its elephant foot) and the
    housing's mouth, built as layer steps (the profile is not convex, so no hull).
  - Loads are tiny (≈0.03 MPa on the lips for 5 N over 100 mm), but the housing's lips are
    pulled across the plate's layers: derate to 40 % in PETG. The tail's neck bends within
    its layers, the strong way. What fails first is the slide binding over 100–200 mm:
    the plate bowing, drooping lip overhangs, seams or blobs on the flanks. Keep seams off the
    flanks, and print a full-length fit test before the big parts.
  - A detent, if one is ever needed, must sit unloaded once seated: PETG creeps under load,
    faster when warm (UTS creep study; Polymers 2025).

- **Keyhole + button** (`mounts.scad`, from soap-caddy): the entry takes the head plus
  `play` 0.3 per side, and the slot takes the shank. A 45° countersink at the front seats a cone
  head, which pulls the piece against the button flange. Axial play `shank_play` 0.1: 0.2 left
  the seated piece a little loose front to back in PETG. The button self-taps onto an M4 stud
  through a pilot hole modelled Ø3.7 as a polyhole, with a lead-in (it prints ≈3.45). A plain
  Ø3.4 cylinder printed ≈3.15 and the stud, turned by hand with the cup, went in only 1 mm. The
  hole goes right through the button: a blind hole sized to the nominal stud stopped the
  flange ≈3 mm short of the cup. Measure the stud from the hub face (`stud_len`, 12 by
  default). Print the pad flat (the slot in XY) and the button standing; the loads are small
  and stay in compression or shear (soap-caddy README, "Strength and orientation").
- **Stand-off peg** (`mounts.scad`): a post that rests on the wall in compression. It stops a
  piece hung on two side-by-side mounts from nodding forward. It goes into a through hole
  **from behind**, its shoulder on the piece's back face, so the wall only pushes it further in.
  The first version went in from the front, under the soap caddy's sloping tray floor: there
  was no room to line a 23 mm pin up with its hole, and the hole printed loose for it anyway.
  Check that a part can actually be put in, along its whole path, not just where it ends up.
  Crush ribs on the spigot hold it when the piece is off the wall: 4 ribs, their diameter
  `rib_d` 0.2–0.5 mm over the hole by the guides, but 0.4 fell out of a PETG hole: 0.8 by
  default, tapered at the tip (community tests on Printables/Prusa and
  MakerWorld; Protolabs for the moulded origin; no FDM standard, so print one and tune
  `rib_d`). It is loaded along its axis, so it prints standing on its wall end.
- **Sprung handle** (`joints.scad`, from cutlery-drainer): a U whose arms are sprung apart by
  hand so diamond pins at their ends snap into sockets on both sides of a part. Once seated it
  cannot turn, and a pull up or forward cannot unseat it: the pins only leave if the arms are
  spread again. Rules, from Bayer's snap-fit guide, Hubs, Fictiv and the Bambu PETG data sheet
  (vendor guidance; the strain formula is beam theory):
  - **Strain to put it on** `ε = 3·s·δ / (a·(2a + 3L))` (s section depth in the plane of the U,
    δ spread per side, a arm length, L bar length; `sprung_handle_strain`). Keep it ≤1 % in
    PETG for a handle taken on and off often, ≤2 % for a one-off, ≤0.5 % in PLA. A long bar
    spreads easily; deepen the section only for stiffness.
  - **No preload once seated**: the arms' free spacing is the part's width plus clearance. PETG
    creeps under constant load, and hot water (≈60 °C, Tg 68 °C) sets a preloaded shape.
  - Pins 3–5 mm long, lead-in chamfer on the tip and the socket mouth, clearance 0.15–0.3 mm
    per side. Diamond pins stop rotation and print without support both lying flat (in the
    handle) and with their axis horizontal (in the part).
  - Print the U flat, so it flexes and carries the load along XY. Inside corner radius ≥ the
    section; nothing on the outer face of the bar, which is at peak strain along its length.
 a square key turned 45° prints on
  its side with no overhang past 45°. Socket play 0.15 per side is a slip fit and 0.05 a press
  fit in PLA.

---

## 5. Fine finishes and variable resolution

### 5.1 Surface quality
| Setting | Recommendation |
|---|---|
| **Scarf seam** | In the process, enable "Override filament scarf seam setting" (`override_filament_scarf_seam_setting`), then `seam_slope_type` = Contour (`external`), "Smart scarf" on (`seam_slope_conditional`), length 10 mm, 10 steps. It is off in Bambu filament presets. If it leaves gaps, slow the outer wall to ~40 mm/s |
| Seam position | `seam_position` = aligned (default) or back. Can be painted by hand |
| **Precise wall** | `precise_outer_wall` = 1, with Inner/Outer wall order |
| Wall order | Inner/Outer (best for overhangs) · Outer/Inner (most accurate outer surface, worse overhangs) · Inner/Outer/Inner (avoids marks on the outer wall) (`wall_sequence`) |
| Wall generator | **Classic** (one continuous loop, best surface). **Arachne** when there are thin strokes or small text on the first layer (`wall_generator`) |
| **Ironing** on flat tops | `ironing_type` = Topmost surface, rectilinear pattern, flow 10–15 %, spacing 0.1–0.15 mm, speed 30 mm/s, inset ~0.2. Only helps on flat top faces; apply it per object |
| Top pattern | Monotonic line (default). Concentric on round tops |
| High visual quality | *High Quality* presets: outer wall at 60 mm/s, low acceleration |
| Tall smooth walls (silk, gloss) | "Smoothing wall speed along Z" (`z_direction_outwall_speed_continuous`) |
| Textured feel | Fuzzy skin (`fuzzy_skin` = Contour, 0.3 mm / 0.8 mm), or painted by area |
| Exact Z | `precise_z_height` = 1 when total height matters (adjusts the last 5 layers) |
| Timelapse | Smooth leaves no marks but forces a prime tower. Keep Traditional for single-colour parts |

### 5.2 Variable layer height
- **Variable layer height** tool: *Adaptive* (detail ↔ speed slider), then *Smooth* (radius 5–10).
  Thin layers on gentle curves, domes and shallow slopes; thick layers on vertical walls. Stored in
  `Metadata/layer_heights_profile.txt`.
- Range on the P1S 0.4: 0.08–0.28 mm.
- **Incompatible with a prime tower unless every part on the plate has the same profile.**
  Multi-colour parts use a fixed layer height; single-colour parts with variable layers go on their
  own plate.
- If only one band needs detail, use a **Height range modifier** (`layer_config_ranges.xml`) with a
  different layer height or more walls.
- With variable layer height, Tree Organic supports are not used; it switches to Tree Hybrid
  automatically.

### 5.3 First layer and the textured plate
- The texture transfers to the bottom face. **Put the face you want "finished" down**: lids, labels
  or inlays face down come out with an even matte finish, no ironing needed.
- Elephant foot: 0.15 mm in the presets (`elefant_foot_compensation`), plus a chamfer in the model.
  **Set it to 0 when there are colour details or thin strokes on the first layer**, because it
  shrinks them (as `cosmere-tracker` does).
- Adhesion: the textured plate needs no glue for PLA/ABS/TPU. **With PETG use a glue stick as a
  release layer**, because it bonds too well. Let it cool to ≤35 °C and flex the plate to remove the
  part.
- Cleaning: warm water with dish soap and a brush. IPA only spreads grease around. Never acetone.
- Small contact area or tall, narrow part: Auto **brim** (`brim_type`), or painted *mouse ears* on
  the corners (`brim_ears`). `brim_object_gap` 0.1 mm.

---

## 6. Multi-colour (AMS)

### 6.1 What a change costs
- Each change: cut, unload and load (≈57 s per the preset) plus purge plus the tower, so
  **≈60–90 s and ≈0.3–0.6 g**. 150 changes are about 3 h and ~80 g.
- Changes per layer = colours on that layer minus one. **Cutting the number of multi-colour layers
  saves the most.**
- Dark to light purges much more than light to dark.
- The tower prints from layer 1 up to the layer of the **last change**. If the changes are only at
  the top, the whole tower is wasted filament.

### 6.2 Design patterns for multi-colour
1. **Colour only on the first layers, face down.** The preferred pattern: text, logos and 0.6 mm
   flush inlays on the face that sits on the textured plate. The tower ends after 3–4 layers and the
   rest of the part is single-colour. `cosmere-tracker` does this.
2. **Flush inlay** (0.4–0.6 mm = 2–3 layers) rather than embossed text: it adds no height and keeps
   the changes to a few layers.
3. If the colour has to be on top, keep it to the **last 2–3 layers**. If possible, flip the part to
   bring it to the bottom (in the documented case the tower shrank by 40 %).
4. **Horizontal colour boundaries**, on natural steps in the geometry. A vertical boundary that
   spans many layers multiplies the changes.
5. **Separate parts per colour** when the design allows it (lids, trims, parts that assemble): zero
   changes and zero purge. The best option when assembly is trivial.
6. Minimum width of colour regions: ≥0.8 mm (2 lines). Below ~5 mm the boundary may not come out
   clean.
7. Same material for every colour (PLA with PLA). When mixing materials (TPU with PETG), enable
   **Use beam interlocking** (`interlocking_beam`), which only works between parts of the same object.

### 6.3 Purge settings (project)
- `flush_volumes_matrix`: the script computes it from the colours' luminance (see `flush()` in
  `cosmere-tracker`). `flush_multiplier` 0.8–0.9 to save filament; check that no layers come out
  contaminated.
- **Flush into objects' infill** (`flush_into_infill`) only with opaque, dark outer colours and
  ≥3 walls. **Flush into this object** (`flush_into_objects`) on a useful single-colour part about as
  tall as the multi-colour one (in the wiki example, from 70 g to <1 g).
- Prime tower v2 (rib wall) is on by default. To save filament, raise `prime_tower_infill_gap`
  from 150 to 200 %.
- **Filament order per plate**: Plate Settings → "Other layers filament sequence" on Auto
  (minimises purge), or manual, light to dark.
- Without the AMS (or for a single change per height): *Add pause* or *Change filament* on the
  Preview layer slider (stored in `custom_gcode_per_layer.xml`).
- Bambu Studio workflow: when importing several parts, answer **"Yes" to loading them as one object
  with multiple parts**. Assign filaments with keys 1–9. The colour painting tool has "Gap Fill" to
  clean up tiny islands that cause pointless changes.

---

## 7. Supports
- Type `tree(auto)` by default. Hybrid under large flat overhangs.
- Top Z distance = one layer height (0.2 mm) with the same material.
- **PLA ↔ PETG interface trick**: they barely bond to each other. Use the other material **only for
  the interface** (`support_interface_filament`) with Top Z distance 0 for an almost smooth
  surface. Keep the door open.
- Paint enforcers and blockers instead of raising the global threshold. Better still, design so
  they are not needed (§4.1).

---

## 8. Materials on the P1S (textured plate)
| Material | Nozzle | Bed (textured) | Door / lid | Use |
|---|---|---|---|---|
| PLA Basic / Matte | 220 °C | 55 °C | **Open, or lid raised** (heat creep) | Decorative, indoor, the stiffest; softens at ~55 °C |
| PLA Silk+ | 230 °C | 55 °C | Open | Glossy decorative; max 12 mm³/s |
| PETG HF | 245 °C | 70 °C + glue as release | Closed is usually fine | Functional, snap-fits, mild outdoor use, borderline in a dishwasher |
| ABS / ASA | 270 °C | 90 / 100 °C | **Closed** | Heat (car), UV outdoors (ASA), higher impact |
| TPU 95A HF | 230 °C | 35 °C | Open | Flexible; **cannot go through the AMS** |

- **Car interior**: ASA, ABS, PC or PA-CF. PLA and PETG deform.
- **Food contact**: layer grooves trap bacteria; occasional use only, or with a food-safe coating,
  and a stainless steel nozzle (the P1S's is).
- Drying: PLA 55 °C 8 h · PETG 65–70 °C 8 h · ABS/ASA 80 °C 8 h.

## 9. Calibration (the P1S has no lidar, so everything is manual)
- **Flow Dynamics (K)**: Calibration → Manual → Pattern. Save the value per filament and AMS slot.
  PLA usually lands at ≈0.02–0.03. Repeat for every new filament or nozzle change.
- **Flow rate**: coarse pass, then fine. With Bambu filaments it can usually be skipped (presets:
  PLA 0.98, PETG 0.95).
- **Elephant foot**: 25 mm cube with no brim and compensation 0; measure bottom and top.
- For critical fits, print a clearance test piece before fixing the `.scad` defaults.

---

## 10. New project checklist
- [ ] Functional components from `tools/scad/`; a new one researched, recorded (§4.7) and added there first (§4.6).
- [ ] Parametric `.scad`: Customizer sections, `part` selector, `echo` of the size, clearances as
      parameters.
- [ ] Every interface with bought hardware or with another printed part has a fit test plate
      that tests the real thing (the button on the cup's stud, the peg in the piece's hole),
      designed against measured hardware, not its nominal size. Check how each part goes in,
      along its whole path, not only where it ends up.
- [ ] Each loaded part oriented for its load (§2.3), with the margin noted in the README.
- [ ] Designed to print without supports: overhangs ≤45°, chamfered base, teardrops and sacrificial
      layers where needed.
- [ ] Walls in multiples of 0.42 mm; heights and inlays in multiples of 0.2 mm.
- [ ] Colour: can it go on the first layers or on separate parts? Strokes ≥0.8 mm?
- [ ] Process preset chosen by goal (§2.1). Infill and walls by use (§2.2).
- [ ] `bambu_project.py`: plates grouped per §3.1, orientation, filaments, Textured PEI bed, tower
      outside the excluded area, per-object settings.
- [ ] `make report` slices every plate without errors. Note time and grams in the README.
- [ ] `Makefile` with phony, always-regenerating targets, `project`, `report`, `render` and `help`
      (§1.5).
- [ ] `make render`: check the orientation in the hero and top views (§3.3) and commit `renders/`.
- [ ] `README.md` (commands, parts table, printing, assembly, renders), `.gitignore`, the committed
      Bambu project(s), row with the hero thumbnail in the root README.
- [ ] Everything written in English (§1).

## Main sources
Bambu Lab Wiki (wiki.bambulab.com: plates, multi-color printing, reduce wasting during filament
change, prime tower, adaptive layer height, ironing, seam, wall generator, support, sequent print,
calibration), BambuStudio source code (`PrintConfig.cpp`, `bbs_3mf.cpp`, BBL presets), the local
Bambu Studio 02.08.02.61 install, CNC Kitchen (walls vs infill, PLA vs PETG vs ASA hooks, 45° orientation, extrusion width, layer height, temperature, annealing, inserts), Bambu filament TDS (XY vs Z), Ahn et al. 2002 (raster direction),
Prusa Knowledge Base, OrcaSlicer wiki (infill patterns), Hubs (FDM design, snap-fits), OpenSCAD
manual.
