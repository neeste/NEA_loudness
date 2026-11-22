function letter_extras()
% LETTER_EXTRAS  Variants of the model for Section S6 of the supplement and for the Discussion of the letter.
%   1 lateral suppression in the periphery (fraction 0.35 of the neighbors, Gaussian width 10 channels), alone and with the read-out
%   2 weight gated by the model's own broad sum
%   3 constant weight (no gate), and the same with three fiber classes whose knees are spread by 10, 100 and 1000
%   4 noise bands (16 tokens of equal-amplitude components with random phases): fitted parameters, and w0 refitted
%   5 the loudness-matching data of Leibold et al. (2007) at 1 kHz and 60 dB: the weight that fits them
% Scores are for the one-octave map over the reliable region (30 to 100 dB, 6 kHz and below).
% Run from this folder: letter_extras   (see README.md)
    P = load('nea_letter_params.mat'); Bt = load('nea_targets_10dB.mat'); t1 = Bt.t1; tq = Bt.tq;
    K = letter_refit('setup', 2); F = K.fa; Lg = 0:5:110; Lv = 0:10:100; Fm = F <= 6000; Lm = Lv >= 30 & Lv <= 100; J = struct();
    fprintf('every second sample is used here (stride 2)\n');
    base = map(K, P, struct(), Lg, Lv); [r, e] = score(base.D1, t1, Fm, Lm); fprintf('%-58s r %+.2f  RMSE %.2f dB | 1 kHz 60 dB %+.1f\n', 'fitted read-out', r, e, base.D1(4,Lv==60)); J.base = [r e];
    Q = P; Q.winh = 0; m0 = map(K, Q, struct(), Lg, Lv); [r, e] = score(m0.D1, t1, Fm, Lm); fprintf('%-58s r %+.2f  RMSE %.2f dB | 1 kHz 60 dB %+.1f\n', 'broad sum alone', r, e, m0.D1(4,Lv==60)); J.sum = [r e m0.D1(4,Lv==60)];
    % ---- 1 suppression
    fprintf('\nsuppression, broad sum alone, one-octave band at 1 kHz and 60 dB, by fraction and width (channels):\n'); lo = Inf; hi = -Inf;
    for w = [0.10 0.20 0.35], for sg = [2 5 10]
        d = one(K, Q, struct('supp_w', w, 'supp_sig', sg), 4, Lg, 60); fprintf('   w %.2f sig %2d: %+.2f dB\n', w, sg, d); lo = min(lo, d); hi = max(hi, d);
    end, end
    o = struct('supp_w', 0.35, 'supp_sig', 10);
    m = map(K, Q, o, Lg, Lv); [r, e] = score(m.D1, t1, Fm, Lm); fprintf('%-58s r %+.2f  RMSE %.2f dB | 1 kHz 60 dB %+.1f\n', 'broad sum with suppression (0.35, 10)', r, e, m.D1(4,Lv==60)); J.supp_alone = [r e m.D1(4,Lv==60) lo hi];
    m = map(K, P, o, Lg, Lv); [r, e] = score(m.D1, t1, Fm, Lm); fprintf('%-58s r %+.2f  RMSE %.2f dB\n', 'fitted read-out with suppression added', r, e); J.supp_readout = [r e];
    % ---- 2 gate on the broad sum
    Ls = 0:5:100; LEs = sum(scx(K, K.T{4}, Ls, P, struct()), 2)'; p = polyfit(log10(LEs), Ls, 1); R2 = corr(polyval(p, log10(LEs))', Ls')^2;
    m = map(K, P, struct('gate', p), Lg, Lv); [r, e] = score(m.D1, t1, Fm, Lm); fprintf('\n%-58s r %+.2f  RMSE %.2f dB (level = %.2f log10(LE) %+.1f, R2 %.3f)\n', 'weight gated by the broad sum', r, e, p(1), p(2), R2); J.gateLE = [r e R2];
    % ---- 3 constant weight, fiber classes
    Qc = P; Qc.Lqw = 1e6; m = map(K, Qc, struct(), Lg, Lv); [r, e] = score(m.D1, t1, Fm, Lm);
    fprintf('\n%-58s r %+.2f  RMSE %.2f dB | 1 kHz by level 30..100:', 'constant weight, no gate', r, e); fprintf(' %+.1f', m.D1(4,Lm)); fprintf('\n'); J.const = [r e]; J.const_1k = m.D1(4,Lm);
    fprintf('%-58s %24s', 'fitted read-out, 1 kHz by level 30..100:', ''); fprintf(' %+.1f', base.D1(4,Lm)); fprintf('\n%-58s %24s', 'data', ''); fprintf(' %+.1f', t1(4,Lm)); fprintf('\n');
    J.sr = zeros(3,2); ss = [10 100 1000];
    for i = 1:3
        m = map(K, Qc, struct('srI0', P.I0*[1/ss(i) 1 ss(i)], 'srwt', [0.6 0.25 0.15]), Lg, Lv); [r, e] = score(m.D1, t1, Fm, Lm); J.sr(i,:) = [r e];
        fprintf('%-58s r %+.2f  RMSE %.2f dB | 1 kHz by level 30..100:', sprintf('constant weight, three fiber classes spread x%d', ss(i)), r, e); fprintf(' %+.1f', m.D1(4,Lm)); fprintf('\n');
    end
    % ---- 4 noise bands
    ntok = 16; CN = cell(10,1); CNq = CN; tic;
    for k = 1:10
        f = F(k); bw1 = f*(2^0.5-2^-0.5); bwq = f*(2^(1/8)-2^(-1/8)); CN{k} = zeros(ntok, numel(Lv), 60); CNq{k} = CN{k};
        for s = 1:ntok
            CN{k}(s,:,:) = scx(K, letter_refit('env', K, noise(K.t, f, bw1, s)), Lv, P, struct());
            if k == 4, CNq{k}(s,:,:) = scx(K, letter_refit('env', K, noise(K.t, f, bwq, s)), Lv, P, struct()); end
        end
    end
    fprintf('\nnoise: channel scores for %d tokens at 10 frequencies in %.0f s\n', ntok, toc);
    CTt = cell(10,1); C5 = CTt; for k = 1:10, CTt{k} = scx(K, K.T{k}, Lg, P, struct()); C5{k} = scx(K, K.O{k}, Lv, P, struct()); end
    ws = 0.50:0.02:1.20; rn = zeros(size(ws)); en = rn; r5 = rn; e5 = rn;
    for i = 1:numel(ws)
        Qw = P; Qw.winh = ws(i); [rn(i), en(i)] = score(nmap(CN, CTt, Qw, Lg, Lv), t1, Fm, Lm); [r5(i), e5(i)] = score(tmap(C5, CTt, Qw, Lg, Lv), t1, Fm, Lm);
    end
    Dn = nmap(CN, CTt, P, Lg, Lv); D5 = tmap(C5, CTt, P, Lg, Lv); [r, e] = score(Dn, t1, Fm, Lm); [~, in] = min(en); [~, i5] = min(e5);
    fprintf('%-58s r %+.2f  RMSE %.2f dB\n', 'noise bands, fitted parameters', r, e); fprintf('%-58s r %+.2f  RMSE %.2f dB\n', sprintf('noise bands, w0 refitted to %.2f', ws(in)), rn(in), en(in));
    fprintf('%-58s r %+.2f  RMSE %.2f dB\n', sprintf('five-tone complexes, w0 refitted to %.2f', ws(i5)), r5(i5), e5(i5));
    lv7 = ismember(Lv, 30:10:90); fprintf('one octave at 1 kHz, 30..90 dB: noise'); fprintf(' %+.2f', Dn(4,lv7)); fprintf(' | five-tone'); fprintf(' %+.2f', D5(4,lv7)); fprintf(' | difference'); fprintf(' %+.2f', Dn(4,lv7)-D5(4,lv7)); fprintf('\n');
    gp = mono(rd(CTt{4}, Lg, P)); dtok = arrayfun(@(s) letter_refit('match', rd(squeeze(CN{4}(s,Lv==60,:))', 60, P), gp, Lg) - 60, 1:ntok);
    dq5 = letter_refit('match', rd(scx(K, K.Q{4}, 60, P, struct()), 60, P), gp, Lg) - 60; dqn = letter_refit('match', mean(arrayfun(@(s) rd(squeeze(CNq{4}(s,Lv==60,:))', 60, P), 1:ntok)), gp, Lg) - 60;
    fprintf('tokens at 1 kHz and 60 dB: SD of the one-octave value over tokens %.2f dB; quarter octave: noise %+.2f, five-tone %+.2f dB\n', std(dtok), dqn, dq5);
    J.noise = [r e ws(in) rn(in) en(in) ws(i5) r5(i5) e5(i5) std(dtok)]; J.noise_diff = Dn(4,lv7) - D5(4,lv7);
    % ---- 5 loudness matching (Leibold et al., 2007): five-tone complexes at 1 kHz and 60 dB
    Lbw = [46 92 231 465 956 2119]; Ld = [56.071 55.257 57.829 60.326 63.529 66.850] - 60; cb = zeros(numel(Lbw), 60);
    for i = 1:numel(Lbw), cb(i,:) = scx(K, letter_refit('env', K, nea_gen_5tc(K.t, 1000, Lbw(i), 1)), 60, P, struct()); end
    wl = 0:0.02:1.20; el = zeros(size(wl)); dl = zeros(numel(wl), numel(Lbw));
    for i = 1:numel(wl), Qw = P; Qw.winh = wl(i); g = mono(rd(CTt{4}, Lg, Qw)); dl(i,:) = arrayfun(@(j) letter_refit('match', rd(cb(j,:), 60, Qw), g, Lg) - 60, 1:numel(Lbw)); el(i) = sqrt(mean((dl(i,:) - Ld).^2)); end
    [~, il] = min(el); [~, i0] = min(abs(wl - round(P.winh/0.02)*0.02));
    fprintf('\nLeibold et al. (2007), 1 kHz, 60 dB, bandwidths %s Hz\n   data          ', mat2str(Lbw)); fprintf(' %+5.1f', Ld);
    fprintf('\n   model, w0 %.2f', wl(i0)); fprintf(' %+5.1f', dl(i0,:)); fprintf('  (RMSE %.2f dB)\n   model, w0 %.2f', el(i0), wl(il)); fprintf(' %+5.1f', dl(il,:)); fprintf('  (RMSE %.2f dB, the best)\n', el(il));
    J.leibold = [wl(il) el(il) el(i0)];
    fid = fopen('nea_letter_extras.json', 'w'); fprintf(fid, '%s', jsonencode(J)); fclose(fid); fprintf('\nsaved nea_letter_extras.json\n');
end

function s = scx(K, env0, Lv, P, o)
% Channel scores as letter_refit('scores'), with the options of this script: lateral suppression of the envelope level
% (supp_w, supp_sig, as supp() of nea_bank_fast.m) and fiber classes (srI0, srwt, as sr_rate()).
    lf = log10(K.fa); lc = log10(K.cfs); G = 10.^interp1(lf, log10(P.G_anchors), lc, 'linear', 'extrap'); G = max(min(G,100), 0.01);
    a = interp1(lf, P.qc_a_anch, lc, 'linear', 'extrap')'; b = interp1(lf, P.qc_b_anch, lc, 'linear', 'extrap')'; c = interp1(lf, P.qc_c_anch, lc, 'linear', 'extrap')';
    q = sqrt(b.^2 - 4*a.*c); C = (2./q).*atanh(b./q); s = zeros(numel(Lv), 60);
    for i = 1:numel(Lv)
        L = 20*log10(max(env0.*(G(:)*20e-6*10^(Lv(i)/20)), 1e-12)/20e-6); L(L > 150) = 150;
        if isfield(o, 'supp_w')
            n = 60; kk = exp(-((-(n-1):(n-1))/o.supp_sig).^2); kk = kk/sum(kk); A = max(L, 0); nb = zeros(size(A));
            for j = 1:n, wgt = kk(n-j+1:2*n-j); wgt(j) = 0; nb(j,:) = wgt*A; end
            L = L - o.supp_w*nb;
        end
        u = max(min((2*c.*L + b)./q, 0.9999), -0.9999); E = -(2./q).*atanh(u) + C; neg = L <= 0; En = L./a; E(neg) = En(neg); I = 10.^(E/10);
        if isfield(o, 'srI0'), rate = zeros(size(I)); for j = 1:numel(o.srI0), rate = rate + o.srwt(j)*((I/o.srI0(j) + 1).^P.alpha_loud - 1); end
        else, rate = (I/P.I0 + 1).^P.alpha_loud - 1; end
        s(i,:) = K.stride*sum(rate, 2)';
    end
end
function v = rd(s, Lv, P), v = letter_refit('readout', s, Lv, P); end
function v = rdg(s, Lv, P, o)
% read-out; with o.gate = [p1 p2] the weight is gated by the level predicted from the broad sum
    if isfield(o, 'gate'), LE = sum(s, 2); v = letter_refit('readout', s, (o.gate(1)*log10(max(LE,eps)) + o.gate(2))', P); else, v = rd(s, Lv, P); end
end
function g = mono(g), g = cummax(g); g = g + linspace(0, 1e-9*max(g), numel(g)); end
function m = map(K, P, o, Lg, Lv)
    m.D1 = nan(10, numel(Lv));
    for k = 1:10, gp = mono(rdg(scx(K, K.T{k}, Lg, P, o), Lg, P, o)); m.D1(k,:) = letter_refit('match', rdg(scx(K, K.O{k}, Lv, P, o), Lv, P, o), gp, Lg) - Lv; end
end
function d = one(K, P, o, k, Lg, L)
    gp = mono(rdg(scx(K, K.T{k}, Lg, P, o), Lg, P, o)); d = letter_refit('match', rdg(scx(K, K.O{k}, L, P, o), L, P, o), gp, Lg) - L;
end
function D = nmap(CN, CT, P, Lg, Lv)
    D = nan(10, numel(Lv)); nt = size(CN{1}, 1);
    for k = 1:10
        gp = mono(rd(CT{k}, Lg, P)); v = zeros(nt, numel(Lv)); for s = 1:nt, v(s,:) = rd(squeeze(CN{k}(s,:,:)), Lv, P); end
        D(k,:) = letter_refit('match', mean(v, 1), gp, Lg) - Lv;
    end
end
function D = tmap(C5, CT, P, Lg, Lv)
    D = nan(10, numel(Lv)); for k = 1:10, gp = mono(rd(CT{k}, Lg, P)); D(k,:) = letter_refit('match', rd(C5{k}, Lv, P), gp, Lg) - Lv; end
end
function w = noise(t, f_c, bw, seed)
% as test_noise_ensemble.m: equal-amplitude components with random phases, linear spacing, geometric centering, unit RMS
    f_max = (bw + sqrt(bw^2 + 4*f_c^2))/2; f_min = f_c^2/f_max; N = max(40, round(bw/20));
    fr = linspace(f_min, f_max, N); rng(seed); ph = 2*pi*rand(N,1); raw = sum(sin(2*pi*fr(:)*t + ph), 1); w = raw/rms(raw);
end
function [r, e] = score(D, T, Fm, Lm)
    a = D(Fm,Lm); c = T(Fm,Lm); m = isfinite(a) & isfinite(c); a = a(m); c = c(m); r = corr(a(:), c(:)); e = sqrt(mean((a-c).^2));
end
