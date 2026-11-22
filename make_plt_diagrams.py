#!/usr/bin/env python3
"""Emit PLT files for the two schematic figures (successor of nea_make_diagrams.m).

  fig_architecture.plt  Fig 1: front end -> single neural-ensemble-averaging read-out
  fig_pathways.plt      Fig 2: expansion of that read-out (excitation vs inhibition)

No axes: data coordinates are inches. No fills (PLT's shading corrupts the SVG page);
boxes are told apart by line color and weight (weights kept within 1.0-1.8 so that box, arrow and lettering strokes stay comparable; harmonized 2026-09-28). Cross-references live in the captions.
Render:  plt -m8 fig_architecture.plt | python3 crop_svg.py /dev/stdin fig_architecture.svg
"""
import math, os

HERE = os.path.dirname(os.path.abspath(__file__))
BLACK, BLUE, GREEN, RED, MAGENTA, BROWN, LGRAY, DGRAY = 0, 1, 2, 4, 5, 6, 7, 8
CAP, TAG, HEAD = 0.12, 0.11, 0.13          # cap heights (in): box text, side tags, bold headers


def header(xlen, ylen):
    return [
        'head=0',
        'xaxis=0 : yaxis=0 : taxis=0 : raxis=0 : axlwt=0 : annlwt=0',
        f'xllc=0 : yllc=0 : xlen={xlen} : ylen={ylen} : xmin=0 : xmax={xlen} : ymin=0 : ymax={ylen}',
        'msgdat=yes',
    ]


def rect(x0, y0, x1, y1, col=BLACK, lwt=1.3):
    return [f'pltype=rect : pltcol={col} : pltlwt={lwt}', f'{x0:.3f}\t{y0:.3f}', f'{x1:.3f}\t{y1:.3f}', 'plot']


def polyline(pts, col=BLACK, lwt=1.3, lintype=0, arrow=False, arosiz=1.0):
    s = [f'pltype=lines : lintype={lintype} : pltcol={col} : pltlwt={lwt} : aronum={1 if arrow else 0} : arosiz={arosiz} : arotip=0.5']
    s += [f'{x:.4f}\t{y:.4f}' for x, y in pts]
    s += ['plot', 'aronum=0']
    return s


def arrow(x0, y0, x1, y1, col=DGRAY, lwt=1.3):
    return polyline([(x0, y0), (x1, y1)], col, lwt, arrow=True, arosiz=1.0)


def msg(x, y, text, size=CAP, col=BLACK, hal='cen', val='half', bold=False):
    return [f'mhal={hal} : mval={val} : msgsiz=-{size} : msgcol={col} : msglwt={1.6 if bold else 1}',
            f'{x:.3f}\t{y:.3f}\t"{text}"']


def box(xc, yc, w, h, lines, col=BLACK, lwt=1.3, pitch=0.30, size=CAP):
    """Outlined box with centered text lines; a line given as (text, True) is bold."""
    s = rect(xc - w / 2, yc - h / 2, xc + w / 2, yc + h / 2, col, lwt)
    n = len(lines)
    for i, ln in enumerate(lines):
        text, bold = (ln if isinstance(ln, tuple) else (ln, False))
        y = yc + pitch * ((n - 1) / 2 - i)
        s += msg(xc, y, text, size=(HEAD if bold else size), bold=bold)
    return s


# ------------------------------------------------------------------ Figure 1
def architecture():
    XLEN, YLEN = 8.4, 6.4
    xc, w, h, pitch = 2.4, 4.0, 0.42, 0.66
    xtag = xc + w / 2 + 0.2
    out = header(XLEN, YLEN)
    stages = [
        ('Stimulus', None, BLACK, 1.3),
        ('Gammatone filterbank (ERB-rate)', 'cochlear place / tuning', BLUE, 1.3),
        ('Half-wave rectify + envelope LPF', 'IHC transduction, phase-locking lost', BLUE, 1.3),   # no ';' in PLT text: it starts a comment
        ('Sensitivity gain  G(f)', 'middle-ear + cochlear sensitivity', BLUE, 1.3),
        ('Quadratic compression (Neely-Jesteadt)', 'BM / OHC compression, place-dependent', BLUE, 1.3),
        ('Neural rate transform', 'AN / CN-input rate-level function', BLUE, 1.3),
        ('Channel scores  s[k]   (k = 1 ... 60)', 'tonotopic array', BLACK, 1.3),
    ]
    ys = [6.0 - i * pitch for i in range(len(stages))]
    for (text, tag, col, lwt), y in zip(stages, ys):
        out += box(xc, y, w, h, [text], col, lwt)
        if tag:
            out += msg(xtag, y, tag, size=TAG, col=DGRAY, hal='lef')
    gap = pitch - h                                    # 0.24 in between boxes
    for y0, y1 in zip(ys[:-1], ys[1:]):
        out += arrow(xc, y0 - h / 2, xc, y1 + h / 2)
    # the single neural-ensemble-averaging read-out (expanded in Figure 2)
    hN = 0.62
    yN = ys[-1] - h / 2 - gap - hN / 2
    out += box(xc, yN, w, hN, [('Neural-ensemble averaging', True), '(level-gated CN read-out)'], MAGENTA, 1.8, pitch=0.27)
    out += msg(xtag, yN, 'cochlear nucleus', size=TAG, col=DGRAY, hal='lef')
    out += arrow(xc, ys[-1] - h / 2, xc, yN + hN / 2)
    yL = yN - hN / 2 - gap - h / 2
    out += box(xc, yL, w, h, ['Expected loudness'], BLACK, 1.3)
    out += arrow(xc, yN - hN / 2, xc, yL + h / 2)
    return '\n'.join(out) + '\n'


# ------------------------------------------------------------------ Figure 2
def pathways():
    XLEN, YLEN = 9.2, 5.5
    out = header(XLEN, YLEN)
    # --- excitation-pattern inset: narrow vs wide band, same RMS ---
    ix0, ix1, base, top = 3.1, 6.1, 4.05, 1.0 * 0.95
    out += rect(2.95, 3.70, 6.25, 5.15, LGRAY, 1.0)
    out += msg(4.6, 5.30, 'Excitation pattern (same RMS)', size=HEAD, bold=True)
    n = 120
    xs = [ix0 + (ix1 - ix0) * i / (n - 1) for i in range(n)]
    u = lambda x: (x - ix0) / (ix1 - ix0)
    narrow = [(x, base + top * math.exp(-((u(x) - 0.5) / 0.07) ** 2)) for x in xs]
    wide = [(x, base + top * (0.07 / 0.18) * math.exp(-((u(x) - 0.5) / 0.18) ** 2)) for x in xs]
    out += polyline(wide, BROWN, 1.8, lintype=3)
    out += polyline(narrow, BLUE, 1.8)
    out += polyline([(ix0, base), (ix1 + 0.05, base)], BLACK, 1.0, arrow=True, arosiz=0.8)
    out += msg(4.3, 4.85, 'narrow', size=TAG, col=BLUE, hal='rig')
    out += msg(5.55, 4.32, 'wide', size=TAG, col=BROWN, hal='lef')
    out += msg(4.6, 3.86, 'characteristic frequency', size=0.10, col=DGRAY)
    # --- two pathway boxes ---
    yb, hb, wb = 2.35, 2.0, 4.1
    out += box(2.30, yb, wb, hb, [('Broad sum', True), 'excitation: T-stellate / chopper',
                                  'L[E] = ^S^ s[k]   (area under the pattern)',
                                  'wider band -> larger sum', ('LOUDER', True)], GREEN, 1.5)
    out += box(6.90, yb, wb, hb, [('Peak-weighted average', True), 'inhibition: D-stellate / onset-C',
                                  'L[I] = (^S^ s[k]{q}){1/q}   (tracks the peak)',
                                  'spreading lowers the peak', ('LESS LOUD', True)], RED, 1.5)
    out += arrow(3.40, 3.70, 2.90, 3.38)
    out += arrow(5.80, 3.70, 6.30, 3.38)
    # --- combination box ---
    out += box(4.60, 0.55, 6.8, 0.90, [('Level-gated ensemble average: peak-weighting recruits with level', True),
                                       'L = L[E] (L[I] / L[E]){w}',
                                       'reduction strongest at mid level, weakest at the extremes'], MAGENTA, 1.8, pitch=0.28)
    out += arrow(2.60, 1.35, 3.40, 1.02)
    out += arrow(6.60, 1.35, 5.80, 1.02)
    return '\n'.join(out) + '\n'


def main():
    open(os.path.join(HERE, 'fig_architecture.plt'), 'w').write(architecture())
    open(os.path.join(HERE, 'fig_pathways.plt'), 'w').write(pathways())
    print('wrote fig_architecture.plt and fig_pathways.plt')


if __name__ == '__main__':
    main()
