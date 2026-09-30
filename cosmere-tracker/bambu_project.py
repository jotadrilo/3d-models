#!/usr/bin/env python3
"""Build a ready-to-print Bambu Studio project for the Cosmere tracker.

Every part is exported from OpenSCAD as a multi-colour 3MF (one mesh per
colour), turned into a Bambu object whose parts are assigned to one filament
per colour, and placed on a single P1S plate. Bambu Studio's CLI then fills
in the full printer / process / filament settings from its system presets.

    python3 bambu_project.py [-o cosmere-tracker-p1s.3mf] [-D var=val ...]
"""
import argparse, json, os, re, subprocess, sys, tempfile, uuid, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "cosmere-tracker.scad")
OPENSCAD = os.environ.get("OPENSCAD", "openscad")
BAMBU = os.environ.get("BAMBU_STUDIO", "/Applications/BambuStudio.app/Contents/MacOS/BambuStudio")
PROFILES = os.environ.get("BAMBU_PROFILES", "/Applications/BambuStudio.app/Contents/Resources/profiles/BBL")

PRINTER = "Bambu Lab P1S 0.4 nozzle"
PROCESS = "0.20mm Standard @BBL X1C"      # 0.2 mm layers: the 0.6 mm inlays are 3 layers
FILAMENT = "Bambu PLA Basic @BBL P1S 0.4 nozzle"
BED = "Textured PEI Plate"
PRIME_TOWER = (20, 30)                    # front-left corner, clear of the excluded purge area
# Labels and digits are printed in the first layer: Arachne keeps thin strokes
# that Classic would drop, and elephant foot compensation would shrink them.
PROCESS_TWEAKS = {"wall_generator": "arachne", "elefant_foot_compensation": "0"}

# (object name, OpenSCAD part, bed centre x, y); the plate is 256 x 256.
LAYOUT = [
    ("Anillo decenas 1", "ring", 90, 36),
    ("Anillo decenas 2", "ring", 154, 36),
    ("Anillo decenas 3", "ring", 218, 36),
    ("Tapa delantera", "front", 104, 102),
    ("Disco unidades 1", "disc", 230, 102),
    ("Marco trasero", "frame", 104, 166),
    ("Disco unidades 2", "disc", 230, 166),
    ("Peana", "stand", 109, 221),
    ("Disco unidades 3", "disc", 234, 221),
]
PART_NAMES = {"body": "cuerpo", "ink": "incrustación"}

NS = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
      'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
      'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p"')


def openscad_meshes(part, defs, tmp):
    """Export one part and return {colour: (vertices, triangles)} centred on the bed origin."""
    out = os.path.join(tmp, f"{part}.3mf")
    cmd = [OPENSCAD, "--enable=lazy-union", "-O", "export-3mf/color-mode=model",
           "-D", f'part="{part}"', *sum((["-D", d] for d in defs), []), "-o", out, SCAD]
    subprocess.run(cmd, check=True, capture_output=True)
    xml = zipfile.ZipFile(out).read("3D/3dmodel.model").decode()
    colours = re.findall(r'<base name="[^"]*" displaycolor="(#[0-9A-Fa-f]{6})', xml)
    by_colour = {}
    for obj in re.findall(r"<object .*?</object>", xml, re.S):
        verts = [tuple(map(float, v)) for v in
                 re.findall(r'<vertex x="([^"]+)" y="([^"]+)" z="([^"]+)"', obj)]
        for a, b, c, p1 in re.findall(r'<triangle v1="(\d+)" v2="(\d+)" v3="(\d+)"[^>]*?p1="(\d+)"', obj):
            vs, ts = by_colour.setdefault(colours[int(p1)].upper(), ([], []))
            base = len(vs)
            vs.extend(verts[int(i)] for i in (a, b, c))
            ts.append((base, base + 1, base + 2))
    # centre in XY, sit on z = 0
    allv = [v for vs, _ in by_colour.values() for v in vs]
    cx = (min(v[0] for v in allv) + max(v[0] for v in allv)) / 2
    cy = (min(v[1] for v in allv) + max(v[1] for v in allv)) / 2
    z0 = min(v[2] for v in allv)
    return {c: dedup([(x - cx, y - cy, z - z0) for x, y, z in vs], ts)
            for c, (vs, ts) in by_colour.items()}


def dedup(verts, tris):
    index, out = {}, []
    remap = [index.setdefault(v, len(index)) for v in verts]
    out = [None] * len(index)
    for v, i in index.items():
        out[i] = v
    return out, [tuple(remap[i] for i in t) for t in tris]


def mesh_xml(oid, verts, tris):
    v = "".join(f'<vertex x="{x:.5f}" y="{y:.5f}" z="{z:.5f}"/>' for x, y, z in verts)
    t = "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris)
    return (f'<object id="{oid}" p:UUID="{uuid.uuid4()}" type="model"><mesh>'
            f"<vertices>{v}</vertices><triangles>{t}</triangles></mesh></object>")


def flatten(kind, name, extra=None):
    """A system preset with its `inherits` chain resolved, as the CLI needs it."""
    presets = {}
    for f in os.listdir(os.path.join(PROFILES, kind)):
        if f.endswith(".json"):
            j = json.load(open(os.path.join(PROFILES, kind, f)))
            presets[j.get("name")] = j

    def resolve(n):
        j = presets[n]
        cfg = resolve(j["inherits"]) if j.get("inherits") else {}
        cfg.update(j)
        return cfg

    cfg = resolve(name)
    cfg.update(inherits="", name=name, **(extra or {}))
    return cfg


def project_settings(machine, process, filament, colours, tmp):
    """Full settings as Bambu Studio writes them, from its CLI on a dummy model."""
    dummy, probe = os.path.join(tmp, "dummy.stl"), os.path.join(tmp, "probe.3mf")
    with open(dummy, "w") as f:  # a 10 mm tetrahedron
        f.write("solid d\n" + "".join(
            f"facet normal 0 0 0\nouter loop\n{''.join(f'vertex {v}\n' for v in t)}endloop\nendfacet\n"
            for t in [("0 0 0", "0 10 0", "10 0 0"), ("0 0 0", "10 0 0", "0 0 10"),
                      ("0 0 0", "0 0 10", "0 10 0"), ("10 0 0", "0 10 0", "0 0 10")]) + "endsolid d\n")
    r = subprocess.run([BAMBU, "--debug", "1", "--load-settings", f"{machine};{process}",
                        "--load-filaments", ";".join([filament] * len(colours)),
                        "--export-3mf", probe, dummy], capture_output=True, text=True)
    if r.returncode or not os.path.exists(probe):
        sys.exit("Bambu Studio CLI failed:\n" + r.stdout[-2000:] + r.stderr[-2000:])
    cfg = json.loads(zipfile.ZipFile(probe).read("Metadata/project_settings.config"))
    cfg.update(curr_bed_type=BED, filament_colour=colours, filament_map=["1"] * len(colours),
               flush_volumes_matrix=[str(flush(a, b)) for a in colours for b in colours])
    return cfg


def flush(src, dst):
    """Purge volume (mm3) going from src to dst colour: light after dark needs the most."""
    if src == dst:
        return 0
    lum = lambda c: sum(w * int(c[i:i + 2], 16) for w, i in ((0.3, 1), (0.59, 3), (0.11, 5))) / 255
    return round(160 + 520 * max(0.0, lum(dst) - lum(src)) + 60 * abs(lum(dst) - lum(src)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", default=os.path.join(HERE, "cosmere-tracker-p1s.3mf"))
    ap.add_argument("-D", dest="defs", action="append", default=[], help="OpenSCAD override")
    args = ap.parse_args()

    layout = LAYOUT
    if any(re.fullmatch(r"\s*show_investiture\s*=\s*false\s*", d) for d in args.defs):
        layout = [o for o in LAYOUT if not o[0].endswith(" 3")]

    with tempfile.TemporaryDirectory() as tmp:
        meshes = {p: openscad_meshes(p, args.defs, tmp) for p in {p for _, p, _, _ in layout}}
        body = meshes["frame"]  # the body colour is the one with the most triangles
        body_colour = max(body, key=lambda c: len(body[c][1]))
        colours = [body_colour] + sorted({c for m in meshes.values() for c in m} - {body_colour})
        print("filaments:", ", ".join(f"{i + 1}={c}" for i, c in enumerate(colours)))

        files, rels, objects, items, settings, instances = {}, [], [], [], [], []
        next_id = 1
        for k, (name, part, x, y) in enumerate(layout, 1):
            parts = []
            for c, (vs, ts) in sorted(meshes[part].items(), key=lambda kv: colours.index(kv[0])):
                parts.append((next_id, c, vs, ts))
                next_id += 1
            obj_id, next_id = next_id, next_id + 1
            path = f"/3D/Objects/object_{k}.model"
            files[path.lstrip("/")] = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" '
                                       f'xml:lang="en-US" {NS}><metadata name="BambuStudio:3mfVersion">1</metadata>'
                                       f"<resources>{''.join(mesh_xml(i, v, t) for i, _, v, t in parts)}"
                                       "</resources><build/></model>")
            rels.append(path)
            comps = "".join(f'<component p:path="{path}" objectid="{i}" p:UUID="{uuid.uuid4()}" '
                            'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>' for i, *_ in parts)
            objects.append(f'<object id="{obj_id}" p:UUID="{uuid.uuid4()}" type="model">'
                           f"<components>{comps}</components></object>")
            items.append(f'<item objectid="{obj_id}" p:UUID="{uuid.uuid4()}" '
                         f'transform="1 0 0 0 1 0 0 0 1 {x} {y} 0" printable="1"/>')
            part_cfg = "".join(
                f'<part id="{i}" subtype="normal_part">'
                f'<metadata key="name" value="{PART_NAMES["body" if c == body_colour else "ink"]} {c}"/>'
                f'<metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>'
                f'<metadata key="extruder" value="{colours.index(c) + 1}"/></part>'
                for i, c, _, _ in parts)
            settings.append(f'<object id="{obj_id}"><metadata key="name" value="{name}"/>'
                            f'<metadata key="extruder" value="1"/>{part_cfg}</object>')
            instances.append(f'<model_instance><metadata key="object_id" value="{obj_id}"/>'
                             f'<metadata key="instance_id" value="0"/>'
                             f'<metadata key="identify_id" value="{100 + k}"/></model_instance>')

        files["3D/3dmodel.model"] = (
            f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {NS}>'
            '<metadata name="Application">BambuStudio-02.08.02.61</metadata>'
            '<metadata name="BambuStudio:3mfVersion">1</metadata>'
            '<metadata name="Title">Cosmere tracker</metadata>'
            f"<resources>{''.join(objects)}</resources><build>{''.join(items)}</build></model>")
        files["3D/_rels/3dmodel.model.rels"] = (
            '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            + "".join(f'<Relationship Target="{p}" Id="rel-{i}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
                      for i, p in enumerate(rels, 1)) + "</Relationships>")
        files["Metadata/model_settings.config"] = (
            f'<?xml version="1.0" encoding="UTF-8"?>\n<config>{"".join(settings)}<plate>'
            '<metadata key="plater_id" value="1"/><metadata key="plater_name" value="Cosmere tracker"/>'
            f'<metadata key="locked" value="false"/>{"".join(instances)}</plate><assemble></assemble></config>')
        files["[Content_Types].xml"] = (
            '<?xml version="1.0" encoding="UTF-8"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
            '<Default Extension="png" ContentType="image/png"/></Types>')
        files["_rels/.rels"] = (
            '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
            "</Relationships>")
        machine = os.path.join(tmp, "machine.json")
        process = os.path.join(tmp, "process.json")
        json.dump(flatten("machine", PRINTER), open(machine, "w"))
        json.dump(flatten("process", PROCESS, {"wipe_tower_x": [str(PRIME_TOWER[0])],
                                               "wipe_tower_y": [str(PRIME_TOWER[1])], **PROCESS_TWEAKS}),
                  open(process, "w"))
        fil = os.path.join(tmp, "filament.json")
        json.dump(flatten("filament", FILAMENT), open(fil, "w"))
        files["Metadata/project_settings.config"] = json.dumps(
            project_settings(machine, process, fil, colours, tmp), indent=4)

        out = os.path.abspath(args.output)
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            for name, data in files.items():
                z.writestr(name, data)
    print("->", out)


if __name__ == "__main__":
    main()
