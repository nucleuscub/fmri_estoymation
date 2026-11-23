function tests = test_design_metrics
%TEST_DESIGN_METRICS Tests for estfmri.design_metrics / plot_design_metrics.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'estfmri'));
cfg = estfmri.tutorial();
[X, labels, info] = estfmri.design_matrix(cfg);
tc.TestData.tut = struct('cfg', cfg, 'X', X, 'labels', {labels}, 'info', info);
tc.TestData.oldVisible = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');
end

function teardownOnce(tc)
set(groot, 'DefaultFigureVisible', tc.TestData.oldVisible);
close all force;
end

function info = stim_info(nbase, nstim)
info.nbase = nbase; info.nstim = nstim;
end

% ---------------------------------------------------------------------------

function test_orthogonal_regressors(tc)
% Centred, mutually orthogonal columns: VIF = 1, SE = 1/norm(column).
n = 200; t = (0:n-1)';
X = [sin(2*pi*3*t/n), cos(2*pi*3*t/n), sin(2*pi*7*t/n)];
m = estfmri.design_metrics(X, stim_info(0, 3));
verifyEqual(tc, m.vif, [1 1 1], 'AbsTol', 1e-9);
verifyEqual(tc, m.se, 1 ./ vecnorm(X), 'AbsTol', 1e-12);
verifyEqual(tc, m.efficiency, vecnorm(X).^2, 'RelTol', 1e-9);
verifyEqual(tc, m.max_abs_r, [0 0 0], 'AbsTol', 1e-9);
verifyEqual(tc, m.level, {'ok', 'ok', 'ok'});
verifyFalse(tc, m.rank_deficient);
end

function test_vif_matches_inverse_correlation(tc)
% Without baseline columns, VIF_k = [inv(corr(X))]_kk.
d = tc.TestData.tut;
m = estfmri.design_metrics(d.X, d.info);
Ri = inv(corrcoef(d.X));
verifyEqual(tc, m.vif, diag(Ri)', 'RelTol', 1e-8);
end

function test_se_matches_inverse_gram(tc)
d = tc.TestData.tut;
m = estfmri.design_metrics(d.X, d.info);
G = inv(d.X' * d.X);
verifyEqual(tc, m.se, sqrt(diag(G))', 'RelTol', 1e-10);
verifyEqual(tc, m.cond, cond(d.X), 'RelTol', 1e-10);
end

function test_se_predicts_beta_spread(tc)
% Monte Carlo: with white noise of SD sigma, SD(beta_hat) = sigma * se.
d = tc.TestData.tut;
m = estfmri.design_metrics(d.X, d.info);
rng(1);
sigma = 0.5; reps = 4000;
beta = [1 5 10 15]';
Y = d.X * beta + sigma * randn(size(d.X, 1), reps);
B = d.X \ Y;
verifyEqual(tc, mean(B, 2), beta, 'AbsTol', 0.02);
verifyEqual(tc, std(B, 0, 2)', sigma * m.se, 'RelTol', 0.05);
end

function test_baseline_counts_in_vif(tc)
% A stimulus regressor equal to a linear drift is fully explained by a
% polort-1 baseline -> VIF Inf and the design is rank deficient.
n = 100;
B = estfmri.baseline(n, 1, 1, 2);
x = B(:, 2);
other = double(mod((1:n)', 10) == 0);
X = [B, x, other];
m = estfmri.design_metrics(X, stim_info(2, 2));
verifyEqual(tc, m.vif(1), Inf);
verifyTrue(tc, m.rank_deficient);
verifyEqual(tc, m.se(1), Inf);
verifyTrue(tc, isfinite(m.se(2)));
verifyEqual(tc, m.level{1}, 'severe');
verifyNotEmpty(tc, m.warnings);
end

function test_levels(tc)
% Two noisy copies of the same signal: strongly collinear.
rng(2);
n = 300; s = randn(n, 1);
X = [s + 0.05*randn(n, 1), s + 0.05*randn(n, 1), randn(n, 1)];
m = estfmri.design_metrics(X, stim_info(0, 3));
verifyEqual(tc, m.level(1:2), {'severe', 'severe'});
verifyEqual(tc, m.level{3}, 'ok');
end

function test_plot_design_metrics(tc)
d = tc.TestData.tut;
m = estfmri.design_metrics(d.X, d.info);
fig = estfmri.plot_design_metrics(m, d.labels(d.info.nbase + 1:end));
vb = findobj(fig, 'Tag', 'vif_bars');
verifyEqual(tc, vb.YData, m.vif, 'AbsTol', 1e-12);
sb = findobj(fig, 'Tag', 'se_bars');
verifyEqual(tc, sb.YData, m.se, 'AbsTol', 1e-12);
end
