function tests = test_app
%TEST_APP Tests for the estfmri.app front end (run headless, Visible off).
%   Programmatic Value changes do not fire callbacks in MATLAB, so the
%   tests invoke the callbacks the same way a user edit would.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'estfmri'));
legacy = fullfile(repo, 'estfmriTOY_V3_PubV_1');
s = load(fullfile(legacy, 'ER_tutorial_config_file.mat'));
tc.TestData.tut = estfmri.cfg_from_legacy_opts(s.opts, fullfile(legacy, 'timings'));

syn.TR = 2; syn.npts = 80; syn.num_runs = 2; syn.polort = 1;
syn.stims(1) = struct('name', 'A', 'onsets', {{[10 60 100], [20 90]}}, 'hrf', 'BLOCK(3,1)');
syn.stims(2) = struct('name', 'B', 'onsets', {{[30 120], [5 50 140]}}, 'hrf', 'GAM(8.6,0.547)');
tc.TestData.syn = syn;
end

function setup(tc)
tc.TestData.h = estfmri.app([], 'Visible', 'off');
end

function teardown(tc)
delete(tc.TestData.h.Figure);
end

% ---------------------------------------------------------------------------

function test_empty_start(tc)
h = tc.TestData.h;
verifyEmpty(tc, h.getCfg());
verifyEmpty(tc, h.PlotPanel.Children);
verifySubstring(tc, h.status(), 'Load timing files');
end

function test_tutorial_design_matches_package(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
[X, labels, info] = h.getDesign();
[X0, labels0, info0] = estfmri.design_matrix(tc.TestData.tut);
verifyEqual(tc, X, X0);
verifyEqual(tc, labels, labels0);
verifyEqual(tc, info, info0);
verifySubstring(tc, h.status(), '210 samples x 4 columns');
verifySubstring(tc, h.status(), 'Max |r|');
verifyEqual(tc, h.Table.Data(:, 1)', {'S_cue', 'S_pict', 'T_cue', 'T_pict'});
verifyEqual(tc, h.Table.Data(:, 2)', {'BLOCK', 'BLOCK', 'BLOCK', 'BLOCK'});
end

function test_metrics_in_table_and_status(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
m = h.getMetrics();
[X, ~, info] = estfmri.design_matrix(tc.TestData.tut);
m0 = estfmri.design_metrics(X, info);
verifyEqual(tc, m.vif, m0.vif);
verifyEqual(tc, h.Table.Data(:, 4)', arrayfun(@(v) sprintf('%.2f', v), m0.vif, 'UniformOutput', false));
verifyEqual(tc, h.Table.Data(:, 5)', arrayfun(@(v) sprintf('%.3f', v), m0.se, 'UniformOutput', false));
verifySubstring(tc, h.status(), 'cond(X)');
end

function test_collinear_design_flagged(tc)
% Two classes with identical onsets and HRF -> perfectly collinear.
h = tc.TestData.h;
c = tc.TestData.syn;
c.stims(2).onsets = c.stims(1).onsets;
c.stims(2).hrf = c.stims(1).hrf;
h.setCfg(c);
verifySubstring(tc, h.status(), 'severe collinearity');
verifySubstring(tc, h.status(), 'rank deficient');
verifyEqual(tc, h.Table.Data{1, 4}, 'Inf');
verifyNotEmpty(tc, h.Table.StyleConfigurations);
% an invalid design clears the metric columns
h.Runs.Value = 3;
h.Runs.ValueChangedFcn(h.Runs, []);
verifyEqual(tc, h.Table.Data(:, 4)', {'', ''});
verifyEmpty(tc, h.Table.StyleConfigurations);
end

function test_every_view_renders(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
for v = h.views
    h.showView(v{1});
    verifyNotEmpty(tc, h.PlotPanel.Children, v{1});
end
h.showView('Correlation');
verifyNotEmpty(tc, findall(h.PlotPanel, 'Tag', 'corr_image'));
verifyError(tc, @() h.showView('Nope'), 'estfmri:app:badView');
end

function test_runs_change_reports_missing_rows(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);            % 1 run row per class
h.Runs.Value = 2;
h.Runs.ValueChangedFcn(h.Runs, []);
verifyEmpty(tc, h.getCfg());
verifySubstring(tc, h.status(), 'Runs = 2');
h.Runs.Value = 1;
h.Runs.ValueChangedFcn(h.Runs, []);
verifyNotEmpty(tc, h.getCfg());
end

function test_polort_change_adds_baseline(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
h.Polort.Value = 'A';
h.Polort.ValueChangedFcn(h.Polort, []);
[~, ~, info] = h.getDesign();
verifyEqual(tc, info.nbase, 1 + floor(210*2/150) + 1);   % p = 3 -> 4 cols
verifyEqual(tc, h.getCfg().polort, 'A');
end

function test_hrf_model_edit_resets_params(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
edit_cell(h, 2, 2, 'GAM');
c = h.getCfg();
verifyEqual(tc, c.stims(2).hrf, 'GAM(8.6,0.547)');
verifyEqual(tc, h.Table.Data{2, 3}, '8.6,0.547');
end

function test_params_edit_and_invalid_revert(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
edit_cell(h, 1, 3, '2,1');
verifyEqual(tc, h.getCfg().stims(1).hrf, 'BLOCK(2,1)');
edit_cell(h, 1, 3, 'abc');
verifySubstring(tc, h.status(), 'Invalid HRF');
verifyEqual(tc, h.Table.Data{1, 3}, '2,1');
verifyEqual(tc, h.getCfg().stims(1).hrf, 'BLOCK(2,1)');
end

function test_name_edit_and_multi_run_cfg(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
edit_cell(h, 1, 1, 'Alpha');
c = h.getCfg();
verifyEqual(tc, {c.stims.name}, {'Alpha', 'B'});
verifyEqual(tc, c.num_runs, 2);
verifyEqual(tc, c.polort, 1);
verifyEqual(tc, c.stims(1).onsets, tc.TestData.syn.stims(1).onsets);
end

% ---------------------------------------------------------------------------
function edit_cell(h, r, c, value)
% Simulate a user edit of table cell (r, c).
prev = h.Table.Data{r, c};
d = h.Table.Data;
d{r, c} = value;
h.Table.Data = d;
evt.Indices = [r c];
evt.PreviousData = prev;
evt.NewData = value;
h.Table.CellEditCallback(h.Table, evt);
end
