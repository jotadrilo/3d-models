# Remote stands (v1 and v2): export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../tools/render_studio.py --
CAMERA         := --render --imgsize=1200,900 --camera=70,27,40,60,0,25,380

.DEFAULT_GOAL := all
.PHONY: all stl v1 v2 project report preview render clean help

all: stl ## Build everything (same as stl)

stl: v1 v2 ## Export both stands as STL

v1: ## Export remote-stand.stl
	$(SCAD) -o remote-stand.stl remote-stand.scad

v2: ## Export remote-stand-v2.stl
	$(SCAD) -o remote-stand-v2.stl remote-stand-v2.scad

project: ## Build remote-stand-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o remote-stand-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../tools/bambu3mf.py report remote-stand-p1s.3mf

preview: ## Render remote-stand.png and remote-stand-v2.png
	$(SCAD) $(CAMERA) -o remote-stand.png remote-stand.scad
	$(SCAD) $(CAMERA) -o remote-stand-v2.png remote-stand-v2.scad

render: project ## Render studio views of both stands into renders/ with Blender (from the project)
	mkdir -p renders
	$(RENDER) remote-stand-p1s.3mf renders/remote-stand --plate 1 $(RENDER_FLAGS)
	$(RENDER) remote-stand-p1s.3mf renders/remote-stand-v2 --plate 2 $(RENDER_FLAGS)

clean: ## Remove exported files (the committed Bambu projects, previews and renders are kept)
	rm -f remote-stand.stl remote-stand-v2.stl

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make v2 DEFS="-D lattice_pitch=4 -D strand_w=1"\n  make project\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
