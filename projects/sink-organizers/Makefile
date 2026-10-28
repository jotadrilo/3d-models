# Sink organizers (soap caddy and cutlery drainer): export from the command
# line. Run `make help` for the targets. Every target is phony, so it always
# regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SOAP_PARTS     ?= plate body tray box button adapter jig test_keyhole test_buttons test_dovetail_housing test_dovetail_tail test_width
DRAINER_PARTS  ?= plate body tray rack bin riser handle jig test_pin test_bin
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
COLOUR         = $(SCAD) --enable=lazy-union -O export-3mf/color-mode=model -D 'piece_colour="\#000000"'
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
PROJECT        := sink-organizers-p1s.3mf
PROJECT_HF     := sink-organizers-p1s-hf.3mf
PROJECT_MATTE  := sink-organizers-p1s-matte.3mf

.DEFAULT_GOAL := all
.PHONY: all stl project report render clean help

all: stl ## Build everything (same as stl)

stl: ## Export each part of both pieces as an STL, soap-caddy-<part>.stl and cutlery-drainer-<part>.stl (as modelled: lay the plates and trays on their backs to print)
	@set -e; for p in $(SOAP_PARTS); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o soap-caddy-$$p.stl soap-caddy.scad"; \
		$(SCAD) -D "part=\"$$p\"" -o soap-caddy-$$p.stl soap-caddy.scad; \
	done
	@set -e; for p in $(DRAINER_PARTS); do \
		echo "$(SCAD) -D 'part=\"$$p\"' -o cutlery-drainer-$$p.stl cutlery-drainer.scad"; \
		$(SCAD) -D "part=\"$$p\"" -o cutlery-drainer-$$p.stl cutlery-drainer.scad; \
	done

project: ## Build the ready-to-print Bambu Studio projects, sink-organizers-p1s.3mf (PETG Basic), sink-organizers-p1s-hf.3mf (PETG HF) and sink-organizers-p1s-matte.3mf (PETG Matte): one plate per piece and kind, and the fit tests
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o $(PROJECT) $(DEFS)
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py --hf -o $(PROJECT_HF) $(DEFS)
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py --matte -o $(PROJECT_MATTE) $(DEFS)

report: project ## Rebuild the projects, slice them and print time and filament per plate
	python3 ../../tools/bambu3mf.py report $(PROJECT)
	python3 ../../tools/bambu3mf.py report $(PROJECT_HF)
	python3 ../../tools/bambu3mf.py report $(PROJECT_MATTE)

render: project ## Render both pieces (bare, on the wall, taken apart, sections) and the print plates into renders/ with Blender
	mkdir -p renders
	$(COLOUR) -D 'show_items=false' -o assembly.3mf soap-caddy.scad
	$(RENDER) $(PROJECT) renders/soap-caddy --model assembly.3mf $(RENDER_FLAGS)
	$(COLOUR) -o assembly.3mf soap-caddy.scad
	$(RENDER) $(PROJECT) renders/soap-caddy-wall --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(COLOUR) -D 'show_items=false' -D 'explode=1' -D 'body_lift=240' -o assembly.3mf soap-caddy.scad
	$(RENDER) $(PROJECT) renders/soap-caddy-apart --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(COLOUR) -D 'section="upper"' -o assembly.3mf soap-caddy.scad
	$(RENDER) $(PROJECT) renders/soap-caddy-section --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(COLOUR) -D 'section="lower"' -o assembly.3mf soap-caddy.scad
	$(RENDER) $(PROJECT) renders/soap-caddy-section-lower --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(COLOUR) -D 'show_items=false' -o assembly.3mf cutlery-drainer.scad
	$(RENDER) $(PROJECT) renders/cutlery-drainer --model assembly.3mf $(RENDER_FLAGS)
	$(COLOUR) -D 'show_items=false' -D 'explode=1' -o assembly.3mf cutlery-drainer.scad
	$(RENDER) $(PROJECT) renders/cutlery-drainer-apart --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(COLOUR) -D 'section="keyhole"' -o assembly.3mf cutlery-drainer.scad
	$(RENDER) $(PROJECT) renders/cutlery-drainer-section-keyhole --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(COLOUR) -D 'section="bins"' -o assembly.3mf cutlery-drainer.scad
	$(RENDER) $(PROJECT) renders/cutlery-drainer-section-bins --model assembly.3mf --views front $(RENDER_FLAGS)
	$(COLOUR) -D 'section="handle"' -o assembly.3mf cutlery-drainer.scad
	$(RENDER) $(PROJECT) renders/cutlery-drainer-section-handle --model assembly.3mf --views top $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/soap-caddy-plate1 --plate 1 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/soap-caddy-plate2 --plate 2 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/cutlery-drainer-plate3 --plate 3 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/cutlery-drainer-plate4 --plate 4 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/cutlery-drainer-plate5 --plate 5 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/cutlery-drainer-plate6 --plate 6 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/cutlery-drainer-plate7 --plate 7 --views hero $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/fit-tests --plate 9 --views top $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/soap-caddy-jig --plate 11 --views top $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/cutlery-drainer-jig --plate 12 --views top $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/adapters --plate 13 --views hero $(RENDER_FLAGS)
	rm -f assembly.3mf

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f assembly.3mf $(SOAP_PARTS:%=soap-caddy-%.stl) $(DRAINER_PARTS:%=cutlery-drainer-%.stl)

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [SOAP_PARTS="body tray ..."] [DRAINER_PARTS="body bin ..."] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project DEFS="-D bottle_w=86 -D bottle_d=54 -D neck_d=32"   # your bottle\n  make project DEFS="-D cup_h=10 -D dt_play=0.3"                  # shared values apply to both pieces\n  make report\n  make stl SOAP_PARTS="test_keyhole button test_dovetail_housing test_dovetail_tail" DRAINER_PARTS="test_pin"   # fit tests only\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n\n'
