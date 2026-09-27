# Export the remote stand to STL from the command line.
#
#   make                         -> remote-stand.stl
#   make preview                 -> remote-stand.png (quick render)
#   make DEFS='-D front_remote_w=45 -D back_count=3'   -> override parameters
#   make OPENSCAD_FLAGS=--backend=Manifold             -> much faster on OpenSCAD >= 2025
#                                                         (nightlies: --enable=manifold)

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := remote-stand.scad

.PHONY: all stl preview clean

all: stl

stl: remote-stand.stl

remote-stand.stl: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) -o $@ $<

preview: remote-stand.png

remote-stand.png: $(SRC)
	$(OPENSCAD) $(DEFS) --render --imgsize=1200,900 --camera=70,27,40,60,0,25,380 -o $@ $<

clean:
	rm -f remote-stand.stl remote-stand.png
