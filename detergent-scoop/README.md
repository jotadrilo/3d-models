# Detergent scoop

Rounded-rectangle measuring scoop that holds exactly `capacity_ml` (190 ml by
default) up to an engraved fill line. The cup depth is solved from the
capacity and the footprint, bottom fillet included, so the measure stays exact
whatever you change. A collar under the floor fits over the bottle cap, so the
scoop can be stored sitting on top of the bottle.

```sh
make project                                   # -> detergent-scoop-p1s.3mf (Bambu Studio, ready to print)
make report                                    # rebuild it, slice it, print time and filament
make                                           # -> detergent-scoop.stl
make DEFS='-D cap_d=38'                        # fit it to your bottle cap
make DEFS='-D capacity_ml=150 -D inner_l=65'
make check                                     # prints the real cavity volume
make OPENSCAD_FLAGS=--backend=Manifold         # OpenSCAD >= 2025, much faster
make preview                                   # -> detergent-scoop.png
```

Measure the widest point of your bottle cap and set `cap_d`; `cap_clearance`
and the small `grip_ribs` inside the collar set how snug it sits. If the
collar is wider than the cup, the cup width grows to fit it (the depth is then
recalculated). The console prints the fill-line height and total size.

## Printing (Bambu P1S)

`make project` builds `detergent-scoop-p1s.3mf`, a Bambu Studio project with
the scoop already upside down (rim and handle on the bed, collar on top) on a
Textured PEI plate: P1S 0.4 nozzle, *0.20mm Standard* with gyroid infill,
Bambu PLA Basic in slot 1. No supports needed. About 1 h and 49 g with the
default parameters (`make report` prints the figures for your parameters). It
needs Bambu Studio installed.

The floor of the cup prints as a bridge over the cavity. For a detergent that
is harsh on PLA, switch the filament to PETG HF in Bambu Studio.
