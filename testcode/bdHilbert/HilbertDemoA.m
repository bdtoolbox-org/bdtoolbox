% Analytic Signal of a Sequence as described in the Matlab documentation
% for the hilbert function.

addpath ../../
addpath ../../panels

xr = [1 2 3 4];
x1 = hilbert(xr - mean(xr))         % Matlab Hilbert function
x2 = bdHilbert.hilbert(xr)          % bdtoolbox Hilbert function
assert(max(abs(x1-x2)) < 1e-8);

imx1 = imag(x1)
imx2 = imag(x2)
assert(max(abs(imx1-imx2)) < 1e-8);

rex1 = real(x1)
rex2 = real(x2)
assert(max(abs(rex1-rex2)) < 1e-8);

dft1 = fft(x1)
dft2 = fft(x2)
assert(max(abs(dft1-dft2)) < 1e-8);
