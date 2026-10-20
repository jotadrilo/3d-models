# Desk hanger rail: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
PARTS          ?= bracket_left bracket_right bar test_socket test_bar test_clip
SRC            := desk-hanger-rail.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --

.DEFAULT_GOAL := all
.PHONY: all stl project report render clean help

all: stl ## Build everything (same as stl)

stl: ## Export each part in PARTS as an STL, in print orientation
	@set -e; for p in $(PARTS); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o $$p.stl $(SRC)"; \
		$(SCAD) -D "part=\"$$p\"" -o $$p.stl $(SRC); \
	done

project: ## Build desk-hanger-rail-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o desk-hanger-rail-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report desk-hanger-rail-p1s.3mf

render: project ## Render the assembly, the print plate and the fit tests into renders/ with Blender, in the project's filament
	mkdir -p renders
	$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'show_desk=false' -o assembly.3mf $(SRC)
	$(RENDER) desk-hanger-rail-p1s.3mf renders/desk-hanger-rail --model assembly.3mf --layer-axis x $(RENDER_FLAGS)
	$(RENDER) desk-hanger-rail-p1s.3mf renders/desk-hanger-rail-parts --views hero,top $(RENDER_FLAGS)
	$(RENDER) desk-hanger-rail-p1s.3mf renders/desk-hanger-rail-fit-test --plate 2 --views hero $(RENDER_FLAGS)
	$(RENDER) desk-hanger-rail-p1s.3mf renders/desk-hanger-rail-clip-test --plate 3 --views hero $(RENDER_FLAGS)
	rm -f assembly.3mf

clean: ## Remove exported files (the committed Bambu projects and renders are kept)
	rm -f assembly.3mf $(PARTS:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PARTS="bracket_left bracket_right bar ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project DEFS="-D desk_t=18"\n  make project DEFS="-D width=240 -D hook_clearance=50"\n  make report\n  make stl PARTS="test_socket test_bar test_clip"   # fit test only\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
