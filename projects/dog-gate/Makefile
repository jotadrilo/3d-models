# Dog gate, simple and reinforced (hooked) versions: export from the command
# line. Run `make help` for the targets. Every target is phony, so it always
# regenerates its files.

OPENSCAD       ?= openscad
OPENSCAD_FLAGS ?=
DEFS           ?=
SCAD           = $(OPENSCAD) $(OPENSCAD_FLAGS) $(DEFS)
COLOUR         = $(SCAD) --enable=lazy-union -O export-3mf/color-mode=model
BLENDER        ?= blender
RENDER_FLAGS   ?=
RENDER         = $(BLENDER) -b -P ../../tools/render_studio.py --
PRINTERS       ?= p1s x2d
PROJECT        := dog-gate-p1s.3mf
PHYSICS        ?= micromamba run -n physics
FEA            ?= micromamba run -n fea
FEA_OUT        ?= /tmp/dog-gate-fea
MU             ?= 0.4
VIDEO          ?= videos

.DEFAULT_GOAL := all
.PHONY: all stl project report render stability sim sim-hook fea clean help

all: stl ## Build everything (same as stl)

stl: ## Export each bracket in print orientation: dog-gate-bracket.stl (simple) and dog-gate-hook-bracket.stl (reinforced); print two of the one you choose
	$(SCAD) -D 'part="bracket"' -o dog-gate-bracket.stl dog-gate.scad
	$(SCAD) -D 'part="bracket"' -o dog-gate-hook-bracket.stl dog-gate-hook.scad

project: ## Build the Bambu Studio projects dog-gate-p1s.3mf and dog-gate-x2d.3mf: one plate per version (print it twice) and the hook tests
	@set -e; for p in $(PRINTERS); do \
		echo "python3 bambu_project.py --printer $$p"; \
		OPENSCAD=$(OPENSCAD) python3 bambu_project.py --printer $$p $(DEFS); \
	done

report: project ## Rebuild the projects, slice them and print time and filament per plate
	@set -e; for p in $(PRINTERS); do python3 ../../tools/bambu3mf.py report dog-gate-$$p.3mf; done

render: project ## Render both versions (on the stair, the board, the shoe in section) and their print plates into renders/ with Blender
	mkdir -p renders
	$(COLOUR) -D 'part="assembly"' -o assembly.3mf dog-gate.scad
	$(RENDER) $(PROJECT) renders/dog-gate --model assembly.3mf --views hero,side $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'show_context=false' -o assembly.3mf dog-gate.scad
	$(RENDER) $(PROJECT) renders/dog-gate-board --model assembly.3mf --views hero,side $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'section=true' -D 'section_h=130' -o assembly.3mf dog-gate.scad
	$(RENDER) $(PROJECT) renders/dog-gate-shoe --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -o assembly.3mf dog-gate-hook.scad
	$(RENDER) $(PROJECT) renders/dog-gate-hook --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'show_stringers=false' -o assembly.3mf dog-gate-hook.scad
	$(RENDER) $(PROJECT) renders/dog-gate-hook --model assembly.3mf --views side $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'show_context=false' -o assembly.3mf dog-gate-hook.scad
	$(RENDER) $(PROJECT) renders/dog-gate-hook-board --model assembly.3mf --views hero $(RENDER_FLAGS)
	$(COLOUR) -D 'part="assembly"' -D 'section=true' -D 'section_h=140' -o assembly.3mf dog-gate-hook.scad
	$(RENDER) $(PROJECT) renders/dog-gate-hook-shoe --model assembly.3mf --front=+x --views front $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/dog-gate-plate --plate 1 --views hero,top $(RENDER_FLAGS)
	$(RENDER) $(PROJECT) renders/dog-gate-hook-plate --plate 2 --views hero,top $(RENDER_FLAGS)
	rm -f assembly.3mf

stability: ## Simple version: tipping force, angle, energy and tap, and its alternatives, by statics (stability/stability.py)
	cd stability && $(PHYSICS) python stability.py $(DEFS)

sim: ## Simple version: rigid-body simulation (MuJoCo) of pushes and taps; clips into stability/$(VIDEO)/
	cd stability && MUJOCO_GL=cgl $(PHYSICS) python sim.py --mu $(MU) $(if $(VIDEO),--video $(VIDEO))

sim-hook: ## Reinforced version: the leaning dog and a hard blow on the hooked gate (MuJoCo), hook forces; clips into stability/$(VIDEO)/
	cd stability && MUJOCO_GL=cgl $(PHYSICS) python sim_hook.py --mu $(MU) $(if $(VIDEO),--video $(VIDEO))

fea: ## Reinforced version: the board on its brackets (fea/board_fea.py, R45x20_in and F45x30) and the bracket (fea/bracket_fea.py) under the leaning dog; runs into $(FEA_OUT)
	cd fea && CASES=lean SIGNS=dn $(FEA) python board_fea.py $(FEA_OUT)/board F45x30 R45x20_in
	cd fea && $(FEA) python bracket_fea.py $(FEA_OUT)/bracket 3.0

clean: ## Remove exported files (the committed Bambu projects, renders and clips are kept)
	rm -f dog-gate-bracket.stl dog-gate-hook-bracket.stl assembly.3mf stability/*.json

help: ## Show this help
	@printf '\nUsage: make \033[36m<target>\033[0m [PRINTERS="p1s x2d"] [DEFS="-D name=value ..."] [OPENSCAD_FLAGS=...]\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*## " } /^[A-Za-z0-9_-]+:.*## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nExamples:\n  make project PRINTERS=x2d\n  make report\n  make render RENDER_FLAGS="--samples 32 --scale 0.25"   # quick draft\n  make stability DEFS="-D lean=8"\n  make sim MU=0.7\n  make sim-hook\n  make fea FEA_OUT=/tmp/fea\n\n'
