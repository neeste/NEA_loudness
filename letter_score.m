function letter_score()
% LETTER_SCORE  Scores, statistical tests and figure data for the letter's model (gtfb filterbank, nea_letter_params.mat,
% fitted by letter_refit.m). 2026-11-22. Every sample of the stimulus is used (stride 1). The loudness constant is
% refitted here at stride 1 and written back to nea_letter_params.mat (the fit used every fourth sample).
% Writes: nea_letter_maps.mat (maps on a 5-dB grid, for letter_maps('draw')), nea_letter_scoremaps.mat (maps on the 10-dB
% grid and for a grid of weights, for letter_bootstrap.m), nea_letter_growth.json, nea_letter_fig2.json,
% nea_letter_fig2a.json, nea_letter_fig4b.json, nea_letter_numbers.json. Console output is the log.
% Run from this folder: letter_score   (see README.md)
    P = load('nea_letter_params.mat'); Tt = load('nea_cls_targets.mat'); Bt = load('nea_targets_10dB.mat');
    K = letter_refit('setup', 1); F = K.fa; nF = 10; Lg = 0:5:110; Lv = 0:10:100; Lf = 0:5:100; Fm = F <= 6000; Lm = Lv >= 30 & Lv <= 100;
    CT = cell(nF,1); C1 = CT; CQ = CT;                       % channel scores: tone on Lg, bands on Lf (5-dB grid)
    for k = 1:nF, CT{k} = sc(K, K.T{k}, Lg, P); C1{k} = sc(K, K.O{k}, Lf, P); CQ{k} = sc(K, K.Q{k}, Lf, P); end
    i10 = ismember(Lf, Lv); N = struct();
    % ---------------------------------------------------------------- loudness constant at stride 1
    L = 30:10:100; iL = ismember(Lf, L); R = [];
    for k = 1:9
        R = [R, rd(CT{k}(ismember(Lg,L),:), L, P)./Tt.sones1(k,L+1), rd(CQ{k}(iL,:), L, P)./Tt.sones2(k,L+1), rd(C1{k}(iL,:), L, P)./Tt.sones5(k,L+1)]; %#ok<AGROW>
    end
    ok = isfinite(R); sfit = sum(R(ok))/sum(R(ok).^2); fprintf('loudness constant: %.4g at stride 1 (%.4g from the fit at stride 4)\n', sfit, P.global_scalar);
    P.global_scalar = sfit; save('nea_letter_params.mat', '-struct', 'P'); N.constant = sfit;
    % ---------------------------------------------------------------- parameters
    fprintf('\nparameters: alpha %.4f, I0 %.4g, q %.2f, w0 %.4f, L0 %.2f, Lw %.2f, constant %.4g\n', P.alpha_loud, P.I0, P.qpeak, P.winh, P.Lq50, P.Lqw, sfit);
    fprintf('anchor (Hz)       G        a        b      c*1e5\n'); for k = 1:10, fprintf('%8d   %7.3f  %7.3f  %7.4f  %7.2f\n', F(k), P.G_anchors(k), P.qc_a_anch(k), P.qc_b_anch(k), 1e5*P.qc_c_anch(k)); end
    sl = @(Lx,k) 1./(P.qc_a_anch(k) + P.qc_b_anch(k)*Lx + P.qc_c_anch(k)*Lx.^2);
    fprintf('growth of excitation at 1 kHz: %.2f dB/dB at 20 dB, %.2f at 60 dB, %.2f at 100 dB\n', sl(20,4), sl(60,4), sl(100,4));
    g = @(Lx) P.winh*exp(-((Lx-P.Lq50)/P.Lqw).^2); fprintf('gate: %.2f at 0 dB, %.2f at 30, %.2f at 60, %.2f at 70, %.2f at 80, %.2f at 100 dB SPL; maximum %.2f at %.0f dB\n', g(0), g(30), g(60), g(70), g(80), g(100), P.winh, P.Lq50);
    N.par = rmfield(P, intersect(fieldnames(P), {'note'}));
    % ---------------------------------------------------------------- maps and scores
    [D1on, DQon] = deltas(P.winh, CT, C1, CQ, P, Lf, Lg); [D1off, DQoff] = deltas(0, CT, C1, CQ, P, Lf, Lg);
    F5 = F; Lf5 = Lf; winh = P.winh; dataQ = Tt.ddb2; data1 = Tt.ddb5; spl = Tt.spl; freqs = Tt.freqs;
    S5 = struct('F', F5, 'Lf', Lf5, 'D1off', D1off, 'DQoff', DQoff, 'D1on', D1on, 'DQon', DQon, 'winh', winh, 'dataQ', dataQ, 'data1', data1, 'spl', spl, 'freqs', freqs);
    save('nea_letter_maps.mat', '-struct', 'S5');
    D1 = D1on(:,i10); DQ = DQon(:,i10); O1 = D1off(:,i10); OQ = DQoff(:,i10); t1 = Bt.t1; tq = Bt.tq;
    fit = ismember(F, [1000 2000 4000 6000]); prd = Fm & ~fit;
    fprintf('\n%-34s %-22s %-22s\n', 'reliable region, 30 to 100 dB', 'one octave: r, RMSE', 'quarter octave: r, RMSE');
    lab = {'fitted read-out, all 9 freq.', Fm; 'fitted read-out, 4 fitted freq.', fit; 'fitted read-out, 5 other freq.', prd};
    for i = 1:3, [r1,e1,n1] = score(D1, t1, lab{i,2}, Lm); [rq,eq] = score(DQ, tq, lab{i,2}, Lm); fprintf('%-34s %6.3f %5.2f dB (n=%d)  %6.3f %5.2f dB\n', lab{i,1}, r1, e1, n1, rq, eq); N.(sprintf('score%d',i)) = [r1 e1 rq eq n1]; end
    [r1,e1] = score(O1, t1, Fm, Lm); [rq,eq] = score(OQ, tq, Fm, Lm); fprintf('%-34s %6.3f %5.2f dB         %6.3f %5.2f dB\n', 'broad sum only, all 9 freq.', r1, e1, rq, eq); N.sumonly = [r1 e1 rq eq];
    [r1,e1] = score(O1, t1, prd, Lm); fprintf('%-34s %6.3f %5.2f dB\n', 'broad sum only, 5 other freq.', r1, e1);
    fprintf('ranges over the whole map (5-dB grid): one octave sum only [%.1f, %.1f], fitted [%.1f, %.1f]; quarter octave sum only [%.1f, %.1f], fitted [%.1f, %.1f]\n', mm(D1off), mm(D1on), mm(DQoff), mm(DQon));
    fprintf('one octave at 1 kHz by level 0..100: model'); fprintf(' %+5.1f', D1(4,:)); fprintf('\n%43s', 'data'); fprintf(' %+5.1f', t1(4,:)); fprintf('\n%43s', 'sum only'); fprintf(' %+5.1f', O1(4,:));
    fprintf('\nquarter octave at 1 kHz:              model'); fprintf(' %+5.1f', DQ(4,:)); fprintf('\n%43s', 'data'); fprintf(' %+5.1f', tq(4,:));
    fprintf('\none octave at 60 dB by frequency:     model'); fprintf(' %+5.1f', D1(:,Lv==60)); fprintf('\n%43s', 'data'); fprintf(' %+5.1f', t1(:,Lv==60)); fprintf('\n');
    fprintf('6 kHz, one octave by level 30..100: model'); fprintf(' %+5.1f', D1(9,Lm)); fprintf(' | data'); fprintf(' %+5.1f', t1(9,Lm)); fprintf('\n');
    pos = false(size(t1)); pos(Fm,Lm) = t1(Fm,Lm) > 1; fprintf('cells of the reliable region with data above +1 dB (one octave): %d, model positive at %d\n', nnz(pos), nnz(pos & D1 > 0));
    Q = tq; Q(~Fm,:) = NaN; Q(:,~Lm) = NaN; [v, ix] = sort(Q(:)); fprintf('largest quarter-octave depressions in the data, model there:\n');
    for i = 1:8, [a, b] = ind2sub(size(Q), ix(i)); fprintf('   %5d Hz %3d dB: data %+.1f  model %+.1f\n', F(a), Lv(b), v(i), DQ(a,b)); end
    Dm = DQ; Dm(~Fm,:) = NaN; Dm(:,~Lm) = NaN; [mv, mi] = min(Dm(:)); [a, b] = ind2sub(size(Dm), mi); fprintf('   largest in the model: %+.1f dB at %d Hz, %d dB (data %+.1f)\n', mv, F(a), Lv(b), tq(a,b));
    % ---------------------------------------------------------------- tests on cells (as test_rigor.m)
    A = D1(Fm,Lm); B = t1(Fm,Lm); a = A(:); b = B(:); okc = isfinite(a) & isfinite(b); a = a(okc); b = b(okc); n = numel(a); r0 = corr(a,b);
    rng(1); nb = 4000; rb = zeros(nb,1); eb = rb; rp = rb;
    for i = 1:nb, ix = randi(n,n,1); rb(i) = corr(a(ix), b(ix)); eb(i) = sqrt(mean((a(ix)-b(ix)).^2)); rp(i) = corr(a, b(randperm(n))); end
    fprintf('\ncells (n = %d): bootstrap 95%% interval r [%.2f, %.2f], RMSE [%.2f, %.2f] dB; permutation 97.5th percentile of r %.2f, P(r_null >= %.2f) < %.4f\n', n, prc(rb,2.5), prc(rb,97.5), prc(eb,2.5), prc(eb,97.5), prc(rp,97.5), r0, max(mean(rp >= r0), 1/nb));
    N.cells = [prc(rb,2.5) prc(rb,97.5) prc(eb,2.5) prc(eb,97.5) prc(rp,97.5)];
    % ---------------------------------------------------------------- held-out center frequencies (refit w0 and L0 on the other eight)
    ws = 0.50:0.02:1.20; L50s = 50:5:100; Dg = cell(numel(ws), numel(L50s)); Pq = P;
    for i = 1:numel(ws), for j = 1:numel(L50s), Pq.Lq50 = L50s(j); d = deltas(ws(i), CT, C1, CQ, Pq, Lf, Lg); Dg{i,j} = d(:,i10); end, end
    fm = find(Fm); pred = nan(size(t1)); fitted = zeros(numel(fm), 2); lm = find(Lm);
    for k = 1:numel(fm)
        ho = fm(k); tr = setdiff(fm, ho); best = inf;
        for i = 1:numel(ws), for j = 1:numel(L50s), Ag = Dg{i,j}(tr,lm); Bg = t1(tr,lm); kk = isfinite(Ag(:)) & isfinite(Bg(:)); err = sqrt(mean((Ag(kk)-Bg(kk)).^2)); if err < best, best = err; bi = i; bj = j; end, end, end
        pred(ho,:) = Dg{bi,bj}(ho,:); fitted(k,:) = [ws(bi) L50s(bj)]; ph = pred(ho,lm); dh = t1(ho,lm); kk = isfinite(dh);
        fprintf('   hold out %5d Hz: w0 %.2f, L0 %3d | held-out RMSE %.2f dB\n', F(ho), ws(bi), L50s(bj), sqrt(mean((ph(kk)-dh(kk)).^2)));
    end
    [rh, eh] = score(pred, t1, Fm, Lm); fprintf('   pooled held-out: r %.3f, RMSE %.2f dB; w0 %.2f to %.2f, L0 %d to %d\n', rh, eh, min(fitted(:,1)), max(fitted(:,1)), min(fitted(:,2)), max(fitted(:,2)));
    N.heldout = [rh eh min(fitted(:,1)) max(fitted(:,1)) min(fitted(:,2)) max(fitted(:,2))];
    % maps for the listener bootstrap: fitted model and a grid of weights
    wsb = 0.50:0.02:1.20; D1s = nan(nF, numel(Lv), numel(wsb)); for i = 1:numel(wsb), d = deltas(wsb(i), CT, C1, CQ, P, Lf, Lg); D1s(:,:,i) = d(:,i10); end
    D1c = D1; DQc = DQ; ws_b = wsb; w0 = P.winh; save('nea_letter_scoremaps.mat', 'D1c', 'DQc', 'D1s', 'ws_b', 'w0');
    % ---------------------------------------------------------------- loudness growth
    Ls = 0:2:100; Kt = {K.T, K.Q, K.O}; nm = {'pure', 'q', 'oct'}; Sd = {Tt.sones1, Tt.sones2, Tt.sones5}; M = struct();
    for j = 1:3, G = zeros(nF, numel(Ls)); for k = 1:nF, G(k,:) = sfit*rd(sc(K, Kt{j}{k}, Ls, P), Ls, P); end, M.(nm{j}) = G; end
    J = struct('spl', Tt.spl, 'freqs', F, 'Ls', Ls, 'data', struct('pure', Tt.sones1, 'q', Tt.sones2, 'oct', Tt.sones5), 'model', M, 'constant', sfit, 'G', P.G_anchors);
    wj('nea_letter_growth.json', J);
    fprintf('\nloudness error (%% of the measured loudness), 30 to 100 dB in 10-dB steps, by frequency 250 Hz to 6 kHz\n'); E = zeros(3,9); LE = zeros(3,8); rmsL = zeros(1,3);
    for j = 1:3
        Rl = zeros(9,8);
        for k = 1:9
            m = interp1(Ls, M.(nm{j})(k,:), L); d = Sd{j}(k, L+1); E(j,k) = 100*sqrt(mean((m./d - 1).^2));
            Rl(k,:) = interp1(log(M.(nm{j})(k,:)), Ls, log(d)) - L;       % level at which the model reaches the measured loudness, minus the level
        end
        LE(j,:) = mean(Rl, 1); rmsL(j) = sqrt(mean(Rl(:).^2)); fprintf('   %-5s', nm{j}); fprintf(' %4.0f', E(j,:)); fprintf('\n');
    end
    fprintf('   range %.0f%% to %.0f%%; 1 kHz: %.0f%%, %.0f%%, %.0f%%\n', min(E(:)), max(E(:)), E(1,4), E(2,4), E(3,4));
    fprintf('level difference at fixed loudness (model level minus data level; negative = model too loud), mean over frequency, 30..100 dB\n');
    for j = 1:3, fprintf('   %-5s', nm{j}); fprintf(' %+5.1f', LE(j,:)); fprintf(' | RMS %.1f dB\n', rmsL(j)); end
    N.growth = E; N.levelerr = LE; N.levelrms = rmsL;
    % ---------------------------------------------------------------- the mechanism at 1 kHz (Figure 2, Table S6)
    f = 1000; oct = 2.^(-4:0.125:1); L0 = 60; Lx = 0:2.5:100; bw = @(o) f*(2^(o/2) - 2^(-o/2));
    Pp = P; Pp.winh = 1; Pp.Lqw = 1e9; Ps = P; Ps.winh = 0; V = {'committed', P; 'sum_only', Ps; 'peak_only', Pp}; R2 = struct();
    cT = CT{4}; cL = sc(K, K.O{4}, Lx, P); EB = cell(1, numel(oct)); cB = zeros(numel(oct), 60);
    for i = 1:numel(oct), EB{i} = letter_refit('env', K, nea_gen_5tc(K.t, f, bw(oct(i)), 1)); cB(i,:) = sc(K, EB{i}, L0, P); end
    o6 = [1/16 1/8 1/4 1/2 1 2]; i6 = arrayfun(@(o) find(abs(oct - o) < 1e-9), o6); T6 = struct();
    for v = 1:3
        Q = V{v,2}; gp = rd(cT, Lg, Q); gp = cummax(gp); gp = gp + linspace(0, 1e-9*max(gp), numel(gp));
        R2.(V{v,1}).level = letter_refit('match', rd(cL, Lx, Q), gp, Lg) - Lx;
        R2.(V{v,1}).bw = arrayfun(@(i) letter_refit('match', rd(cB(i,:), L0, Q), gp, Lg) - L0, 1:numel(oct));
        T = zeros(6, numel(Lv)); for i = 1:6, T(i,:) = letter_refit('match', rd(sc(K, EB{i6(i)}, Lv, P), Lv, Q), gp, Lg) - Lv; end, T6.(V{v,1}) = T;
    end
    i60 = find(Lx == 60); i1 = find(abs(oct-1) < 1e-9);
    fprintf('\n1 kHz, 60 dB, one octave: sum only %+.2f, peak only %+.2f, blend %+.2f dB (data %+.2f); quarter octave: blend %+.2f (data %+.2f)\n', R2.sum_only.level(i60), R2.peak_only.level(i60), R2.committed.level(i60), t1(4,Lv==60), R2.committed.bw(abs(oct-0.25)<1e-9), tq(4,Lv==60));
    fprintf('influence of bandwidth at 1 kHz (dB), rows 1/16 1/8 1/4 1/2 1 2 octaves, columns 30..100 dB\n   fitted read-out\n'); for i = 1:6, fprintf('   '); fprintf(' %+5.1f', T6.committed(i,Lm)); fprintf('\n'); end
    fprintf('   sum only\n'); for i = 1:6, fprintf('   '); fprintf(' %+5.1f', T6.sum_only(i,Lm)); fprintf('\n'); end
    J = struct('f', f, 'L0', L0, 'oct', oct, 'Lv', Lx, 'delta', R2, 'w', P.winh*exp(-((Lx-P.Lq50)/P.Lqw).^2), 'winh', P.winh, 'Lq50', P.Lq50, 'Lqw', P.Lqw, 'table', T6, 'table_oct', o6, 'table_Lv', Lv, ...
               'data', struct('Lv', Lv, 'quarter', tq(4,:), 'octave', t1(4,:)));
    wj('nea_letter_fig2.json', J); N.mech = [R2.sum_only.level(i60) R2.peak_only.level(i60) R2.committed.level(i60)]; N.table6 = T6;
    sT = sc(K, K.T{4}, 60, P); sQ = sc(K, K.Q{4}, 60, P); sO = sc(K, K.O{4}, 60, P); S3 = [sT; sQ; sO]; q = P.qpeak;
    LEs = sum(S3, 2)'; LIs = arrayfun(@(i) max(S3(i,:))*(sum((S3(i,:)/max(S3(i,:))).^q))^(1/q), 1:3);
    fprintf('channel scores at 60 dB: sum relative to the tone, quarter octave %.2f, one octave %.2f; peak-weighted average %.2f, %.2f; peak score %.2f, %.2f\n', LEs(2)/LEs(1), LEs(3)/LEs(1), LIs(2)/LIs(1), LIs(3)/LIs(1), max(sQ)/max(sT), max(sO)/max(sT));
    wj('nea_letter_fig2a.json', struct('f', f, 'level', 60, 'cfs', K.cfs, 'tone', sT, 'quarter', sQ, 'octave', sO, 'LE', LEs, 'LI', LIs));
    N.fig2a = [LEs(2)/LEs(1) LEs(3)/LEs(1) LIs(2)/LIs(1) LIs(3)/LIs(1)];
    % ---------------------------------------------------------------- the weight and a loudness match (Figure 4b)
    Lw4 = 30:5:100; wsx = [P.winh-0.25 P.winh P.winh+0.25]; km = [4 8]; Y = nan(3, 2, numel(Lw4)); i4 = ismember(Lf, Lw4);
    for i = 1:3, d = deltas(wsx(i), CT, C1, CQ, P, Lf, Lg); Y(i,:,:) = d(km, i4); end
    fprintf('\none-octave band against the tone for three weights (%.2f, %.2f, %.2f)\n', wsx);
    for j = 1:2
        fprintf('  %g Hz, levels %s\n', F(km(j)), mat2str(Lw4)); for i = 1:3, fprintf('   w0 %.2f', wsx(i)); fprintf(' %+5.1f', squeeze(Y(i,j,:))); fprintf('\n'); end
        fprintf('   per 0.1 of the weight'); fprintf(' %5.2f', squeeze(Y(3,j,:) - Y(1,j,:))/5); fprintf('\n');
    end
    wj('nea_letter_fig4b.json', struct('levels', Lw4, 'weights', wsx, 'freqs', F(km), 'delta', Y)); N.fig4b = Y; N.fig4b_levels = Lw4;
    wj('nea_letter_numbers.json', N); fprintf('\nsaved the maps, the JSON files and nea_letter_numbers.json\n');
end

function s = sc(K, env0, Lv, P)
% channel scores in chunks of levels, to bound memory at stride 1
    s = zeros(numel(Lv), 60); for i = 1:6:numel(Lv), j = i:min(i+5, numel(Lv)); s(j,:) = letter_refit('scores', K, env0, Lv(j), P); end
end
function v = rd(s, Lv, P), v = letter_refit('readout', s, Lv, P); end
function [D1, DQ] = deltas(w, CT, C1, CQ, P, Lf, Lg)
    Q = P; Q.winh = w; nF = numel(CT); D1 = nan(nF, numel(Lf)); DQ = D1;
    for k = 1:nF
        gp = rd(CT{k}, Lg, Q); gp = cummax(gp); gp = gp + linspace(0, 1e-9*max(gp), numel(gp));
        D1(k,:) = letter_refit('match', rd(C1{k}, Lf, Q), gp, Lg) - Lf; if nargout > 1, DQ(k,:) = letter_refit('match', rd(CQ{k}, Lf, Q), gp, Lg) - Lf; end
    end
end
function [r, e, n] = score(D, T, Fm, Lm)
    a = D(Fm,Lm); c = T(Fm,Lm); m = isfinite(a) & isfinite(c); a = a(m); c = c(m); r = corr(a(:), c(:)); e = sqrt(mean((a-c).^2)); n = numel(a);
end
function v = mm(X), v = [min(X(:)) max(X(:))]; end
function p = prc(x, q), x = sort(x(:)); p = x(max(1, min(numel(x), round(q/100*(numel(x)-1))+1))); end
function wj(fn, J), fid = fopen(fn, 'w'); fprintf(fid, '%s', jsonencode(J)); fclose(fid); end
