# Export the Cosmere tracker parts from the command line.
#
#   make                          -> frame.3mf front.3mf wheels.3mf stand.3mf
#                                    (multi-colour: one part per colour, for the AMS)
#   make project                  -> cosmere-tracker-p1s.3mf: Bambu Studio project, every
#                                    part on one P1S plate with its filaments assigned
#   make stl                      -> the same parts as single-colour STLs
#   make preview                  -> cosmere-tracker-front.png / -back.png
#   make DEFS='-D show_investiture=false -D digit_h=6'   -> override parameters

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := cosmere-tracker.scad
PARTS          := frame front wheels stand

# lazy-union keeps every colour as its own object in the 3MF.
LAZY := --enable=lazy-union -O export-3mf/color-mode=model

.PHONY: all 3mf stl project preview clean

all: 3mf

3mf: $(PARTS:%=%.3mf)

stl: $(PARTS:%=%.stl)

project: cosmere-tracker-p1s.3mf

cosmere-tracker-p1s.3mf: $(SRC) bambu_project.py
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o $@ $(DEFS)

%.3mf: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(LAZY) $(DEFS) -D 'part="$*"' -o $@ $<

%.stl: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) -D 'part="$*"' -o $@ $<

preview: cosmere-tracker-front.png cosmere-tracker-back.png

cosmere-tracker-front.png: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) --render --imgsize=1400,700 --projection=o \
		--colorscheme=Tomorrow --camera=0,-400,32,0,0,32 -o $@ $<

cosmere-tracker-back.png: $(SRC)
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS) --render --imgsize=1400,700 --projection=o \
		--colorscheme=Tomorrow --camera=0,400,32,0,0,32 -o $@ $<

clean:
	rm -f cosmere-tracker-p1s.3mf $(PARTS:%=%.3mf) $(PARTS:%=%.stl) cosmere-tracker-front.png cosmere-tracker-back.png
