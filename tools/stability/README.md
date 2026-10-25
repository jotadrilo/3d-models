# stability: will it tip over?

For pieces that **stand free** (nothing screws them down) and can be knocked: a gate or a screen on
its feet, a tall stand, a shelf on a floor, a holder on a counter. What limits them is
tipping or sliding, long before any part breaks, so FEA ([tools/fea](../fea/README.md)) is the wrong
tool here: it measures stress and bending, and a rigid body falls over at the same push whatever its
stresses. This page is the method, the worked example and what we learned. The first project was
`dog-gate` ([its scripts](../../projects/dog-gate/stability/)).

## When it is worth it

| Situation | Analysis |
|---|---|
| A piece that cannot fall over (low and wide, or fixed down) | None |
| It stands free and only its own weight keeps it up; someone will ask "how much does it take to knock it over?" or "which base is steadier?" | **Statics**: seconds, the numbers to compare variants |
| It gets knocked or tapped, not pushed slowly (a dog, a passing leg, a door); there are contacts other than the floor (a wall or a step behind, a stop); or it could slide as well as tip | **Statics + rigid-body simulation** (MuJoCo) |
| Whatever the models say | A real test with a luggage scale pulling at the top edge, to calibrate them with the real piece and floor |

Offer it to the user like the FEA: when the piece stands free, before arguing about bases.

## What to measure

From the weight `W`, the height of the centre of mass `h` and the horizontal distance `b` from it to
the edge the piece tips over (each direction has its own edge):

| Quantity | Formula | Tells you |
|---|---|---|
| Tipping force | `F = W · b / H` (push at height H) | the steady push that tips it; compare with sliding, `μ · W`: whichever is smaller happens first |
| Tipping angle | `atan(b / h)` | how far it can lean before it falls on its own |
| Energy barrier | `E = W · (√(b² + h²) − h)` | what a bump or a tap must give it to go over; it grows with b², so it separates variants more than the force |
| Shortest tap | `J = √(2 · I · E) / H`, I about the edge | a short push at height H that tips it, if the edge does not slip |

- **The base depth is shared between the two directions.** A symmetric base (discs, brackets on both
  faces) gives half its depth each way; feet on one side give almost all of it that way and nothing
  the other. Put the depth where the dangerous fall is, and let a wall or a step cover the other side.
- **More feet of the same reach change nothing.** Only a longer reach, more weight (ballast low on the
  feet) or a tie to something fixed do.
- **Leaning the piece over its feet** moves the centre of mass forwards: steadier backwards, easier
  forwards; each degree moves it `h · tan` (dog-gate: 5° on a 1 m board).
- **Nothing that only rests on a stair can be stopped from sliding downhill**: treads push up and
  risers face downhill. Only friction holds it that way.

## Method

1. **Rigid bodies from the model itself.** A small `gate.py`-style module reads the project's
   `.scad`: its echo (positions, edges) and an STL of each printed part, whose volume, centroid and
   inertia come from the mesh (signed tetrahedra). Scale the mass to the sliced grams from
   `make report`: a printed part is not solid (dog-gate's brackets: 0.67 of the mesh's volume). Bought
   parts (the board) from their size and density, the worst case (light plywood) for tipping.
2. **Statics** (`stability.py`): the table above for each variant and direction, in one table
   (`make stability`). Variants to always include: the design, the knob that trades directions (lean,
   reach), ballast, and the alternative the user asked about.
3. **Simulation** (`sim.py`, MuJoCo): the piece as one free rigid body built from boxes at the same
   positions and masses, on a plane (the floor or the tread) with the real obstacles as boxes (the
   steps above), Coulomb friction for bare plastic (μ 0.4) and rubber pads (μ 0.7). Two experiments:
   - **ramp**: a horizontal force at the top edge growing 2 N/s; record lift-off (0.5°), fall (15°)
     and sliding (3 mm before 0.3° of tilt). It must match the statics within ~15 %; if not, the
     geometry or the masses differ, fix that first.
   - **tap**: 50 ms half-sine pushes at the same point, bisected to the smallest that makes it fall,
     **both** "falls the way it was pushed" and "falls at all" (see below). Report peak and impulse
     (`2 · peak · T / π`).
   - A few clips just under and just over each threshold (`--video`, `MUJOCO_GL=cgl` on macOS) show
     the user what happens. Commit the final ones in `projects/<project>/stability/videos/` (MP4,
     tens of KB each) and link them from the README: they are simulation results, like the FEA
     images, not renders of the model (which stay Blender, CLAUDE.md §3.3).
4. **Report** in the README: one table of the design (statics and simulation side by side), one of
   the trade-off knob, one line per alternative, and what the user should do (pads, ballast, lean).

Setup, once: `micromamba create -n physics -c conda-forge python=3.12 mujoco numpy imageio
imageio-ffmpeg`. The Makefile calls it as `$(PHYSICS) python …` with `PHYSICS ?= micromamba run -n
physics`.

## What the simulation showed that the statics did not (dog-gate, 2026-10)

- **A wall or a step behind is a fulcrum, not a stop.** The gate leans on the riser's top edge and,
  pushed back, levers over it onto the steps above at 3 N. Do the statics with that edge as the pivot
  (and the push lever `H − z`): it gives 2.8 N.
- **A sharp tap tips it the other way.** Tapped forwards, the gate rocks forward, lands back on its
  foot and goes over **backwards**, its weak side: at 1.15 N·s, against 2.6 N·s to throw it forwards.
  So a piece with one weak direction is as weak as that direction against taps from either side.
  Always bisect both "the way pushed" and "at all".
- **Friction matters against taps, not slow pushes.** Rubber pads (μ 0.4 → 0.7) left the ramp figures
  alone but raised the tap that tips it at all from 1.15 to 1.84 N·s: on the rebound the foot is
  pushed back into the riser and the grip holds it there.
- **The fixed-pivot tap formula is an upper bound** when the foot can slip or lift: it gave 2.3 N·s
  forwards, the simulation 2.6 N·s for the same fall (close), but nothing about the rebound.
- **Low pushes slide it**: below `b / μ` (58 cm at μ 0.4) a steady push slides it before it tips;
  with the toes 5 mm from a stair's nosing, that is a fall too.
- Modelling: the tread as a plane or as a box gave the same results; `multiccd` on for box contacts;
  timestep 0.5 ms; `solref 0.004 1`. A body falling off a short stair model looked like it went
  through the step; give it enough steps (three) to land on.

## Case studies

### 1. dog-gate, simple version (2026-10-25)

A 1 m plywood board (3.5 kg) on two one-sided brackets with 275 mm feet, leaning 5° over them,
against the next riser. Steady push at the top: 8.5 N statics / 10.4 N simulated forwards, 2.8 / 3.1
backwards over the riser. Taps: 2.6 N·s to throw it down the stair, 1.15 to make it fall at all
(rebound). Brackets on both faces in the middle of the tread, or discs Ø230: ≈5 N either way, half
as steady down the stair. Figures and tables: [dog-gate README](../../projects/dog-gate/README.md#stability).

### 2. dog-gate, reinforced version: anchored, not just standing (2026-10-25)

The same gate with each bracket's heel hooked under the back flange of an open stair's tray tread
([`sim_hook.py`](../../projects/dog-gate/stability/sim_hook.py)): the treads as plates with their
flanges, the hooks as boxes under them. Leaning (206 N at the top) it tilts 0.5° and stays put;
the hooks' contact force, 807 N for the two, matches the board FEA (2 × 377 N), which is the check
that the rigid model's geometry is right (a first run gave 3 kN: the brace box was tilted the wrong
way and became the pivot). A hard blow (690 N, 50 ms) tilts it 0.7° and it settles back. Once a
piece is anchored, stability is a yes/no and the question moves to strength: the forces go to the
FEA ([tools/fea](../fea/README.md), case 6). The contact peak of a blow in a rigid model depends on
the contact stiffness, not on the parts: do not size parts from it.
