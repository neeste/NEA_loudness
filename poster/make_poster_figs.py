#!/usr/bin/env python3
"""Poster variants of the PLT figures, with lettering sized for a 56 x 36 in poster read from 6 ft.
Since 2026-11-22 the mechanism and growth figures show the published model (the model of the JASA-EL letter).

The document generators (make_plt_diagrams.py, make_plt_mechanism.py, make_plt_growth.py) are loaded as
source text, their size constants and output paths are substituted, and the modified source is executed.
The document figures are not touched. Outputs (in fig/): pathways.png, mechanism.png, growth1k.png.

Run from this folder:  python3 make_poster_figs.py
Needs plt, crop_svg.py (main folder) and rsvg-convert.
"""
import os, re, subprocess, sys, textwrap

HERE = os.path.dirname(os.path.abspath(__file__)); MAIN = os.path.dirname(HERE)
os.chdir(HERE); os.makedirs("fig", exist_ok=True)

def load(name):
    return open(os.path.join(MAIN, name), encoding="utf-8").read()

def sub(src, pairs):
    for o, n in pairs:
        assert src.count(o) == 1, f"pattern not found once: {o[:60]}"
        src = src.replace(o, n)
    return src

def run(src, name, main_call="main()"):
    """Execute modified generator source with HERE pointing at the main folder (for its JSON inputs)."""
    g = {"__name__": "__poster__", "__file__": os.path.join(MAIN, name)}
    exec(compile(src, name, "exec"), g)
    if main_call:
        exec(main_call, g)
    return g

def render(stem):
    plt_file = f"fig/{stem}.plt"; svg = f"fig/{stem}.svg"; png = f"fig/{stem}.png"
    p1 = subprocess.run(["plt", "-m8", plt_file], capture_output=True)
    p2 = subprocess.run([sys.executable, os.path.join(MAIN, "crop_svg.py"), "/dev/stdin", svg], input=p1.stdout, capture_output=True, text=False)
    print(stem, p2.stdout.decode().strip() or p2.stderr.decode().strip())
    subprocess.run(["rsvg-convert", "-d", "600", "-p", "600", svg, "-o", png], check=True)

# ---------------------------------------------------------------- pathways (Figure 2 of the poster)
src = load("make_plt_diagrams.py")
src = sub(src, [
    ("CAP, TAG, HEAD = 0.12, 0.11, 0.13", "CAP, TAG, HEAD = 0.165, 0.15, 0.19"),
    # the whole pathways() body is replaced by a version with shorter lines and taller boxes
    ("def pathways():", "def pathways_doc():"),
])
src += textwrap.dedent('''
def pathways():
    XLEN, YLEN = 9.6, 6.9
    out = header(XLEN, YLEN)
    # excitation-pattern inset
    ix0, ix1, base, top = 3.2, 6.4, 5.05, 1.05
    out += rect(3.0, 4.65, 6.6, 6.45, LGRAY, 1.0)
    out += msg(4.8, 6.65, 'Excitation pattern (same RMS)', size=HEAD, bold=True)
    n = 120
    xs = [ix0 + (ix1 - ix0) * i / (n - 1) for i in range(n)]
    u = lambda x: (x - ix0) / (ix1 - ix0)
    narrow = [(x, base + top * math.exp(-((u(x) - 0.5) / 0.07) ** 2)) for x in xs]
    wide = [(x, base + top * (0.07 / 0.18) * math.exp(-((u(x) - 0.5) / 0.18) ** 2)) for x in xs]
    out += polyline(wide, BROWN, 1.8, lintype=3)
    out += polyline(narrow, BLUE, 1.8)
    out += polyline([(ix0, base), (ix1 + 0.05, base)], BLACK, 1.0, arrow=True, arosiz=0.8)
    out += msg(4.45, 5.95, 'narrow', size=TAG, col=BLUE, hal='rig')
    out += msg(5.75, 5.38, 'wide', size=TAG, col=BROWN, hal='lef')
    out += msg(4.8, 4.82, 'characteristic frequency', size=0.13, col=DGRAY)
    # two pathway boxes
    yb, hb, wb, pitch = 2.95, 2.25, 4.45, 0.42
    out += box(2.40, yb, wb, hb, [('Broad sum', True), 'T-stellate / chopper cells',
                                  'L[E] = ^S^ s[k]',
                                  'wider band -> larger sum', ('LOUDER', True)], GREEN, 1.5, pitch=pitch)
    out += box(7.20, yb, wb, hb, [('Peak-weighted average', True), 'D-stellate / onset-C inhibition',
                                  'L[I] = (^S^ s[k]{q}){1/q}',
                                  'spreading lowers the peak', ('LESS LOUD', True)], RED, 1.5, pitch=pitch)
    out += arrow(3.55, 4.65, 2.95, 4.12)
    out += arrow(6.05, 4.65, 6.65, 4.12)
    # combination box
    out += box(4.80, 0.72, 7.4, 1.25, [('Level-gated ensemble average', True),
                                       'L = L[E] (L[I] / L[E]){w}    peak-weighting recruits with level'], MAGENTA, 1.8, pitch=0.45)
    out += arrow(2.80, 1.82, 3.60, 1.36)
    out += arrow(6.80, 1.82, 6.00, 1.36)
    return '\\n'.join(out) + '\\n'
''')
g = run(src, "make_plt_diagrams.py", main_call=None)
open("fig/pathways.plt", "w").write(g["pathways"]())
render("pathways")

# ---------------------------------------------------------------- mechanism (Figure 3 of the poster)
src = load("make_plt_mechanism.py")
src = sub(src, [
    ("CAP, LAB = 0.12, 0.12", "CAP, LAB = 0.15, 0.15"),
    ("w, h, gab, gbc, x0 = 2.1, 2.5, 0.35, 0.75, 0.95", "w, h, gab, gbc, x0 = 2.45, 2.7, 0.4, 0.85, 1.0"),
    ("YMIN = min(-16,", "YMIN = min(-20,"),
    ("y0 = -8.5; dy = 2.0", "y0 = -11.0; dy = 4.0"),
    # 2026-11-22 (the user's suggestion): the legend is split, two lines at the bottom of panel A and two at the bottom of
    # panel B, so that the lines can stand 4 dB apart (0.30 in, twice the cap height) and no longer touch
    ("for k, key in enumerate(('sum_only', 'peak_only', 'committed')):", "for k, key in enumerate(('sum_only', 'peak_only')):"),
    (r"""    s.append(f'0.07\t{y0 - 3 * dy:.4g}\t"|11| CLS data"')""", "    pass   # the last two legend lines are in panel B"),
    (r"""    s.append(f'3\t{YMAX - 0.04 * (YMAX - YMIN):.4g}\t"B   1-octave band"')""",
     r"""    s.append(f'3\t{YMAX - 0.04 * (YMAX - YMIN):.4g}\t"B   1-octave band"')
    s.append('mval=half : msgcol=0 : pltcol=0 : pltlwt=2.2')
    s.append('5\t-11\t"|_0| gated blend"')
    s.append(f'mvkey=-{1.2 * (w + h) / 2 / 50:.4f}')
    s.append('5\t-15\t"|11| CLS data"')"""),
    # 2026-11-22, published model: the sum alone reaches +12 dB in panel A, so the axis runs to 16 (the unplotted 2-octave
    # value at 100 dB no longer sets it); the gate peaks at 0.93, so panel C gets a title band above 1.0
    ("YMAX = max(12, 4 * math.ceil(max(vals) / 4))", "YMAX = 16"),
    ("'gate weight w', 0, 1, yfmt='f3.1')", "'gate weight w', 0, 1.2, yfmt='f3.1')"),
    ("s.append('yanskp=0 : yint=5.2')", "s.append('yanskp=0 : yint=6.2'); s.append('yannot= 0.0 0.2 0.4 0.6 0.8 1.0')"),
    (r"""s.append('3\t0.96\t"C   level gate"')""", r"""s.append('3\t1.15\t"C   level gate"')"""),
    ("open(os.path.join(HERE, 'fig_mechanism.plt'), 'w')", "open(os.path.join(POSTER, 'fig/mechanism.plt'), 'w')"),
    # 2026-11-21: a legend line sample takes the current pltcol, so set it with the text color; the tick at 1/8 keeps
    # its mark but loses its label, which ran into the label at 1/16
    ("        s.append(f'msgcol={col}')", "        s.append(f'msgcol={col} : pltcol={col}')"),
    # the circle in the legend at the size of the data points: mvkey sets the height of a symbol in a message (negative =
    # inches), and a plotted symbol is symsiz * (xlen + ylen) / 2 / 50 inches high (symsiz = 1.2 here)
    ("    s.append('msgcol=0')", "    s.append(f'msgcol=0 : pltcol=0 : mvkey=-{1.2 * (w + h) / 2 / 50:.4f}')"),
    ("0.0625,1/16 0.125,1/8 0.25,1/4", "0.0625,1/16 0.125,$ 0.25,1/4"),
    # 2026-11-22: the published model (gtfb filterbank, refitted): data file in the same format, from letter_score.m
    ("'nea_mechanism.json'", "'nea_mechanism_letter.json'"),
])
src = src.replace("HERE = os.path.dirname(os.path.abspath(__file__))", f"HERE = {MAIN!r}\nPOSTER = {HERE!r}")
run(src, "make_plt_mechanism.py")
render("mechanism")

# ---------------------------------------------------------------- growth, 1 kHz x 3 bandwidths (Figure 4 of the poster)
src = load("make_plt_growth.py")
src = sub(src, [("CAP = 0.12 ", "CAP = 0.15 "), ("LAB = 0.14 ", "LAB = 0.17 "),
    ("'nea_growth_curves.json'", "'nea_letter_growth.json'"),   # 2026-11-22: the published model, with its fitted loudness constant
    # 2026-11-21: legend line samples in the color of their curve, and the legend moved left so that it stays inside the frame
    ("s.append('mval=half : msgcol=0')", "s.append('mval=half : msgcol=0 : pltcol=0')"),
    ("s.append('msgcol=4')", "s.append('msgcol=4 : pltcol=4')"),
    (r"""'34\t0.012\t"|_0| CLS data"'""", r"""'28\t0.012\t"|_0| CLS data"'"""),
    (r"""'34\t0.004\t"|_3| model"'""", r"""'28\t0.004\t"|_3| model"'"""),
])
g = run(src, "make_plt_growth.py", main_call=None)
J, FI, BW, khz, figure = g["J"], g["FI"], g["BW"], g["khz"], g["figure"]
panels = [(f'{khz(1000)}, {name}', J['data'][key][FI[1000]], J['model'][key][FI[1000]]) for key, name in BW]
txt = figure(panels, ncol=3, nrow=1, w=2.55, h=2.0, gx=0.4, gy=0.0, x0=1.1, y0=0.95)
open("fig/growth1k.plt", "w").write(txt)
render("growth1k")

from PIL import Image
for stem in ("pathways", "mechanism", "growth1k"):
    im = Image.open(f"fig/{stem}.png"); print(stem, im.size, "aspect %.2f" % (im.size[0] / im.size[1]))
