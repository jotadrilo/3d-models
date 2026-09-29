# Detergent scoop

Rounded-rectangle measuring scoop that holds exactly `capacity_ml` (190 ml by
default) up to an engraved fill line. The cup depth is solved from the
capacity and the footprint, bottom fillet included, so the measure stays exact
whatever you change. A collar under the floor fits over the bottle cap, so the
scoop can be stored sitting on top of the bottle.

```sh
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

Print it upside down, rim and handle on the bed: no supports needed.
