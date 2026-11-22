function nea_poster_heatmaps()
% NEA_POSTER_HEATMAPS  Poster Figure 1 (ARO 2027): the influence of bandwidth in the data, quarter-octave and one-octave
% bands, with 26-pt lettering and a diverging map (blue below 0, white at 0, red above). Writes poster/fig/data_heatmaps.png.
% Figure 5 (data and model) is drawn by nea_poster_heatmaps_letter.m. Run from this folder: nea_poster_heatmaps
    out = fullfile('poster', 'fig'); fs = 26; lw = 1.4;
    Tt = load('nea_cls_targets.mat'); clim = [-8 12]; cm = divmap(clim);
    % ---------- data-only maps ----------
    figure('Color','w','Position',[80 80 1300 640]);
    tl = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
    nexttile; nea_heatpanel(Tt.ddb2, Tt.spl, Tt.freqs, 'DATA: 1/4-octave', struct('clim',clim,'fs',fs,'cmap',cm,'lw',lw));
    nexttile; nea_heatpanel(Tt.ddb5, Tt.spl, Tt.freqs, 'DATA: 1-octave', struct('clim',clim,'ylab',false,'fs',fs,'cmap',cm,'lw',lw));
    cb = colorbar; cb.Layout.Tile = 'east'; cb.Label.String = 'Influence of bandwidth (dB)'; cb.FontSize = fs - 2;
    set(findall(gcf,'Type','axestoolbar'),'Visible','off');
    exportgraphics(gcf, fullfile(out,'data_heatmaps.png'), 'Resolution', 200);
    fprintf('saved %s\n', fullfile(out,'data_heatmaps.png'));
end
function cm = divmap(clim)
% Diverging blue-white-red map with white exactly at 0 for an asymmetric clim.
    n = 256; v = linspace(clim(1), clim(2), n)'; blue = [0.13 0.40 0.67]; red = [0.70 0.09 0.17]; w = [1 1 1];
    cm = zeros(n,3);
    neg = v < 0; pos = ~neg;
    cm(neg,:) = w + (blue - w) .* (v(neg)/clim(1));
    cm(pos,:) = w + (red - w) .* (v(pos)/clim(2));
end
