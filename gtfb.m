function [y,g] = gtfb(x,fs,cf,bw)
% function [y,g] = gtfb(x,fs,cf,bw)
% gammatone filterbank:
% x  = input signal
% fs = sampling rate (Hz)
% cf = center frequencies (Hz)
% bw = equivalent rectangular bandwidths (Hz)
% y  = output signals
% g  = gammatone parameters
%
if (nargin < 3), cf = 1000*2.^(-3:(1/3):3); end
if (nargin < 4), bw = cf/6; end
%
fn = fs/2;     % Nyquist frequency
nb = length(cf);
n = length(x);
y = zeros(n,nb);
if(nargout>2), g=zeros(nb,2); end
for k=1:nb
   [b,a,gp] = gammatone(cf(k)/fn,bw(k)/fn);
   y(:,k) = filter(b,a,x);
   if(nargout>1), g(k,:)=gp*fn; end
end
return

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
if(nargout>2), g=[aa bb]; end
return
