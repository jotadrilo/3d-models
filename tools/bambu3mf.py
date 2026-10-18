#!/usr/bin/env python3
"""Build ready-to-print Bambu Studio projects (.3mf) from OpenSCAD models.

Each project's `bambu_project.py` describes plates, objects and filaments with
this module; see CLAUDE.md §3 for how to lay out plates.

    from bambu3mf import Project, Filament, load_scad

    proj = Project("Scoop", process="0.20mm Standard @BBL X1C",
                   filaments=[Filament(PLA_BASIC, "#F2F2F2")])
    plate = proj.plate("Scoop")
    plate.add("Scoop", load_scad("detergent-scoop.scad", rotate=(180, 0, 0)))
    proj.write("detergent-scoop-p1s.3mf")

Geometry comes from OpenSCAD as a 3MF (lazy-union, colour-mode=model), grouped
by colour: each colour becomes one part of the Bambu object, printed with the
filament whose colour matches (or the one given in `colour_map`). Bambu
Studio's CLI fills in the full printer / process / filament settings from its
system presets.

Run as a script to slice a project with the Bambu Studio CLI and print time
and filament per plate:

    python3 tools/bambu3mf.py report <project>.3mf
"""
import json, math, os, re, subprocess, sys, tempfile, uuid, zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field

OPENSCAD = os.environ.get("OPENSCAD", "openscad")
BAMBU = os.environ.get("BAMBU_STUDIO", "/Applications/BambuStudio.app/Contents/MacOS/BambuStudio")
PROFILES = os.environ.get("BAMBU_PROFILES", "/Applications/BambuStudio.app/Contents/Resources/profiles/BBL")

BED = "Textured PEI Plate"
BED_W, BED_D = 256, 256            # P1S and X2D alike
EXCLUDED = (0, 0, 18, 28)          # front-left corner kept clear on the P1S (x0, y0, x1, y1)
PLATE_GAP = 0.2                    # Bambu lays plates out on a grid, 20 % apart
MARGIN = 3                         # minimum distance between objects and to the bed edge

PLA_BASIC = "Bambu PLA Basic @BBL P1S 0.4 nozzle"
PLA_MATTE = "Bambu PLA Matte @BBL P1S 0.4 nozzle"
PETG_HF = "Bambu PETG HF @BBL P1S 0.4 nozzle"
PETG_BASIC = "Bambu PETG Basic @BBL X1C"      # also the P1S 0.4 preset (no P1S-specific one)


@dataclass(frozen=True)
class Printer:
    machine: str                   # Bambu Studio machine preset
    tag: str                       # short name, used in file names: <project>-<tag>.3mf
    excluded: tuple = None         # bed area kept clear (x0, y0, x1, y1), if any
    height: float = 250

    def preset(self, kind, base):
        """System preset `base @BBL ...` (e.g. "Bambu PLA Matte", "0.16mm High
        Quality") made for this machine. The P1S has few of its own and
        uses the X1C ones; this finds whichever the profiles list it in."""
        hits = sorted(n for n, j in _presets(kind).items()
                      if n.startswith(base + " @") and self.machine in j.get("compatible_printers", []))
        if not hits:
            sys.exit(f"No {kind} preset '{base} @...' for {self.machine}")
        return min(hits, key=len)


P1S = Printer("Bambu Lab P1S 0.4 nozzle", "p1s", excluded=EXCLUDED, height=250)
# Two nozzles; the right one cannot reach x < 20.5 ("Left nozzle only area"), so
# layouts keep that strip clear and either nozzle can print any plate.
X2D = Printer("Bambu Lab X2D 0.4 nozzle", "x2d", excluded=(0, 0, 20.5, BED_D), height=261)
PRINTERS = {p.tag: p for p in (P1S, X2D)}
PRINTER = P1S.machine

NS = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
      'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
      'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p"')
CORE = "{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}"


# ---------------------------------------------------------------- geometry

class Mesh:
    """Triangles grouped by colour: {"#RRGGBB" or None: (vertices, triangles)}."""

    def __init__(self, by_colour):
        self.by_colour = by_colour

    def bbox(self):
        vs = [v for verts, _ in self.by_colour.values() for v in verts]
        return [min(v[i] for v in vs) for i in range(3)], [max(v[i] for v in vs) for i in range(3)]

    def colours(self):
        return list(self.by_colour)


def load_scad(scad, part=None, defs=(), rotate=(0, 0, 0), colour=True):
    """Export `scad` (optionally one `part`) and return it as a Mesh.

    `colour=False` is for single-colour models: without it, OpenSCAD tags the
    faces of an uncoloured model with its preview colours.

    `rotate` (degrees about X, Y, Z, applied in that order) orients the part
    for printing; the result is centred in XY and sits on z = 0.
    """
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "part.3mf")
        cmd = [OPENSCAD, "--enable=lazy-union", "-O", f"export-3mf/color-mode={'model' if colour else 'none'}"]
        if part is not None:
            cmd += ["-D", f'part="{part}"']
        for d in defs:
            cmd += ["-D", d]
        r = subprocess.run(cmd + ["-o", out, scad], capture_output=True, text=True)
        if r.returncode:
            sys.exit(f"OpenSCAD failed on {scad} ({part}):\n{r.stderr[-2000:]}")
        root = ET.fromstring(zipfile.ZipFile(out).read("3D/3dmodel.model"))

    materials = {}
    for group in root.iter():
        if group.tag.endswith("basematerials"):
            materials[group.get("id")] = [b.get("displaycolor", "")[:7].upper() for b in group]
    by_colour = {}
    for obj in root.iter(CORE + "object"):
        mesh = obj.find(CORE + "mesh")
        if mesh is None:
            continue
        verts = [(float(v.get("x")), float(v.get("y")), float(v.get("z")))
                 for v in mesh.find(CORE + "vertices")]
        pid, pindex = obj.get("pid"), obj.get("pindex")
        for t in mesh.find(CORE + "triangles"):
            p = t.get("p1", pindex)
            colour = materials[t.get("pid", pid)][int(p)] if p is not None else None
            vs, ts = by_colour.setdefault(colour, ([], []))
            base = len(vs)
            vs.extend(verts[int(t.get(k))] for k in ("v1", "v2", "v3"))
            ts.append((base, base + 1, base + 2))

    rot = _rotation(rotate)
    by_colour = {c: ([_apply(rot, v) for v in vs], ts) for c, (vs, ts) in by_colour.items()}
    lo, hi = Mesh(by_colour).bbox()
    cx, cy = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
    return Mesh({c: _dedup([(x - cx, y - cy, z - lo[2]) for x, y, z in vs], ts)
                 for c, (vs, ts) in by_colour.items()})


def _rotation(angles):
    m = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
    for axis, deg in enumerate(angles):
        if deg % 360 == 0:
            continue
        c, s = round(math.cos(math.radians(deg)), 12), round(math.sin(math.radians(deg)), 12)
        i, j = [(1, 2), (0, 2), (0, 1)][axis]
        r = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
        r[i][i], r[i][j], r[j][i], r[j][j] = c, -s, s, c
        if axis == 1:  # rotation about Y has the sine signs swapped
            r[i][j], r[j][i] = s, -s
        m = [[sum(r[a][k] * m[k][b] for k in range(3)) for b in range(3)] for a in range(3)]
    return m


def _apply(m, v):
    return tuple(sum(m[a][k] * v[k] for k in range(3)) for a in range(3))


def _dedup(verts, tris):
    index = {}
    remap = [index.setdefault(v, len(index)) for v in verts]
    out = [None] * len(index)
    for v, i in index.items():
        out[i] = v
    return out, [tuple(remap[i] for i in t) for t in tris]


# ---------------------------------------------------------------- project

@dataclass
class Filament:
    preset: str               # Bambu system filament preset
    colour: str               # "#RRGGBB"; also used to match OpenSCAD colours


@dataclass
class Object:
    name: str
    mesh: Mesh
    x: float
    y: float
    settings: dict            # per-object process overrides, e.g. {"wall_loops": "4"}
    part_name: object         # callable(colour) -> part name


@dataclass
class Plate:
    name: str
    prime_tower: tuple = (20, 30)     # front-left, clear of the excluded area
    objects: list = field(default_factory=list)

    def add(self, name, mesh, x=BED_W / 2, y=BED_D / 2, settings=None, part_name=None):
        """Place `mesh` centred at (x, y) on this plate (default: the plate centre)."""
        self.objects.append(Object(name, mesh, x, y, settings or {}, part_name or (lambda c: c or name)))


class Project:
    def __init__(self, title, process, filaments, process_overrides=None, colour_map=None,
                 printer=P1S, bed=BED):
        self.title, self.process, self.filaments = title, process, filaments
        self.process_overrides = process_overrides or {}
        self.colour_map = {k.upper(): v for k, v in (colour_map or {}).items()}
        self.printer, self.bed = printer, bed
        self.plates = []

    def plate(self, name, **kw):
        p = Plate(name, **kw)
        self.plates.append(p)
        return p

    def filament_for(self, colour):
        """1-based filament index for an OpenSCAD colour (None = uncoloured -> filament 1)."""
        if colour is None:
            return 1
        c = colour.upper()
        if c in self.colour_map:
            return self.colour_map[c]
        for i, f in enumerate(self.filaments, 1):
            if f.colour.upper() == c:
                return i
        sys.exit(f"{self.title}: no filament for colour {colour}; add it to filaments or colour_map")

    def check_layout(self):
        """Every object inside the bed, clear of the excluded corner and of each other,
        and no plate or object name Bambu Studio refuses on opening."""
        for plate in self.plates:
            for name in [plate.name] + [o.name for o in plate.objects]:
                if any(c in name for c in '<>:/\\|?*"'):
                    sys.exit(f"'{name}': Bambu Studio does not allow any of <>:/\\|?*\" in names")
            boxes = []
            for o in plate.objects:
                lo, hi = o.mesh.bbox()
                box = (o.x + lo[0], o.y + lo[1], o.x + hi[0], o.y + hi[1])
                if box[0] < MARGIN or box[1] < MARGIN or box[2] > BED_W - MARGIN or box[3] > BED_D - MARGIN:
                    sys.exit(f"{plate.name}: '{o.name}' does not fit on the bed {tuple(round(b, 1) for b in box)}")
                if hi[2] > self.printer.height:
                    sys.exit(f"{plate.name}: '{o.name}' is taller than {self.printer.height} mm")
                excluded = [("excluded area", self.printer.excluded)] if self.printer.excluded else []
                for other, b in boxes + excluded:
                    if box[0] < b[2] and b[0] < box[2] and box[1] < b[3] and b[1] < box[3]:
                        sys.exit(f"{plate.name}: '{o.name}' overlaps {other}")
                boxes.append((o.name, box))

    # -------------------------------------------------------- writing

    def write(self, out):
        self.check_layout()
        cols = _plate_columns(len(self.plates))
        files, rels, objects, items, settings, plates_cfg = {}, [], [], [], [], []
        next_id, k = 1, 0
        for pi, plate in enumerate(self.plates):
            ox = (pi % cols) * BED_W * (1 + PLATE_GAP)
            oy = -(pi // cols) * BED_D * (1 + PLATE_GAP)
            instances = []
            for o in plate.objects:
                k += 1
                parts = []
                for c, (vs, ts) in sorted(o.mesh.by_colour.items(), key=lambda kv: self.filament_for(kv[0])):
                    parts.append((next_id, c, vs, ts))
                    next_id += 1
                obj_id, next_id = next_id, next_id + 1
                path = f"/3D/Objects/object_{k}.model"
                files[path.lstrip("/")] = (
                    f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {NS}>'
                    '<metadata name="BambuStudio:3mfVersion">1</metadata>'
                    f"<resources>{''.join(_mesh_xml(i, v, t) for i, _, v, t in parts)}</resources><build/></model>")
                rels.append(path)
                comps = "".join(f'<component p:path="{path}" objectid="{i}" p:UUID="{uuid.uuid4()}" '
                                'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>' for i, *_ in parts)
                objects.append(f'<object id="{obj_id}" p:UUID="{uuid.uuid4()}" type="model">'
                               f"<components>{comps}</components></object>")
                items.append(f'<item objectid="{obj_id}" p:UUID="{uuid.uuid4()}" '
                             f'transform="1 0 0 0 1 0 0 0 1 {ox + o.x:.3f} {oy + o.y:.3f} 0" printable="1"/>')
                part_cfg = "".join(
                    f'<part id="{i}" subtype="normal_part">'
                    f'<metadata key="name" value="{_attr(o.part_name(c))}"/>'
                    '<metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>'
                    f'<metadata key="extruder" value="{self.filament_for(c)}"/></part>'
                    for i, c, _, _ in parts)
                extra = "".join(f'<metadata key="{key}" value="{_attr(v)}"/>' for key, v in o.settings.items())
                settings.append(f'<object id="{obj_id}"><metadata key="name" value="{_attr(o.name)}"/>'
                                f'<metadata key="extruder" value="{self.filament_for(parts[0][1])}"/>'
                                f"{extra}{part_cfg}</object>")
                instances.append(f'<model_instance><metadata key="object_id" value="{obj_id}"/>'
                                 '<metadata key="instance_id" value="0"/>'
                                 f'<metadata key="identify_id" value="{100 + k}"/></model_instance>')
            plates_cfg.append(f'<plate><metadata key="plater_id" value="{pi + 1}"/>'
                              f'<metadata key="plater_name" value="{_attr(plate.name)}"/>'
                              f'<metadata key="locked" value="false"/>{"".join(instances)}</plate>')

        with tempfile.TemporaryDirectory() as tmp:
            cfg, app = self._settings(tmp)
        files["3D/3dmodel.model"] = (
            f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {NS}>'
            f'<metadata name="Application">{_attr(app)}</metadata>'
            '<metadata name="BambuStudio:3mfVersion">1</metadata>'
            f'<metadata name="Title">{_attr(self.title)}</metadata>'
            f"<resources>{''.join(objects)}</resources><build>{''.join(items)}</build></model>")
        files["3D/_rels/3dmodel.model.rels"] = (
            '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            + "".join(f'<Relationship Target="{p}" Id="rel-{i}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
                      for i, p in enumerate(rels, 1)) + "</Relationships>")
        files["Metadata/model_settings.config"] = (
            f'<?xml version="1.0" encoding="UTF-8"?>\n<config>{"".join(settings)}{"".join(plates_cfg)}'
            "<assemble></assemble></config>")
        files["Metadata/project_settings.config"] = json.dumps(cfg, indent=4)
        files["[Content_Types].xml"] = (
            '<?xml version="1.0" encoding="UTF-8"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
            '<Default Extension="png" ContentType="image/png"/></Types>')
        files["_rels/.rels"] = (
            '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
            "</Relationships>")

        out = os.path.abspath(out)
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            for name, data in files.items():
                z.writestr(name, data)
        print("filaments:", ", ".join(f"{i}={f.colour} ({f.preset.split(' @')[0]})"
                                      for i, f in enumerate(self.filaments, 1)))
        print("plates:", ", ".join(f"{i}={p.name} ({len(p.objects)} objects)" for i, p in enumerate(self.plates, 1)))
        print("->", out)

    def _settings(self, tmp):
        """Full project settings as Bambu Studio writes them, from its CLI on a dummy model."""
        machine, process = os.path.join(tmp, "machine.json"), os.path.join(tmp, "process.json")
        json.dump(_flatten("machine", self.printer.machine), open(machine, "w"))
        json.dump(_flatten("process", self.process, self.process_overrides), open(process, "w"))
        fils = []
        for i, f in enumerate(self.filaments):
            path = os.path.join(tmp, f"filament{i}.json")
            json.dump(_flatten("filament", f.preset), open(path, "w"))
            fils.append(path)
        dummy, probe = os.path.join(tmp, "dummy.stl"), os.path.join(tmp, "probe.3mf")
        with open(dummy, "w") as fh:  # a 10 mm tetrahedron
            fh.write("solid d\n" + "".join(
                "facet normal 0 0 0\nouter loop\n" + "".join(f"vertex {v}\n" for v in t) + "endloop\nendfacet\n"
                for t in [("0 0 0", "0 10 0", "10 0 0"), ("0 0 0", "10 0 0", "0 0 10"),
                          ("0 0 0", "0 0 10", "0 10 0"), ("10 0 0", "0 10 0", "0 0 10")]) + "endsolid d\n")
        r = subprocess.run([BAMBU, "--debug", "1", "--load-settings", f"{machine};{process}",
                            "--load-filaments", ";".join(fils), "--export-3mf", probe, dummy],
                           capture_output=True, text=True, cwd=tmp)  # the CLI drops a result.json in cwd
        if r.returncode or not os.path.exists(probe):
            sys.exit("Bambu Studio CLI failed:\n" + r.stdout[-2000:] + r.stderr[-2000:])
        z = zipfile.ZipFile(probe)
        cfg = json.loads(z.read("Metadata/project_settings.config"))
        app = re.search(r'name="Application">([^<]*)<', z.read("3D/3dmodel.model").decode())
        colours = [f.colour.upper() for f in self.filaments]
        n = len(self.plates)
        # One N x N purge matrix per nozzle, back to back, and one multiplier per
        # nozzle: a dual-nozzle machine left with one matrix purges 0 on the other.
        nozzle_count = max(1, len(cfg.get("nozzle_diameter") or []))
        matrix = [str(flush(a, b)) for a in colours for b in colours]
        cfg.update(self.process_overrides)
        for key in ("flush_multiplier", "flush_multiplier_fast"):
            if isinstance(cfg.get(key), list) and cfg[key]:
                cfg[key] = (cfg[key] * nozzle_count)[:nozzle_count]
        cfg.update(curr_bed_type=self.bed, filament_colour=colours, filament_map=["1"] * len(colours),
                   flush_volumes_matrix=matrix * nozzle_count,
                   wipe_tower_x=[str(p.prime_tower[0]) for p in self.plates],
                   wipe_tower_y=[str(p.prime_tower[1]) for p in self.plates])
        # Dual-nozzle machines (X2D) refuse to slice without the nozzles mounted on
        # each extruder, which the GUI syncs from the printer: one of its type each.
        nozzles = cfg.get("nozzle_volume_type") or []
        if len(nozzles) > 1 and not any(cfg.get("extruder_nozzle_stats") or []):
            cfg["extruder_nozzle_stats"] = [f"{t}#1" for t in nozzles]
        if n > 1 and isinstance(cfg.get("wipe_tower_rotation_angle"), list):
            cfg["wipe_tower_rotation_angle"] = cfg["wipe_tower_rotation_angle"][:1] * n
        return cfg, app.group(1) if app else "BambuStudio"


def flush(src, dst):
    """Purge volume (mm3) going from src to dst colour: light after dark needs the most."""
    if src == dst:
        return 0
    lum = lambda c: sum(w * int(c[i:i + 2], 16) for w, i in ((0.3, 1), (0.59, 3), (0.11, 5))) / 255
    return round(160 + 520 * max(0.0, lum(dst) - lum(src)) + 60 * abs(lum(dst) - lum(src)))


def _plate_columns(n):
    """Columns of Bambu Studio's plate grid (PartPlateList::compute_colum_count)."""
    v = math.sqrt(n)
    return int(round(v) + 1 if v > round(v) else round(v))


_PRESETS = {}


def _presets(kind):
    """Every system preset of `kind` (machine, process, filament) by name."""
    if kind not in _PRESETS:
        _PRESETS[kind] = {}
        for f in os.listdir(os.path.join(PROFILES, kind)):
            if f.endswith(".json"):
                j = json.load(open(os.path.join(PROFILES, kind, f)))
                if "name" in j:
                    _PRESETS[kind][j["name"]] = j
    return _PRESETS[kind]


def _flatten(kind, name, extra=None):
    """A system preset with its `inherits` chain resolved, as the CLI needs it."""
    presets = _presets(kind)
    if name not in presets:
        sys.exit(f"Unknown {kind} preset: {name}")

    def resolve(n):
        j = presets[n]
        cfg = resolve(j["inherits"]) if j.get("inherits") else {}
        cfg.update(j)
        return cfg

    cfg = resolve(name)
    cfg.update(inherits="", name=name, **(extra or {}))
    return cfg


def _mesh_xml(oid, verts, tris):
    v = "".join(f'<vertex x="{x:.5f}" y="{y:.5f}" z="{z:.5f}"/>' for x, y, z in verts)
    t = "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris)
    return (f'<object id="{oid}" p:UUID="{uuid.uuid4()}" type="model"><mesh>'
            f"<vertices>{v}</vertices><triangles>{t}</triangles></mesh></object>")


def _attr(s):
    return str(s).replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;")


# ---------------------------------------------------------------- report

def report(path):
    """Slice every plate with the Bambu Studio CLI and print time and filament used."""
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "sliced.3mf")
        r = subprocess.run([BAMBU, "--debug", "1", "--slice", "0", "--export-3mf", out, os.path.abspath(path)],
                           capture_output=True, text=True, cwd=tmp)
        if r.returncode or not os.path.exists(out):
            sys.exit("Slicing failed:\n" + r.stdout[-3000:] + r.stderr[-2000:])
        info = ET.fromstring(zipfile.ZipFile(out).read("Metadata/slice_info.config"))
    total_s = total_g = 0.0
    for plate in info.iter("plate"):
        meta = {m.get("key"): m.get("value") for m in plate.findall("metadata")}
        # The CLI leaves "weight" empty on plates that do not use filament 1.
        secs = float(meta.get("prediction", 0))
        grams = float(meta.get("weight") or sum(float(f.get("used_g", 0)) for f in plate.iter("filament")))
        total_s, total_g = total_s + secs, total_g + grams
        fils = ", ".join(f"slot {f.get('id')} {f.get('color')} {float(f.get('used_g', 0)):.1f} g"
                         for f in plate.iter("filament"))
        print(f"plate {meta.get('index')}: {_hm(secs)}, {grams:.1f} g  ({fils})")
    print(f"total: {_hm(total_s)}, {total_g:.1f} g")


def _hm(secs):
    return f"{int(secs // 3600)} h {int(secs % 3600 // 60):02d} min"


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "report":
        report(sys.argv[2])
    else:
        sys.exit(__doc__)
