# Cosmere tracker: export the parts from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
PARTS          ?= frame front wheels stand
SRC            := cosmere-tracker.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../tools/render_studio.py --
VIEW           := --render --imgsize=1400,700 --projection=o --colorscheme=Tomorrow

# lazy-union keeps every colour as its own object in the 3MF.
LAZY := --enable=lazy-union -O export-3mf/color-mode=model

.DEFAULT_GOAL := all
.PHONY: all 3mf stl project report preview render clean help

all: 3mf ## Build everything (same as 3mf)

3mf: ## Export each part in PARTS as a multi-colour 3MF (one part per colour, for the AMS)
	@set -e; for p in $(PARTS); do \
		echo "$(SCAD) $(LAZY) -D 'part=\"$$p\"' -o $$p.3mf $(SRC)"; \
		$(SCAD) $(LAZY) -D "part=\"$$p\"" -o $$p.3mf $(SRC); \
	done

stl: ## Export each part in PARTS as a single-colour STL
	@set -e; for p in $(PARTS); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o $$p.stl $(SRC)"; \
		$(SCAD) -D "part=\"$$p\"" -o $$p.stl $(SRC); \
	done

project: ## Build cosmere-tracker-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o cosmere-tracker-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../tools/bambu3mf.py report cosmere-tracker-p1s.3mf

preview: ## Render cosmere-tracker-front.png and cosmere-tracker-back.png
	$(SCAD) $(VIEW) --camera=0,-400,32,0,0,32 -o cosmere-tracker-front.png $(SRC)
	$(SCAD) $(VIEW) --camera=0,400,32,0,0,32 -o cosmere-tracker-back.png $(SRC)

render: project ## Render the assembly and the print plate into renders/ with Blender, in the project's filaments
	mkdir -p renders
	$(SCAD) $(LAZY) -D 'part="assembly"' -o assembly.3mf $(SRC)
	$(RENDER) cosmere-tracker-p1s.3mf renders/cosmere-tracker --model assembly.3mf --layer-axis y $(RENDER_FLAGS)
	$(RENDER) cosmere-tracker-p1s.3mf renders/cosmere-tracker-parts --views hero,top $(RENDER_FLAGS)
	rm -f assembly.3mf

clean: ## Remove exported files (the committed Bambu projects, previews and renders are kept)
	rm -f assembly.3mf $(PARTS:=.3mf) $(PARTS:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PARTS="frame front wheels stand"] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n  make 3mf PARTS=front\n  make DEFS="-D show_investiture=false -D digit_h=6"\n\n'
