function nea_heatpanel(D, L, F, ttl, opts)
% NEA_HEATPANEL  One influence-of-bandwidth heatmap panel in the house style (2026-09-28).
% D is numel(F) x numel(L) (dB at fixed loudness) on any level grid; it is interpolated onto
% 100 log-spaced frequencies and 1-dB levels with 'makima' (shape-preserving), so maps that
% exist on a 5- or 10-dB grid do not look blocky. Drawn with imagesc plus 2-dB contours, the
% dashed reliable region (30-100 dB, CF <= 6 kHz) and 14-pt lettering. Rows of D with no
% finite value (e.g. 8 kHz where no trials exist) are left blank.
% opts fields (all optional): clim [-8 10], cstep 2, fs 14, region true, xlab true,
% ylab true (or a string to use as the label), ticks [250 500 1000 2000 4000 8000], cmap jet, lw 1 (contour width).
    if nargin < 5 || isempty(opts), opts = struct(); end
    def = struct('clim',[-8 10],'cstep',2,'fs',14,'region',true,'xlab',true,'ylab',true,'ticks',[250 500 1000 2000 4000 8000],'cmap',jet,'lw',1);
    fn = fieldnames(def); for i = 1:numel(fn), if ~isfield(opts,fn{i}), opts.(fn{i}) = def.(fn{i}); end, end
    F = double(F(:)'); L = double(L(:)'); Lq = 0:100; fI = logspace(log10(250), log10(8000), 100);
    rows = any(isfinite(D), 2); Df = fillmissing(D(rows,:), 'nearest', 2);
    [X,Y] = meshgrid(L, F(rows)); [Xq,Yq] = meshgrid(Lq, fI); inr = fI >= min(F(rows)) & fI <= max(F(rows));
    Dq = nan(100, numel(Lq)); Dq(inr,:) = interp2(X, Y, Df, Xq(inr,:), Yq(inr,:), 'makima');
    imagesc(1:100, Lq, Dq', 'AlphaData', isfinite(Dq')); set(gca, 'YDir','normal', 'Color','w', 'FontSize',opts.fs, 'LineWidth',1);
    caxis(opts.clim); colormap(gca, opts.cmap); hold on;        % opts.cmap (default jet; the ARO 2027 poster passes a diverging map)
    contour(1:100, Lq, Dq', 'k', 'LevelStep', opts.cstep, 'LineWidth', opts.lw);
    ti = interp1(fI, 1:100, opts.ticks); xticks(ti); xlim([1 100]); ylim([0 100]);
    lab = strings(size(opts.ticks));                        % short labels (1k, 2k ...) so six ticks fit a narrow panel unrotated
    for i = 1:numel(opts.ticks), f = opts.ticks(i); if f >= 1000, lab(i) = sprintf('%gk', f/1000); else, lab(i) = sprintf('%g', f); end, end
    xticklabels(lab); xtickangle(0);
    if opts.region, i6 = interp1(fI, 1:100, 6000); plot([1 i6 i6], [30 30 100], 'k--', 'LineWidth', 1.3); plot([1 i6], [100 100], 'k--', 'LineWidth', 1.3); end
    if ~isempty(ttl), title(ttl, 'FontSize', opts.fs, 'FontWeight', 'normal'); end
    if ischar(opts.ylab) || isstring(opts.ylab), ylabel(opts.ylab, 'FontSize', opts.fs); elseif opts.ylab, ylabel('Level (dB SPL)', 'FontSize', opts.fs); end
    if opts.xlab, xlabel('Center frequency (Hz)', 'FontSize', opts.fs); end
end
