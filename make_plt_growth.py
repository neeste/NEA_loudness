#!/usr/bin/env python3
"""Emit PLT files for the loudness-growth figures from nea_growth_curves.json
(written by nea_dump_growth.m).

  fig_growth3.plt     3 CFs (1, 2, 4 kHz) x 3 bandwidths, CLS data vs model
  fig_pure_freqs.plt  pure-tone growth at 6 CFs, panel titles give the fitted G(f)

Render:  plt -m8 fig_growth3.plt > fig_growth3.svg      (SVG device is -m8 on the Mac build)
         plt -r -m5 fig_growth3.plt > fig_growth3.eps
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
J = json.load(open(os.path.join(HERE, 'nea_growth_curves.json')))
FREQS = [int(f) for f in J['freqs']]
FI = {f: i for i, f in enumerate(FREQS)}
SPL, LS, G = J['spl'], J['Ls'], J['G']
BW = [('pure', 'pure tone'), ('q', '1/4 octave'), ('oct', '1 octave')]

YMIN, YMAX = 1e-3, 1e2
CAP = 0.12                       # absolute cap height (in) for annotations and messages: 0.085 * W / C
LAB = 0.14                       # axis labels                      with W ~ 9.2 in natural, C = 6.5 in printed


def khz(f):
    return f'{f/1000:g} kHz' if f >= 1000 else f'{f} Hz'


def curve(xs, ys):
    """x y lines for a log-y curve; non-positive values are dropped (clip=yes handles the rest)."""
    pts = [f'{x:.5g}\t{y:.5g}' for x, y in zip(xs, ys) if y is not None and y > 0]
    return '\n'.join(pts) + '\nplot\n'


def panel(xllc, yllc, w, h, title, data, model, xlab, ylab, legend=False):
    s = []
    s.append(f'xllc={xllc:.3f} : yllc={yllc:.3f} : xlen={w:.3f} : ylen={h:.3f}')
    s.append('xmin=0 : xmax=100 : xint=5.2')
    s.append(f'ymin={YMIN:g} : ymax={YMAX:g} : ycyc=5 : yhor=yes')
    s.append('yannot= 0.001 0.01 0.1 1 10 100')
    s.append('ticdir=in : clip=yes')
    s.append(f'annsiz=-{CAP} : labsiz=-{LAB}')
    s.append(f'xlabel={"level (dB SPL)" if xlab else ""}')
    s.append(f'ylabel={"loudness (sones)" if ylab else ""}')
    s.append(f'xanskp={0 if xlab else -1} : yanskp={0 if ylab else -1}')
    # data floor of the CLS fits (15 dB)
    s.append('pltype=lines : lintype=1 : pltcol=1 : pltlwt=1')
    s.append(f'15\t{YMIN:g}\n15\t{YMAX:g}\nplot')
    # CLS data (black solid) and model (red dashed)
    s.append('pltype=lines : lintype=0 : pltcol=0 : pltlwt=2')
    s.append(curve(SPL, data))
    s.append('pltype=lines : lintype=3 : pltcol=4 : pltlwt=2')
    s.append(curve(LS, model))
    # title inside the panel, top left
    s.append(f'msgdat=yes : mhal=lef : mval=top : msgsiz=-{CAP} : msgcol=0')
    s.append(f'3\t60\t"{title}"')
    if legend:
        s.append('mval=half : msgcol=0')
        s.append('34\t0.012\t"|_0| CLS data"')
        s.append('msgcol=4')
        s.append('34\t0.004\t"|_3| model"')
    return '\n'.join(s) + '\n'


def figure(panels, ncol, nrow, w, h, gx, gy, x0, y0):
    out = ['head=0 : clip=yes']
    first = True
    for r in range(nrow):
        for c in range(ncol):
            k = r * ncol + c
            if k >= len(panels):
                continue
            if not first:
                out.append('newframe')
            first = False
            xllc = x0 + c * (w + gx)
            yllc = y0 + (nrow - 1 - r) * (h + gy)
            title, data, model = panels[k]
            out.append(panel(xllc, yllc, w, h, title, data, model,
                             xlab=(r == nrow - 1), ylab=(c == 0), legend=(k == 0)))
    return '\n'.join(out) + '\n'


def main():
    # ---- fig_growth3: rows 1, 2, 4 kHz; columns pure / 1/4-oct / 1-oct ----
    panels = []
    for f in (1000, 2000, 4000):
        for key, name in BW:
            panels.append((f'{khz(f)}, {name}', J['data'][key][FI[f]], J['model'][key][FI[f]]))
    txt = figure(panels, ncol=3, nrow=3, w=2.3, h=1.6, gx=0.45, gy=0.42, x0=1.05, y0=0.85)
    open(os.path.join(HERE, 'fig_growth3.plt'), 'w').write(txt)

    # ---- fig_pure_freqs: six CFs, pure tone, with G(f) ----
    panels = []
    for f in (250, 500, 1000, 4000, 6000, 8000):
        panels.append((f'{khz(f)}, G = {G[FI[f]]:.2f}', J['data']['pure'][FI[f]], J['model']['pure'][FI[f]]))
    txt = figure(panels, ncol=3, nrow=2, w=2.3, h=1.7, gx=0.45, gy=0.45, x0=1.05, y0=0.85)
    open(os.path.join(HERE, 'fig_pure_freqs.plt'), 'w').write(txt)
    print('wrote fig_growth3.plt and fig_pure_freqs.plt')


if __name__ == '__main__':
    main()
