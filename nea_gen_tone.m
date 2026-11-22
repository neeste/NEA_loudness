function w = nea_gen_tone(t, f, rms_val)
% NEA_GEN_TONE  Pure tone at frequency f, scaled to rms_val.
    raw = sin(2*pi*f*t);
    w = raw * (rms_val / rms(raw));
end
