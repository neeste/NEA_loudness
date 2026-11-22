#!/usr/bin/env python3
"""Emit fig_letter4.plt: Figure 4 of the JASA-EL letter (2026-11-21), two panels at 1 kHz for the committed model.
A  Loudness growth: categorical-scaling data (black solid) and model (red dashed) for the tone, the quarter-octave and the
   one-octave band (the three pairs nearly coincide); dotted vertical line, the data floor near 15 dB SPL.
   Source: nea_growth_curves.json (nea_dump_growth.m). Since 2026-11-22 (the user's decision) the model curves use the loudness constant fitted
   over 250 Hz to 6 kHz (0.813e-5, const_10 of nea_letter_supp_window.json) in place of the 1.011e-5 of nea_fit_params.mat, with which the file
   of curves was written: the curves are multiplied by KC = 0.804. The parameter file is not changed.
B  Influence of bandwidth for the one-octave band (tone level at equal loudness minus band level) against level, for
   three values of the read-out weight: the committed value 0.88 (black solid) and 0.25 below and above it (0.63, blue
   dashed; 1.13, red dashed); circles, the categorical-scaling data (30 to 100 dB SPL). Source: nea_letter_fig4b.json
   (general-model/letter_fig4b.m, committed model with its 10-ms gammatone window, no fit) and nea_mechanism.json (data).
The linear frame (B) is drawn first and the logarithmic frame (A) last, because PLT carries ycyc across frames.
In-frame text is the panel letter and title only; styles go in the caption.
Render: python3 make_plt_letter_fig4.py && plt -m8 fig_letter4.plt | python3 crop_svg.py /dev/stdin fig_letter4.svg && python3 svg_to_pdf.py fig_letter4.svg letter_figures/Fig4_growth_and_weight 0.75
Journal size (2026-11-22): the last argument sets the final size to 0.75 of this layout, 5.7 in wide with a cap height of 0.09 in (9-pt type, as in
Figs. 1 to 3); parts are labeled (a) and (b); no line is under 0.5 pt at that size (a PLT weight of 1 is 0.35 pt there, so no weight is under 1.5).
"""
import json, os
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); CAP = 0.12; MARG = 0.04
G = json.load(open(os.path.join(HERE, 'nea_letter_growth.json'))); KC = 1.0; B = json.load(open(os.path.join(HERE, 'nea_letter_fig4b.json'))); F2 = json.load(open(os.path.join(HERE, 'nea_letter_fig2.json'))); M = {'Lv': F2['data']['Lv'], 'data': F2['data']}   # letter model (gtfb filterbank, letter_score.m); the growth curves carry the fitted constant
def line(xs, ys, lt, col, lwt=1.5):
    return f'pltype=lines : lintype={lt} : pltcol={col} : pltlwt={lwt}\n' + '\n'.join(f'{x:.5g}\t{y:.5g}' for x, y in zip(xs, ys) if y is not None and np.isfinite(y)) + '\nplot\n'
def sym(xs, ys, symbol, col, size=0.8):
    return f'pltype=sym : symbol={symbol} : pltcol={col} : symsiz={size}\n' + '\n'.join(f'{x:.4g}\t{y:.4g}' for x, y in zip(xs, ys)) + '\nplot\n'
def main():
    w, h, gx, x0, y0 = 2.8, 2.5, 1.0, 0.95, 0.90
    out = ['head=0 : clip=yes']
    # ---- B (linear), drawn first ----
    # the level axis runs to 110 so that the data point at 100 dB is not on the frame edge; ticks every 10 dB, labels every 20
    assert B['freqs'][0] == 1000
    Lv = np.array(B['levels'], float); D = np.array(B['delta'], float)[:, 0, :]; ws = B['weights']        # weight x level at 1 kHz
    ylo, yhi, ny = -12, 4, 8; top = yhi + (yhi - ylo) / ny
    yt = ' '.join(str(v) for v in range(ylo, yhi + 1, 2)); xt = ' '.join(str(v) for v in range(20, 101, 20))
    s = [f'xllc={x0 + w + gx} : yllc={y0} : xlen={w} : ylen={h}', 'xmin=20 : xmax=110 : xcyc=0 : xint=9.1 : xfmt=i3', f'ymin={ylo} : ymax={top} : ycyc=0 : yhor=yes : yint={ny + 1}.2 : yfmt=i3',
         f'xannot= {xt}', f'yannot= {yt}', 'ticdir=in : clip=yes', f'annsiz=-{CAP} : labsiz=-{CAP}', 'xlabel=level (dB SPL)', 'ylabel=influence of bandwidth (dB)']
    s.append(line([20, 110], [0, 0], 1, 8, 1.5))
    for wi, (lt, col) in zip(range(3), ((3, 1), (0, 0), (3, 4))): s.append(line(Lv, D[wi], lt, col, 1.8 if wi == 1 else 1.5))
    ml = np.array(M['Lv'], float); md = np.array(M['data']['octave'], float); k = ml >= 30
    s.append(sym(ml[k], md[k], 1, 0, 0.8))
    x = 20 + MARG * 90; y = top - (MARG + 0.5 * CAP / h) * (top - ylo)
    s.append(f'pltcol=0\nmsgdat=yes : mhal=lef : mval=half : msgsiz=-{CAP} : msgcol=0\n{x:.5g}\t{y:.5g}\t"(b)  one-octave band"\n')
    out.append('\n'.join(s) + '\n'); out.append('newframe')
    print('weights', [round(v, 2) for v in ws], '| at 60 dB:', np.round(D[:, list(Lv).index(60)], 2), '| per 0.1 of the weight, 45 to 80 dB:', np.round((D[2] - D[0])[(Lv >= 45) & (Lv <= 80)] / 5, 2))
    # ---- A (logarithmic), drawn last ----
    fi = [int(f) for f in G['freqs']].index(1000)
    s = [f'xllc={x0} : yllc={y0} : xlen={w} : ylen={h}', 'xmin=0 : xmax=100 : xcyc=0 : xint=5.2 : xfmt=i3', 'ymin=0.001 : ymax=1000 : ycyc=6 : yhor=yes', 'xannot= 0 20 40 60 80 100', 'yannot= 0.001 0.01 0.1 1 10 100', 'ticdir=in : clip=yes',
         f'annsiz=-{CAP} : labsiz=-{CAP}', 'xlabel=level (dB SPL)', 'ylabel=loudness (sones)']
    s.append(line([15, 15], [0.001, 100], 1, 8, 1.5))
    for bw in ('pure', 'q', 'oct'): s.append(line(G['spl'], G['data'][bw][fi], 0, 0, 1.5))
    for bw in ('pure', 'q', 'oct'): s.append(line(G['Ls'], KC * np.array(G['model'][bw][fi], float), 3, 4, 1.5))
    s.append(f'pltcol=0\nmsgdat=yes : mhal=lef : mval=half : msgsiz=-{CAP} : msgcol=0\n{100 * MARG:.5g}\t{10 ** (3 - (MARG + 0.5 * CAP / h) * 6):.5g}\t"(a)  loudness growth, 1 kHz"\n')
    out.append('\n'.join(s) + '\n')
    open(os.path.join(HERE, 'fig_letter4.plt'), 'w').write('\n'.join(out) + '\n'); print('wrote fig_letter4.plt')
if __name__ == '__main__':
    main()
