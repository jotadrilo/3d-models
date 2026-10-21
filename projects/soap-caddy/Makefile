# Soap caddy: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
PARTS          ?= frame tray box button test_keyhole test_width
SRC            := soap-caddy.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --

.DEFAULT_GOAL := all
.PHONY: all stl project report render clean help

all: stl ## Build everything (same as stl)

stl: ## Export each part in PARTS as an STL (frame and tray as modelled: lay them on their backs to print)
	@set -e; for p in $(PARTS); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o $$p.stl $(SRC)"; \
		$(SCAD) -D "part=\"$$p\"" -o $$p.stl $(SRC); \
	done

project: ## Build soap-caddy-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o soap-caddy-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report soap-caddy-p1s.3mf

render: project ## Render the caddy, taken apart on the wall, sections through its upper and lower keyholes (bottle, sponge, cups) and the print plates into renders/ with Blender
	mkdir -p renders
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'show_items=false' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy --model assembly.3mf $(RENDER_FLAGS)
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-wall --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'explode=1' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-apart --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'section="upper"' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-section --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'section="lower"' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-section-lower --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-frame-plate --plate 1 --views hero $(RENDER_FLAGS)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-parts --plate 2 --views hero,top $(RENDER_FLAGS)
	$(RENDER) soap-caddy-p1s.3mf renders/soap-caddy-tests --plate 3 --views top $(RENDER_FLAGS)
	rm -f assembly.3mf

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f assembly.3mf $(PARTS:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PARTS="frame tray ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project DEFS="-D bottle_w=86 -D bottle_d=54 -D neck_d=32"\n  make project DEFS="-D cup_h=10 -D sink_dist=120"\n  make report\n  make stl PARTS="test_keyhole button test_width"   # fit tests only\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
