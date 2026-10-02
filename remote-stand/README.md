# Remote stand

Two-row stepped box for TV remotes: the front row is lower and the back row
sits on a raised floor, so every remote stays visible. Two finishes of the
same body:

![Remote stand v1](renders/remote-stand-hero.webp)

- `remote-stand.scad` (v1): rounded ribs all around the body and the step.
- `remote-stand-v2.scad` (v2): flush walls with narrow channels cut into
  them, under a smooth rounded rim.

```sh
make project                                   # -> remote-stand-p1s.3mf (Bambu Studio, ready to print)
make report                                    # rebuild it, slice it, print time and filament per plate
make                                           # -> remote-stand.stl + remote-stand-v2.stl
make v2 DEFS='-D back_count=3 -D back_remote_w=45'
make preview                                   # -> remote-stand.png + remote-stand-v2.png (OpenSCAD)
make render                                    # -> renders/*.webp, studio views with Blender
make help                                      # every target
```

Set the number of remotes per row and the widest and thickest remote of each
row (`front_*`, `back_*`); `clearance` is added to every pocket. The console
prints the footprint (about 133 x 77 x 95 mm by default). The base has
optional dust holes and recesses for adhesive rubber feet.

## Printing (Bambu P1S)

`make project` builds `remote-stand-p1s.3mf`, a Bambu Studio project with one
plate per version (print whichever one you want), each standing upright on a
Textured PEI plate: P1S 0.4 nozzle, *0.20mm Standard* with the seam at the
back, Bambu PLA Basic in slot 1. No supports needed. With the default
parameters v1 takes about 4 h 20 min and 156 g, v2 about 5 h 35 min and
169 g. It needs Bambu Studio installed.

## Renders

`make render` builds the project and renders studio views of each stand with
Blender (`../tools/render_studio.py`), in the filament colour and with layer
lines at the project's layer height. 2400 x 1800 WebP, ready for MakerWorld's
model images; add `RENDER_FLAGS="--samples 32 --scale 0.25"` for a quick draft.

| | Hero | Front | Side | Top | Back |
|---|---|---|---|---|---|
| v1 | ![](renders/remote-stand-hero.webp) | ![](renders/remote-stand-front.webp) | ![](renders/remote-stand-side.webp) | ![](renders/remote-stand-top.webp) | ![](renders/remote-stand-back.webp) |
| v2 | ![](renders/remote-stand-v2-hero.webp) | ![](renders/remote-stand-v2-front.webp) | ![](renders/remote-stand-v2-side.webp) | ![](renders/remote-stand-v2-top.webp) | ![](renders/remote-stand-v2-back.webp) |

OpenSCAD previews (`make preview`): [v1](remote-stand.png) · [v2](remote-stand-v2.png).
