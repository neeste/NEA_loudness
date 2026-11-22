function nea_poster_heatmaps_letter()
% NEA_POSTER_HEATMAPS_LETTER  Poster Figure 5 (ARO 2027) for the published model (2026-11-22): the peak-term off/on
% comparison of nea_poster_heatmaps.m, with the model maps read from nea_letter_maps.mat (letter_score.m; the model of
% the JASA-EL letter with the gtfb filterbank) in place of the committed model's. Same layout, lettering (26 pt) and
% diverging map; the data column and Figure 1 (data_heatmaps.png) are unchanged. Writes poster/fig/winh_onoff.png.
% Run from this folder: nea_poster_heatmaps_letter
    out = fullfile('poster', 'fig'); fs = 26; lw = 1.4; M = load('nea_letter_maps.mat'); Tt = load('nea_cls_targets.mat'); clim = [-8 12];
    n = 256; v = linspace(clim(1), clim(2), n)'; blue = [0.13 0.40 0.67]; red = [0.70 0.09 0.17]; w = [1 1 1]; cm = zeros(n,3); neg = v < 0;
    cm(neg,:) = w + (blue - w).*(v(neg)/clim(1)); cm(~neg,:) = w + (red - w).*(v(~neg)/clim(2));
    P = {Tt.ddb2, M.DQoff, M.DQon; Tt.ddb5, M.D1off, M.D1on}; Lx = {Tt.spl, M.Lf, M.Lf}; F = M.F;
    figure('Color','w','Position',[60 60 1500 1000]); tl = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
    ct = {'DATA (CLS)', 'MODEL, peak term off', sprintf('MODEL, fitted (w = %.2f)', M.winh)}; rt = {'1/4-octave','1-octave'};
    for r = 1:2, for c = 1:3
        nexttile; o = struct('xlab', r==2, 'ylab', false, 'fs', fs, 'clim', clim, 'cmap', cm, 'lw', lw);
        if c == 1, o.ylab = sprintf('%s\nLevel (dB SPL)', rt{r}); end
        ttl = ''; if r == 1, ttl = ct{c}; end
        nea_heatpanel(P{r,c}, Lx{c}, F, ttl, o);
    end, end
    cb = colorbar; cb.Layout.Tile = 'east'; cb.Label.String = 'Influence of bandwidth (dB)'; cb.FontSize = fs - 2;
    set(findall(gcf,'Type','axestoolbar'),'Visible','off');
    tmp = [tempname '.png']; exportgraphics(gcf, tmp, 'Resolution', 200); copyfile(tmp, fullfile(out,'winh_onoff.png'), 'f'); delete(tmp);
    fprintf('saved %s\n', fullfile(out,'winh_onoff.png'));
end
