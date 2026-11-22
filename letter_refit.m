function varargout = letter_refit(mode, varargin)
% LETTER_REFIT  The neural-ensemble averaging (NEA) model of loudness, and its staged fit.
% Periphery: 60 complex fourth-order gammatone filters (gtfb.m; recursive filters after Harma 1999, one ERB of Glasberg and
% Moore wide, unit gain at the center frequency) on an ERB-rate scale from 100 Hz to 10 kHz. The envelope of a channel is the
% magnitude of the filter output over sqrt(2) times the sensitivity gain G, so that for a tone at the center frequency with
% G = 1 the envelope level is the level of the tone in dB SPL. Then a quadratic compression of the envelope level (Neely and
% Jesteadt 2005), a rate function, and the sum over the samples of the stimulus, which is the score of the channel.
% Read-out: L = LE (LI/LE)^w with LE the sum of the scores, LI = (sum of s^q)^(1/q), and w = w0 exp(-((L-L0)/Lw)^2).
% The fit is staged (function fitall): at 1 kHz the rate function is fitted to the tone and the read-out (w0, L0, Lw) to the
% three stimuli, with the exponent q held at 13.88; then the gain and the compression coefficients at each anchor frequency
% to tone growth; then w0 and the gains at 3 to 8 kHz to tone growth and the influence of bandwidth at 1, 2, 4 and 6 kHz.
% Parameters are written to nea_letter_params.mat; the starting values are in nea_start_params.mat.
%
%   letter_refit('fit')     the staged fit; writes nea_letter_params.mat (and a copy after each stage)
%   K = letter_refit('setup', stride)          cache of unit envelopes for the 30 standard stimuli
%   s = letter_refit('scores', K, env0, Lv, P) channel scores (numel(Lv) x 60) for one cached stimulus at levels Lv
%   env0 = letter_refit('env', K, w)           unit envelope (60 x N/stride) of a waveform w of unit RMS
%   v = letter_refit('readout', s, Lv, P)      read-out (1 x numel(Lv)) from channel scores
%
% Because the filters are linear and the magnitude is homogeneous, the envelope of a stimulus at any level
% and gain is the unit envelope times G times the pressure amplitude, so the periphery is computed once per stimulus.
% During the fit the sum over time uses every fourth sample (times four); scoring uses every sample.
% Run from this folder: letter_refit('fit')   (see README.md)
    switch mode
        case 'fit', fitall();
        case 'report', K = setup(4); for i = 1:numel(varargin), fprintf('%s\n', varargin{i}); report(load(varargin{i}), K, load('nea_cls_targets.mat')); end
        case 'setup', varargout{1} = setup(varargin{:});
        case 'scores', varargout{1} = scores(varargin{:});
        case 'env', varargout{1} = unitenv(varargin{:});
        case 'readout', varargout{1} = readout(varargin{:});
        case 'match', varargout{1} = ml(varargin{:});
        otherwise, error('unknown mode');
    end
end

% ====================================================================== engine
function K = setup(stride, freqs)
    if nargin < 1 || isempty(stride), stride = 1; end
    K.fs = 32000; K.t = 0:1/K.fs:0.3-1/K.fs; K.stride = stride; fn = K.fs/2;
    e1 = 21.4*log10(4.37*0.1+1); e2 = 21.4*log10(4.37*10.0+1); K.cfs = (10.^(linspace(e1,e2,60)/21.4)-1)/4.37*1000;
    K.erb = 24.7*(4.37*K.cfs/1000 + 1); K.fa = [250 500 750 1000 1500 2000 3000 4000 6000 8000];
    K.Hcf = zeros(1, 60);        % gain of gammatone.m at its passband, which is at -cf (pole at exp(-i pi cf))
    for k = 1:60, [b, a] = gammatone(K.cfs(k)/fn, K.erb(k)/fn); z = exp(+1i*pi*K.cfs(k)/fn).^(0:4); K.Hcf(k) = abs(sum(b.*z)/sum(a.*z)); end
    if nargin < 2, freqs = K.fa; end
    K.F = freqs; K.T = cell(1, numel(freqs)); K.Q = K.T; K.O = K.T;
    for k = 1:numel(freqs)
        f = freqs(k);
        K.T{k} = unitenv(K, nea_gen_tone(K.t, f, 1));
        K.Q{k} = unitenv(K, nea_gen_5tc(K.t, f, f*(2^(1/8)-2^(-1/8)), 1));
        K.O{k} = unitenv(K, nea_gen_5tc(K.t, f, f*(2^(1/2)-2^(-1/2)), 1));
    end
end

function env0 = unitenv(K, w)
% Envelope per channel for a waveform of unit RMS (1 Pa), before the gain: the magnitude of the complex output of the
% filterbank, divided by sqrt(2), so that for a tone at the center frequency the envelope equals the RMS pressure and
% the envelope level equals the level of the tone in dB SPL (2026-11-22, the user's decision: "Switch to the magnitude
% envelope and refit"). There is no rectifier and no low-pass filter. The filter output is scaled to unit gain at the
% center frequency (K.Hcf).
    y = 2*gtfb(w(:), K.fs, K.cfs, K.erb).'./K.Hcf(:);
    env0 = abs(y)/sqrt(2); env0 = env0(:, 1:K.stride:end);
end

function [G, a, b, c] = chanpar(K, P)
    lf = log10(K.fa); lc = log10(K.cfs);
    G = 10.^interp1(lf, log10(P.G_anchors), lc, 'linear', 'extrap'); G = max(min(G,100), 0.01);
    a = interp1(lf, P.qc_a_anch, lc, 'linear', 'extrap'); b = interp1(lf, P.qc_b_anch, lc, 'linear', 'extrap'); c = interp1(lf, P.qc_c_anch, lc, 'linear', 'extrap');
end

function s = scores(K, env0, Lv, P)
% Channel scores, numel(Lv) x 60, for a cached unit envelope at the levels Lv (dB SPL).
    [G, a, b, c] = chanpar(K, P); amp = reshape(20e-6*10.^(Lv(:)'/20), 1, 1, []);
    L = 20*log10(max(env0.*(G(:).*amp), 1e-12)/20e-6); L(L > 150) = 150;
    a = a(:); b = b(:); c = c(:); q = sqrt(b.^2 - 4*a.*c); C = (2./q).*atanh(b./q);
    u = max(min((2*c.*L + b)./q, 0.9999), -0.9999); E = -(2./q).*atanh(u) + C; neg = L <= 0; En = L./a; E(neg) = En(neg);
    rate = ((10.^(E/10))/P.I0 + 1).^P.alpha_loud - 1;
    s = K.stride*squeeze(sum(rate, 2)).'; if numel(Lv) == 1, s = s(:).'; end
end

function v = readout(s, Lv, P)
% Read-out for channel scores s (numel(Lv) x 60) at stimulus levels Lv.
    LE = sum(s, 2); cm = max(s, [], 2); LI = cm.*(sum((s./max(cm,realmin)).^P.qpeak, 2)).^(1/P.qpeak);
    wg = P.winh*exp(-((Lv(:) - P.Lq50)/P.Lqw).^2); v = (LE.*(LI./max(LE,eps)).^wg).';
end

function Lp = ml(v, gp, Lg)
% Level of the tone with read-out v, from the monotone tone growth gp on the grid Lg.
    Lp = zeros(size(v));
    for i = 1:numel(v)
        if v(i) <= gp(1), Lp(i) = Lg(1) + (v(i)-gp(1))*(Lg(2)-Lg(1))/max(gp(2)-gp(1),eps);
        elseif v(i) >= gp(end), Lp(i) = Lg(end) + (v(i)-gp(end))*(Lg(end)-Lg(end-1))/max(gp(end)-gp(end-1),eps);
        else, Lp(i) = interp1(gp, Lg, v(i), 'pchip'); end
    end
end

% ====================================================================== the staged fit
function fitall()
    Pc = load('nea_start_params.mat'); Tt = load('nea_cls_targets.mat'); K = setup(4); fa = K.fa;   % starting values: the parameters of the earlier version of the model
    P = struct('I0', Pc.I0, 'alpha_loud', Pc.alpha_loud, 'qpeak', Pc.qpeak, 'winh', Pc.winh, 'Lq50', Pc.Lq50, 'Lqw', Pc.Lqw, ...
               'G_anchors', Pc.G_anchors, 'qc_a_anch', Pc.qc_a_anch, 'qc_b_anch', Pc.qc_b_anch, 'qc_c_anch', Pc.qc_c_anch, 'global_scalar', Pc.global_scalar);
    fprintf('start (starting values):\n'); report(P, K, Tt);
    opt = @(n) optimset('Display', 'off', 'MaxFunEvals', n, 'MaxIter', n, 'TolX', 1e-3, 'TolFun', 1e-4);
    % ---- stages 1 and 2 at 1 kHz, twice over so that each is fitted with the other's result:
    %      1: rate function (alpha, I0) to tone growth; 2: read-out (w0, L0, Lw) to growth and influence of bandwidth of the
    %      three stimuli. The exponent q is held at its committed value: the cost is flat above q of about 10 (0.1074 at 14,
    %      0.1052 at 1000; letter_refit_diag.m), and a free q ran away to 1e7 in a first attempt. With alpha and I0 free in
    %      stage 2, as in nea_fit.m, the fit moves to another regime (I0 near 0.15, gate width over 100 dB) that fits growth at
    %      1 kHz better and the influence of bandwidth worse; the rate function is therefore taken from the tone alone.
    for pass = 1:4
        tic; x = fminsearch(@(x) cost12(up1(P,x), K, Tt, 1), [P.alpha_loud log10(P.I0)], opt(300)); P = up1(P, x); [c, d] = cost12(P, K, Tt, 1);
        fprintf('\nstage 1, pass %d (%.0f s): alpha %.4f, I0 %.4g | cost %.4f, tone growth %.1f%%\n', pass, toc, P.alpha_loud, P.I0, c, 100*(10^d.g-1));
        tic; x = fminsearch(@(x) cost12(up2(P,x), K, Tt, 2), [P.winh P.Lq50 P.Lqw], opt(500)); P = up2(P, x); [c, d] = cost12(P, K, Tt, 2); P.global_scalar = d.scal;
        fprintf('stage 2, pass %d (%.0f s): w0 %.3f, L0 %.2f, Lw %.2f (q held at %.2f) | cost %.4f, growth %.1f%%, influence %.2f dB\n', pass, toc, P.winh, P.Lq50, P.Lqw, P.qpeak, c, 100*(10^d.g-1), d.d);
    end
    save('nea_letter_params_stage2.mat', '-struct', 'P');
    fprintf('after stage 2:\n'); report(P, K, Tt);
    % ---- stage 4: gain at each anchor but 1 kHz to tone growth, constant pinned by 1 kHz
    tic; L = 20:10:100;
    for k = [1:3 5:10]
        lg = fminbnd(@(lg) gcost(setG(P,k,lg), K, Tt, k, L), log10(0.05), log10(8), optimset('TolX', 2e-3)); P = setG(P, k, lg);
    end
    fprintf('stage 4 (%.0f s): G anchors', toc); fprintf(' %.3f', P.G_anchors); fprintf('\n');
    % ---- stage 5: compression coefficients at each anchor to tone growth (scales of the default, regularized)
    tic; abc0 = [0.82507 0.01493 -0.00001634]; REG = 0.008; L = 30:10:100; A = zeros(10,3);
    for k = 1:10
        x0 = [P.qc_a_anch(k) P.qc_b_anch(k) P.qc_c_anch(k)]./abc0;
        xb = fminsearch(@(x) qcost(x, abc0, P, K, Tt, k, L, REG), x0, opt(400)); A(k,:) = abc0.*xb;
    end
    P.qc_a_anch = A(:,1)'; P.qc_b_anch = A(:,2)'; P.qc_c_anch = A(:,3)';
    fprintf('stage 5 (%.0f s): scales a', toc); fprintf(' %.2f', P.qc_a_anch/abc0(1)); fprintf(' | b'); fprintf(' %.2f', P.qc_b_anch/abc0(2)); fprintf(' | c'); fprintf(' %.2f', P.qc_c_anch/abc0(3)); fprintf('\n');
    save('nea_letter_params_stage5.mat', '-struct', 'P');
    fprintf('after stage 5:\n'); report(P, K, Tt);
    % ---- stage 6: weight and the gains at 3, 4, 6, 8 kHz to tone growth and influence of bandwidth (both bands) at 1, 2, 4, 6 kHz
    % Three starts for the gains (the result of stage 4, the committed values, and the defaults of nea_fit_stage4.m); the
    % start with the lowest value of this stage's own cost is kept. The simplex is restarted once from each result.
    tic; gi = 7:10; Gdef = [1.7061 1.6430 1.0702 0.6947]; starts = {P.G_anchors(gi), Pc.G_anchors(gi), Gdef}; best = Inf;
    for i = 1:numel(starts)
        x = fminsearch(@(x) fdcost(up6(P,x,gi), K, Tt), [P.winh log10(starts{i})], opt(600)); x = fminsearch(@(x) fdcost(up6(P,x,gi), K, Tt), x, opt(600));
        [c, d] = fdcost(up6(P,x,gi), K, Tt); fprintf('stage 6, start %d: w0 %.3f, G(3k) %.3f, G(4k) %.3f, G(6k) %.3f, G(8k) %.3f | cost %.4f, growth %.1f%%, influence %.2f dB\n', i, max(0,x(1)), 10.^x(2:end), c, 100*(10^d.g-1), d.d);
        if c < best, best = c; xb = x; end
    end
    P = up6(P, xb, gi); fprintf('stage 6 (%.0f s): kept the start with cost %.4f\n', toc, best);
    % ---- loudness constant over 250 Hz to 6 kHz, three stimuli, 30 to 100 dB
    P.global_scalar = fitconst(P, K, Tt);
    P.note = 'letter model, gtfb filterbank, fitted 2026-11-22 by letter_refit.m'; P.fa = fa;
    save('nea_letter_params.mat', '-struct', 'P');
    fprintf('\nresult:\n'); report(P, K, Tt);
    fprintf('saved nea_letter_params.mat\n');
end

function P = up1(P, x), P.alpha_loud = x(1); P.I0 = 10^x(2); end
function P = up2(P, x), P.winh = max(0, x(1)); P.Lq50 = x(2); P.Lqw = max(5, x(3)); end
function P = up6(P, x, gi), P.winh = max(0, x(1)); P.G_anchors(gi) = 10.^x(2:end); end
function P = setG(P, k, lg), P.G_anchors(k) = 10^lg; end

function [c, det] = cost12(P, K, Tt, stage)
% Cost of nea_fit.m at 1 kHz: growth in log10 sones (constant free), influence of bandwidth / 30, monotonicity penalty.
    k = 4; L = 20:10:100; ix = L+1; Lg = -20:5:110;
    gp = readout(scores(K, K.T{k}, Lg, P), Lg, P);
    if any(gp <= 0) || any(~isfinite(gp)), c = 1e3; det = struct('scal',1,'g',1e3,'d',1e3); return; end
    mp = interp1(Lg, gp, L); gpm = cummax(gp) + linspace(0, 1e-9, numel(gp));
    tp = Tt.sones1(k, ix); scal = 10^mean(log10(tp) - log10(mp)); res = log10(scal*mp) - log10(tp);
    mono = sum(max(0, -diff(gp)))/max(mean(gp), eps); rd = [];
    if stage >= 2
        mq = readout(scores(K, K.Q{k}, L, P), L, P); m1 = readout(scores(K, K.O{k}, L, P), L, P);
        dq = ml(mq, gpm, Lg) - L; d1 = ml(m1, gpm, Lg) - L;
        res = [res, log10(scal*mq) - log10(Tt.sones2(k,ix)), log10(scal*m1) - log10(Tt.sones5(k,ix))];
        mono = mono + sum(max(0, -diff(mq)))/max(mean(mq), eps) + sum(max(0, -diff(m1)))/max(mean(m1), eps);
        tq = Tt.ddb2(k, ix); t1 = Tt.ddb5(k, ix); ok = L >= 30 & isfinite(tq); rq = dq - tq; ro = d1 - t1; rd = [rq(ok), ro(ok)];
    end
    g = sqrt(mean(res.^2)); d = 0; if ~isempty(rd), d = sqrt(mean(rd.^2)); end
    c = g + d/30 + 5*mono; det = struct('scal', scal, 'g', g, 'd', d);
end

function r = gcost(P, K, Tt, k, L)
    m = P.global_scalar*readout(scores(K, K.T{k}, L, P), L, P);
    if any(m <= 0) || any(~isfinite(m)), r = 10; return; end
    r = sqrt(mean((log10(m) - log10(Tt.sones1(k, L+1))).^2));
end

function e = qcost(x, abc0, P, K, Tt, k, L, reg)
% As nea_fit_qc.m: for the tone at anchor k, the same coefficients in every channel, regularized toward the default.
    P.qc_a_anch = repmat(abc0(1)*x(1), 1, 10); P.qc_b_anch = repmat(abc0(2)*x(2), 1, 10); P.qc_c_anch = repmat(abc0(3)*x(3), 1, 10);
    if any(x <= 0) || (abc0(2)*x(2))^2 - 4*abc0(1)*x(1)*abc0(3)*x(3) <= 0, e = 10; return; end
    m = P.global_scalar*readout(scores(K, K.T{k}, L, P), L, P);
    if any(m <= 0) || any(~isfinite(m)), e = 10; return; end
    e = sqrt(mean((log10(m) - log10(Tt.sones1(k, L+1))).^2)) + reg*sqrt(sum(log(x).^2));
end

function [c, det] = fdcost(P, K, Tt)
% As nea_fit_freqdelta.m: tone growth (shape, constant free at each frequency) and the influence of bandwidth for the
% quarter-octave and the one-octave band at 1, 2, 4 and 6 kHz, 30 to 100 dB.
    Lg = 0:10:110; L = 30:10:100; ix = L+1; gres = []; dres = [];
    for k = [4 6 8 9]
        gp = readout(scores(K, K.T{k}, Lg, P), Lg, P);
        if any(gp <= 0) || any(~isfinite(gp)), c = 1e3; det = struct('g',1e3,'d',1e3); return; end
        gpm = cummax(gp) + linspace(0, 1e-9, numel(gp)); mp = interp1(Lg, gp, L);
        dq = ml(readout(scores(K, K.Q{k}, L, P), L, P), gpm, Lg) - L; d1 = ml(readout(scores(K, K.O{k}, L, P), L, P), gpm, Lg) - L;
        tq = Tt.ddb2(k, ix); t1 = Tt.ddb5(k, ix); dres = [dres, dq(isfinite(tq)) - tq(isfinite(tq)), d1(isfinite(t1)) - t1(isfinite(t1))]; %#ok<AGROW>
        sc = 10^mean(log10(Tt.sones1(k,ix)) - log10(mp)); gres = [gres, log10(sc*mp) - log10(Tt.sones1(k,ix))]; %#ok<AGROW>
    end
    g = sqrt(mean(gres.^2)); d = sqrt(mean(dres.^2)); c = g + d/30; det = struct('g', g, 'd', d);
end

function sfit = fitconst(P, K, Tt)
    L = 30:10:100; R = [];
    for k = 1:9
        R = [R, readout(scores(K,K.T{k},L,P),L,P)./Tt.sones1(k,L+1), readout(scores(K,K.Q{k},L,P),L,P)./Tt.sones2(k,L+1), readout(scores(K,K.O{k},L,P),L,P)./Tt.sones5(k,L+1)]; %#ok<AGROW>
    end
    ok = isfinite(R); sfit = sum(R(ok))/sum(R(ok).^2);
end

function report(P, K, Tt)
    Bt = load('nea_targets_10dB.mat'); F = K.fa; Lv = 0:10:100; Lg = 0:5:110; Fm = F <= 6000; Lm = Lv >= 30 & Lv <= 100;
    for wv = [P.winh 0]
        Q = P; Q.winh = wv; D1 = nan(10, numel(Lv)); DQ = D1;
        for k = 1:10
            gp = readout(scores(K, K.T{k}, Lg, Q), Lg, Q); gp = cummax(gp); gp = gp + linspace(0, 1e-9*max(gp), numel(gp));
            D1(k,:) = ml(readout(scores(K, K.O{k}, Lv, Q), Lv, Q), gp, Lg) - Lv; DQ(k,:) = ml(readout(scores(K, K.Q{k}, Lv, Q), Lv, Q), gp, Lg) - Lv;
        end
        a = D1(Fm,Lm); c = Bt.t1(Fm,Lm); m = isfinite(a) & isfinite(c); r1 = corr(a(m), c(m)); e1 = sqrt(mean((a(m)-c(m)).^2));
        a = DQ(Fm,Lm); c = Bt.tq(Fm,Lm); m = isfinite(a) & isfinite(c); rq = corr(a(m), c(m)); eq = sqrt(mean((a(m)-c(m)).^2));
        fprintf('  w0 %.3f: one octave r %.3f RMSE %.2f dB | quarter octave r %.3f RMSE %.2f dB | 1 kHz 60 dB: %+.2f, %+.2f | 6 kHz 70 dB: %+.2f\n', wv, r1, e1, rq, eq, D1(4,Lv==60), DQ(4,Lv==60), D1(9,Lv==70));
    end
    sfit = fitconst(P, K, Tt); L = 30:10:100; fprintf('  loudness error (%%), constant %.3g, by frequency 250 Hz to 6 kHz:\n', sfit);
    nm = {'tone', 'quarter', 'octave'}; C = {K.T, K.Q, K.O}; S = {Tt.sones1, Tt.sones2, Tt.sones5};
    for j = 1:3, fprintf('   %-8s', nm{j}); for k = 1:9, fprintf(' %4.0f', 100*sqrt(mean((sfit*readout(scores(K,C{j}{k},L,P),L,P)./S{j}(k,L+1) - 1).^2))); end, fprintf('\n'); end
    fprintf('  alpha %.4f I0 %.4g q %.3f w0 %.4f L0 %.2f Lw %.2f | G', P.alpha_loud, P.I0, P.qpeak, P.winh, P.Lq50, P.Lqw); fprintf(' %.3f', P.G_anchors); fprintf('\n');
end
