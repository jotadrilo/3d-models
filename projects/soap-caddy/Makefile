# Soap caddy: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
PARTS          ?= upper lower button test_keyhole
SRC            := soap-caddy.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
VIEW           := --render --imgsize=1400,1100 --colorscheme=Tomorrow

.DEFAULT_GOAL := all
.PHONY: all stl project report preview render clean help

all: stl ## Build everything (same as stl)

stl: ## Export each part in PARTS as an STL (lower as modelled: lay it on its back to print)
	@set -e; for p in $(PARTS); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o $$p.stl $(SRC)"; \
		$(SCAD) -D "part=\"$$p\"" -o $$p.stl $(SRC); \
	done

project: ## Build soap-caddy-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o soap-caddy-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report soap-caddy-p1s.3mf

preview: ## Render soap-caddy.png (on the wall, with bottle and sponge) and soap-caddy-side.png (profile)
	$(SCAD) $(VIEW) --camera=0,-40,120,62,0,325,900 -o soap-caddy.png $(SRC)
	$(SCAD) $(VIEW) --projection=o --camera=0,-40,120,90,0,270,700 -o soap-caddy-side.png $(SRC)

render: project ## Render the caddy on the wall and the print plate into renders/ with Blender, in the project's filament
	mkdir -p renders
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'show_items=false' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy --model assembly.3mf $(RENDER_FLAGS)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-parts --views hero,top $(RENDER_FLAGS)
	rm -f assembly.3mf

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f assembly.3mf $(PARTS:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PARTS="upper lower ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project DEFS="-D bottle_w=80 -D bottle_d=54 -D neck_d=32"\n  make project DEFS="-D cup_h=10 -D sink_dist=120"\n  make report\n  make stl PARTS="test_keyhole button"   # keyhole fit test only\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
