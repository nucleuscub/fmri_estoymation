function [B, labels] = baseline(npts, num_runs, polort, TR)
%BASELINE Per-run Legendre polynomial baseline (AFNI -polort).
%   [B, labels] = estfmri.baseline(npts, num_runs, polort, TR)
%     polort : -1 or 'None' (no baseline), 'A' (automatic), or degree >= 0
%   Returns B of size (npts*num_runs) x ((p+1)*num_runs), ordered run by run
%   (Run1Pol0, Run1Pol1, ..., Run2Pol0, ...), each column zero outside its
%   run. Within a run, x goes linearly from -1 to 1 and column k is the
%   Legendre polynomial P_k(x). 'A' uses p = 1 + floor(npts*TR/150).
%
%   Not yet validated against AFNI output (the tutorial config uses no
%   baseline).

p = resolve_polort(polort, npts, TR);
N = npts * num_runs;
if p < 0
    B = zeros(N, 0);
    labels = {};
    return;
end

if npts > 1
    x = linspace(-1, 1, npts)';
else
    x = 0;
end
P = zeros(npts, p+1);
for k = 0:p
    P(:, k+1) = legendre_poly(k, x);
end

B = zeros(N, (p+1) * num_runs);
labels = cell(1, (p+1) * num_runs);
for r = 1:num_runs
    rows = (r-1)*npts + (1:npts);
    cols = (r-1)*(p+1) + (1:p+1);
    B(rows, cols) = P;
    for k = 0:p
        labels{cols(k+1)} = sprintf('Run#%dPol#%d', r, k);
    end
end
end

function p = resolve_polort(polort, npts, TR)
if ischar(polort) || isstring(polort)
    s = upper(strtrim(char(polort)));
    switch s
        case {'A', 'AUTO'}
            p = 1 + floor(npts * TR / 150);
        case {'NONE', '-1'}
            p = -1;
        otherwise
            p = str2double(s);
            if isnan(p)
                error('estfmri:baseline:badPolort', 'Bad polort "%s".', s);
            end
    end
else
    p = polort;
end
end

function y = legendre_poly(k, x)
% Legendre P_k(x) via Bonnet's recursion.
if k == 0
    y = ones(size(x));
    return;
end
pm1 = ones(size(x));
y = x;
for n = 1:k-1
    pn1 = ((2*n + 1) .* x .* y - n .* pm1) ./ (n + 1);
    pm1 = y;
    y = pn1;
end
end
