#!/usr/bin/env python3
"""Emit fig_letterS2.plt: Figure S2 of the supplement to the JASA-EL letter (2026-11-22): loudness growth at the nine
center frequencies from 250 Hz to 6 kHz. In each panel, the categorical-scaling data (black solid) and the model (red
dashed) for the tone, the quarter-octave band and the one-octave band (the three pairs nearly coincide), as in
Fig. 4(a) of the letter; dotted vertical line, the lower limit of the data near 15 dB SPL.
Source: nea_growth_curves.json (nea_dump_growth.m, written with the loudness constant 1.011e-5 of nea_fit_params.mat). Since 2026-11-22 (the
user's decision) the model curves are multiplied by KC = 0.804, which gives the constant fitted over 250 Hz to 6 kHz (0.813e-5, const_10 of
nea_letter_supp_window.json), as in Fig. 4(a). The parameter file is not changed.
All frames are logarithmic in y. Tick labels and axis labels are drawn on the left column and the bottom row only.
In-frame text is the part label and the frequency, in the top decade, which holds no data.
Render: python3 make_plt_letter_figS2.py && plt -m8 fig_letterS2.plt | python3 crop_svg.py /dev/stdin fig_letterS2.svg
        && python3 svg_to_pdf.py fig_letterS2.svg letter_figures/FigS2_growth_all_frequencies 0.83
The last argument sets the final size to 0.83 of this layout: 6.6 in wide, cap height 0.09 in; a PLT weight of 1 is
0.39 pt there, so no weight is under 1.4.
"""
import json, os
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); CAP = 0.105; MARG = 0.05
G = json.load(open(os.path.join(HERE, 'nea_letter_growth.json'))); KC = 1.0   # letter model (gtfb filterbank, letter_score.m); the curves carry the fitted constant
W, H, GX, GY, X0, Y0 = 2.0, 1.55, 0.42, 0.22, 0.95, 0.65   # GX 0.42 keeps the label 100 of one panel clear of the 0 of the next
FREQS = [250, 500, 750, 1000, 1500, 2000, 3000, 4000, 6000]


def line(xs, ys, lt, col, lwt=1.6):
    return f'pltype=lines : lintype={lt} : pltcol={col} : pltlwt={lwt}\n' + '\n'.join(f'{x:.5g}\t{y:.5g}' for x, y in zip(xs, ys) if y is not None and np.isfinite(y) and y > 0) + '\nplot\n'


def name(f):
    return f'{f} Hz' if f < 1000 else f'{f / 1000:g} kHz'


def main():
    out = ['head=0 : clip=yes']
    fl = [int(f) for f in G['freqs']]
    for n, f in enumerate(FREQS):
        row, col = 2 - n // 3, n % 3; fi = fl.index(f)
        s = [f'xllc={X0 + col * (W + GX):.3f} : yllc={Y0 + row * (H + GY):.3f} : xlen={W} : ylen={H}', 'xmin=0 : xmax=100 : xcyc=0 : xint=5.2 : xfmt=i3', 'ymin=0.001 : ymax=1000 : ycyc=6 : yhor=yes',
             'xannot= 0 20 40 60 80 100', 'yannot= 0.001 0.01 0.1 1 10 100', 'ticdir=in : clip=yes', f'annsiz=-{CAP} : labsiz=-{CAP}',
             f'xanskp={0 if row == 0 else -1} : yanskp={0 if col == 0 else -1}',
             'xlabel=' + ('level (dB SPL)' if (row == 0 and col == 1) else ''), 'ylabel=' + ('loudness (sones)' if (row == 1 and col == 0) else '')]
        s.append(line([15, 15], [0.001, 100], 1, 8, 1.4))
        for bw in ('pure', 'q', 'oct'): s.append(line(G['spl'], G['data'][bw][fi], 0, 0, 1.6))
        for bw in ('pure', 'q', 'oct'): s.append(line(G['Ls'], KC * np.array(G['model'][bw][fi], float), 3, 4, 1.6))
        s.append(f'pltcol=0\nmsgdat=yes : mhal=lef : mval=half : msgsiz=-{CAP} : msgcol=0\n{100 * MARG:.5g}\t{10 ** (3 - (MARG + 0.5 * CAP / H) * 6):.5g}\t"({"abcdefghi"[n]})  {name(f)}"\n')
        out.append('\n'.join(s) + '\n')
        if n < len(FREQS) - 1: out.append('newframe')
    open(os.path.join(HERE, 'fig_letterS2.plt'), 'w').write('\n'.join(out) + '\n'); print('wrote fig_letterS2.plt')


if __name__ == '__main__':
    main()
