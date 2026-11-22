#!/usr/bin/env python3
"""Make a plain PDF (and a 600-dpi PNG) from a cropped PLT SVG for embedding in a document (2026-11-21).
The SVG from plt -m8 | crop_svg.py carries a clip path on every element and a white background the size of the whole
PLT page. Both are legal, and the PDF made directly by rsvg-convert renders correctly in Quartz and in Ghostscript, but a
reader that mishandles clip paths can cut panels. This script removes the clip paths and sizes the background to the
cropped page before converting, so the PDF contains only strokes and fills. Use it only for figures whose data are
already inside their frames (the generators clamp symbols and error bars), because nothing is clipped afterwards.
Usage: svg_to_pdf.py fig_X.svg out_stem [size]     writes out_stem.pdf and out_stem.png
size (optional, 2026-11-22): final size as a fraction of the size laid out in the pltfile. The SVG driver of PLT draws
everything at 0.72 of the pltfile dimensions (its page of 10.5 x 8 in is fitted to 7.56 x 5.76 in), so without this
argument the output is 0.72 of the layout; with size = 1 a cap height of 0.10 in the pltfile is 0.10 in on the page.
"""
import re, subprocess, sys, tempfile, os
src, stem = sys.argv[1], sys.argv[2]
size = float(sys.argv[3]) if len(sys.argv) > 3 else None; PLT_SVG = 0.72
s = open(src).read()
m = re.search(r'viewBox="([-\d. ]+)"', s); x0, y0, w, h = (float(v) for v in m.group(1).split())
n_clip = len(re.findall(r'\sclip-path="url\(#[^"]+\)"', s))
s = re.sub(r'\sclip-path="url\(#[^"]+\)"', '', s)
s = re.sub(r'<clipPath id="[^"]*">.*?</clipPath>\s*', '', s, flags=re.S)
bg = re.search(r'<path style="stroke:none;fill:#FFFFFF;" d="\s*M 0\.0 0\.0L 0\.0 [\d.]+L [\d.]+ [\d.]+L [\d.]+ 0\.0"/>', s)
if bg: s = s[:bg.start()] + f'<path style="stroke:none;fill:#FFFFFF;" d="M {x0} {y0}L {x0} {y0 + h}L {x0 + w} {y0 + h}L {x0 + w} {y0}Z"/>' + s[bg.end():]
k = 1.0
if size is not None:
    k = size / PLT_SVG
    s, n = re.subn(r'<svg width="[\d.]+in" height="[\d.]+in"', f'<svg width="{w/100*k:.3f}in" height="{h/100*k:.3f}in"', s, count=1); assert n == 1
with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f: f.write(s); tmp = f.name
subprocess.run(['rsvg-convert', '-f', 'pdf', tmp, '-o', stem + '.pdf'], check=True)
subprocess.run(['rsvg-convert', '-d', '600', '-p', '600', tmp, '-o', stem + '.png'], check=True)
os.unlink(tmp)
try:   # flatten the PNG onto white and record 600 pixels per inch, so that it opens at its physical size
    from PIL import Image
    im = Image.open(stem + '.png').convert('RGBA'); bgim = Image.new('RGBA', im.size, (255, 255, 255, 255)); bgim.alpha_composite(im); bgim.convert('RGB').save(stem + '.png', dpi=(600, 600))
except ImportError:
    pass
print(f'{stem}.pdf and .png: {w/100*k:.2f} x {h/100*k:.2f} in, {n_clip} clip references removed, background {"resized" if bg else "not found"}')
