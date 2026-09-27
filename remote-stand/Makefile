# Export the remote stands to STL from the command line.
#
#   make                         -> remote-stand.stl + remote-stand-v2.stl
#   make v1 / make v2            -> just one of them
#   make preview                 -> remote-stand.png + remote-stand-v2.png (quick render)
#   make v2 DEFS='-D lattice_pitch=4 -D strand_w=1'    -> override parameters
#   make OPENSCAD_FLAGS=--backend=Manifold             -> much faster on OpenSCAD >= 2025
#                                                         (nightlies: --enable=manifold)

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
MODELS         := remote-stand remote-stand-v2

.PHONY: all stl v1 v2 preview clean

all: stl

stl: $(MODELS:=.stl)

v1: remote-stand.stl
v2: remote-stand-v2.stl

%.stl: %.scad
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) -o $@ $<

preview: $(MODELS:=.png)

%.png: %.scad
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) --render --imgsize=1200,900 --camera=70,27,40,60,0,25,380 -o $@ $<

clean:
	rm -f $(MODELS:=.stl) $(MODELS:=.png)
