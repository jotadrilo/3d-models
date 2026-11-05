# Lattice bowl: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := lattice_bowl.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
PRINTERS       ?= p1s x2d

.DEFAULT_GOAL := all
.PHONY: all stl project report render clean help

all: stl ## Build everything (same as stl)

stl: ## Export lattice_bowl.stl
	$(SCAD) -o lattice_bowl.stl $(SRC)

project: ## Build the ready-to-print Bambu Studio projects, one per printer in PRINTERS: lattice-bowl-p1s.3mf and lattice-bowl-x2d.3mf
	@set -e; for p in $(PRINTERS); do \
		echo "python3 bambu_project.py --printer $$p"; \
		OPENSCAD=$(OPENSCAD) python3 bambu_project.py --printer $$p $(DEFS); \
	done

report: project ## Rebuild the projects, slice them and print time and filament per plate
	@set -e; for p in $(PRINTERS); do echo "== lattice-bowl-$$p.3mf"; python3 ../../tools/bambu3mf.py report lattice-bowl-$$p.3mf; done

render: project ## Render studio views into renders/ with Blender (from the project)
	mkdir -p renders
	$(RENDER) lattice-bowl-p1s.3mf renders/lattice-bowl $(RENDER_FLAGS)

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f lattice_bowl.stl

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PRINTERS="p1s x2d"] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make DEFS="-D top_diameter=200 -D rod_width=2.5"\n  make project\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
