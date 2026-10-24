"""Put a title above a render and its colour bar beside it.

usage: python caption.py <render.png> <legend.png> <out.png> "<title>"
"""
import sys
from PIL import Image, ImageDraw

render, legend, out, title = sys.argv[1:5]
leg = Image.open(legend).convert('RGBA')
leg = leg.resize((int(leg.width * 1.6), int(leg.height * 1.6)))
im = Image.open(render).convert('RGBA')
img = Image.new('RGBA', (im.width + leg.width, im.height + 110), 'white')
img.paste(im, (0, 110))
img.paste(leg, (im.width, 110 + (im.height - leg.height) // 2), leg)
ImageDraw.Draw(img).text((40, 30), title, fill='black', font_size=44)
img.convert('RGB').save(out)
