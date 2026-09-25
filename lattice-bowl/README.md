# Lattice bowl

Parametric decorative bowl with a diagonal lattice of diamond openings that
follow the wall curvature. Printable without supports.

```sh
make                                           # -> lattice_bowl.stl
make DEFS='-D top_diameter=200 -D rod_width=2.5'
make OPENSCAD_FLAGS=--backend=Manifold         # OpenSCAD >= 2025, much faster
make preview                                   # -> lattice_bowl.png
# or directly:
openscad -o lattice_bowl.stl lattice_bowl.scad
```

All parameters are at the top of `lattice_bowl.scad` (also editable from the
OpenSCAD Customizer). The console prints the number of rows/columns, the
maximum wall tilt, and the minimum overhang angle, with a warning if any of
them is out of the safe range for support-free printing.
