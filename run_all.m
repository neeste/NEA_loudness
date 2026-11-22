function run_all(refit)
% RUN_ALL  Recompute everything the figures need, from the data in this folder.
%   run_all          scores, tests and figure data for the parameters on file (nea_letter_params.mat), about 5 minutes
%   run_all(true)    refit the model first (letter_refit('fit'), about 10 minutes), then the same
% Then run make_figures.sh for the line figures. Needs MATLAB with the Statistics and Machine Learning Toolbox (corr).
    if nargin < 1, refit = false; end
    if refit, letter_refit('fit'); end
    if ~exist('letter_figures', 'dir'), mkdir('letter_figures'); end
    if ~exist(fullfile('poster', 'fig'), 'dir'), mkdir(fullfile('poster', 'fig')); end
    letter_score;                  % scores, tests on cells, held-out frequencies, data for Figures 2 to 4, S1 and S2
    letter_extras;                 % variants of the model (supplement, Section S6)
    letter_maps('draw');           % Figures 1 and 3 of the letter and Figure S1
    nea_poster_heatmaps;           % poster Figure 1
    nea_poster_heatmaps_letter;    % poster Figure 5
end
