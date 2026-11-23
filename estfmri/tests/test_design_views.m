function tests = test_design_views
%TEST_DESIGN_VIEWS Tests for the GUI-free design-stage plots.
%   Run from the repo root:
%     addpath('estfmri'); results = runtests('estfmri/tests')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'estfmri'));
legacy = fullfile(repo, 'estfmriTOY_V3_PubV_1');

tc.TestData.oldVisible = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');

s = load(fullfile(legacy, 'ER_tutorial_config_file.mat'));
tut = estfmri.cfg_from_legacy_opts(s.opts, fullfile(legacy, 'timings'));
[X, labels, info] = estfmri.design_matrix(tut);
tc.TestData.tut = struct('cfg', tut, 'X', X, 'labels', {labels}, 'info', info);

% synthetic: 2 runs, linear baseline, three different HRF models
syn.TR = 2; syn.npts = 80; syn.num_runs = 2; syn.polort = 1;
syn.stims(1) = struct('name', 'A_blk', 'onsets', {{[10 60 100], [20 90]}}, 'hrf', 'BLOCK(3,1)');
syn.stims(2) = struct('name', 'B_gam', 'onsets', {{[30 120], [5 50 140]}}, 'hrf', 'GAM');
syn.stims(3) = struct('name', 'C_mionn', 'onsets', {{40, 70}}, 'hrf', 'MIONN(2)');
[X, labels, info] = estfmri.design_matrix(syn);
tc.TestData.syn = struct('cfg', syn, 'X', X, 'labels', {labels}, 'info', info);
end

function teardownOnce(tc)
set(groot, 'DefaultFigureVisible', tc.TestData.oldVisible);
end

function teardown(~)
close all force;
end

% --- stim_duration ----------------------------------------------------------

function test_stim_duration(tc)
verifyEqual(tc, estfmri.stim_duration('BLOCK(0.75,1)'), 0.75);
verifyEqual(tc, estfmri.stim_duration('BLOCK(4)'), 4);
verifyEqual(tc, estfmri.stim_duration('MION(2)'), 2);
verifyEqual(tc, estfmri.stim_duration('MIONN(3)'), 3);
verifyEqual(tc, estfmri.stim_duration('GAM(8.6,0.6,5)'), 5);
verifyEqual(tc, estfmri.stim_duration('GAM(8.6,0.6)'), 2.3*sqrt(8.6)*0.6, 'AbsTol', 1e-12);
verifyEqual(tc, estfmri.stim_duration('GAM'), 2.3*sqrt(8.6)*0.547, 'AbsTol', 1e-12);
end

% --- plot_stimuli -----------------------------------------------------------

function test_plot_stimuli_boxcar(tc)
for d = {tc.TestData.tut, tc.TestData.syn}
    c = d{1}.cfg;
    fig = estfmri.plot_stimuli(c);
    verifyClass(tc, fig, 'matlab.ui.Figure');
    ax = findobj(fig, 'Type', 'axes');
    verifyNumElements(tc, ax, numel(c.stims) + 1);
    verifyNumElements(tc, findall(fig, 'Tag', 'run_boundary'), (c.num_runs - 1) * numel(ax));
end
end

function test_plot_stimuli_boxcar_geometry(tc)
% The 'All' tile's first trace must rise to 1 exactly at each onset and
% stay there for the stimulus duration.
c = tc.TestData.syn.cfg;
fig = estfmri.plot_stimuli(c, 'Stims', 1);
ln = findobj(fig, 'Type', 'line');
x = ln(1).XData; y = ln(1).YData;
runlen = c.npts * c.TR;
ons = [c.stims(1).onsets{1}, runlen + c.stims(1).onsets{2}];
for o = ons
    verifyTrue(tc, any(abs(x - o) < 1e-9 & y == 1), sprintf('rise at %g', o));
    verifyTrue(tc, any(abs(x - (o + 3)) < 1e-9 & y == 1), sprintf('top end at %g', o + 3));
end
end

function test_plot_stimuli_onset_subset(tc)
c = tc.TestData.syn.cfg;
fig = estfmri.plot_stimuli(c, 'Style', 'onset', 'Stims', [1 3]);
verifyNumElements(tc, findobj(fig, 'Type', 'axes'), 3);
verifyError(tc, @() estfmri.plot_stimuli(c, 'Style', 'bars'), 'MATLAB:InputParser:ArgumentFailedValidation');
end

% --- plot_regressors --------------------------------------------------------

function test_plot_regressors(tc)
d = tc.TestData.syn;
fig = estfmri.plot_regressors(d.cfg, d.X, d.info);
verifyNumElements(tc, findobj(fig, 'Type', 'axes'), d.info.nstim + 1);
verifyNumElements(tc, findobj(fig, 'Tag', 'regressor'), 2 * d.info.nstim);
verifyEmpty(tc, findall(fig, 'Tag', 'stimulus'));
% plotted data = stimulus columns of X (not baseline)
lns = findobj(fig, 'Tag', 'regressor');
Y = cell2mat(arrayfun(@(h) h.YData(:), lns', 'UniformOutput', false));
for k = 1:d.info.nstim
    col = d.X(:, d.info.nbase + k);
    verifyTrue(tc, any(all(abs(Y - col) < 1e-12, 1)), sprintf('column %d plotted', k));
end
% MIONN goes negative -> y-limits must include it
ax = findobj(fig, 'Type', 'axes');
verifyLessThan(tc, min(arrayfun(@(a) a.YLim(1), ax)), 0);
end

function test_plot_regressors_with_stimuli(tc)
d = tc.TestData.tut;
fig = estfmri.plot_regressors(d.cfg, d.X, d.info, 'ShowStimuli', true);
nev = sum(cellfun(@(o) numel([o{:}]), {d.cfg.stims.onsets}));
verifyNumElements(tc, findall(fig, 'Tag', 'stimulus'), nev);
end

% --- plot_design_matrix -----------------------------------------------------

function test_plot_design_matrix(tc)
d = tc.TestData.syn;
fig = estfmri.plot_design_matrix(d.X, d.labels, d.info);
im = findobj(fig, 'Type', 'image');
verifyEqual(tc, im.CData, d.X(:, d.info.nbase + 1:end));
fig2 = estfmri.plot_design_matrix(d.X, d.labels, d.info, 'ShowBaseline', true, 'TR', d.cfg.TR);
im2 = findobj(fig2, 'Type', 'image');
verifyEqual(tc, im2.CData, d.X);
verifyEqual(tc, im2.YData([1 end]), [0, (size(d.X, 1) - 1) * d.cfg.TR]);
end

% --- plot_correlation / plot_regressor_pair --------------------------------

function test_plot_correlation_values(tc)
d = tc.TestData.tut;
[fig, R] = estfmri.plot_correlation(d.X, d.labels, d.info);
S = d.X(:, d.info.nbase + 1:end);
verifyEqual(tc, R, corrcoef(S), 'AbsTol', 1e-12);
im = findobj(fig, 'Tag', 'corr_image');
verifyEqual(tc, im.CData, abs(corrcoef(S)), 'AbsTol', 1e-12);
K = d.info.nstim;
verifyNumElements(tc, findobj(fig, 'Tag', 'corr_value'), K*(K-1)/2);
end

function test_plot_correlation_baseline_toggle(tc)
d = tc.TestData.syn;
[~, R1] = estfmri.plot_correlation(d.X, d.labels, d.info);
verifySize(tc, R1, [d.info.nstim d.info.nstim]);
[~, R2] = estfmri.plot_correlation(d.X, d.labels, d.info, 'ShowBaseline', true);
verifySize(tc, R2, [d.info.nbase + d.info.nstim, d.info.nbase + d.info.nstim]);
end

function test_plot_regressor_pair(tc)
d = tc.TestData.tut;
[fig, st] = estfmri.plot_regressor_pair(d.X, 1, 3, d.labels);
x = d.X(:, 1); y = d.X(:, 3);
pf = polyfit(x, y, 1);
c = corrcoef(x, y);
verifyEqual(tc, st.slope, pf(1), 'AbsTol', 1e-12);
verifyEqual(tc, st.intercept, pf(2), 'AbsTol', 1e-12);
verifyEqual(tc, st.r, c(1, 2), 'AbsTol', 1e-12);
verifyNumElements(tc, findobj(fig, 'Tag', 'fit'), 1);
end

% --- plot_hrfs --------------------------------------------------------------

function test_plot_hrfs(tc)
d = tc.TestData.syn;
fig = estfmri.plot_hrfs(d.cfg, 'TMax', 40);
lns = findobj(fig, 'Tag', 'hrf');
verifyNumElements(tc, lns, numel(d.cfg.stims));
verifyEqual(tc, lns(1).XData([1 end]), [0 40]);
end
