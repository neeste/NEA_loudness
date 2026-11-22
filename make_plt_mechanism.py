#!/usr/bin/env python3
"""Emit fig_mechanism.plt from nea_mechanism.json (written by nea_mechanism_dump.m):
the mechanism of mid-bandwidth loudness depression at 1 kHz in the committed model.

  A  influence of bandwidth (dB at fixed loudness) vs bandwidth at 60 dB, for the broad sum
     alone, the peak-weighted average alone, and the level-gated blend; CLS data at 1/4 and 1 oct
  B  the same for the 1-octave band vs level, with the CLS data
  C  the level gate w(L) that sets the blend

Render:  plt -m8 fig_mechanism.plt | python3 crop_svg.py /dev/stdin fig_mechanism.svg
         plt -r -m5 fig_mechanism.plt > fig_mechanism.eps
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
J = json.load(open(os.path.join(HERE, 'nea_mechanism.json')))
OCT, LV = J['oct'], J['Lv']
D = J['delta']                      # committed / sum_only / peak_only : n_bw x n_Lv
W = J['w']
DQ, DO = J['data']['quarter'], J['data']['octave']
CAP, LAB = 0.12, 0.12   # one lettering size (2026-10-02: the 0.14 y label overhung the frame)
i60 = LV.index(60); i1 = OCT.index(1.0)
# common y range for A and B, rounded to 5 dB
vals = [v for key in D for row in D[key] for v in row if v is not None] + [v for v in DQ + DO if v is not None]
YMIN = min(-16, 4 * math.floor(min(vals) / 4)); YMAX = max(12, 4 * math.ceil(max(vals) / 4))   # 2026-10-02: room for the legend below the data
STY = {'sum_only': ('3', '2', 'sum only'), 'peak_only': ('5', '4', 'peak only'), 'committed': ('0', '0', 'gated blend')}


def pts(xs, ys):
    return '\n'.join(f'{x:.5g}\t{y:.4g}' for x, y in zip(xs, ys) if y is not None) + '\nplot\n'


def frame(xllc, w, h, xspec, ylab, ymin, ymax, yfmt=None):
    s = [f'xllc={xllc:.3f} : yllc=0.90 : xlen={w:.3f} : ylen={h:.3f}', xspec,
         f'ymin={ymin:g} : ymax={ymax:g} : yhor=yes' + (f' : yint={(ymax - ymin) // 4 + 0.2:.1f}' if ymax - ymin > 2 else ''), 'ticdir=in : clip=yes',
         f'annsiz=-{CAP} : labsiz=-{LAB}', f'ylabel={ylab}']
    if yfmt: s.append(f'yfmt={yfmt}')
    return s


def panel_A(xllc, w, h):
    s = frame(xllc, w, h, 'xmin=0.0625 : xmax=2 : xcyc=1.505 : xlabel=bandwidth (octaves)',
              'influence of bandwidth (dB)', YMIN, YMAX)
    s.append('xannot= 0.0625,1/16 0.125,1/8 0.25,1/4 0.5,1/2 1,1 2,2')
    s.append('pltype=lines : lintype=1 : pltcol=8 : pltlwt=1')          # zero line
    s.append(f'0.0625\t0\n2\t0\nplot')
    for key in ('sum_only', 'peak_only', 'committed'):
        lt, col, _ = STY[key]
        s.append(f'pltype=lines : lintype={lt} : pltcol={col} : pltlwt={2.2 if key == "committed" else 1.8}')
        s.append(pts(OCT, [row[i60] for row in D[key]]))
    s.append('pltype=sym : symbol=11 : pltcol=0 : symsiz=1.2')
    s.append(pts([0.25, 1.0], [DQ[i60], DO[i60]]))
    s.append(f'msgdat=yes : mhal=lef : mval=top : msgsiz=-{CAP} : msgcol=0')
    s.append(f'0.07\t{YMAX - 0.04 * (YMAX - YMIN):.4g}\t"A   1 kHz, 60 dB"')
    # legend, lower left (2026-10-02: the lower-right legend ran past the frame), below the
    # 1/4-octave data point; rows 2 dB apart with the frame bottom at YMIN = -16
    y0 = -8.5; dy = 2.0
    s.append('mval=half')
    for k, key in enumerate(('sum_only', 'peak_only', 'committed')):
        lt, col, name = STY[key]
        s.append(f'msgcol={col}')
        s.append(f'0.07\t{y0 - k * dy:.4g}\t"|_{lt}| {name}"')
    s.append('msgcol=0')
    s.append(f'0.07\t{y0 - 3 * dy:.4g}\t"|11| CLS data"')
    return '\n'.join(s) + '\n'


def panel_B(xllc, w, h):
    s = frame(xllc, w, h, 'xmin=0 : xmax=100 : xcyc=0 : xint=5.2 : xlabel=level (dB SPL)', '', YMIN, YMAX)
    s.append('xannot= 0 20 40 60 80 100')
    s.append('yanskp=-1')
    s.append('pltype=lines : lintype=1 : pltcol=8 : pltlwt=1')
    s.append('0\t0\n100\t0\nplot')
    for key in ('sum_only', 'peak_only', 'committed'):
        lt, col, _ = STY[key]
        s.append(f'pltype=lines : lintype={lt} : pltcol={col} : pltlwt={2.2 if key == "committed" else 1.8}')
        s.append(pts(LV, D[key][i1]))
    s.append('pltype=sym : symbol=11 : pltcol=0 : symsiz=1.2')
    s.append(pts(LV, DO))
    s.append(f'msgdat=yes : mhal=lef : mval=top : msgsiz=-{CAP} : msgcol=0')
    s.append(f'3\t{YMAX - 0.04 * (YMAX - YMIN):.4g}\t"B   1-octave band"')
    return '\n'.join(s) + '\n'


def panel_C(xllc, w, h):
    s = frame(xllc, w, h, 'xmin=0 : xmax=100 : xcyc=0 : xint=5.2 : xlabel=level (dB SPL)', 'gate weight w', 0, 1, yfmt='f3.1')
    s.append('xannot= 0 20 40 60 80 100')
    s.append('yanskp=0 : yint=5.2')
    s.append('pltype=lines : lintype=0 : pltcol=5 : pltlwt=2.2')
    s.append(pts(LV, W))
    s.append(f'msgdat=yes : mhal=lef : mval=top : msgsiz=-{CAP} : msgcol=0')
    s.append('3\t0.96\t"C   level gate"')
    s.append('mhal=rig : mval=half : msgcol=5')      # right-aligned (2026-10-02: left-aligned at 40 dB it ran past the frame)
    s.append(f'97\t0.20\t"w = {J["winh"]:.2f} exp(-z{{2}})"')
    s.append(f'97\t0.09\t"z = (L - {J["Lq50"]:.0f}) / {J["Lqw"]:.0f}"')
    return '\n'.join(s) + '\n'


def main():
    w, h, gab, gbc, x0 = 2.1, 2.5, 0.35, 0.75, 0.95   # 2026-10-02: 2.1 x 2.5 in panels; right edge 8.35 in
    out = ['head=0 : clip=yes', panel_A(x0, w, h), 'newframe', panel_B(x0 + w + gab, w, h), 'newframe', panel_C(x0 + 2 * w + gab + gbc, w, h)]
    open(os.path.join(HERE, 'fig_mechanism.plt'), 'w').write('\n'.join(out) + '\n')
    print(f'wrote fig_mechanism.plt  (y range {YMIN} .. {YMAX} dB)')


if __name__ == '__main__':
    main()
