# K120 keyboard leg: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := keyboard-leg.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
PRINTERS       ?= p1s x2d

.DEFAULT_GOAL := all
.PHONY: all stl project report render clean help

all: stl ## Build everything (same as stl)

stl: ## Export keyboard-leg.stl
	$(SCAD) -D 'part="leg"' -o keyboard-leg.stl $(SRC)

project: ## Build the ready-to-print Bambu Studio projects, one per printer in PRINTERS: keyboard-leg-p1s.3mf and keyboard-leg-x2d.3mf
	@set -e; for p in $(PRINTERS); do \
		echo "python3 bambu_project.py --printer $$p"; \
		OPENSCAD=$(OPENSCAD) python3 bambu_project.py --printer $$p $(DEFS); \
	done

report: project ## Rebuild the projects, slice them and print time and filament per plate
	@set -e; for p in $(PRINTERS); do echo "== keyboard-leg-$$p.3mf"; python3 ../../tools/bambu3mf.py report keyboard-leg-$$p.3mf; done

render: project ## Render studio views of one leg into renders/ with Blender (plate 2)
	mkdir -p renders
	$(RENDER) keyboard-leg-p1s.3mf renders/keyboard-leg --plate 2 --objects "Leg 1" $(RENDER_FLAGS)

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f keyboard-leg.stl

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PRINTERS="p1s x2d"] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make DEFS="-D pin_d=1.9"          # pins a little thinner, if they bind\n  make project DEFS="-D length=30"\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
