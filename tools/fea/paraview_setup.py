# Open a CalculiX result (converted with frd_to_vtu.py) in ParaView, ready to look at:
#   FEA_VTU=<run>/<job>.vtu FEA_WARP=20 FEA_VMAX=3 \
#       /Applications/ParaView-6.2.0.app/Contents/MacOS/paraview --script=paraview_setup.py
# Warps the result by U (x FEA_WARP), colours it by von Mises (0..FEA_VMAX MPa),
# and draws the undeformed shape's edges in grey.
import os
from paraview.simple import *

path = os.environ['FEA_VTU']
warp = float(os.environ.get('FEA_WARP', '5'))
vmax = float(os.environ.get('FEA_VMAX', '10'))
src = OpenDataFile(path)
RenameSource(os.path.basename(path), src)
names = src.PointData.keys()
mises = next((n for n in names if 'mises' in n.lower()), names[0])

w = WarpByVector(Input=src)
w.Vectors = ['POINTS', 'U']
w.ScaleFactor = warp
RenameSource('deformed x%g' % warp, w)
view = GetActiveViewOrCreate('RenderView')
d = Show(w, view)
ColorBy(d, ('POINTS', mises))
lut = GetColorTransferFunction(mises)
lut.ApplyPreset('Turbo', True)
lut.RescaleTransferFunction(0.0, vmax)
lut.AutomaticRescaleRangeMode = 'Never'
d.SetScalarBarVisibility(view, True)
bar = GetScalarBar(lut, view)
bar.Title = 'von Mises (MPa)'
bar.ComponentTitle = ''
# the undeformed shape, as a faint outline
o = Show(src, view)
o.SetRepresentationType('Feature Edges')
o.AmbientColor = o.DiffuseColor = [0.6, 0.6, 0.6]
o.ColorArrayName = [None, '']   # plain colour (ColorBy(o, None) fails in ParaView 6.2)
view.Background = [1, 1, 1]
try:
    view.UseColorPaletteForBackground = 0
except AttributeError:
    pass
view.OrientationAxesVisibility = 1
view.CameraPosition = [-350, -600, 420]
view.CameraFocalPoint = [0, -50, 100]
view.CameraViewUp = [0, 0, 1]
view.ResetCamera()
Render()
