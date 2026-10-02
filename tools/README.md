# tools

Shared scripts used by every project's Makefile. With them, a project only needs its `.scad`, a
short `bambu_project.py` and a Makefile; without them, each project would have to be set up by hand
in Bambu Studio (plates, filaments, orientation, settings) and photographed by hand.

| Script | Used by | Does |
|---|---|---|
| [`bambu3mf.py`](bambu3mf.py) | `make project`, `make report` | Builds the ready-to-print Bambu Studio project `<project>-p1s.3mf` from the OpenSCAD model, and slices it to report time and grams |
| [`render_studio.py`](render_studio.py) | `make render` | Photoreal "as printed" studio renders of that project in Blender Cycles |

Requirements: Python 3, OpenSCAD, Bambu Studio and Blender (versions and paths in
[CLAUDE.md](../CLAUDE.md#local-environment-verified)).

## `bambu3mf.py`

Bambu Studio cannot turn an OpenSCAD export into a print-ready project on its own: it splits the
colours into parts but does not assign filaments, and it knows nothing about orientation, layout or
per-object settings. This module does that work:

- **Exports from OpenSCAD** (`load_scad`) with `lazy-union` and groups the triangles by colour.
  Each colour becomes one part of the Bambu object, assigned to the filament of the same colour (or
  the one given in `colour_map`).
- **Applies the print orientation** (`rotate=(rx, ry, rz)`) and rests the part on z = 0.
- **Lays out the plates** of the P1S: refuses objects that leave the bed, overlap each other or
  touch the excluded front-left corner (`0..18 × 0..28`), and places plates on Bambu's grid so
  multi-plate projects open and slice correctly.
- **Fills in the full settings** by running the Bambu Studio CLI with the system presets, then sets
  the Textured PEI plate, filament colours, the flush matrix (from the colours' luminance) and the
  prime tower position per plate.
- **Writes per-object settings** (walls, ironing…) to `Metadata/model_settings.config`.

A project's `bambu_project.py` is then a short description:

```python
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
from bambu3mf import PLA_MATTE, Filament, Project, load_scad

proj = Project("Detergent scoop", process="0.20mm Standard @BBL X1C",
               filaments=[Filament(PLA_MATTE, "#A3D8E1")],
               process_overrides={"sparse_infill_pattern": "gyroid"})
scoop = load_scad("detergent-scoop.scad", "scoop", rotate=(180, 0, 0), colour=False)
proj.plate("Detergent scoop").add("Detergent scoop", scoop)
proj.write("detergent-scoop-p1s.3mf")
```

Main pieces:

| | |
|---|---|
| `load_scad(scad, part, defs, rotate, colour=True)` | Mesh grouped by colour. `colour=False` for single-colour models (otherwise uncoloured faces get OpenSCAD's preview colours) |
| `Project(title, process, filaments, process_overrides, colour_map)` | Process preset name, `Filament(preset, "#RRGGBB")` list (slot order) |
| `proj.plate(name, prime_tower=(20, 30))` | New plate |
| `plate.add(name, mesh, x, y, settings={...})` | Object centred at (x, y), default the plate centre; `settings` are per-object overrides |
| `proj.write(path)` | Checks the layout and writes the 3MF |
| `PLA_BASIC`, `PLA_MATTE`, `PETG_HF` | Filament preset names for the P1S 0.4 |

Run as a script to slice every plate and print time and grams per plate and slot (the figures in
each README):

```sh
python3 tools/bambu3mf.py report <project>/<project>-p1s.3mf
```

Environment overrides: `OPENSCAD`, `BAMBU_STUDIO`, `BAMBU_PROFILES`.

## `render_studio.py`

Reads the project 3MF, so the renders show exactly what gets printed, with no colour or layer
height picked by hand:

- each part in the **colour and finish** of its filament (Matte, Silk, PETG… from the preset name);
- **layer lines** at the project's layer height, along the print Z;
- **exposure and backdrop** that follow the filament brightness, so black and white parts keep
  their detail;
- views hero, front, side, top and back, 2400×1800 WebP, written to `renders/<name>-<view>.webp`.

```sh
blender -b -P tools/render_studio.py -- <project>-p1s.3mf renders/<name> [options]
```

| Option | |
|---|---|
| `--plate N` | Plate to render, 1-based (default 1) |
| `--objects A,B` | Only these objects of the plate |
| `--rotate RX,RY,RZ` | From the print orientation back to the display one (e.g. `180,0,0` for a part printed upside down) |
| `--front -y\|+y\|-x\|+x` | Side that faces the viewer (default `-y`, OpenSCAD's front) |
| `--model FILE --layer-axis y` | Render an OpenSCAD colour export (e.g. an assembly) instead of a plate |
| `--views a,b` | Subset of `hero,front,side,top,back` |
| `--samples N`, `--scale F` | Quality; `--samples 32 --scale 0.25` for a draft in seconds |

The Makefiles call it through `make render`, passing extra options with `RENDER_FLAGS`.
See [CLAUDE.md §3](../CLAUDE.md#3-the-bambu-studio-project-make-project) for the full conventions.
