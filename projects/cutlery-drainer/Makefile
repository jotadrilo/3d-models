# Cutlery drainer: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
PARTS          ?= frame tray bin handle button test_pin
SRC            := cutlery-drainer.scad
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

project: ## Build cutlery-drainer-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o cutlery-drainer-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report cutlery-drainer-p1s.3mf

render: project ## Render the drainer, sections through a keyhole and level with the handle's pins (on the wall, with cutlery and towel) and the print plates into renders/ with Blender
	mkdir -p renders
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'show_items=false' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) cutlery-drainer-p1s.3mf renders/cutlery-drainer --model assembly.3mf $(RENDER_FLAGS)
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'section="keyhole"' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) cutlery-drainer-p1s.3mf renders/cutlery-drainer-section-keyhole --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'section="handle"' -D 'piece_colour="#000000"' -o assembly.3mf $(SRC)
	$(RENDER) cutlery-drainer-p1s.3mf renders/cutlery-drainer-section-handle --model assembly.3mf --views top $(RENDER_FLAGS)
	$(RENDER) cutlery-drainer-p1s.3mf renders/cutlery-drainer-frame-plate --plate 1 --views hero $(RENDER_FLAGS)
	$(RENDER) cutlery-drainer-p1s.3mf renders/cutlery-drainer-parts --plate 2 --views hero,top $(RENDER_FLAGS)
	rm -f assembly.3mf

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f assembly.3mf $(PARTS:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PARTS="frame tray ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project DEFS="-D bins=2 -D frame_w=180"\n  make project DEFS="-D cup_h=10 -D sink_dist=120"\n  make report\n  make stl PARTS="test_pin"   # the handle fit test only\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
