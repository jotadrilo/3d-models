# Export the detergent scoop to STL from the command line.
#
#   make                         -> detergent-scoop.stl
#   make preview                 -> detergent-scoop.png (quick render)
#   make check                   -> prints the volume of the cavity up to the fill line
#   make DEFS='-D capacity_ml=150 -D cap_d=38'         -> override parameters
#   make OPENSCAD_FLAGS=--backend=Manifold             -> much faster on OpenSCAD >= 2025
#                                                         (nightlies: --enable=manifold)

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := detergent-scoop.scad

.PHONY: all stl preview check clean

all: stl

stl: detergent-scoop.stl

detergent-scoop.stl: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) -o $@ $<

preview: detergent-scoop.png

detergent-scoop.png: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) --render --imgsize=1200,900 --camera=30,0,30,55,0,30,300 -o $@ $<

check: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) -D 'part="cavity"' --export-format=asciistl -o cavity.stl $<
	@awk '/vertex/ { v[n++] = $$2" "$$3" "$$4 } \
	     n == 3 { split(v[0], a); split(v[1], b); split(v[2], c); \
	              V += a[1]*(b[2]*c[3]-b[3]*c[2]) - a[2]*(b[1]*c[3]-b[3]*c[1]) + a[3]*(b[1]*c[2]-b[2]*c[1]); n = 0 } \
	     END { printf "Cavity volume up to the fill line: %.2f ml\n", V / 6000 }' cavity.stl
	@rm -f cavity.stl

clean:
	rm -f detergent-scoop.stl detergent-scoop.png cavity.stl
