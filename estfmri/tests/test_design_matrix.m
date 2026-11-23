function tests = test_design_matrix
%TEST_DESIGN_MATRIX Tests for the native (AFNI-free) design-matrix builder.
%   Run from the repo root:
%     addpath('estfmri'); results = runtests('estfmri/tests')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'estfmri'));
tc.TestData.legacy = fullfile(repo, 'estfmriTOY_V3_PubV_1');
end

% --- Validation against AFNI output --------------------------------------

function test_tutorial_matches_afni(tc)
% opts.X in the tutorial config was produced by AFNI 3dDeconvolve -nodata.
s = load(fullfile(tc.TestData.legacy, 'ER_tutorial_config_file.mat'));
opts = s.opts;
cfg = estfmri.cfg_from_legacy_opts(opts, fullfile(tc.TestData.legacy, 'timings'));
[X, labels, info] = estfmri.design_matrix(cfg);

verifySize(tc, X, size(opts.X));
verifyEqual(tc, info.nstim, opts.num_stim);
verifyEqual(tc, labels(end-info.nstim+1:end), opts.regnames);
for k = 1:size(X, 2)
    err = max(abs(X(:, k) - opts.X(:, k)));
    verifyLessThan(tc, err, 1e-4, ...
        sprintf('Column %d (%s, %s) differs from AFNI by %.3g', ...
        k, labels{k}, cfg.stims(min(k, end)).hrf, err));
end
end

% --- HRF shapes -----------------------------------------------------------

function test_gam_peak(tc)
p = 8.6; q = 0.547;
verifyEqual(tc, estfmri.hrf(sprintf('GAM(%g,%g)', p, q), p*q), 1, 'AbsTol', 1e-12);
t = linspace(0, 30, 3001);
verifyLessThanOrEqual(tc, max(estfmri.hrf('GAM', t)), 1 + 1e-12);
end

function test_gam_duration_peak(tc)
t = linspace(0, 40, 40001);
verifyEqual(tc, max(estfmri.hrf('GAM(8.6,0.547,5)', t)), 1, 'AbsTol', 1e-6);
end

function test_block_peak_normalised(tc)
t = linspace(0, 30, 30001);
for d = [0.5 1 5 20]
    h = estfmri.hrf(sprintf('BLOCK(%g,1)', d), t);
    verifyEqual(tc, max(h), 1, 'AbsTol', 1e-6, sprintf('BLOCK(%g,1)', d));
    h2 = estfmri.hrf(sprintf('BLOCK(%g,2.5)', d), t);
    verifyEqual(tc, max(h2), 2.5, 'AbsTol', 1e-6);
end
end

function test_block_truncated(tc)
d = 0.75;
verifyEqual(tc, estfmri.hrf('BLOCK(0.75,1)', [d + 15, d + 20]), [0 0]);
verifyGreaterThan(tc, estfmri.hrf('BLOCK(0.75,1)', d + 14.9), 0);
end

function test_causal(tc)
models = {'GAM', 'GAM(8.6,0.547,3)', 'BLOCK(2,1)', 'MION(2)', 'MIONN(2)'};
for i = 1:numel(models)
    verifyEqual(tc, estfmri.hrf(models{i}, [-5 -0.1 0]), [0 0 0], models{i});
end
end

function test_mionn_is_negative_mion(tc)
t = 0:0.5:60;
verifyEqual(tc, estfmri.hrf('MIONN(3)', t), -estfmri.hrf('MION(3)', t), 'AbsTol', 1e-12);
end

% --- Parsing / IO ---------------------------------------------------------

function test_parse_hrf(tc)
s = estfmri.parse_hrf(' block(0.75, 1) ');
verifyEqual(tc, s.model, 'BLOCK');
verifyEqual(tc, s.params, [0.75 1]);
s = estfmri.parse_hrf('GAM');
verifyEqual(tc, s.model, 'GAM');
verifyEmpty(tc, s.params);
verifyError(tc, @() estfmri.parse_hrf('TENT(0,10,5)'), 'estfmri:parse_hrf:unknownModel');
verifyError(tc, @() estfmri.parse_hrf('BLOCK(a)'), 'estfmri:parse_hrf:badParams');
end

function test_read_timings(tc)
f = [tempname '.1D'];
fid = fopen(f, 'w');
fprintf(fid, '# comment\n10 20.5 30\n*\n\n5\n');
fclose(fid);
c = onCleanup(@() delete(f));
on = estfmri.read_timings(f);
verifyEqual(tc, numel(on), 3);
verifyEqual(tc, on{1}, [10 20.5 30]);
verifyEmpty(tc, on{2});
verifyEqual(tc, on{3}, 5);
end

% --- Baseline / assembly --------------------------------------------------

function test_baseline_structure(tc)
npts = 50; runs = 3;
[B, labels] = estfmri.baseline(npts, runs, 2, 2);
verifySize(tc, B, [npts*runs, 3*runs]);
verifyEqual(tc, labels{4}, 'Run#2Pol#0');
% each column is zero outside its own run
for r = 1:runs
    cols = (r-1)*3 + (1:3);
    other = setdiff(1:npts*runs, (r-1)*npts + (1:npts));
    verifyEqual(tc, B(other, cols), zeros(numel(other), 3));
end
% P0 = 1, P1 runs -1..1, P2 = (3x^2-1)/2
x = linspace(-1, 1, npts)';
verifyEqual(tc, B(1:npts, 1:3), [ones(npts,1), x, (3*x.^2-1)/2], 'AbsTol', 1e-12);
end

function test_baseline_polort_options(tc)
verifySize(tc, estfmri.baseline(100, 2, -1, 2), [200 0]);
verifySize(tc, estfmri.baseline(100, 2, 'None', 2), [200 0]);
% 'A': p = 1 + floor(100*2/150) = 2 -> 3 columns per run
verifySize(tc, estfmri.baseline(100, 2, 'A', 2), [200 6]);
end

function test_regressor_stays_in_run(tc)
% An event late in run 1 must not leak into run 2.
% Run 1 has samples at 0,2,...,18 s; an onset at 15 s peaks after 18 s.
x = estfmri.stim_regressor({15, []}, 'BLOCK(1,1)', 2, 10);
verifyGreaterThan(tc, max(x(1:10)), 0);
verifyEqual(tc, x(11:20), zeros(10, 1));
end

function test_design_matrix_layout(tc)
cfg.TR = 2; cfg.npts = 60; cfg.num_runs = 2; cfg.polort = 1;
cfg.stims(1) = struct('name', 'A', 'onsets', {{[10 40], [20]}}, 'hrf', 'BLOCK(1,1)');
cfg.stims(2) = struct('name', 'B', 'onsets', {{[30], [5 50]}}, 'hrf', 'GAM');
[X, labels, info] = estfmri.design_matrix(cfg);
verifySize(tc, X, [120, 4 + 2]);
verifyEqual(tc, info.nbase, 4);
verifyEqual(tc, labels(end-1:end), {'A', 'B'});
cfg.stims(1).onsets = {10};
verifyError(tc, @() estfmri.design_matrix(cfg), 'estfmri:design_matrix:runMismatch');
end
