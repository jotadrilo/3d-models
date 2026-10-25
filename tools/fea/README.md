# fea: load analysis with gmsh + CalculiX

An optional check for parts that carry a load, on top of the hand calculation every functional
project already has (CLAUDE.md §2.3). It meshes the real geometry, applies the loads and the
supports, and reports how much each part deflects, how hard it works and where. In an assembly it
also reports how the load is shared: for example, how hard each suction cup pulls on the wall.

This page is a working log as well as a guide. The method is being tried on `sink-organizers`,
and what we learn (results, what was simplified and whether that held) is added under
[Case studies](#case-studies).

## When it is worth it

| Situation | Analysis |
|---|---|
| Simple beam, hook, bracket or pin, margin ≥ 5× by hand | None: the hand calculation in the README is enough |
| Margin under ~5× by hand, or a load path you can't work out by hand (grids of slats and ties, frames, shells) | **Single part**, linear (§ [Single part](#single-part)): a minute or two |
| Deflection matters (something sags, rubs or touches) | Single part: the deflection converges with a coarse mesh |
| Several parts on a wall or a stand, and the question is how the load is shared (cups, screws, hooks) | **Assembly** (§ [Assembly](#assembly)) |
| The joint itself is the question (binding, seating, snap-in) | Contact on that joint alone, not the whole assembly |

Nothing replaces the fit test print. FEA answers "how strong and how stiff", not "does it fit".

## Design study: the workflow for a loaded part

The way of working agreed on sink-organizers. Unless the user sets other priorities, the default
aim is **the most reliable part for its normal use**: the least material and the least bending
under its load cases, with a comfortable stress margin.

1. **Load cases from real use**, agreed with the user ([Load cases](#load-cases)). Mark which one is
   permanent: it drives creep.
2. **Reference:** the part as it is, through the whole chain. Its numbers are the baseline every
   variant is compared with.
3. **Variables:** list the parameters that change the part and nothing else. Add new ones to the
   `.scad` with defaults that leave the geometry unchanged, and check that every project using them
   exports the same volume and triangle count. Leave out shared ones that would change other parts.
4. **One variable per variant**, against a named reference (the baseline, or the best so far). For
   each, a draft preview of its geometry, its material (volume from the STL) and, after the run:
   - how far the part moves (its own bending);
   - the largest deflection of the assembly;
   - stress, peak and p99, in the region that matters;
   - the reactions that matter (the cups' pull).
5. **Show the results side by side**: one table, and the stress maps at one scale and one viewpoint,
   so the user compares them directly.
6. **Next round from the best variant**, again one variable at a time. Sweep the variable that
   sets the trade-off (here, the width of the solid bands).
7. **Top 3** under every load case. The user picks one. Only then does it become the project's
   default, with the final renders (CLAUDE.md §3.3) and the README's strength table updated.

Each variant that changes one part costs 1–2 min (mesh cache, linear bonded run), so a dozen
variants take under half an hour. Keep the contact model for the cases that need it.

**Where the part is held comes first.** Before thickening or ribbing anything, put the supports
under the load path.
- **The drainer:** moving its cups from 120 to 175 mm apart, under the dovetails that carry the
  body, cut the bending by 91 % and used less plastic.
- **The alternative cost more for less:** a 25 % thicker plate gave a third of that gain for
  16.5 % more plastic.
- **Once the supports are right, a lot of material stops working:** the drainer's plate then lost
  a quarter of its plastic to one big window with no change in stiffness.

So vary the supports (cup positions, row distance) in the first round. The row distance also
sets what the cups pull.

## Toolchain

| Program | Role | Where |
|---|---|---|
| OpenSCAD | The model, as always. Exports each part as an STL, the input to the analysis | installed |
| fTetWild (pytetwild) | Fills an OpenSCAD STL with tetrahedra. It copes with the STL's self-intersections, which gmsh refuses | `fea` env, pip |
| gmsh 4 (Python API) | Meshes a STEP (exact geometry), when there is one; surface meshes for `proximity.py` | `fea` env |
| CalculiX `ccx` 2.23 | The solver: reads the `.inp` deck (mesh, material, supports, loads, joints) and computes displacements and stresses | `fea` env |
| numpy, scipy | Picking faces and node sets, stresses, reactions; nearest-neighbour searches (proximity, penetration) | `fea` env |
| meshio | Reads the STL; writes the `.vtu` for ParaView | `fea` env |
| matplotlib, Pillow | Colour bars; titles and legends on the images | `fea` env |
| ParaView 6 | Exploring results interactively; sections rendered without a window (`pvpython`) | `brew install --cask paraview` |
| Blender | Still images of the results (house rule: images come from Blender) | installed |
| micromamba | Keeps all of the `fea` env apart from the system Python. CalculiX is in conda-forge, not Homebrew | `brew install micromamba` |

```sh
export MAMBA_ROOT_PREFIX=~/mamba
micromamba create -y -n fea -c conda-forge calculix gmsh python-gmsh numpy scipy matplotlib meshio pyvista pip
micromamba run -n fea python -m pip install pytetwild
micromamba run -n fea python <script>.py ...
```

The conda-forge `ccx` uses the SPOOLES solver. Set `OMP_NUM_THREADS` and
`CCX_NPROC_EQUATION_SOLVER` to use more than one core.

## Pipeline

1. **Geometry.** From OpenSCAD, the STL every project already exports. The tray of case 1 was
   solved from both its STL and its STEP: the same results within 3 % (below).
   - **OpenSCAD STL (default):** fTetWild (`pytetwild.tetrahedralize`) fills it with 4-node
     tetrahedra, keeping the surface within an envelope (0.03 mm here), and a node added at the
     middle of every edge makes them 10-node. Two traps:
     - fTetWild numbers the corners the other way round from CalculiX ("nonpositive jacobian" on
       every element): flip the tetrahedra whose (b − a) × (c − a) · (d − a) is negative;
     - the surface is only within the envelope, so pick faces with a tolerance of about twice
       it, not 1e-3.

     About 2–3 min of meshing per part (the tray at h = 1.2 mm, the soap caddy's parts at 1.5–2.5),
     against about 1 min for a linear solve of the whole assembly. Meshing is the slow step, so
     `caddy_model.mesh_stl` caches each mesh by the STL's content (`~/.cache/fea-mesh`): a variant
     that changes one part meshes only that part. A looser envelope (0.1 mm) would mesh faster,
     but then every part, the reference included, has to be meshed again to compare like with
     like.
   - **STEP, when there is one:** gmsh meshes it cleanly and fast. OpenSCAD cannot write STEP.
     The STEPs here came from the Fusion rebuild of sink-organizers, exported per component with
     the Fusion MCP.
   - **What failed on the STL:** gmsh rebuilding surfaces from it (`classifySurfaces` with
     reparametrisation) ran over 10 min and was stopped. Without reparametrisation it fails on
     "wrong topology of boundary mesh". A volume on the raw triangles makes no tetrahedra.
     Remeshing the STL first with MeshLab's isotropic remeshing made it worse: the STL has 57
     self-intersecting triangles, 1 804 after remeshing.
2. **Mesh** (gmsh on a STEP; fTetWild on an STL, see above): `Mesh.ElementOrder 2` (10-node tetrahedra, needed for walls bending
   only 2–3 elements thick), `Mesh.Algorithm3D 10` (HXT), `MeshSizeMax` = h.
   gmsh and CalculiX number the 10-node tetrahedron differently: swap the last two nodes
   (gmsh `0..9` → C3D10 `0 1 2 3 4 5 6 7 9 8`).
3. **Deck** (`.inp`, written by the project script): nodes, `C3D10` elements, `*MATERIAL`, sets
   picked by geometry (faces whose three corners satisfy a test such as "on the slat tops"),
   `*BOUNDARY` for supports, `*DLOAD` pressures for loads (total force / loaded area).
   Tetrahedron faces for `*DLOAD` and `*SURFACE`: `S1` = 1-2-3, `S2` = 1-4-2, `S3` = 2-4-3,
   `S4` = 3-4-1.
4. **Solve:** `ccx -i <job>`. Results in `<job>.dat` (what `*NODE PRINT` / `*EL PRINT` ask for:
   text, easy to parse) and `<job>.frd` (`*NODE FILE` / `*EL FILE`: for viewing).
5. **Read:** displacement, von Mises, principal stress, and **the stress components along and
   across the print layers** (see [Reading the results](#reading-the-results)).
6. **Look:** ParaView to explore, Blender for the images (see [Viewing](#viewing)).

## Linear or nonlinear

A run is **linear** when the response is proportional to the load: twice the force gives twice the
deflection and stress, and the response to two loads together is the sum of the responses to each.
That holds while:
- the material stays elastic (it springs back; true at margins of 4–5×);
- the deflections are small (the part works the same way after it bends);
- nothing about the joints changes (what is joined stays joined, what is apart stays apart).

**Contact breaks the third condition.** A surface that only pushes behaves one way where it presses
and another where it lifts, and which is which is only known after solving. So the solver guesses,
solves, checks which areas opened or closed, corrects and solves again, in load increments. Each
iteration is a full solve.

| | Linear (bonded joints) | Nonlinear (contact) |
|---|---|---|
| Solves per load case | 1 | Tens per increment, several increments |
| Time, soap caddy assembly | Minutes | Tens of minutes to hours, or no convergence |
| One more load case | Seconds to a minute: the stiffness matrix depends on the geometry, material and supports, not on the loads | A full new run |
| Combining cases | Add and scale results (daily use = bottle + hand; a 40 N hand = 30 N × 4/3) | Recompute every combination, since the contact areas change |
| Blind to | Joints that open, gaps that close | — |

Start linear. Check every bonded joint for tension (see [Assembly](#assembly)). Use contact only on
the joints that need it.

## Load cases

Take them from how the piece is really used, and ask the user. A case nobody will ever apply wastes
a run and can push the design the wrong way. A case that is always there (a full bottle hanging all
day) matters more than its size suggests, because PETG creeps under a constant load.

The soap caddy's, agreed with the user:

| Case | Loads | For |
|---|---|---|
| 1. Daily use | the bottle on its 45° neck seat (6.5 N), a hand pressing the sponge (30 N on the slats), own weight | Load sharing and margins in normal use |
| 2. Squeezing the bottle | the bottle on its seat, 30 N pushing it towards the wall on the inside of the box's back wall, own weight | The box's back wall; its 0.5 mm gap to the housings and 1.9 mm to the upper button heads; the cups, all in compression |
| 3. Bottle only | the bottle on its seat, own weight | The permanent load: creep, and what the cups hold all day |

Discarded: pushing the bottle down onto its seat (it goes in gently) and squeezing it against the
collar (it is squeezed towards the wall).

The cutlery drainer's. The weights come from product sheets: a teaspoon 20–30 g, a fork 35–46 g, a
spoon 50–60 g, a table knife 75–92 g, a chef's knife 170–260 g, a paring knife 20–60 g. A meal for
four with the kitchen knives comes to about 1050 g.

| Case | Loads | For |
|---|---|---|
| 1. Daily use, permanent | 350 g in each of the three bins (on the rack, under each bin's footprint), a soaked towel of 300 g over the bar, own weight | Stiffness, what the cups hold all day, creep |
| 2. One end bin | 600 g in one end bin (all the knives), the others empty, the towel | Asymmetry. It came out milder than case 1, so the study left it out |
| 3. Towel pulled | case 1 + 20 N on the bar, down and forward at 45°, in the middle or at one end | The handle's pins, the plate, the cups' peak pull |

Discarded: leaning a hand on a bin (nobody does).

**Mark which case is permanent.** On the soap caddy, the hand is momentary and only the bottle
stays. On the drainer, the cutlery and the towel hang for hours, so the daily case is also the
permanent one.

Bins that only rest on a part are not meshed: their weight and what they hold become a pressure
on their footprint. That is the pessimistic end for the part under them. A bin is a stiff box,
so in reality its walls carry much of the load to its edges.

A load on a cone (the bottle's shoulder on a 45° seat) is a pressure normal to the cone, which is
how a frictionless shoulder pushes. For a vertical resultant F, p = F / (A·cos 45°). The horizontal
components cancel overall, but they load the collar in hoop, which a vertical load on the box floor
would miss.

## Modelling choices

### Material

PETG Basic, Bambu TDS V2.0 (ISO 527): E = 1460 MPa in X-Y (1120 in Z), tensile strength 48 MPa in
X-Y (39 in Z), elongation 11 % (5.7 % in Z), density 1.25 g/cm³; ν = 0.38 (typical for PETG, not
in the TDS). These are TDS **V2.0**; PETG Basic is now V3.0 (E 2780 / 2550 MPa, tensile 51 / 35),
about twice as stiff, so the soap caddy's deflections are on the safe side for new spools.
Every filament's TDS, and a table of their figures, is in [tools/materials](../materials/README.md).

The solver treats the material as **isotropic, with the X-Y modulus**. A printed part is not
isotropic, so:
- **Strength:** compare each stress with its own allowable. Along the layers, 48 MPa. Across
  them, derate to 40 % for PETG (CLAUDE.md §2.3), ≈ 19 MPa. This is why the results are split by
  direction.
- **Stiffness:** the Z modulus is about a quarter lower, so deflections across the layers come out
  slightly short. Read them as "about", not exact. CalculiX supports orthotropic materials if this
  ever matters (`*ELASTIC, TYPE=ENGINEERING CONSTANTS`).
- Infill, walls and seams are not modelled. Parts made of 1–2 mm walls (these organizers) are close
  to solid. A thick part with sparse infill is not: model it as its walls, or scale E down.

### Single part

- **Supports:** fix only the directions the support actually stops, on the faces that actually
  touch (the tray: the vertical direction on its underside where it lies on the ledges). Add one
  or two "anchor" nodes held sideways so the part cannot slide as a rigid body.
- **Loads:** a pressure over the faces the load acts on, the total force divided by their area
  (the hand: 30 N over the slat tops under the sponge).
- **Mesh convergence:** run 2–3 sizes (e.g. 2.0 / 1.2 / 0.8 mm). Deflection and broad stress
  levels must settle; peaks that keep growing are singularities (see below).

### Assembly

Each printed part is meshed separately. The joints between them are modelled at one of three
levels:

| Level | Joints | Cost | Use |
|---|---|---|---|
| Chain of parts | Solve one part, apply its reaction forces to the next | Cheapest | Simple, statically clear load paths |
| Bonded (`*TIE`) | The parts glued where they touch | Linear: minutes | Joints that only ever push, or that are locked (a tight dovetail) |
| Contact (`*CONTACT PAIR`) | Surfaces push but never pull, and slide with friction | Nonlinear: tens of minutes to hours, may not converge | Joints that can open or slide, or to check the bonded model |

A bonded joint also carries tension and shear that the real joint cannot. So after a bonded run,
**check the normal stress across each joint**: compression everywhere means bonding changed
nothing; tension somewhere means that joint needs contact.

**The wall** is a boundary condition, not a part. For a keyhole on a button on a suction cup:
- the button clamps its pad between its flange and its cone head, so the button and the pad move
  together: one `*RIGID BODY` per cup, made of the nodes where the shank bears on the top of the
  slot and the back-face nodes under the flange;
- its reference node sits **where the cup meets the wall** (`wall_gap` behind the plate: the stud
  and the hub are part of the rigid body), held in x, y and z;
- its rotations are left **free**. A suction cup hardly resists a turn: tilted, it peels off.

The reaction at each reference node (the force of the wall on the plate) is the load on that
cup: − y means the plate presses on the wall, + y means it pulls off it, which loads the cup in
tension. Compare that pull with what a cup holds, and remember the sideways shear too.

**Why the hinge matters.** The first models held every node of the shank and the flange fixed.
That clamps the plate at each cup, and each cup took a share of the piece's turning moment as a
local bending moment, which a suction cup cannot carry:
- the totals of the node sets hid it, because the fixed nodes push and pull against each other
  in pairs that cancel out;
- the soap caddy's top cup came out at 5.3 N in daily use, against 13.8 N with the hinge;
- the drainer's upper cups came out at 4.6 N, against 12.6 N.

With hinges, what the cups pull is statics: the turning moment of the loads about the lower
row, divided by the distance between the rows. The plate's stiffness only shifts it between
cups. So check it by hand (see [Reading the results](#reading-the-results)).

**Ties across a gap lose moment.** A `*TIE` makes each slave node move with the point of the
master surface it is tied to. When the two are apart, the force passes from one to the other
without the moment of that offset, so the model is no longer in balance.
- **The drainer's case:** with `POSITION TOLERANCE=0.6`, the stepped lead-ins at the tails' ends
  (0.2 mm steps, up to a few tenths off the housing) were tied, and about 30 N per node went
  through them. The cups lost a third of the turning moment.
- **The fix:**
  - tolerance 0.25 mm, which still covers the STL meshes' 0.1 mm envelope and the fits' plays;
  - leave the lead-in zones (and anything else that only nearly touches) out of the slave
    surface.
- **Check:** the cup forces against the statics. The drainer went from 34 % off to 4 %.

Contact settings used: `SURFACE TO SURFACE`, linear pressure-overclosure with slope 5000 N/mm³,
friction μ = 0.3 (stick slope 2000), `ADJUST=0.05` to close the tested 0.025 mm plays. Weak springs
to ground (`SPRING1`, 0.01 N/mm) on a few nodes of each loose part stop the first iteration from
being singular before the contacts carry load.

### What can touch: before and after an assembly run

A model keeps two parts apart only where it was told to (a bonded joint or a contact pair).
Everywhere else they pass through each other with no resistance. So every assembly run is
bracketed by two checks.

**Before: list every place two parts come close.** Use
[`proximity.py`](proximity.py) on the parts' STEP files. Set the distance to the largest movement
you expect, or 2–3 mm, and more if unsure:

```sh
micromamba run -n fea python proximity.py 8 plate.step body.step tray.step box.step
```

It lists zones per pair of parts with their gap (under 0.6 mm: touching or a fit's play;
0.6–2.5 mm; beyond). Decide each one:

| Zone | Model it as |
|---|---|
| Always pressed, or locked by its shape (a tight dovetail) | Bonded (`*TIE`), then check it for tension |
| Can open (a part resting on a ledge) or close (a gap a load can shut) | Contact pair. CalculiX measures the initial gap itself: the pair does nothing while open and pushes once closed |
| Gap far larger than any movement | Nothing, but write down why |

Things that are not meshed are not in the list: the wall, screws, the buttons on the cups. Add
them by hand. Model them either as a small rigid part meshed and held (a button head fixed in
space) or as a stop on the nodes that would reach them (`GAP` elements).

The soap caddy at 8 mm gives 32 zones, which reduce to:

| Pair | Gap | What | Decision |
|---|---|---|---|
| tray, box ↔ body | 0 | standing on their ledges | contact (bonded: ≈ 30 % in tension) |
| tray, box ↔ body | 0.25 | their sides against the side walls | contact |
| box ↔ body | 0.25 | the box's front against the returns | contact |
| plate ↔ body | 0–0.025 | tails in the housings | bonded or contact |
| tray, box ↔ plate | 0.5 | their back corners and the housings' lips | contact |
| box ↔ plate | 5.8 | the box's back wall and the plate's face | **missed at first**: contact for the squeeze |
| box ↔ buttons | 1.9 | the box's back wall and the upper buttons' heads | not meshed: **add by hand** for the squeeze |

**After: did any part go into another?** Use [`penetration.py`](penetration.py) on the result
(`.vtu` from `frd_to_vtu.py`). It moves every node by its displacement, at real scale, and finds
the surface nodes of one part that lie inside another (the closest point on the other's surface
triangles, behind its outward face):

```sh
micromamba run -n fea python penetration.py <run>/<job>.vtu 0.1
```

Anything it finds is a contact the model is missing: add it and run again. A first version
compared each node with the nearest *node* of the other part. On a 2.5 mm mesh that flagged 0.2–0.8
mm "penetrations" at every bonded joint; measuring to the surface triangles removed them. The soap
caddy, bonded: daily use, none; squeeze, the box's back wall up to 1.9 mm into the plate.

## Reading the results

- **Singularities:** a sharp inside corner or the edge of a support gives a stress peak that grows
  every time the mesh is refined (tray: 19 → 25 → 33 MPa at 2.0 / 1.2 / 0.8 mm). It is not real:
  real corners have a radius and the plastic yields locally. Read the levels that converge: the
  99.5th percentile per region, or the maximum away from corners.
- **Direction:** split the stress into components along the print axes (`sxx`, `syy`, `szz`) and
  compare the one across the layers with the derated allowable. Von Mises alone hides this.
- **Margin** = allowable / converged stress for that direction. A margin of 4–5× is comfortable for
  occasional loads on PETG. Constant loads also creep (PETG, warm water), so keep more margin there.
- **Check the balance by hand** before trusting the reactions.
  - **The loads:** add up every load's force and its moment, from the `.inp`: own weight per
    element at its centroid, pressures per face.
  - **The reactions:** compare that with the reactions at their nodes. The total force always
    matches; the moment does not when something in the model takes moment it should not (a
    clamped support, a tie across a gap).
  - **Cups:** for cups in two rows, the upper row's total pull is (the loads' moment about the
    lower row) / (row distance). If the model gives less, find where the rest went.

## Viewing

- **ParaView (interactive):** [`frd_to_vtu.py`](frd_to_vtu.py) converts the last increment of
  the results to `.vtu`. It writes U, von Mises, the stress components, the largest principal
  stress, and a `part` number per element (so a threshold on `part` can show or hide a part).
  [`paraview_setup.py`](paraview_setup.py) opens it ready to look at: deformed, coloured by von
  Mises, with the undeformed edges in grey. ccx2paraview 3.x crashes with current numpy (complex
  eigenvalues in its principal stresses), hence the converter of our own.

  ```sh
  micromamba run -n fea python frd_to_vtu.py <run> <job>
  FEA_VTU=<run>/<job>.vtu FEA_WARP=20 FEA_VMAX=3 \
      /Applications/ParaView-6.2.0.app/Contents/MacOS/paraview --script=paraview_setup.py
  ```

  The `.frd` grows one increment at a time, so a long nonlinear run can be looked at while it is
  still solving: copy the `.inp` and the `.frd` to another folder and convert the copy.

- **Blender (images):** [`to_ply.py`](to_ply.py) writes the outer surface, deformed and coloured
  by von Mises and by the stress along one axis. [`render_ply.py`](render_ply.py) renders it with
  Workbench (flat colours, seconds), and the colour bar goes on the side:

  ```sh
  micromamba run -n fea python to_ply.py <run> <job> 5 10 y 4    # x5 deformation, vM 0..10, syy +-4
  blender -b -P render_ply.py -- <run>/vm.ply <run>/vm hero,under
  ```

  `under` uses flat lighting: from below, the studio light leaves the part black.

- **Sections:** [`section.py`](section.py) (ParaView's `pvpython`, no window) cuts the result
  at a plane x = const and colours each part, with the undeformed outline in black. Use it to see
  inside an assembly, or to check whether two parts went through each other:

  ```sh
  /Applications/ParaView-6.2.0.app/Contents/bin/pvpython section.py <run>/<job>.vtu out.png 1 0
  ```

- **Exaggerated deformation makes neighbours overlap.** At ×3 or ×10, parts a few mm apart are
  drawn through each other. Before reading an overlap as a result, look at it at ×1. If the parts
  still overlap at real scale, the model is missing a contact there.

## Case studies

### 1. Soap caddy tray, single part (2026-10-24)

[`projects/sink-organizers/fea/tray_fea.py`](../../projects/sink-organizers/fea/tray_fea.py).
A hand pressing the sponge: 30 N on the slat tops under the sponge. The tray lies on the body's two
side ledges (vertical support on its underside over 3.36 mm each side).

| Mesh h | Nodes | Max sag | Slats p99.5 vM | Peak vM (singular) |
|---|---|---|---|---|
| 2.0 mm | 74 k | 1.68 mm | 7.1 MPa | 19 MPa |
| 1.2 mm | 199 k | 1.69 mm | 7.1 MPa | 25 MPa |
| 0.8 mm | 487 k | 1.71 mm | 7.1 MPa | 33 MPa |

Each run took 10 s to 2 min, mesh to results.

- **Deflection:** 1.7 mm (about 2 mm with the Z modulus), at the middle of the **front tie**. The tie
  carries the slats' front ends and spans the 94 mm between the side rims.
- **Hardest-working member:** the front tie, bending along x, inside the layers (the tray prints on
  its back). 10 MPa against 48 MPa: margin ≈ 4.7×.
- **Across the layers:** the slats' stress along their length (y = print Z) peaks at 3.9 MPa where
  they meet the back rim, against 19 MPa: margin ≈ 5×.
- **From the OpenSCAD STL** (fTetWild, h = 1.2 mm, 281 k nodes, ≈ 3 min): sag 1.70 mm, slats p99.5
  6.9 MPa, front tie 9.0 MPa, across the layers 3.4 MPa. The same as the STEP within 3 %.
- **Against the hand calculation:** the README gives the slats ≈ 4× across the layers. The slats are
  fine at about 5×. The member that works hardest is the front tie (≈ 4.7×, in the layers), which
  the hand calculation did not look at.

### 2. Soap caddy on the wall, assembly with contact (2026-10-24)

[`projects/sink-organizers/fea/assembly_fea.py`](../../projects/sink-organizers/fea/assembly_fea.py).
The plate, body, tray and box, each meshed from its STEP at h = 2.5 mm (about 500 k lines of deck).
- **Contacts:** tray on its ledges, box on its ledges, tails in the housings, all with friction.
- **The wall:** the four buttons, as described in [Assembly](#assembly).
- **Loads:** the hand (30 N on the slats), a full bottle (6.5 N on the box floor) and the parts'
  own weight.

Progress so far: after 6 min and 16 iterations (≈ 22 s each) the first quarter of the load had not
converged. The residual force swung between 900 and 2 500 N while about 50 000 contact elements
opened and closed. Large contact areas that start exactly flush (the tails' wide faces on the plate,
the trays on sloping ledges), with friction, are a known source of this. The first quarter of the load converged after 24 iterations (≈ 9 min). The cup reactions at
that point already match the README's reasoning:
- the two **lower cups carry almost all the weight** (4.6 N each in z) and **press** on the wall
  (1.1 N each);
- the **lower of the upper cups pulls** off the wall (1.1 N);
- the upper pair carry almost nothing vertically (0.3 and 0.1 N).

The second increment did not converge: after 50 iterations (≈ 20 min) the residual force was
still around 2·10⁵ N, the corrections 100 %, and the contact elements kept changing (220 k → 55 k).
CalculiX then halved the increment and tried again. The log showed why it fails: the largest
correction was 36 mm sideways (x), on a node of the **box**.

**Lesson: a loose part must be held by contacts in every direction it is held in reality.** The
model has the box and the tray standing on their ledges, but not the body's side walls that guide
them sideways (0.25 mm play). With only friction and the weak springs across x, the box slides
off sideways and the solver chases it. Before a contact run, list for each loose part what stops
it in x, y and z, and model each of those surfaces (or hold the part in that direction).

**Second attempt**, with the side walls and the stops modelled: the first quarter of the load
converged in 23 iterations (≈ 12 min). The second ran 60 iterations, cut its increment and was
stopped after ≈ 1 h. The comparison with the bonded model (case 3) uses that first quarter: the
model is linear, so the bonded result scales by 0.25. Each cup's push or pull on the wall matched
(1.11 against 1.11 N), and the vertical shares differed by up to 0.5 N. **Bonded is good enough for
the loads on the wall, at about a hundredth of the cost.** Contact is for the joints that
change, like the squeeze below.

**Squeeze, with contact on that joint only** (`squeeze_contact.py`): the joints stay bonded, and
the box's back wall gets contact with the upper buttons' heads (rigid discs) and the plate's front
faces. It converged in 4 increments, ≈ 25 min. The wall closes its 1.9 mm gap and rests on the
heads, which take about half the push. Contact limited to the joint that changes is what made it
solvable.

### 3. Same assembly, bonded joints (2026-10-24)

[`projects/sink-organizers/fea/assembly_tie.py`](../../projects/sink-organizers/fea/assembly_tie.py).
It uses the same meshes, surfaces, wall and loads, shared with case 2 through
[`caddy_model.py`](../../projects/sink-organizers/fea/caddy_model.py), with `*TIE` on the three
joints. It runs the three [load cases](#load-cases) as one linear run each:
- the bottle on its 45° seat;
- in the squeeze case, the box's back corners also bonded to the housings' lips, 0.5 mm behind
  them (`POSITION TOLERANCE=0.6`).

For each case it prints:
- the cup reactions and the largest deflection;
- von Mises (99.5th percentile and peak) per part;
- the share of each bonded joint's area in tension, which the real joint could not carry;
- for the squeeze case, how far the box's back wall moves at the upper buttons, against their
  1.9 mm gap.

`check` as the case meshes the model and lists the surfaces it picked (6 s), to check the
selections before a run.

**Run:** 1 min for all three cases, meshing included (≈ 20 s per case). The first run failed
with "nonpositive jacobian". By default `*TIE` moves the slave nodes onto the master within the
position tolerance (0.6 mm), and on the tails that turned elements inside out. `ADJUST=NO` keeps
them in place.

| | Daily use | Squeeze | Bottle only |
|---|---|---|---|
| Lower cups, each: down / on the wall | 17.8 N / presses 4.5 N | 0.5 N / presses 3.4 N | 3.8 N / presses 0.8 N |
| Upper cups (lower one / top one): down | 2.1 / 0.9 N | 5.3 / 2.3 N | 0.7 / 0.3 N |
| Upper cups: on the wall | **pull 4.4 / 4.5 N** | press 10.8 / 11.7 N | pull 0.8 / 0.8 N |
| Largest deflection | 2.35 mm, the tray's front tie | **9.2 mm, the box's back wall** | 0.54 mm, the box |
| p99.5 von Mises: plate / body / tray / box | 4.8 / 1.2 / 7.3 / 1.4 MPa | 12.5 / 1.1 / 0.1 / **16.9** MPa | 0.9 / 0.4 / 0.0 / 1.4 MPa |
| Bonded area in tension: tray bottom / box bottom / tails | **30 % / 30 % / 18 %** | 0 / 16 / 28 % (box back on the lips: 49 %) | 0 / 31 / 2 % |

What it says:
- **Cups.** Pressing on the sponge, the upper pair pull off the wall with ≈ 4.5 N each and the lower
  pair press and carry the weight. The README's description holds. The permanent pull, the bottle
  alone, is 0.8 N per upper cup: tiny for a 50 mm cup.
- **Daily use is easy.** The tray works hardest (7.3 MPa, its front tie). The assembly's own give
  (body, plate, cups) adds 0.6 mm to the tray's sag: 2.35 mm here against 1.7 mm alone.
- **Squeezing is not.** With nothing behind it, the box's back wall bends 5–9 mm towards the wall,
  far past its 1.9 mm gap to the upper button heads. So in reality it **closes the gap and leans on
  the buttons**, which the bonded model cannot show. Free, it would reach 17 MPa near its slots,
  mostly vertical stress, that is, across the box's layers (it prints standing), against 19 MPa
  allowed: no margin. The buttons stop it first, so the real stress is lower. That needs the
  contact model, with the button heads in it.
  At real scale (×1), a section through the upper buttons shows the box's back wall going 3.4 mm
  into the plate. A solid cannot do that, so the squeeze case cannot be solved bonded. Its stress
  and deflection only flag that the box will lean on the buttons and the plate.
- **Bonding is not equivalent here.** About 30 % of the tray's and the box's seats come out in
  tension: they would lift off their ledges at the back (the tray rocks forward under the hand,
  the box floor bends under the bottle). The tails' 18 % is partly real (their 45° flanks do pull
  on the housings) and partly not (their wide faces only rest on the plate). Case 2 (contact) is
  the reference to compare with.

**The plate's slot ends.** In ParaView, the plate's back face lights up at the ends of its upper
slots. The stress there is horizontal (x).
- **Load path:** the upper cups hold the plate in the middle (x = 0), while the body, nodding
  forward, pulls the housings at its edges (x = ±50). The plate's upper half works as a horizontal
  beam, held in the middle and loaded at its ends. Each column of slots cuts that beam, and only
  the 2.6 mm bridges between a column's segments (where long slots split) and the top margin carry
  the bending across it.
- **Where it peaks:** the columns next to the upper pads (x = ±19.8, tension) and the outermost
  ones (±39.6, compression), at the splits (z = 152, 178.8) and the top (202.8).
- **Real, not the mesh:** with the plate refined from 2.5 to 1 mm (717 k nodes, 61 s) the peak went
  from 8.5 to 9.9 MPa (sxx 9.0 → 10.2). It grows about 15 % and settles, as a real, rounded stress
  raiser does; a singularity would keep growing.
- **Verdict:** in the layers (the plate prints flat), 10 against 48 MPa, margin ≈ 4.8×. Under 2 MPa
  with the bottle alone. Fine.
- **To spread it, if ever needed:**
  - leave out the slot column next to each upper pad (the moment is largest near the middle);
  - make the bridges between segments wider, or add more of them. Keep them lined up: a beam
    bending in x needs continuous horizontal ribs, which staggered slots would break;
  - a thicker plate (1.68 → 2.1 mm: about −36 %, bending goes with t²);
  - upper cups near the housings rather than in the middle (they are where the old cups are on
    the wall).

Compared with case 2: start bonded, check the joints for tension, and add contact only where
the joint itself changes the answer.

### 4. Soap caddy wall plate, one variable at a time (2026-10-24)

The project's full record, with images and the decision, is in
[projects/sink-organizers/fea/README.md](../../projects/sink-organizers/fea/README.md). Chosen:
WH0i20 (windows, upper bands 20 mm).

[`projects/sink-organizers/fea/variants.py`](../../projects/sink-organizers/fea/variants.py).
**Goal:** the least material in the wall plate, and the least bending in daily use.

**Method:**
- Each variant changes one `common.scad` parameter from the plate as it is (W: one from H1).
  The new parameters default to the current geometry: same volume and triangle count for both
  pieces' plates.
- Each variant is exported from OpenSCAD, meshed with fTetWild (h 2.5 mm, the plate 1.5 mm) and
  solved bonded under daily use (bottle on its seat + 30 N hand).
- **"Moves"** is the plate's largest displacement: its own bending, since the buttons hold it.

| Variant | Change | Plate (mm³) | Moves (mm) | Slot field peak / p99 (MPa) | Largest deflection (mm) |
|---|---|---|---|---|---|
| V0 | as is | 43 171 | 1.57 | 9.3 / 6.4 | 2.37 |
| T1 | `back_t=1.26` | 36 885 (−14.6 %) | 2.69 (+71 %) | 14.0 / 9.9 | 3.00 |
| T2 | `back_t=2.1` | 49 453 (+14.6 %) | 1.06 (−33 %) | 7.3 / 4.4 | 2.14 |
| H1 | `plate_window=[1]` (upper windows, full height) | 40 779 (−5.5 %) | 2.03 (+29 %) | 8.8 / 6.9 | 2.57 |
| W | H1 + `plate_window_inset=14` (50 mm tall) | 43 018 (−0.4 %) | **1.23 (−22 %)** | **4.3 / 3.8** | 2.22 |
| H0 | `plate_window=[0]` (lower window) | **39 174 (−9.3 %)** | 1.61 (+3 %) | 9.8 / 6.5 | 2.39 |
| C1 | `plate_slot_clear=4.3` | 44 114 (+2.2 %) | 1.27 (−19 %) | 7.8 / 4.9 | 2.24 |
| B1 | `plate_bridge=0.8` | 43 397 (+0.5 %) | 1.52 (−3 %) | 8.5 / 5.9 | 2.35 |
| L1 | `plate_slot_max_len=22` | 43 358 (+0.4 %) | 1.43 (−9 %) | 8.8 / 5.8 | 2.31 |

**What it says:**
- **The solid bands above and below the upper field carry the plate.** Opening the whole upper
  field (H1) loses 29 % of stiffness. Closing 14 mm top and bottom of it again (W) gains 22 %
  over the slots, for the same material, and halves the stress. The bending runs across the
  plate (see case 3), and continuous horizontal material is what resists it.
- **The lower field hardly matters:** one window there (H0) saves 9.3 % of the plate for 3 % more
  bending.
- **Thickness** buys stiffness at the worst rate: +14.6 % material for −33 %.
- Wider or more bridges (B1, L1) change little. Keeping the slots away from the upper pads (C1)
  works almost as well as W, for 2 % more material.

**Second round, from W** (`plate_window_inset` per zone: `[lower, upper]`):

| Variant | Change | Plate (mm³) | Moves (mm) | Slot field peak / p99 (MPa) | Largest deflection (mm) |
|---|---|---|---|---|---|
| WH0 | W + lower window (`plate_window=[0,1]`, `plate_window_inset=[0,14]`) | 39 021 (−9.6 %) | 1.26 (−20 %) | 4.5 / 3.9 | 2.23 |
| WH0i8 | WH0, upper bands 8 mm | 38 061 (−11.8 %) | 1.48 (−6 %) | 5.6 / 4.7 | 2.33 |
| WH0i20 | WH0, upper bands 20 mm | 39 980 (−7.4 %) | 1.11 (−29 %) | 3.9 / 3.4 | 2.17 |

All three take less material **and** bend less than the plate as it is. The upper bands set the
trade: each 6 mm more costs about 960 mm³ (2.2 % of the plate) and takes off about 0.2 mm of bending.

**Both load cases, the candidates** (moves: daily / bottle only):

| Variant | Plate | Moves daily | Moves bottle only | Peak daily / bottle | Top cup pull daily / bottle |
|---|---|---|---|---|---|
| V0 | 43 171 mm³ | 1.57 mm | 0.29 mm | 9.3 / 1.8 MPa | 4.5 / 0.8 N |
| WH0i8 | −11.8 % | 1.48 (−6 %) | 0.28 (−5 %) | 5.6 / 1.0 | 5.2 / 1.0 |
| WH0i11 | −10.7 % | 1.36 (−14 %) | 0.25 (−14 %) | 4.8 / 0.9 | 5.3 / 1.0 |
| WH0 (14 mm) | −9.6 % | 1.26 (−20 %) | 0.24 (−19 %) | 4.5 / 0.8 | 5.3 / 1.0 |
| WH0i20 | −7.4 % | 1.11 (−29 %) | 0.21 (−29 %) | 3.9 / 0.7 | 5.3 / 1.0 |

The two cases rank the variants the same way. Every candidate beats V0 on material, bending and
stress. The windows move a little of the pull onto the top cup (4.5 → 5.3 N daily, 0.8 → 1.0 N
permanent): still small for a 50 mm cup. Top 3 offered: WH0i20, WH0, WH0i11. The squeeze case is
still to do, with contact on the button heads.

**Corrected 2026-10-25.** The cup figures in cases 3 and 4 came from the clamped cups and the
0.6 mm ties (see [Assembly](#assembly)). The same plates, rerun with hinged cups and the tighter
ties:

| | Slots (V0) | Windows (WH0i20, chosen) |
|---|---|---|
| Plate moves, daily | 2.32 mm | 1.51 mm (−35 %) |
| Plate peak / p99, daily | 16.9 / 9.5 MPa | 10.2 / 5.2 MPa |
| Top cup pull, daily / bottle only | 13.5 / 2.75 N | 13.8 / 2.8 N |

The ranking held, and the windows win by more. The top cup carries almost all the pull: the
upper cups stand one above the other, and the one further from the lower row takes nearly all of
it.

**Meshing lessons from this run:**
- fTetWild's optimisation must be capped (`stop_energy=30, num_opt_iter=20`): uncapped, the
  plate ran over 40 min on one core; capped, 1.5 min.
- Capped, it leaves a few sliver tetrahedra (about 1 in 30 000) on which CalculiX stops
  ("nonpositive jacobian"). They are left out by shape (volume / longest edge³ < 1e-4; a regular
  tetrahedron is 0.118): about 0.02 mm³ in all.
- With the meshes cached, a variant that changes only the plate takes 1–2 min.

### 5. Cutlery drainer on the wall, its supports and plate (2026-10-25)

[`projects/sink-organizers/fea/drainer_fea.py`](../../projects/sink-organizers/fea/drainer_fea.py),
with the model in [`drainer_model.py`](../../projects/sink-organizers/fea/drainer_model.py). The
project's record, with the images, is in
[projects/sink-organizers/fea/README.md](../../projects/sink-organizers/fea/README.md#cutlery-drainer).

**Model:**
- **Parts:** plate, body, tray, rack and towel handle, from the OpenSCAD STLs (fTetWild, h 2.5 mm,
  the plate and the handle 1.5 mm).
- **Joints, bonded:** the tray and the rack on their ledges, the tails in their housings, and the
  handle's pins in their sockets (0.15 mm play).
- **Bins:** a pressure on their footprint on the rack.
- **Cups:** rigid buttons hinged at the wall.
- **Cost:** 670 k nodes, about 1 min per load case.

**What it found:**
- **The supports were in the wrong place.** The dovetails that carry the body are at x = ±104,
  the cups at ±60. In between, 44 mm of slotted 1.68 mm plate twisted: the whole body nodded
  forward about 2° and the towel bar dropped 9 mm under its daily load.
- **The supports beat material:**
  - cups 175 mm apart (−3.1 % plastic): bar 0.8 mm (−91 %), plate stress a seventh;
  - a 2.1 mm plate (+16.5 %): −34 %.
- **Row distance sets the cups' pull:** 55 → 80 mm cut the upper cups' permanent pull from
  13.2 to 9.1 N each.
- **With the cups under the dovetails, the plate's middle does nothing.** One window with 4 mm
  bands took 25 % of its plastic with no loss of stiffness.
- **Next weak point, the rack:**
  - 2.3–2.9 mm of sag in the middle of its 1.6 mm slotted floor, between fences that sag only
    0.5 mm;
  - 5.4 MPa (p99.9) within its layers.
- **The bonded towel pull is overstated where the body nods a lot:** the body's floor then closes
  its 3 mm gap onto the lower keyhole pads (found by `penetration.py`).
- **Bracketing a load you cannot model well.** How the bins load the rack decides its sag by a
  factor of ten, so each rack was solved under three assumptions:
  - an even pressure on each bin's footprint (pessimistic);
  - the load under each bin's walls, as a stiff box (realistic);
  - the bins meshed and bonded (far too optimistic: a box girder that resting bins are not).

  Resting bins with frictional contact did not converge in 1.5 hours: two slotted floors on each
  other open and close thousands of contact patches. Bracket instead of waiting.
- **Slot direction is a free stiffness variable.** The rack's floor slots turned to run front to
  back, so its strips span the short way between the fences: −29 % sag for +0.4 % plastic. With
  a 2.4 mm floor, the same plastic sags 35 % less than with the slots the other way.
- **Chosen by the user:** cups at the plate's corners and 80 mm between the rows, one window in
  the plate, the rack at 2.4 mm with its slots turned. Results:
  - the bar drops 0.7 mm instead of 8.8;
  - each upper cup pulls 9 N all day instead of 13;
  - the plate's plastic is −25 % and the rack's +31 %, about the same in all.
  - nothing closes under any case, so the bonded linear model holds.
