# 3d-models

| | Project |
|---|---|
| <a href="lattice-bowl/"><img src="lattice-bowl/renders/lattice-bowl-hero.webp" width="240" alt="Lattice bowl"></a> | [lattice-bowl](lattice-bowl/) — parametric lattice bowl (OpenSCAD) |
| <a href="detergent-scoop/"><img src="detergent-scoop/renders/detergent-scoop-hero.webp" width="240" alt="Detergent scoop"></a> | [detergent-scoop](detergent-scoop/) — measuring scoop with an exact, parametric capacity that sits on the bottle cap (OpenSCAD) |
| <a href="remote-stand/"><img src="remote-stand/renders/remote-stand-hero.webp" width="240" alt="Remote stand"></a> | [remote-stand](remote-stand/) — two-row stepped stand for TV remotes, ribbed (v1) or channelled (v2) (OpenSCAD) |
| <a href="cosmere-tracker/"><img src="cosmere-tracker/renders/cosmere-tracker-hero.webp" width="240" alt="Cosmere tracker"></a> | [cosmere-tracker](cosmere-tracker/) — two-sided Health / Focus / Investiture wheels for the Cosmere RPG, multi-colour inlays (OpenSCAD) |

Shared build scripts live in [`tools/`](tools/): `bambu3mf.py` builds each project's
ready-to-print Bambu Studio 3MF (`make project`, `make report`), and `render_studio.py` renders it
in Blender (`make render`). See [tools/README.md](tools/README.md).
