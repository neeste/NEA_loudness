#!/bin/sh
# Line figures of the letter (Figures 2 and 4, Figure S2) and of the poster (Figures 2 to 4), from the JSON files that
# letter_score.m writes. Needs python3 with numpy and Pillow, the PLT plotting program (plt) and rsvg-convert.
set -e
cd "$(dirname "$0")"
mkdir -p letter_figures poster/fig
python3 make_mechanism_json.py
python3 make_plt_letter_fig2.py  && plt -m8 fig_letter2.plt  | python3 crop_svg.py /dev/stdin fig_letter2.svg  && python3 svg_to_pdf.py fig_letter2.svg  letter_figures/Fig2_readout_and_mechanism 0.9
python3 make_plt_letter_fig4.py  && plt -m8 fig_letter4.plt  | python3 crop_svg.py /dev/stdin fig_letter4.svg  && python3 svg_to_pdf.py fig_letter4.svg  letter_figures/Fig4_growth_and_weight 0.75
python3 make_plt_letter_figS2.py && plt -m8 fig_letterS2.plt | python3 crop_svg.py /dev/stdin fig_letterS2.svg && python3 svg_to_pdf.py fig_letterS2.svg letter_figures/FigS2_growth_all_frequencies 0.83
(cd poster && python3 make_poster_figs.py)
