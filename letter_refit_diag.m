function letter_refit_diag()
% Diagnostic for the 1-kHz stage of letter_refit.m: its cost against the peak-weighting exponent q, with the rate function
% of the fitted model held and (w0, L0, Lw) refitted at each q; and the same with alpha and I0 free as well.
    Tt = load('nea_cls_targets.mat'); K = letter_refit('setup', 4, 1000); K.F = 1000;
    P = load('nea_letter_params.mat');   % the fitted model: its rate function is held, q is varied
    opt = optimset('Display', 'off', 'MaxFunEvals', 500, 'MaxIter', 500, 'TolX', 1e-3, 'TolFun', 1e-5);
    fprintf('rate function fixed (alpha %.4f, I0 %.3g); w0, L0, Lw fitted at each q\n     q |   cost  growth%%  infl dB |   w0     L0     Lw | one-octave influence at 30..100 dB\n', P.alpha_loud, P.I0);
    for q = [4 8 14 20 30 60 1e3]
        Q = P; Q.qpeak = q; x = fminsearch(@(x) c2(up(Q,x), K, Tt), [Q.winh Q.Lq50 Q.Lqw], opt); Q = up(Q, x); [c, d] = c2(Q, K, Tt);
        fprintf('%6g | %6.4f %7.1f %8.2f | %5.3f %6.1f %6.1f |', q, c, 100*(10^d.g-1), d.d, Q.winh, Q.Lq50, Q.Lqw); fprintf(' %+5.1f', d.d1); fprintf('\n');
    end
    fprintf('data, one octave:%58s', ''); fprintf(' %+5.1f', Tt.ddb5(4, (30:10:100)+1)); fprintf('\n');
    fprintf('\nalpha and I0 free as well (start: the fitted values), q held\n     q |   cost  growth%%  infl dB |   w0     L0     Lw | alpha    I0\n');
    for q = [8 14 30]
        Q = P; Q.qpeak = q; x = fminsearch(@(x) c2(up5(Q,x), K, Tt), [Q.winh Q.Lq50 Q.Lqw Q.alpha_loud log10(Q.I0)], opt); Q = up5(Q, x); [c, d] = c2(Q, K, Tt);
        fprintf('%6g | %6.4f %7.1f %8.2f | %5.3f %6.1f %6.1f | %.4f %6.3g\n', q, c, 100*(10^d.g-1), d.d, Q.winh, Q.Lq50, Q.Lqw, Q.alpha_loud, Q.I0);
    end
end
function P = up(P, x), P.winh = max(0, x(1)); P.Lq50 = x(2); P.Lqw = max(5, x(3)); end
function P = up5(P, x), P = up(P, x(1:3)); P.alpha_loud = x(4); P.I0 = 10^x(5); end
function [c, det] = c2(P, K, Tt)
    k = 4; L = 20:10:100; ix = L+1; Lg = -20:5:110; R = @(e, Lv) letter_refit('readout', letter_refit('scores', K, e, Lv, P), Lv, P);
    gp = R(K.T{1}, Lg); if any(gp <= 0) || any(~isfinite(gp)), c = 1e3; det = struct('g',1e3,'d',1e3,'d1',nan(1,8)); return; end
    mp = interp1(Lg, gp, L); gpm = cummax(gp) + linspace(0, 1e-9, numel(gp)); tp = Tt.sones1(k, ix); scal = 10^mean(log10(tp) - log10(mp));
    mq = R(K.Q{1}, L); m1 = R(K.O{1}, L); dq = letter_refit('match', mq, gpm, Lg) - L; d1 = letter_refit('match', m1, gpm, Lg) - L;
    res = [log10(scal*mp) - log10(tp), log10(scal*mq) - log10(Tt.sones2(k,ix)), log10(scal*m1) - log10(Tt.sones5(k,ix))];
    mono = sum(max(0, -diff(gp)))/max(mean(gp), eps) + sum(max(0, -diff(mq)))/max(mean(mq), eps) + sum(max(0, -diff(m1)))/max(mean(m1), eps);
    tq = Tt.ddb2(k, ix); t1 = Tt.ddb5(k, ix); ok = L >= 30; rd = [dq(ok) - tq(ok), d1(ok) - t1(ok)];
    g = sqrt(mean(res.^2)); d = sqrt(mean(rd.^2)); c = g + d/30 + 5*mono; det = struct('g', g, 'd', d, 'd1', d1(ok));
end
