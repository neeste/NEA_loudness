#!/usr/bin/env python3
"""Emit fig_letter2.plt: Figure 2 of the JASA-EL letter at journal size (2026-11-22), four panels for the committed model
at 1 kHz. It combines the two poster figures (the two averages, and the mechanism at 1 kHz).
(a) Activity across the 60 channels at 60 dB SPL, relative to the peak for the tone: tone (solid), quarter-octave complex
    (dotted), one-octave complex (dashed). Source: nea_letter_fig2a.json (letter_score.m).
(b) Influence of bandwidth against bandwidth at 60 dB SPL under three read-outs: broad sum alone (red dashed),
    peak-weighted average alone (blue dash-dot), fitted level-gated blend (black solid); circles, the data.
(c) The level gate: weight of the peak-weighted average against level.
(d) As (b) for the one-octave complex against level; data from 30 dB SPL.
Sources for (b) to (d): nea_letter_fig2.json (letter_score.m, the letter's model with the gtfb filterbank since 2026-11-22; data included).
Journal limits: width at most 6.69 in, lettering at least 8 pt (cap height 0.10 in here, about 10-pt type), lines at
least 0.5 pt (a PLT weight of 1 is 0.42 pt at the final size, so no weight here is under 1.3), parts labeled (a), (b). In-frame text is the part label and a short title, in a band one tick interval
high; styles go in the caption. The y label of (b) and (d) is one rotated message centered on the pair, because the
label is longer than one frame is high.
Render: python3 make_plt_letter_fig2.py && plt -m8 fig_letter2.plt | python3 crop_svg.py /dev/stdin fig_letter2.svg
        && python3 svg_to_pdf.py fig_letter2.svg letter_figures/Fig2_readout_and_mechanism 0.9
The last argument sets the final size to 0.9 of this layout: 5.8 in wide, cap height 0.09 in (9-pt type, as in Figs. 1 and 3).
"""
import json, os
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); CAP = 0.10; MARG = 0.04
A = json.load(open(os.path.join(HERE, 'nea_letter_fig2a.json'))); J = json.load(open(os.path.join(HERE, 'nea_letter_fig2.json'))); M = {'Lv': J['data']['Lv'], 'data': J['data']}   # letter model (gtfb filterbank, letter_score.m)
W, H, GX, GY, X0, Y0 = 2.40, 1.50, 0.85, 0.78, 0.75, 0.60
STY = {'sum_only': (3, 4, 1.5), 'peak_only': (5, 1, 1.5), 'committed': (0, 0, 1.7)}          # lintype, color, weight


def line(xs, ys, lt, col, lwt=1.5):
    return f'pltype=lines : lintype={lt} : pltcol={col} : pltlwt={lwt}\n' + '\n'.join(f'{x:.5g}\t{y:.5g}' for x, y in zip(xs, ys) if y is not None and np.isfinite(y)) + '\nplot\n'


def sym(xs, ys, symbol, col, size=1.0):
    return f'pltype=sym : symbol={symbol} : pltcol={col} : symsiz={size}\n' + '\n'.join(f'{x:.4g}\t{y:.4g}' for x, y in zip(xs, ys)) + '\nplot\n'


def frame(col, row, xspec, yspec, xlabel, ylabel):
    return [f'xllc={X0 + col * (W + GX):.3f} : yllc={Y0 + row * (H + GY):.3f} : xlen={W} : ylen={H}', xspec, yspec, 'ticdir=in : clip=yes',
            f'annsiz=-{CAP} : labsiz=-{CAP}', f'xlabel={xlabel}', f'ylabel={ylabel}']


def title(text, xlo, xhi, ylo, ytop, logx=False):
    """Part label and title at the upper left, inside the title band, at a margin of MARG of the frame."""
    x = 10 ** (np.log10(xlo) + MARG * np.log10(xhi / xlo)) if logx else xlo + MARG * (xhi - xlo)
    y = ytop - (MARG + 0.5 * CAP / H) * (ytop - ylo)
    return f'pltcol=0 : msgang=0\nmsgdat=yes : mhal=lef : mval=half : msgsiz=-{CAP} : msgcol=0\n{x:.5g}\t{y:.5g}\t"{text}"\n'


def influence_axis():
    # -8 to 16 dB with ticks every 4 dB, and one more interval (to 20) for the title
    return -8, 20, 'ymin=-8 : ymax=20 : ycyc=0 : yhor=yes : yint=7.2 : yfmt=i3\nyannot= -8 -4 0 4 8 12 16'


def main():
    out = ['head=0 : clip=yes']
    LEV = 'xmin=0 : xmax=110 : xcyc=0 : xint=11.1 : xfmt=i3\nxannot= 0 20 40 60 80 100'
    Lv = np.array(J['Lv'], float)
    # ---- (c) level gate: bottom left ----
    s = frame(0, 0, LEV, 'ymin=0 : ymax=1.2 : ycyc=0 : yhor=yes : yint=6.2 : yfmt=f3.1\nyannot= 0.0 0.2 0.4 0.6 0.8 1.0', 'level (dB SPL)', 'weight')
    s.append(line(Lv, J['w'], 0, 0, 1.7))
    s.append(title('(c)  level gate', 0, 110, 0, 1.2))
    out.append('\n'.join(s) + '\n'); out.append('newframe')
    # ---- (d) influence against level, one-octave complex: bottom right ----
    ylo, ytop, yspec = influence_axis()
    s = frame(1, 0, LEV, yspec, 'level (dB SPL)', '')
    s.append(line([0, 110], [0, 0], 1, 8, 1.3))
    for key in ('sum_only', 'peak_only', 'committed'):
        lt, col, lwt = STY[key]; s.append(line(Lv, J['delta'][key]['level'], lt, col, lwt))
    ml = np.array(M['Lv'], float); md = np.array(M['data']['octave'], float); k = ml >= 30
    s.append(sym(ml[k], md[k], 1, 0))
    s.append(title('(d)  one-octave band', 0, 110, ylo, ytop))
    # the y label shared by (b) and (d): rotated, centered on the pair, in inches from the lower left corner of (d)
    s.append(f'msgdat=no : msgang=90 : mhal=cen : mval=half : msgsiz=-{CAP} : msgcol=0\n{-0.50:.3f}\t{H + GY / 2:.3f}\t"influence of bandwidth (dB)"\nmsgang=0\n')
    out.append('\n'.join(s) + '\n'); out.append('newframe')
    # ---- (b) influence against bandwidth at 60 dB SPL: top right ----
    oc = np.array(J['oct'], float)
    s = frame(1, 1, 'xmin=0.0625 : xmax=2 : xcyc=1.505\nxannot= 0.0625,1/16 0.125,1/8 0.25,1/4 0.5,1/2 1,1 2,2', yspec, 'bandwidth (octaves)', '')
    s.append(line([0.0625, 2], [0, 0], 1, 8, 1.3))
    for key in ('sum_only', 'peak_only', 'committed'):
        lt, col, lwt = STY[key]; s.append(line(oc, J['delta'][key]['bw'], lt, col, lwt))
    i60 = M['Lv'].index(60); s.append(sym([0.25, 1.0], [M['data']['quarter'][i60], M['data']['octave'][i60]], 1, 0))
    s.append(title('(b)  60 dB SPL', 0.0625, 2, ylo, ytop, logx=True))
    out.append('\n'.join(s) + '\n'); out.append('newframe')
    # ---- (a) activity across channels: top left ----
    cf = np.array(A['cfs'], float) / 1000; pk = max(A['tone']); k = (cf >= 0.2) & (cf <= 5)
    s = frame(0, 1, 'xmin=0.2 : xmax=5 : xcyc=1.39794\nxannot= 0.25 0.5 1 2 4', 'ymin=0 : ymax=1.2 : ycyc=0 : yhor=yes : yint=6.2 : yfmt=f3.1\nyannot= 0.0 0.2 0.4 0.6 0.8 1.0', 'characteristic frequency (kHz)', 'channel activity')
    for key, lt, lwt in (('octave', 3, 1.5), ('quarter', 1, 1.5), ('tone', 0, 1.7)):
        s.append(line(cf[k], np.array(A[key], float)[k] / pk, lt, 0, lwt))
    s.append(title('(a)  60 dB SPL', 0.2, 5, 0, 1.2, logx=True))
    out.append('\n'.join(s) + '\n')
    open(os.path.join(HERE, 'fig_letter2.plt'), 'w').write('\n'.join(out) + '\n')
    print('wrote fig_letter2.plt | at 60 dB, one octave: sum %+.1f, peak %+.1f, blend %+.1f dB; data %+.1f dB' % tuple(
        [J['delta'][key]['level'][list(Lv).index(60)] for key in ('sum_only', 'peak_only', 'committed')] + [M['data']['octave'][i60]]))
    print('peak activity relative to the tone: quarter octave %.2f, one octave %.2f' % (max(A['quarter']) / pk, max(A['octave']) / pk))


if __name__ == '__main__':
    main()
