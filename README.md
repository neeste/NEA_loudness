# NEA loudness model: data and code for the figures

This repository holds what is needed to reproduce the figures of

- the letter on the neural-ensemble averaging (NEA) model of loudness (S. T. Neely and Y. Shen, in preparation for JASA Express Letters), and
- the poster "A physiologically inspired neural-ensemble averaging model illustrates a possible origin of nonmonotonic bandwidth effects in loudness" (ARO MidWinter Meeting 2027).

Both report the same model: 60 complex fourth-order gammatone filters on an ERB-rate scale, an envelope taken from the magnitude of the filter output, a sensitivity gain, place-dependent compression, a rate function, and a read-out across channels that blends a broad sum with a peak-weighted average under a level-dependent weight.

## Contents

| Files | What they are |
|---|---|
| `letter_refit.m` | the model (cached envelopes, channel scores, read-out) and its staged fit |
| `gtfb.m`, `gammatone.m` | the gammatone filterbank (S. T. Neely; complex recursive filters after Härmä, 1999) |
| `nea_gen_tone.m`, `nea_gen_5tc.m` | stimuli: tone and five-tone complex |
| `nea_letter_params.mat` | the fitted parameters; `nea_start_params.mat`, the starting values of the fit |
| `nea_cls_targets.mat`, `nea_targets_10dB.mat` | the data: loudness and influence of bandwidth averaged over 30 listeners with normal hearing |
| `letter_score.m` | scores, tests and the data files of the figures (`nea_letter_*.json`, `nea_letter_maps.mat`) |
| `letter_extras.m`, `letter_refit_diag.m` | variants of the model and a diagnostic of the fit |
| `letter_maps.m`, `nea_heatpanel.m`, `nea_poster_heatmaps*.m` | the maps: letter Figures 1 and 3, Figure S1, poster Figures 1 and 5 |
| `make_plt_letter_fig2.py`, `..._fig4.py`, `..._figS2.py` | letter Figures 2 and 4, Figure S2 |
| `poster/make_poster_figs.py` with `make_plt_diagrams.py`, `make_plt_mechanism.py`, `make_plt_growth.py` | poster Figures 2 to 4 |
| `figures/`, `logs/` | the figures and the console output as produced on 2026-11-22 |

## To reproduce

1. In MATLAB, from this folder: `run_all` (about 5 minutes), or `run_all(true)` to refit the model first.
2. In a shell: `./make_figures.sh`.

The data files that step 1 writes are included, so step 2 can be run on its own.

## Requirements

- MATLAB (R2025b was used) with the Statistics and Machine Learning Toolbox.
- Python 3 with numpy and Pillow; `rsvg-convert`.
- The PLT plotting program for the line figures: http://audres.org/rc/plt/

## Data

The measurements are categorical loudness scaling of tones and of quarter-octave and one-octave bands of noise, made at Boys Town National Research Hospital. The trial-by-trial responses of all participants are at https://doi.org/10.5281/zenodo.23090549. This repository holds the averages over the 30 listeners with normal hearing that the model was fitted to, and the standard errors of those averages; it holds no data of individual listeners. The intervals from resampling listeners that the letter quotes need the listeners' fitted functions, which are not included; their results are in `logs/letter_bootstrap.log`.

## License

The code is released under the MIT License (`LICENSE`). The data files (`*.mat`, `*.json`) and the figures are released under the Creative Commons Attribution 4.0 International license (`LICENSE-DATA.md`).
