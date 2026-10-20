# Detergent scoop: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := detergent-scoop.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --

.DEFAULT_GOAL := all
.PHONY: all stl project report render check clean help

all: stl ## Build everything (same as stl)

stl: ## Export detergent-scoop.stl
	$(SCAD) -o detergent-scoop.stl $(SRC)

project: ## Build detergent-scoop-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o detergent-scoop-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report detergent-scoop-p1s.3mf

check: ## Print the cavity volume up to the fill line
	$(SCAD) -D 'part="cavity"' --export-format=asciistl -o cavity.stl $(SRC)
	@awk '/vertex/ { v[n++] = $$2" "$$3" "$$4 } \
	     n == 3 { split(v[0], a); split(v[1], b); split(v[2], c); \
	              V += a[1]*(b[2]*c[3]-b[3]*c[2]) - a[2]*(b[1]*c[3]-b[3]*c[1]) + a[3]*(b[1]*c[2]-b[2]*c[1]); n = 0 } \
	     END { printf "Cavity volume up to the fill line: %.2f ml\n", V / 6000 }' cavity.stl
	@rm -f cavity.stl

render: project ## Render studio views into renders/ with Blender (from the project, cup up)
	mkdir -p renders
	$(RENDER) detergent-scoop-p1s.3mf renders/detergent-scoop --rotate 180,0,0 $(RENDER_FLAGS)

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f detergent-scoop.stl cavity.stl

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make DEFS="-D cap_d=38"\n  make DEFS="-D capacity_ml=150 -D inner_l=65"\n  make check\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
