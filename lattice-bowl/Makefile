# Export the lattice bowl to STL from the command line.
#
#   make                         -> lattice_bowl.stl
#   make preview                 -> lattice_bowl.png (quick render)
#   make DEFS='-D top_diameter=200 -D rod_width=2.5'   -> override parameters
#   make OPENSCAD_FLAGS=--backend=Manifold             -> much faster on OpenSCAD >= 2025
#                                                         (nightlies: --enable=manifold)

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := lattice_bowl.scad

.PHONY: all stl preview clean

all: stl

stl: lattice_bowl.stl

lattice_bowl.stl: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) -o $@ $<

preview: lattice_bowl.png

lattice_bowl.png: $(SRC)
	$(OPENSCAD) $(DEFS) --render --imgsize=1200,900 --camera=0,0,40,55,0,25,420 -o $@ $<

clean:
	rm -f lattice_bowl.stl lattice_bowl.png
