function [b,a,g] = gammatone(cf,bw)
% function [b,a,g] = gammatone(cf,bw)
%   Fourth-order complex-gammatone IIR filter coefficients
%   based on "Derivation of complex-valued gammatone filters"
%   by Aki Härmä, April 13th 1999.
% http://www.acoustics.hut.fi/software/HUTear/Gammatone/Complex_gt.html
%
% cf = center frequency (divided by Nyquist frequency)
% bw = equivalent rectangular bandwidth (divided by Nyquist frequency)
% b  = IIR input coefficients
% a  = IIR output coefficients
% g = gammatone amplitude and decay rate
%
aa = (4.089058411 * bw) ^ (4 / 3);  % gammatone amplitude
bb = (1.018572639 * bw);            % gammatone decay rate
ae = exp(-pi * (bb + 1i * cf));
av = [1 [1 [1 [1 ae] * ae] * ae] * ae];
b = av .* [0  1  4  1 0] * (aa / 2) ^ 3;
a = av .* [1 -4  6 -4 1];
if(nargout>2) g=[aa bb]; end
return
