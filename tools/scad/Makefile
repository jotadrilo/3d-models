# Shared OpenSCAD library: a sample of every piece, to check and render them.
# Run `make help` for the targets. Every target is phony, so it always
# regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SAMPLES        ?= keyhole_pad keyhole_button standoff_peg peg_block screw_plate holes diamond_female diamond_male tongue_female tongue_male lead_in_female lead_in_male handle_block handle dovetail_housing dovetail_tail house_box board_bracket
DEMOS          ?= keyhole standoff_peg screw holes diamond tongue lead_in handle dovetail bracket
SRC            := catalog.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../render_studio.py --

.DEFAULT_GOAL := all
.PHONY: all stl project report render clean help

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

render: project ## Render each demo in DEMOS assembled and in section (with its mate and hardware), and the plate, into renders/
	mkdir -p renders
	@set -e; for d in $(DEMOS); do \
		echo "render $$d"; \
		$(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D "demo=\"$$d\"" -D assembled=true -D section=true -o demo.3mf $(SRC); \
		case $$d in holes|diamond|lead_in) cut=-y; view=front;; handle|dovetail) cut=-y; view=top;; *) cut=+x; view=front;; esac; \
		$(RENDER) catalog-p1s.3mf renders/$$d-section --model demo.3mf --views $$view --front=$$cut $(RENDER_FLAGS); \
	done
	$(RENDER) catalog-p1s.3mf renders/catalog --views hero,top $(RENDER_FLAGS)
	rm -f demo.3mf

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f demo.3mf $(SAMPLES:=.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [SAMPLES="holes ..."] [DEMOS="keyhole ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make render DEMOS="keyhole diamond"\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
