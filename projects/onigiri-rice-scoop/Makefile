# Onigiri rice scoop: export from the command line. Run `make help` for the targets.
# Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SRC            := onigiri-rice-scoop.scad
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
RICES          := basmati integral

.DEFAULT_GOAL := all
.PHONY: all stl 3mf project report render check clean help

all: stl ## Build everything (same as stl)

stl: ## Export one single-colour STL per rice (onigiri-rice-scoop-<rice>.stl)
	for r in $(RICES); do $(SCAD) -D "rice=\"$$r\"" -D 'part="body"' -o onigiri-rice-scoop-$$r.stl $(SRC); done

3mf: ## Export one multi-colour 3MF per rice (onigiri-rice-scoop-<rice>.3mf)
	for r in $(RICES); do $(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D "rice=\"$$r\"" -o onigiri-rice-scoop-$$r.3mf $(SRC); done

project: ## Build onigiri-rice-scoop-p1s.3mf, the ready-to-print Bambu Studio project
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o onigiri-rice-scoop-p1s.3mf $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report onigiri-rice-scoop-p1s.3mf

check: ## Print each scoop's volume up to the rim and the grams of rice it holds
	@for r in $(RICES); do \
	  $(SCAD) -D "rice=\"$$r\"" -D 'part="cavity"' --export-format=asciistl -o cavity.stl $(SRC) 2>&1 | grep -o '"[a-z]*: .* ml"' ; \
	  awk '/vertex/ { v[n++] = $$2" "$$3" "$$4 } \
	     n == 3 { split(v[0], a); split(v[1], b); split(v[2], c); \
	              V += a[1]*(b[2]*c[3]-b[3]*c[2]) - a[2]*(b[1]*c[3]-b[3]*c[1]) + a[3]*(b[1]*c[2]-b[2]*c[1]); n = 0 } \
	     END { printf "  cavity up to the rim: %.2f ml\n", V / 6000 }' cavity.stl; \
	done
	@rm -f cavity.stl

render: project ## Render studio views into renders/ with Blender (from the project, cup up)
	mkdir -p renders
	$(RENDER) onigiri-rice-scoop-p1s.3mf renders/onigiri-rice-scoop --objects 'Basmati scoop' --rotate 180,0,0 $(RENDER_FLAGS)

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f onigiri-rice-scoop-*.stl onigiri-rice-scoop-basmati.3mf onigiri-rice-scoop-integral.3mf cavity.stl

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make check\n  make project DEFS="-D basmati_density=0.80"   # after weighing your rice\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
