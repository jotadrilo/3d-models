# 3d-models

| | Project |
|---|---|
| <a href="projects/soap-caddy/"><img src="projects/soap-caddy/renders/soap-caddy-hero.webp" width="240" alt="Soap caddy"></a> | [soap-caddy](projects/soap-caddy/) — wall-mounted holder on suction cups for an upside-down dish soap bottle over a sponge cradle that drains into the sink (OpenSCAD) |
| <a href="projects/desk-hanger-rail/"><img src="projects/desk-hanger-rail/renders/desk-hanger-rail-hero.webp" width="240" alt="Desk hanger rail"></a> | [desk-hanger-rail](projects/desk-hanger-rail/) — clip-on rail under the desk edge for coat hangers, two C brackets and a bar (OpenSCAD) |
| <a href="projects/lattice-bowl/"><img src="projects/lattice-bowl/renders/lattice-bowl-hero.webp" width="240" alt="Lattice bowl"></a> | [lattice-bowl](projects/lattice-bowl/) — parametric lattice bowl (OpenSCAD) |
| <a href="projects/detergent-scoop/"><img src="projects/detergent-scoop/renders/detergent-scoop-hero.webp" width="240" alt="Detergent scoop"></a> | [detergent-scoop](projects/detergent-scoop/) — measuring scoop with an exact, parametric capacity that sits on the bottle cap (OpenSCAD) |
| <a href="projects/remote-stand/"><img src="projects/remote-stand/renders/remote-stand-hero.webp" width="240" alt="Remote stand"></a> | [remote-stand](projects/remote-stand/) — two-row stepped stand for TV remotes, ribbed (v1) or channelled (v2) (OpenSCAD) |
| <a href="projects/cosmere-tracker/"><img src="projects/cosmere-tracker/renders/cosmere-tracker-hero.webp" width="240" alt="Cosmere tracker"></a> | [cosmere-tracker](projects/cosmere-tracker/) — two-sided Health / Focus / Investiture wheels for the Cosmere RPG, multi-colour inlays (OpenSCAD) |

The models live in [`projects/`](projects/), one folder each. Everything they share lives in
[`tools/`](tools/): `bambu3mf.py` builds each project's ready-to-print Bambu Studio 3MF
(`make project`, `make report`), `render_studio.py` renders it in Blender (`make render`), and
[`tools/scad/`](tools/scad/) is the OpenSCAD library of functional components (mounts, joints,
holes, the house style), each one researched, documented in [CLAUDE.md](CLAUDE.md) and printable
as a sample. See [tools/README.md](tools/README.md).
