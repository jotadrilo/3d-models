# Shared OpenSCAD library: a sample of every piece, to check and render them.
# Run `make help` for the targets. Every target is phony, so it always
# regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SAMPLES        ?= keyhole_pad keyhole_button standoff_peg house_box holes sockets keys
SRC            := catalog.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../render_studio.py --
VIEW           := --render --imgsize=2000,700 --colorscheme=Tomorrow --autocenter --viewall

.DEFAULT_GOAL := all
.PHONY: all stl project report preview render clean help

all: stl ## Build everything (same as stl)

stl: ## Export each sample in SAMPLES as an STL, in print orientation
	@set -e; for p in $(SAMPLES); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o $$p.stl $(SRC)"; \
		$(SCAD) -D "part=\"$$p\"" -o $$p.stl $(SRC); \
	done

project: ## Build catalog-p1s.3mf, every sample on one plate, ready to print
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o catalog-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament
	python3 ../bambu3mf.py report catalog-p1s.3mf

preview: ## Render catalog.png (every sample, the ones with an inside cut in half) with OpenSCAD
	$(SCAD) $(VIEW) -D cut=true --camera=0,0,0,60,0,15,0 -o catalog.png $(SRC)

render: project ## Render each sample into renders/ with Blender (cut in half where the inside matters) and the plate
	mkdir -p renders
	@set -e; for p in $(SAMPLES); do \
		echo "render $$p"; \
		$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D "part=\"$$p\"" -D cut=true -o sample.3mf $(SRC); \
		$(RENDER) catalog-p1s.3mf renders/$$p --model sample.3mf --views hero $(RENDER_FLAGS); \
	done
	$(RENDER) catalog-p1s.3mf renders/catalog --views hero,top $(RENDER_FLAGS)
	rm -f sample.3mf

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f sample.3mf catalog.png $(SAMPLES:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [SAMPLES="holes keys ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make preview\n  make render SAMPLES="keyhole_pad keyhole_button"\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
