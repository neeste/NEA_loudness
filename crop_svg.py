#!/usr/bin/env python3
"""Crop a PLT SVG page to its drawn content: rewrite width/height/viewBox from the
bounding box of all path coordinates (PLT draws text as stroked paths, so nothing is
missed). Also fixes PLT's lowercase 'viewbox'. Usage: crop_svg.py in.svg out.svg [margin_units]"""
import re, sys
fn, out = sys.argv[1], sys.argv[2]
margin = float(sys.argv[3]) if len(sys.argv) > 3 else 12.0        # 100 units = 1 in
s = open(fn).read().replace('viewbox=', 'viewBox=')
m = re.search(r'<svg width="[^"]*" height="[^"]*" viewBox="([\d. ]+)"', s)
_, _, PW, PH = (float(v) for v in m.group(1).split())
xs, ys = [], []
for d in re.findall(r' d="([^"]+)"', s):
    nums = [float(v) for v in re.findall(r'-?\d+\.?\d*', d)]
    xs += nums[0::2]; ys += nums[1::2]
xs = [v for v in xs if 0 < v < PW]; ys = [v for v in ys if 0 < v < PH]   # drop the page background/clip
x0, y0 = max(0, min(xs) - margin), max(0, min(ys) - margin)
x1, y1 = min(PW, max(xs) + margin), min(PH, max(ys) + margin)
w, h = x1 - x0, y1 - y0
s = s[:m.start()] + f'<svg width="{w/100:.3f}in" height="{h/100:.3f}in" viewBox="{x0:.1f} {y0:.1f} {w:.1f} {h:.1f}"' + s[m.end():]
open(out, 'w').write(s)
print(f'{out}: crop origin ({x0:.0f},{y0:.0f}), {w/100:.2f} x {h/100:.2f} in')
