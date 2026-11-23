function h = hrf(spec, t)
%HRF Evaluate a fixed-shape AFNI response model at times t (seconds after onset).
%   h = estfmri.hrf(spec, t) where spec is an HRF string such as
%   'BLOCK(0.75,1)' or a struct from estfmri.parse_hrf. h(t) = 0 for t < 0.
%
%   Models (following the AFNI 3dDeconvolve -stim_times definitions):
%     GAM(p,q)    (t/(p*q))^p * exp(p - t/q); peak 1 at t = p*q.
%                 Defaults p = 8.6, q = 0.547.
%     GAM(p,q,d)  GAM(p,q) convolved with a d-second boxcar, peak scaled to 1.
%     BLOCK(d)    d-second boxcar convolved with g(s) = s^4 exp(-s)/(4^4 exp(-4)).
%     BLOCK(d,p)  same shape, scaled so the peak equals p (if p > 0).
%                 BLOCK responses are set to 0 for t >= d + 15 s, as in AFNI.
%     MION(d)     d-second boxcar convolved with the MION impulse response
%                 16.4486*(-0.184/1.5 e^(-t/1.5) + 0.330/4.5 e^(-t/4.5)
%                 + 0.670/13.5 e^(-t/13.5)).
%     MIONN(d)    negative of MION(d).
%
%   Only BLOCK(d,1) has been checked against AFNI output (tutorial config);
%   the other models follow the AFNI documentation but are not yet validated.

if ~isstruct(spec)
    spec = estfmri.parse_hrf(spec);
end
prm = spec.params;
h = zeros(size(t));

switch spec.model
    case 'GAM'
        p = getp(prm, 1, 8.6);
        q = getp(prm, 2, 0.547);
        d = getp(prm, 3, 0);
        if d <= 0
            h = gam_impulse(t, p, q);
        else
            f = @(tt) boxcar_conv(@(s) gam_integral(s, p, q), tt, d);
            h = f(t) ./ peak_of(f, p*q + d + 20*q*sqrt(p));
        end

    case 'BLOCK'
        if isempty(prm)
            error('estfmri:hrf:missingParam', 'BLOCK needs a duration: BLOCK(d) or BLOCK(d,p).');
        end
        d   = prm(1);
        amp = getp(prm, 2, 0);
        f = @(tt) boxcar_conv(@block_integral, tt, d);
        h = f(t);
        if amp > 0
            h = amp * h ./ peak_of(f, d + 15);
        end
        % AFNI truncates the BLOCK response at d + 15 s, endpoint included
        % (h = 0 for t >= d + 15). Verified against the tutorial X, where a
        % sample falling exactly on d + 15 is 0 in AFNI's output.
        h(t >= d + 15 - 1e-9) = 0;

    case {'MION', 'MIONN'}
        if isempty(prm)
            error('estfmri:hrf:missingParam', '%s needs a duration: %s(d).', spec.model, spec.model);
        end
        d = prm(1);
        h = boxcar_conv(@mion_integral, t, d);
        if strcmp(spec.model, 'MIONN')
            h = -h;
        end
end
end

% ---------------------------------------------------------------------------
function v = getp(prm, i, default)
if numel(prm) >= i, v = prm(i); else, v = default; end
end

function y = boxcar_conv(G, t, d)
% Convolution of a d-second boxcar starting at 0 with impulse response g,
% given its running integral G(t) = int_0^t g(s) ds (G = 0 for t <= 0).
% y(t) = G(t) - G(t - d). For d = 0 this degenerates, so callers pass d > 0.
if d <= 0
    error('estfmri:hrf:badDuration', 'Duration must be > 0.');
end
y = G(t) - G(t - d);
end

function pk = peak_of(f, tmax)
% Peak of a non-negative response on [0, tmax], fine grid + local refinement.
tt = linspace(0, tmax, 20001);
[~, i] = max(f(tt));
lo = tt(max(i-1, 1)); hi = tt(min(i+1, numel(tt)));
tbest = fminbnd(@(x) -f(x), lo, hi, optimset('TolX', 1e-10));
pk = f(tbest);
end

function g = gam_impulse(t, p, q)
g = zeros(size(t));
k = t > 0;
g(k) = (t(k) ./ (p*q)).^p .* exp(p - t(k) ./ q);
end

function G = gam_integral(t, p, q)
% int_0^t (s/(pq))^p exp(p - s/q) ds = (q e^p / p^p) * Gamma(p+1) * P(p+1, t/q)
G = zeros(size(t));
k = t > 0;
G(k) = q * exp(p) / p^p * gamma(p+1) .* gammainc(t(k) ./ q, p+1);
end

function G = block_integral(t)
% int_0^t s^4 e^-s / (4^4 e^-4) ds = (e^4/256) * 24 * P(5, t)
G = zeros(size(t));
k = t > 0;
G(k) = exp(4) / 256 * 24 .* gammainc(t(k), 5);
end

function G = mion_integral(t)
% Running integral of the MION impulse response.
a = [-0.184, 0.330, 0.670];
tau = [1.5, 4.5, 13.5];
G = zeros(size(t));
k = t > 0;
for j = 1:3
    G(k) = G(k) + a(j) .* (1 - exp(-t(k) ./ tau(j)));
end
G = 16.4486 .* G;
end
