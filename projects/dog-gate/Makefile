# Dog gate brackets: export from the command line. Run `make help` for the
# targets. Every target is phony, so it always regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
COLOUR         = $(SCAD) --enable=lazy-union -O export-3mf/color-mode=model
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
PROJECT        := dog-gate-p1s.3mf
PHYSICS        ?= micromamba run -n physics
MU             ?= 0.4
VIDEO          ?=

.DEFAULT_GOAL := all
.PHONY: all stl project report render stability sim clean help

all: stl ## Build everything (same as stl)

stl: ## Export one bracket in print orientation as dog-gate-bracket.stl (print two)
	$(SCAD) -D 'part="bracket"' -o dog-gate-bracket.stl dog-gate.scad

project: ## Build dog-gate-p1s.3mf, the ready-to-print Bambu Studio project: two plates, one bracket each
	OPENSCAD=$(OPENSCAD) python3 bambu_project.py -o $(PROJECT) $(DEFS)

report: project ## Rebuild the project, slice it and print time and filament per plate
	python3 ../../tools/bambu3mf.py report $(PROJECT)

render: project ## Render the gate on the stair, a bracket and the print plate into renders/ with Blender
	mkdir -p renders
	$(COLOUR) -D 'part="assembly"' -o assembly.3mf dog-gate.scad
	$(RENDER) $(PROJECT) renders/dog-gate --model assembly.3mf --views hero,side $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'show_context=false' -o assembly.3mf dog-gate.scad
	$(RENDER) $(PROJECT) renders/dog-gate-board --model assembly.3mf --views hero,side $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'section=true' -D 'section_h=130' -o assembly.3mf dog-gate.scad
	$(RENDER) $(PROJECT) renders/dog-gate-shoe --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/dog-gate-plate --plate 1 --views hero,top $(RENDER_FLAGS)
	rm -f assembly.3mf

stability: ## Tipping force, angle, energy and tap of the gate and its alternatives, by statics (stability/stability.py)
	cd stability && $(PHYSICS) python stability.py $(DEFS)

sim: ## Rigid-body simulation (MuJoCo) of pushes and taps, to check `make stability` (stability/sim.py; VIDEO=dir for clips)
	cd stability && MUJOCO_GL=cgl $(PHYSICS) python sim.py --mu $(MU) $(if $(VIDEO),--video $(VIDEO))

clean: ## Remove exported files (the committed Bambu project and renders are kept)
	rm -f dog-gate-bracket.stl assembly.3mf stability/*.json

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project DEFS="-D board_t=9.5 -D tread=280"   # your board and stair\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n  make stability DEFS="-D lean=8"\n  make sim MU=0.7 VIDEO=/tmp/clips\n\n'
