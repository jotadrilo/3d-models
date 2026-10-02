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
4. **Project folder layout**:
   ```
   <project>/
     <project>.scad        # parametric model, Customizer parameters at the top
     Makefile              # all / stl / 3mf / project / report / preview / render / clean / help (+ check)
     bambu_project.py      # builds <project>-p1s.3mf with tools/bambu3mf.py (§3)
     README.md             # what it is, make commands, parts table, how to print, assembly
     .gitignore            # *.3mf, *.stl (build outputs are not committed; previews and renders are)
     <project>*.png        # OpenSCAD preview(s), `make preview`
     renders/<name>-<view>.webp   # studio renders, `make render` (§3.3), linked from the README
   ```
   The root `.gitignore` already ignores macOS metadata (`.DS_Store`, `._*`) everywhere.
   Add the project to the root `README.md` with one line. Shared code lives in `tools/`.
5. **Makefile**:
   - `OPENSCAD ?= openscad`, `OPENSCAD_FLAGS ?=` and `DEFS ?=` for overrides
     (`make DEFS='-D x=1'`), combined in `SCAD = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)`.
   - **Every target is `.PHONY` and always regenerates its files**, even when they already exist
     on disk. Targets are named by what they do (`stl`, `3mf`, `project`, `preview`, `render`, `check`),
     not by the file they produce. No pattern rules (`%.stl`) and no `FORCE` prerequisites:
     hardcode the file names in the recipe, or loop over a variable
     (`for p in $(PARTS)` in `cosmere-tracker`).
   - **Every Makefile has a `help` target**. Each target line carries a `## description`
     comment, and `help` prints them in colour with awk, plus a usage line and examples. Copy it
     from an existing Makefile.
   - `clean` removes exported files only, never the committed previews or `renders/`.
   - `render` depends on `project` and calls Blender through
     `BLENDER ?= blender`, `RENDER_FLAGS ?=` and
     `RENDER = $(BLENDER) -b -P ../tools/render_studio.py --` (§3.3).
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
| Printer | `Bambu Lab P1S 0.4 nozzle`: bed 256×256, height 250, excluded area front-left `0..18 × 0..28` |
| Processes compatible with the P1S 0.4 | the `@BBL X1C` ones (0.08 Extra Fine/High Quality, 0.12 Fine/HQ, 0.16 Optimal/HQ, 0.20 Standard/Strength, 0.24 Draft, 0.28 Extra Draft) |
| Filaments | `Bambu PLA Basic @BBL P1S 0.4 nozzle`, `… PLA Matte …`, `… PLA Silk+ …`, `… PETG HF …`, `… ABS …`, `Bambu TPU 95A HF @BBL P1S` |

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

### 2.3 Strength and orientation
- **Z is the weak direction.** Layer adhesion gives 55 % of the XY strength in PLA, 46 % in PETG
  and 29 % in ASA. Orient parts so tensile and bending loads run in XY. Hooks and snap-fits must
  never have their length along Z.
- Printing hotter improves layer adhesion: PLA ≈230 °C and PETG ≈245 °C for maximum strength.
  Use the low end of the range for looks.
- Annealing PLA is only worth it for heat resistance: Z strength does not change and the part warps.

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
- `make report` (`python3 tools/bambu3mf.py report <project>-p1s.3mf`) slices every plate with the
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

### 3.3 Previews and renders
Every project has two kinds of images, both committed and both linked from its README:

| | `make preview` | `make render` |
|---|---|---|
| What | OpenSCAD render, preview colours | Photoreal "as printed" studio shots (Blender Cycles) |
| Source | the `.scad` | the Bambu project `<project>-p1s.3mf` |
| Output | `<project>*.png` next to the `.scad` | `renders/<name>-<view>.webp` |
| Use | quick look while designing | README hero image, MakerWorld model images |

`tools/render_studio.py` reads the project 3MF, so the renders match what gets printed with no
colour or layer height chosen by hand:
- **Colour and finish** from the filament each part is assigned to (`filament_colour`; Matte, Silk,
  PETG… from the preset name). Multi-colour parts keep one material per filament.
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
- `--front -y|+y|-x|+x`: which side faces the viewer; the default `-y` is OpenSCAD's front.
  Check the hero and top views of every new model.
- `--model assembly.3mf --layer-axis y`: render an OpenSCAD colour export (lazy-union) instead of a
  plate, with each colour mapped to the project filament of the same colour. Use it for assemblies
  of flat-printed parts (`cosmere-tracker`), and render the plate too (`--views hero,top`).
- `RENDER_FLAGS="--samples 32 --scale 0.25"` for a draft in seconds before the final render.

MakerWorld needs **real photos** for its covers and for the ≥3 required "real photos" (front,
side, top). The renders go in "Model images".

---

## 4. Designing for FDM in OpenSCAD

### 4.1 Printable geometry
- **Overhangs ≤45°.** Good cooling reaches 55–60°, but design for 45°.
- **Bridges ≤10 mm** as a rule. The P1S usually manages 20–30 mm, but test before relying on it.
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
| Running / loose | 0.3–0.5 mm |
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
- Preview from the CLI:
  `openscad --render --imgsize=1400,900 --colorscheme=Tomorrow --camera=… -o x.png x.scad`.

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
- [ ] Parametric `.scad`: Customizer sections, `part` selector, `echo` of the size, clearances as
      parameters.
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
- [ ] `README.md` (commands, parts table, printing, assembly, renders), `.gitignore`, preview PNG,
      entry in the root README.
- [ ] Everything written in English (§1).

## Main sources
Bambu Lab Wiki (wiki.bambulab.com: plates, multi-color printing, reduce wasting during filament
change, prime tower, adaptive layer height, ironing, seam, wall generator, support, sequent print,
calibration), BambuStudio source code (`PrintConfig.cpp`, `bbs_3mf.cpp`, BBL presets), the local
Bambu Studio 02.08.02.61 install, CNC Kitchen (walls vs infill, temperature, annealing, inserts),
Prusa Knowledge Base, OrcaSlicer wiki (infill patterns), Hubs (FDM design, snap-fits), OpenSCAD
manual.
