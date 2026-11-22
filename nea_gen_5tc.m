function w = nea_gen_5tc(t, f_c, bw, rms_val)
% NEA_GEN_5TC  5-tone complex, geometrically centered on f_c, with BANDWIDTH bw.
%
% BUGFIX (2026-07-17): the previous in-file version took the 3rd argument as
% f_max while every caller passed a BANDWIDTH.  That made the "1/4-octave"
% stimulus span 5.05 octaves (173-5764 Hz at 1 kHz) instead of 0.25 octaves
% (917-1090 Hz).  The 1-octave case was correct only by coincidence (for one
% octave bw happens to equal f_min numerically, so the error cancelled).
%
% Geometric centering: f_min*f_max = f_c^2 and f_max - f_min = bw.
    f_max = (bw + sqrt(bw^2 + 4*f_c^2)) / 2;
    f_min = f_c^2 / f_max;
    freqs = logspace(log10(f_min), log10(f_max), 5);
    raw = zeros(size(t));
    for f = freqs
        raw = raw + sin(2*pi*f*t);
    end
    w = raw * (rms_val / rms(raw));
end
