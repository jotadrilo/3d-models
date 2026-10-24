"""Render a vertex-coloured PLY (an FEA result, from to_ply.py) with Blender Workbench.

blender -b -P render_ply.py -- <in.ply> <out prefix> view[,view...]
views: hero (3/4 front, above), under (3/4 front, below), top, front, side (from +x),
       wall (from the wall side, +y: the wall plate's back face)
"""
import sys, math
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:]
ply, prefix, views = argv[0], argv[1], argv[2].split(',')

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.ply_import(filepath=ply)
ob = bpy.context.selected_objects[0]
bpy.ops.object.shade_flat()
pts = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
centre, size = (lo + hi) / 2, (hi - lo).length

sc = bpy.context.scene
sc.render.engine = 'BLENDER_WORKBENCH'
sh = sc.display.shading
sh.light = 'STUDIO'
sh.color_type = 'VERTEX'
sh.show_cavity = True
sh.cavity_type = 'WORLD'
sh.show_object_outline = False
sc.render.resolution_x, sc.render.resolution_y = 2000, 1500
sc.render.film_transparent = False
sc.world = bpy.data.worlds.new('w')
sc.world.color = (1, 1, 1)
sh.background_type = 'WORLD' if hasattr(sh, 'background_type') else None
sc.view_settings.view_transform = 'Standard'

cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
sc.collection.objects.link(cam)
sc.camera = cam
cam.data.type = 'ORTHO'
cam.data.ortho_scale = size * 1.05 * 4 / 3   # the width: fits the size in the 3:4 height too

DIRS = {'hero': (-0.9, -1.6, 1.1), 'under': (-0.9, -1.6, -0.9), 'top': (0, -0.0001, 1), 'front': (0, -1, 0.25),
        'side': (1, -0.0001, 0.1), 'wall': (0.0001, 1, 0.05)}
for v in views:
    sh.light = 'FLAT' if v == 'under' else 'STUDIO'
    d = Vector(DIRS[v]).normalized()
    cam.location = centre + d * size * 2
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = '%s-%s.png' % (prefix, v)
    bpy.ops.render.render(write_still=True)
