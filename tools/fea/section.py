# A section of an FEA result, rendered headless with ParaView, each part in its own colour:
#   pvpython section.py <job.vtu> <out.png> <warp> <x of the cut> [zmin,zmax,ymin,ymax]
# Cuts at x = <x>, keeps x < <x>, looks from +x (the wall on the right), the shape deformed
# by U x <warp>, and the undeformed cut in black lines. The optional window zooms in (mm),
# one argument with commas (pvpython mangles a lone negative number).
import sys
from paraview.simple import *

vtu, png, warp, x = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
win = list(map(float, sys.argv[5].split(','))) if len(sys.argv) > 5 else None
src = XMLUnstructuredGridReader(FileName=[vtu])
view = CreateView('RenderView')
view.ViewSize = [1600, 1200]
view.Background = [1, 1, 1]
try:
    view.UseColorPaletteForBackground = 0
except AttributeError:
    pass
view.OrientationAxesVisibility = 0

w = WarpByVector(Input=src)
w.Vectors = ['POINTS', 'U']
w.ScaleFactor = warp
for inp, deformed in ((w, True), (src, False)):
    c = Clip(Input=inp)
    c.ClipType = 'Plane'
    c.ClipType.Origin = [x, 0, 0]
    c.ClipType.Normal = [1, 0, 0]
    c.Invert = 1
    try:
        c.Crinkleclip = 0
    except AttributeError:
        pass
    d = Show(c, view)
    if deformed:
        ColorBy(d, ('CELLS', 'part'))
        lut = GetColorTransferFunction('part')
        lut.InterpretValuesAsCategories = 1
        lut.Annotations = ['0', 'plate', '1', 'body', '2', 'tray', '3', 'box']
        lut.IndexedColors = [0.25, 0.45, 0.85, 0.55, 0.55, 0.55, 0.30, 0.70, 0.35, 0.90, 0.45, 0.15]
        d.SetScalarBarVisibility(view, True)
    else:
        d.SetRepresentationType('Feature Edges')
        d.ColorArrayName = [None, '']
        d.AmbientColor = d.DiffuseColor = [0, 0, 0]
        d.LineWidth = 1.5
view.CameraPosition = [x + 1000, -60, 110]
view.CameraFocalPoint = [x, -60, 110]
view.CameraViewUp = [0, 0, 1]
view.CameraParallelProjection = 1
view.ResetCamera()
if win:
    zmin, zmax, ymin, ymax = win
    view.CameraFocalPoint = [x, (ymin + ymax) / 2, (zmin + zmax) / 2]
    view.CameraPosition = [x + 1000, (ymin + ymax) / 2, (zmin + zmax) / 2]
    view.CameraParallelScale = max((zmax - zmin) / 2, (ymax - ymin) / 2 * 0.75)
Render(view)
SaveScreenshot(png, view, ImageResolution=[1600, 1200])
