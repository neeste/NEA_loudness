function letter_maps(mode)
% LETTER_MAPS  Figures 1 and 3 of the JASA-EL letter at journal size (2026-11-22), and the data for panel (a) of Figure 2.
%   letter_maps('draw')     draws from nea_letter_maps.mat, at 6.6 in wide with 9-pt lettering:
%                           (each as .png, .tif and .pdf at 600 pixels per inch)
%                           letter_figures/Fig1_data_maps.pdf/.png     data, quarter-octave and one-octave
%                           letter_figures/Fig3_model_maps.pdf/.png    one-octave: data, sum only, fitted model
%                           letter_figures/FigS1_quarter_octave_maps.pdf/.png   the same three maps, quarter-octave (supplement)
% Journal limits (Information for Contributors, 1 May 2025): width at most 6.69 in, lettering at least 8 pt, lines at
% least 0.5 pt, parts labeled (a), (b). Maps are interpolated for display exactly as in nea_heatpanel.m (makima), on a
% finer grid so that no cell is visible at 600 dpi. Color: diverging, blue below 0 (band less loud than the tone),
% white at 0, red above. Run from this folder after letter_score: letter_maps('draw')
    if nargin < 1, mode = 'draw'; end
    switch mode
        case 'draw', draw();
        otherwise, error('mode is draw');
    end
end

function draw()
    M = load('nea_letter_maps.mat'); out = 'letter_figures'; if ~exist(out,'dir'), mkdir(out); end
    clim = [-8 12]; cm = divmap(clim);
    % ---------- Figure 1: the data ----------
    [fig, ax, cax] = layout(2, 2.00); 
    panel(ax(1), M.dataQ, M.spl, M.freqs, '(a) Quarter-octave band', clim, cm, true);
    panel(ax(2), M.data1, M.spl, M.freqs, '(b) One-octave band', clim, cm, false);
    cbar(ax(2), cax, clim, cm); save2(fig, fullfile(out, 'Fig1_data_maps'));
    % ---------- Figure 3: one-octave band, data and model ----------
    [fig, ax, cax] = layout(3, 1.75);
    panel(ax(1), M.data1, M.spl, M.freqs, '(a) Data', clim, cm, true);
    panel(ax(2), M.D1off, M.Lf, M.F, '(b) Model, broad sum only', clim, cm, false);
    panel(ax(3), M.D1on, M.Lf, M.F, '(c) Model, fitted read-out', clim, cm, false);
    cbar(ax(3), cax, clim, cm); save2(fig, fullfile(out, 'Fig3_model_maps'));
    % ---------- supplement: the same for the quarter-octave band ----------
    [fig, ax, cax] = layout(3, 1.75);
    panel(ax(1), M.dataQ, M.spl, M.freqs, '(a) Data', clim, cm, true);
    panel(ax(2), M.DQoff, M.Lf, M.F, '(b) Model, broad sum only', clim, cm, false);
    panel(ax(3), M.DQon, M.Lf, M.F, '(c) Model, fitted read-out', clim, cm, false);
    cbar(ax(3), cax, clim, cm); save2(fig, fullfile(out, 'FigS1_quarter_octave_maps'));
end

function [fig, ax, cax] = layout(n, ph)
% n panels in a row on a page 6.60 in wide, all dimensions in inches: panel height ph, gap between panels 0.36 (so that
% the end tick labels of neighbors stay apart), a color bar 0.13 wide.
    W = 6.60; left = 0.52; gap = 0.36; cgap = 0.14; cw = 0.13; right = 0.50; bot = 0.47; top = 0.27;   % the image PDF comes out about 0.04 in wider than the figure, so 6.60 keeps it under 6.69
    pw = (W - left - (n-1)*gap - cgap - cw - right)/n; H = bot + ph + top;
    fig = figure('Color', 'w', 'Units', 'inches', 'Position', [1 1 W H], 'PaperUnits', 'inches', 'PaperSize', [W H], 'PaperPosition', [0 0 W H]);
    ax = gobjects(1,n);
    for i = 1:n, ax(i) = axes(fig, 'Units', 'inches', 'Position', [left + (i-1)*(pw+gap), bot, pw, ph]); end
    cax = [left + n*pw + (n-1)*gap + cgap, bot, cw, ph];
    fprintf('layout: %d panels of %.2f x %.2f in, page %.2f x %.2f in\n', n, pw, ph, W, H);
end

function cbar(ax, cax, clim, cm)
    pos = ax.Position; cb = colorbar(ax, 'Units', 'inches', 'Position', cax); ax.Position = pos;
    cb.Label.String = 'Influence of bandwidth (dB)'; cb.FontSize = 9; cb.Label.FontSize = 9; cb.LineWidth = 0.6; cb.Ticks = clim(1):4:clim(2); cb.TickDirection = 'out';
    set(findall(gcf, 'Type', 'axestoolbar'), 'Visible', 'off');
end

function save2(fig, stem)
% Everything at 600 pixels per inch, the journal's figure for a combination of line art and shading. A vector PDF is not
% written: MATLAB embeds the map in it at screen resolution (96 pixels per inch), under the journal's 600.
% Files are written to a temporary folder and copied into place: written directly over a file that OneDrive was
% syncing, two of the PDFs came out empty (2026-11-22).
    tmp = tempname; mkdir(tmp); ext = {'.png', '.tif', '.pdf'};
    exportgraphics(fig, fullfile(tmp, 'f.png'), 'Resolution', 600);
    exportgraphics(fig, fullfile(tmp, 'f.tif'), 'Resolution', 600);
    exportgraphics(fig, fullfile(tmp, 'f.pdf'), 'ContentType', 'image', 'Resolution', 600);
    for i = 1:3
        d = dir(fullfile(tmp, ['f' ext{i}])); assert(~isempty(d) && d.bytes > 1000, 'export failed: %s', ext{i});
        copyfile(fullfile(tmp, ['f' ext{i}]), [stem ext{i}], 'f'); e = dir([stem ext{i}]); assert(e.bytes == d.bytes, 'copy incomplete: %s', [stem ext{i}]);
    end
    rmdir(tmp, 's'); fprintf('saved %s.png, .tif and .pdf\n', stem); close(fig);
end

function panel(ax, D, L, F, ttl, clim, cm, ylab)
% One map. D is numel(F) x numel(L). Interpolation as in nea_heatpanel.m (makima over level and frequency in Hz), on
% 400 log-spaced frequencies and quarter-dB levels. Rows without data stay white. Ticks point outward on the bottom and
% left only; the top and right of the frame are plain lines, so that the part label above the frame stays clear.
    fs = 9; F = double(F(:)'); L = double(L(:)'); Lq = 0:0.25:100; nx = 400; fI = logspace(log10(250), log10(8000), nx);
    rows = any(isfinite(D), 2); Df = fillmissing(D(rows,:), 'nearest', 2);
    [X,Y] = meshgrid(L, F(rows)); inr = find(fI >= min(F(rows)) & fI <= max(F(rows))); [Xq,Yq] = meshgrid(Lq, fI(inr));
    Dq = interp2(X, Y, Df, Xq, Yq, 'makima');                       % numel(inr) x numel(Lq)
    imagesc(ax, inr, Lq, Dq'); set(ax, 'YDir', 'normal', 'Color', 'w', 'FontSize', fs, 'LineWidth', 0.6, 'TickDir', 'out', 'TickLength', [0.02 0.02], 'Box', 'off', 'Layer', 'top');
    set(ax, 'CLim', clim); colormap(ax, cm); hold(ax, 'on');
    lev = clim(1)-20:2:clim(2)+20; lev(lev == 0) = [];
    contour(ax, inr, Lq, Dq', lev, 'Color', [0.25 0.25 0.25], 'LineWidth', 0.5);
    contour(ax, inr, Lq, Dq', [0 0], 'Color', 'k', 'LineWidth', 1.1);
    ticks = [250 500 1000 2000 4000 8000]; xticks(ax, interp1(fI, 1:nx, ticks)); xlim(ax, [1 nx]); ylim(ax, [0 100]); yticks(ax, 0:20:100);
    xticklabels(ax, {'0.25','0.5','1','2','4','8'}); xtickangle(ax, 0);
    plot(ax, [1 nx nx], [100 100 0], 'k-', 'LineWidth', 0.6, 'Clipping', 'off');
    i6 = interp1(fI, 1:nx, 6000); plot(ax, [1 i6 i6], [30 30 100], 'k--', 'LineWidth', 0.9);   % reliable region: its left and top sides are the frame
    text(ax, 0, 1.035, ttl, 'Units', 'normalized', 'FontSize', fs, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
    if ylab, ylabel(ax, 'Level (dB SPL)', 'FontSize', fs); else, yticklabels(ax, {}); end
    xlabel(ax, 'Center frequency (kHz)', 'FontSize', fs);
end

function cm = divmap(clim)
% Diverging blue-white-red map with white exactly at 0 for an asymmetric clim (as on the ARO 2027 poster).
    n = 256; v = linspace(clim(1), clim(2), n)'; blue = [0.13 0.40 0.67]; red = [0.70 0.09 0.17]; w = [1 1 1];
    cm = zeros(n,3); neg = v < 0; pos = ~neg;
    cm(neg,:) = w + (blue - w) .* (v(neg)/clim(1));
    cm(pos,:) = w + (red - w) .* (v(pos)/clim(2));
end
