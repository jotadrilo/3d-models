"""Photoreal "as printed" studio renders of a Bambu Studio project, in Blender Cycles.

    blender -b -P tools/render_studio.py -- <project>-p1s.3mf <out_prefix> [options]

Reads the project built by `make project` (tools/bambu3mf.py), so the renders
show exactly what gets printed: the objects of one plate, each part in the
colour of the filament it is assigned to, with layer lines at the project's
layer height. Writes <out_prefix>-<view>.webp for each view.

Options:
    --plate N            plate to render, 1-based (default 1)
    --model FILE         render this multi-colour OpenSCAD 3MF (lazy-union,
                         colour-mode=model) instead of a plate, e.g. an assembly
                         that is never printed as such; each colour gets the
                         project filament of the same colour (else filament 1)
    --layer-axis x|y|z   axis the layer lines run along, in the model's
                         coordinates before --rotate (default z, the print Z;
                         y for a --model of flat parts assembled upright)
    --objects A,B        only these objects of the plate (default: all of them)
    --rotate RX,RY,RZ    degrees about X, Y, Z (in that order) from the print
                         orientation to the display one, e.g. 180,0,0 for a part
                         printed upside down. Layer lines stay horizontal to the bed.
    --front -y|+y|-x|+x  side of the model that faces the viewer in the front
                         view, after --rotate (default -y, OpenSCAD's front)
    --views a,b          subset of hero,front,side,top,back (default: all)
    --samples N          Cycles samples (default 256)
    --scale F            resolution scale, e.g. 0.25 for a quick draft (default 1)

The studio is a seamless sweep with a key, a fill and a rim area light, all on
a rig that turns with the camera. Exposure and backdrop tone follow the
brightness of the filaments, so black and white parts keep their detail.
"""
import argparse
import json
import math
import sys
import xml.etree.ElementTree as ET
import zipfile

import bpy
from mathutils import Euler, Matrix, Vector

# ---------------------------------------------------------------- defaults

RESOLUTION = (2400, 1800)       # 4:3, as MakerWorld recommends for model images
IMAGE_QUALITY = 90               # WebP: about a third smaller than JPEG at the same quality
SAMPLES = 256
LENS_MM = 70                      # on a 36 mm sensor
FSTOP = 5.6
VIEWS = {                         # direction from the model to the camera; the front faces +Y
    "hero": (0.6, 1.0, 0.55),     # 3/4 front
    "front": (0.0, 1.0, 0.12),
    "side": (1.0, 0.0, 0.12),
    "top": None,                  # straight down, front edge at the bottom
    "back": (-0.7, -1.0, 0.5),    # 3/4 back
}
FINISHES = {                      # by the filament preset name, first match: roughness, subsurface weight, coat, transmission
    "Translucent": (0.18, 0.0, 0.2, 0.92),   # PETG / PLA Translucent: clear, like glass with a slight haze
    "Matte": (0.62, 0.04, 0.0, 0.0),
    "Silk": (0.22, 0.02, 0.35, 0.0),
    "PETG": (0.25, 0.10, 0.15, 0.0),
    "ABS": (0.38, 0.04, 0.0, 0.0),
    "TPU": (0.55, 0.10, 0.0, 0.0),
    "": (0.42, 0.08, 0.0, 0.0),   # PLA Basic and anything else
}
LAYER_BUMP = 0.6                  # strength of the layer-line bump
OPENSCAD_DEFAULT_COLOURS = {"#F9D72C", "#9DCB51"}   # what OpenSCAD gives uncoloured faces
MID_GREY = 0.18                   # linear luminance the exposure is balanced around
BACKDROP_DARK_PART = 0.62         # backdrop albedo behind dark parts
BACKDROP_LIGHT_PART = 0.30        # backdrop albedo behind light parts

FRONTS = {"-y": 180, "+y": 0, "-x": -90, "+x": 90}  # yaw that turns that side to face +Y
CORE = "{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}"
PROD = "{http://schemas.microsoft.com/3dmanufacturing/production/2015/06}"


def parse_args():
    ap = argparse.ArgumentParser(prog="render_studio.py")
    ap.add_argument("project")
    ap.add_argument("out")
    ap.add_argument("--plate", type=int, default=1)
    ap.add_argument("--objects", default="")
    ap.add_argument("--model", default="")
    ap.add_argument("--layer-axis", choices="xyz", default="z")
    ap.add_argument("--rotate", default="0,0,0")
    ap.add_argument("--front", choices=FRONTS, default="-y")
    ap.add_argument("--views", default=",".join(VIEWS))
    ap.add_argument("--samples", type=int, default=SAMPLES)
    ap.add_argument("--scale", type=float, default=1.0)
    args = ap.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    unknown = set(args.views.split(",")) - set(VIEWS)
    if unknown:
        ap.error(f"unknown views: {', '.join(sorted(unknown))}")
    return args


# ---------------------------------------------------------------- project

def load_project(path, plate_no, only):
    """Parts of one plate as [(object name, filament index, verts, tris)] in bed coordinates,
    plus the filaments [(hex colour, preset name)] and the layer height."""
    z = zipfile.ZipFile(path)
    cfg = json.loads(z.read("Metadata/project_settings.config"))
    filaments = list(zip(cfg["filament_colour"], cfg["filament_settings_id"]))
    layer = float(cfg["layer_height"])

    settings = ET.fromstring(z.read("Metadata/model_settings.config"))
    names, extruders = {}, {}
    for obj in settings.findall("object"):
        meta = {m.get("key"): m.get("value") for m in obj.findall("metadata")}
        names[obj.get("id")] = meta["name"]
        for part in obj.findall("part"):
            pm = {m.get("key"): m.get("value") for m in part.findall("metadata")}
            extruders[(obj.get("id"), part.get("id"))] = int(pm.get("extruder", meta.get("extruder", 1)))
    plates = settings.findall("plate")
    if not 1 <= plate_no <= len(plates):
        sys.exit(f"{path}: no plate {plate_no} (it has {len(plates)})")
    plate = plates[plate_no - 1]
    ids = [m.get("value") for inst in plate.findall("model_instance")
           for m in inst.findall("metadata") if m.get("key") == "object_id"]
    if only:
        missing = set(only) - {names[i] for i in ids}
        if missing:
            sys.exit(f"plate {plate_no} has no object {', '.join(sorted(missing))}")
        ids = [i for i in ids if names[i] in only]

    model = ET.fromstring(z.read("3D/3dmodel.model"))
    items = {i.get("objectid"): i.get("transform") for i in model.iter(CORE + "item")}
    meshes = {}
    parts = []
    for obj in model.iter(CORE + "object"):
        oid = obj.get("id")
        if oid not in ids:
            continue
        place = _matrix(items[oid])
        for comp in obj.iter(CORE + "component"):
            file = comp.get(PROD + "path").lstrip("/")
            if file not in meshes:
                meshes[file] = _meshes(z.read(file))
            verts, tris = meshes[file][comp.get("objectid")]
            m = place @ _matrix(comp.get("transform"))
            verts = [tuple(m @ Vector(v)) for v in verts]
            parts.append((names[oid], extruders.get((oid, comp.get("objectid")), 1), verts, tris))
    return parts, filaments, layer


def load_model(path, filaments):
    """Parts of an OpenSCAD colour 3MF, one per colour, as load_project returns them.

    A colour that matches a project filament renders as that filament. Any other
    colour is context (a wall, a bottle, bought hardware): it is appended to
    `filaments` as a "Context" material of its own colour, with no layer lines,
    clear if the OpenSCAD colour has alpha < 1, and left out of the exposure."""
    root = ET.fromstring(zipfile.ZipFile(path).read("3D/3dmodel.model"))
    materials = {g.get("id"): [b.get("displaycolor", "").upper() for b in g]
                 for g in root.iter() if g.tag.endswith("basematerials")}
    slots = {c.upper(): i for i, (c, _) in reversed(list(enumerate(filaments, 1)))}
    by_colour = {}
    for obj in root.iter(CORE + "object"):
        mesh = obj.find(CORE + "mesh")
        if mesh is None:
            continue
        verts = [(float(v.get("x")), float(v.get("y")), float(v.get("z"))) for v in mesh.find(CORE + "vertices")]
        pid, pindex = obj.get("pid"), obj.get("pindex")
        for t in mesh.find(CORE + "triangles"):
            p = t.get("p1", pindex)
            colour = materials[t.get("pid", pid)][int(p)] if p is not None else None
            vs, ts = by_colour.setdefault(colour, ([], []))
            ts.append(tuple(range(len(vs), len(vs) + 3)))
            vs.extend(verts[int(t.get(k))] for k in ("v1", "v2", "v3"))
    parts = []
    for colour, (vs, ts) in by_colour.items():
        index = {}
        remap = [index.setdefault(v, len(index)) for v in vs]  # weld, for smooth shading
        rgb = colour[:7] if colour else None
        if rgb is None or rgb in OPENSCAD_DEFAULT_COLOURS:   # uncoloured geometry is the model
            slot = 1
        elif rgb in slots:
            slot = slots[rgb]
        else:
            clear = len(colour) == 9 and colour[7:] != "FF"
            filaments.append((rgb, "Context Translucent" if clear else "Context Matte"))
            slot = slots[rgb] = len(filaments)
        parts.append((rgb or "model", slot, list(index), [tuple(remap[i] for i in t) for t in ts]))
    return parts


def _matrix(transform):
    """3MF 3x4 row-vector transform -> 4x4 Matrix."""
    t = [float(x) for x in (transform or "1 0 0 0 1 0 0 0 1 0 0 0").split()]
    return Matrix(((t[0], t[3], t[6], t[9]), (t[1], t[4], t[7], t[10]),
                   (t[2], t[5], t[8], t[11]), (0, 0, 0, 1)))


def _meshes(data):
    out = {}
    for obj in ET.fromstring(data).iter(CORE + "object"):
        mesh = obj.find(CORE + "mesh")
        if mesh is None:
            continue
        verts = [(float(v.get("x")), float(v.get("y")), float(v.get("z"))) for v in mesh.find(CORE + "vertices")]
        tris = [(int(t.get("v1")), int(t.get("v2")), int(t.get("v3"))) for t in mesh.find(CORE + "triangles")]
        out[obj.get("id")] = (verts, tris)
    return out


# ---------------------------------------------------------------- scene

def linear(hex_colour):
    h = hex_colour.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def luminance(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


def filament_material(colour, preset, layer, axis):
    """Printed plastic: satin Principled BSDF, a touch of subsurface and layer lines
    as a sine bump along the object's `axis` (the print Z, whatever the display rotation)."""
    rough, sss, coat, transmission = next(v for k, v in FINISHES.items() if k in preset)
    m = bpy.data.materials.new(f"{colour} {preset}")
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = linear(colour) + [1]
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Subsurface Weight"].default_value = sss
    bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.6, 0.3)
    bsdf.inputs["Subsurface Scale"].default_value = 0.6
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Transmission Weight"].default_value = transmission
    bsdf.inputs["IOR"].default_value = 1.57          # PETG
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = 2 * math.pi / layer
    sine = nt.nodes.new("ShaderNodeMath")
    sine.operation = "SINE"
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0 if "Context" in preset else LAYER_BUMP
    bump.inputs["Distance"].default_value = layer * 0.15
    nt.links.new(coord.outputs["Object"], sep.inputs[0])
    nt.links.new(sep.outputs[axis.upper()], mul.inputs[0])
    nt.links.new(mul.outputs[0], sine.inputs[0])
    nt.links.new(sine.outputs[0], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def build_model(scene, parts, filaments, layer, axis, rotate, front):
    """One Blender object per part under a 'model' empty that holds the display
    rotation. Returns the part objects and the area-weighted part luminance."""
    model = bpy.data.objects.new("model", None)
    scene.collection.objects.link(model)
    materials, objs = {}, []
    area_lum = area_sum = 0.0
    for name, extruder, verts, tris in parts:
        colour, preset = filaments[extruder - 1]
        if extruder not in materials:
            materials[extruder] = filament_material(colour, preset, layer, axis)
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], tris)
        me.validate()
        me.materials.append(materials[extruder])
        ob = bpy.data.objects.new(name, me)
        scene.collection.objects.link(ob)
        ob.parent = model
        objs.append(ob)
        if "Context" not in preset:           # the exposure follows the printed parts only
            a = sum(p.area for p in me.polygons)
            area_lum += a * luminance(linear(colour))
            area_sum += a
    for ob in objs:
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.shade_auto_smooth(angle=math.radians(30))

    rx, ry, rz = (math.radians(float(a)) for a in rotate.split(","))
    spin = Matrix.Rotation(math.radians(FRONTS[front]), 4, "Z")
    model.matrix_world = spin @ Euler((rx, ry, rz), "XYZ").to_matrix().to_4x4()
    bpy.context.view_layer.update()
    pts = [ob.matrix_world @ v.co for ob in objs for v in ob.data.vertices]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    model.matrix_world = Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))) @ model.matrix_world
    bpy.context.view_layer.update()
    return objs, area_lum / area_sum


def build_studio(scene, size, height, part_lum):
    """Seamless sweep, three area lights and a world that is dark for lighting but
    grey to the camera, all on a rig that turns with the view. The exposure lifts
    dark parts and holds back light ones; the backdrop albedo is compensated so it
    keeps the same tone, a little darker behind light parts for contrast."""
    exposure = max(-1.0, min(1.0, 0.4 * math.log2(MID_GREY / max(part_lum, 1e-3))))
    t = min(1.0, part_lum / 0.6)
    backdrop = (BACKDROP_DARK_PART * (1 - t) + BACKDROP_LIGHT_PART * t) / 2 ** exposure
    scene.view_settings.exposure = exposure

    rig = bpy.data.objects.new("rig", None)
    scene.collection.objects.link(rig)

    s, wall, r = size * 25, size * 0.9, size * 1.2
    prof = [(s, 0.0), (-wall, 0.0)]
    for k in range(1, 17):
        a = k / 16 * (math.pi / 2)
        prof.append((-wall - r * math.sin(a), r - r * math.cos(a)))
    prof.append((-wall - r, s))
    verts, faces = [], []
    for y, z in prof:
        verts += [(-s, y, z), (s, y, z)]
    for i in range(len(prof) - 1):
        faces.append((2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2))
    me = bpy.data.meshes.new("sweep")
    me.from_pydata(verts, [], faces)
    for p in me.polygons:
        p.use_smooth = True
    mat = bpy.data.materials.new("Backdrop")
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (backdrop, backdrop * 0.99, backdrop * 0.96, 1)
    bsdf.inputs["Roughness"].default_value = 0.9
    me.materials.append(mat)
    sweep = bpy.data.objects.new("sweep", me)
    scene.collection.objects.link(sweep)
    sweep.parent = rig

    k = (size / 100) ** 2  # light energy scales with the area it covers (mm units)
    for name, loc, energy, sz, col in [
        ("key", (-1.4, 1.6, 1.8), 1.1e6, 1.2, (1, 0.97, 0.92)),
        ("fill", (1.8, 1.0, 0.9), 0.3e6, 1.5, (0.92, 0.95, 1)),
        ("rim", (0.4, -1.6, 1.5), 0.8e6, 0.8, (1, 1, 1)),
    ]:
        light = bpy.data.lights.new(name, "AREA")
        light.energy, light.size, light.color = energy * k, size * sz, col
        ob = bpy.data.objects.new(name, light)
        ob.location = Vector(loc) * size
        ob.rotation_euler = (Vector((0, 0, height * 0.4)) - ob.location).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(ob)
        ob.parent = rig

    world = bpy.data.worlds.new("studio")
    world.use_nodes = True
    wn = world.node_tree
    dark = wn.nodes["Background"]
    dark.inputs["Color"].default_value = (0.02, 0.02, 0.02, 1)
    seen = wn.nodes.new("ShaderNodeBackground")
    g = backdrop * 0.8
    seen.inputs["Color"].default_value = (g, g, g, 1)
    path = wn.nodes.new("ShaderNodeLightPath")
    mix = wn.nodes.new("ShaderNodeMixShader")
    wn.links.new(path.outputs["Is Camera Ray"], mix.inputs[0])
    wn.links.new(dark.outputs[0], mix.inputs[1])
    wn.links.new(seen.outputs[0], mix.inputs[2])
    wn.links.new(mix.outputs[0], wn.nodes["World Output"].inputs[0])
    scene.world = world
    return rig


def build_camera(scene, size):
    data = bpy.data.cameras.new("camera")
    data.lens = LENS_MM
    data.clip_start, data.clip_end = 1, size * 50
    data.dof.use_dof = True
    data.dof.aperture_fstop = FSTOP
    cam = bpy.data.objects.new("camera", data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def frame(cam, rig, corners, direction, aspect):
    """Aim the camera along `direction`, turn the rig to match, and back off until
    the bounding box fills the frame with a margin."""
    centre = sum(corners, Vector()) / len(corners)
    if direction is None:
        d = Vector((0, 0, 1))
        cam.rotation_euler = (0, 0, math.pi)  # +Y (the front) at the bottom of the frame
        rig.rotation_euler.z = 0
    else:
        d = Vector(direction).normalized()
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        hero = VIEWS["hero"]
        rig.rotation_euler.z = math.atan2(-d.x, d.y) - math.atan2(-hero[0], hero[1])
    lim = 18 / LENS_MM * 0.80  # tan of the half field of view, 80 % filled
    dist = max((c - centre).length for c in corners) * 3
    for _ in range(6):
        cam.location = centre + d * dist
        bpy.context.view_layer.update()
        inv = cam.matrix_world.inverted()
        need = max(max(abs(p.x) / -p.z / lim, abs(p.y) / -p.z / (lim / aspect))
                   for p in (inv @ c for c in corners))
        dist *= need
    cam.location = centre + d * dist
    cam.data.dof.focus_distance = dist


def setup_render(scene, samples, scale):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "GPU"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "METAL"
    prefs.get_devices()
    for d in prefs.devices:
        d.use = True
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.resolution_x, scene.render.resolution_y = RESOLUTION
    scene.render.resolution_percentage = round(scale * 100)
    scene.render.image_settings.file_format = "WEBP"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.quality = IMAGE_QUALITY


def main():
    args = parse_args()
    only = [o for o in args.objects.split(",") if o]
    parts, filaments, layer = load_project(args.project, args.plate, only)
    if args.model:
        parts = load_model(args.model, filaments)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    objs, part_lum = build_model(scene, parts, filaments, layer, args.layer_axis, args.rotate, args.front)
    corners = [ob.matrix_world @ Vector(c) for ob in objs for c in ob.bound_box]
    dims = Vector([max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3)])
    rig = build_studio(scene, max(dims), dims.z, part_lum)
    cam = build_camera(scene, max(dims))
    setup_render(scene, args.samples, args.scale)
    print(f"render: {args.model or f'plate {args.plate}'}, {len(parts)} parts, {dims.x:.0f} x {dims.y:.0f} x {dims.z:.0f} mm, "
          f"layer {layer} mm, luminance {part_lum:.3f}, exposure {scene.view_settings.exposure:+.2f}")

    for view in args.views.split(","):
        frame(cam, rig, corners, VIEWS[view], RESOLUTION[0] / RESOLUTION[1])
        scene.render.filepath = f"{args.out}-{view}.webp"
        bpy.ops.render.render(write_still=True)


main()
