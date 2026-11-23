function tests = test_app
%TEST_APP Tests for the estfmri.app front end (run headless, Visible off).
%   Programmatic Value changes do not fire callbacks in MATLAB, so the
%   tests invoke the callbacks the same way a user edit would. File
%   operations are tested through h.openFile / h.saveTo / h.exportReport,
%   which the menu items call after their dialogs.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'estfmri'));
[tc.TestData.tut, ~, tc.TestData.data] = estfmri.tutorial();

syn.TR = 2; syn.npts = 80; syn.num_runs = 2; syn.polort = 1;
syn.stims(1) = struct('name', 'A', 'onsets', {{[10 60 100], [20 90]}}, 'hrf', 'BLOCK(3,1)');
syn.stims(2) = struct('name', 'B', 'onsets', {{[30 120], [5 50 140]}}, 'hrf', 'GAM(8.6,0.547)');
tc.TestData.syn = syn;
tc.TestData.oldVisible = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');
end

function teardownOnce(tc)
set(groot, 'DefaultFigureVisible', tc.TestData.oldVisible);
end

function setup(tc)
tc.TestData.h = estfmri.app([], 'Visible', 'off');
tc.TestData.tmp = tempname;
mkdir(tc.TestData.tmp);
end

function teardown(tc)
if isvalid(tc.TestData.h.Figure), delete(tc.TestData.h.Figure); end
rmdir(tc.TestData.tmp, 's');
close all force;
end

% --- start, title, status ----------------------------------------------------

function test_empty_start(tc)
h = tc.TestData.h;
verifyEmpty(tc, h.getCfg());
verifySubstring(tc, h.status(), 'No design yet');
verifyNotEmpty(tc, findall(h.PlotPanel, 'Tag', 'message_body'));
verifySubstring(tc, h.Figure.Name, 'Untitled');
verifyFalse(tc, h.isDirty());
verifyEqual(tc, char(h.ViewOption.Visible), 'off');
verifyEqual(tc, char(h.Preview.Visible), 'off');
end

function test_tutorial_design_matches_package(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
[X, labels, info] = h.getDesign();
[X0, labels0, info0] = estfmri.design_matrix(tc.TestData.tut);
verifyEqual(tc, X, X0);
verifyEqual(tc, labels, labels0);
verifyEqual(tc, info, info0);
verifySubstring(tc, h.status(), 'X 210 x 4');
verifySubstring(tc, h.status(), 'max |r| 0.62');
verifyEqual(tc, h.Table.Data(:, 1)', {'S_cue', 'S_pict', 'T_cue', 'T_pict'});
verifyEqual(tc, h.Table.Data(:, 2)', {'Block', 'Block', 'Block', 'Block'});
verifyFalse(tc, h.isDirty());
end

function test_every_view_renders(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
for v = h.views
    h.showView(v{1});
    verifyNotEmpty(tc, h.PlotPanel.Children, v{1});
    verifyEmpty(tc, findall(h.PlotPanel, 'Tag', 'message_body'), v{1});
end
h.showView('Correlation');
verifyNotEmpty(tc, findall(h.PlotPanel, 'Tag', 'corr_image'));
verifyError(tc, @() h.showView('Nope'), 'estfmri:app:badView');
end

function test_view_options_follow_view(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
h.showView('Regressors');
verifyEqual(tc, char(h.ViewOption.Visible), 'on');
verifyEqual(tc, h.ViewOption.Text, 'Show stimuli');
verifyNotEmpty(tc, findall(h.PlotPanel, 'Tag', 'stimulus'));
h.ViewOption.Value = false;
h.ViewOption.ValueChangedFcn(h.ViewOption, []);
verifyEmpty(tc, findall(h.PlotPanel, 'Tag', 'stimulus'));
h.showView('Design matrix');
verifyEqual(tc, h.ViewOption.Text, 'Include baseline');
h.showView('HRF shapes');
verifyEqual(tc, char(h.ViewOption.Visible), 'off');
end

% --- acquisition ---------------------------------------------------------------

function test_runs_change_reports_missing_rows(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);            % 1 run row per class
h.Runs.Value = 2;
h.Runs.ValueChangedFcn(h.Runs, []);
verifyEmpty(tc, h.getCfg());
verifySubstring(tc, h.status(), 'Runs = 2');
verifyNotEmpty(tc, findall(h.PlotPanel, 'Tag', 'message_body'));
verifyTrue(tc, h.isDirty());
verifySubstring(tc, h.Figure.Name, '*');
h.Runs.Value = 1;
h.Runs.ValueChangedFcn(h.Runs, []);
verifyNotEmpty(tc, h.getCfg());
end

function test_baseline_auto(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
verifyEqual(tc, h.Baseline.Items{2}, 'Auto (order 3)');   % 1 + floor(420/150)
h.Baseline.Value = 'A';
h.Baseline.ValueChangedFcn(h.Baseline, []);
[~, ~, info] = h.getDesign();
verifyEqual(tc, info.nbase, 4);
verifyEqual(tc, h.getCfg().polort, 'A');
h.Volumes.Value = 300;                                   % 600 s -> order 5
h.Volumes.ValueChangedFcn(h.Volumes, []);
verifyEqual(tc, h.Baseline.Items{2}, 'Auto (order 5)');
end

% --- class editor ----------------------------------------------------------------

function test_detail_shows_selected_class(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
h.selectClass(2);                                         % S_pict BLOCK(0.5,1)
verifyEqual(tc, h.Model.Value, 'BLOCK');
verifyEqual(tc, [h.Params(1).Value, h.Params(2).Value], [0.5 1]);
verifyEqual(tc, char(h.Params(3).Visible), 'off');
verifyNotEmpty(tc, h.Preview.Children);
verifyError(tc, @() h.selectClass(9), 'estfmri:app:badClass');
end

function test_model_change_sets_defaults(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
h.selectClass(2);
h.Model.Value = 'GAM';
h.Model.ValueChangedFcn(h.Model, []);
verifyEqual(tc, h.getCfg().stims(2).hrf, 'GAM(8.6,0.547)');
verifyEqual(tc, h.Table.Data{2, 2}, 'Gamma');
verifyEqual(tc, char(h.Params(3).Visible), 'on');
h.Model.Value = 'MIONN';
h.Model.ValueChangedFcn(h.Model, []);
verifyEqual(tc, h.getCfg().stims(2).hrf, 'MIONN(1)');
verifyEqual(tc, char(h.Params(2).Visible), 'off');
end

function test_param_edit(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
h.selectClass(1);
set_param(h, 1, 2);
verifyEqual(tc, h.getCfg().stims(1).hrf, 'BLOCK(2,1)');
set_param(h, 2, 0);                                       % unscaled block
verifyEqual(tc, h.getCfg().stims(1).hrf, 'BLOCK(2)');
verifyError(tc, @() set(h.Params(1), 'Value', -1), 'MATLAB:ui:NumericEditField:invalidValue');
end

function test_rename_class(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
edit_name(h, 1, 'Alpha');
verifyEqual(tc, {h.getCfg().stims.name}, {'Alpha', 'B'});
edit_name(h, 2, 'Alpha');                                 % duplicate -> rejected
verifyEqual(tc, {h.getCfg().stims.name}, {'Alpha', 'B'});
verifyEqual(tc, h.Table.Data{2, 1}, 'B');
verifySubstring(tc, h.status(), 'unique');
end

function test_add_remove_move_classes(tc)
h = tc.TestData.h;
t = fullfile(tc.TestData.data, 'timings');
h.importTimingFiles({fullfile(t, 'S_cue.1D'), fullfile(t, 'T_cue.1D')});
verifyEqual(tc, {h.getCfg().stims.name}, {'S_cue', 'T_cue'});
verifyEqual(tc, h.getCfg().stims(1).hrf, 'GAM(8.6,0.547)');
verifyTrue(tc, h.isDirty());
h.addClassFromFile(fullfile(t, 'S_cue.1D'));              % same file -> unique name
verifyEqual(tc, {h.getCfg().stims.name}, {'S_cue', 'T_cue', 'S_cue_2'});
h.moveClass(3, -1);
verifyEqual(tc, {h.getCfg().stims.name}, {'S_cue', 'S_cue_2', 'T_cue'});
h.moveClass(1, -1);                                       % no-op at the top
verifyEqual(tc, {h.getCfg().stims.name}, {'S_cue', 'S_cue_2', 'T_cue'});
h.removeClass(2);
verifyEqual(tc, {h.getCfg().stims.name}, {'S_cue', 'T_cue'});
h.removeClass(1); h.removeClass(1);
verifyEmpty(tc, h.getCfg());
verifySubstring(tc, h.status(), 'No design yet');
end

% --- metrics ----------------------------------------------------------------------

function test_metrics_in_table(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
[X, ~, info] = estfmri.design_matrix(tc.TestData.tut);
m0 = estfmri.design_metrics(X, info);
verifyEqual(tc, h.getMetrics().vif, m0.vif);
verifyEqual(tc, h.Table.Data(:, 3)', arrayfun(@(v) sprintf('%.2f', v), m0.vif, 'UniformOutput', false));
verifyEqual(tc, h.Table.Data(:, 4)', arrayfun(@(v) sprintf('%.3f', v), m0.se, 'UniformOutput', false));
end

function test_collinear_design_flagged(tc)
h = tc.TestData.h;
c = tc.TestData.syn;
c.stims(2).onsets = c.stims(1).onsets;
c.stims(2).hrf = c.stims(1).hrf;
h.setCfg(c);
verifySubstring(tc, h.status(), 'severe collinearity');
verifySubstring(tc, h.status(), 'rank deficient');
verifyEqual(tc, h.Table.Data{1, 3}, 'Inf');
verifyNotEmpty(tc, h.Table.StyleConfigurations);
end

% --- files ------------------------------------------------------------------------

function test_save_and_reopen(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
h.selectClass(1);
set_param(h, 1, 4);
verifyTrue(tc, h.isDirty());
p = fullfile(tc.TestData.tmp, 'my_design.mat');
h.saveTo(p);
verifyFalse(tc, h.isDirty());
verifySubstring(tc, h.Figure.Name, 'my_design.mat');
verifyFalse(tc, contains(h.Figure.Name, '*'));
saved = h.getCfg();

h2 = estfmri.app([], 'Visible', 'off');
c2 = onCleanup(@() delete(h2.Figure));
h2.openFile(p);
verifyEqual(tc, h2.getCfg(), saved);
verifyFalse(tc, h2.isDirty());
verifyEqual(tc, h2.getCfg().stims(1).hrf, 'BLOCK(4,1)');
end

function test_open_legacy_config(tc)
h = tc.TestData.h;
h.openFile(fullfile(tc.TestData.data, 'ER_tutorial_config_file.mat'));
verifyEqual(tc, {h.getCfg().stims.name}, {'S_cue', 'S_pict', 'T_cue', 'T_pict'});
verifySubstring(tc, h.Figure.Name, 'ER_tutorial_config_file.mat');
h.selectClass(1);
verifyEqual(tc, h.getCfg().stims(1).hrf, 'BLOCK(0.75,1)');
end

function test_open_bundled_tutorial_cfg(tc)
h = tc.TestData.h;
h.openFile(fullfile(tc.TestData.data, 'tutorial_cfg.mat'));
verifyEqual(tc, h.getCfg(), tc.TestData.tut);
verifySubstring(tc, h.Figure.Name, 'tutorial_cfg.mat');
verifyFalse(tc, h.isDirty());
end

function test_open_bad_file(tc)
h = tc.TestData.h;
p = fullfile(tc.TestData.tmp, 'other.mat');
x = 1; save(p, 'x');
verifyError(tc, @() h.openFile(p), 'estfmri:app:badFile');
end

function test_export_report(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.tut);
d = fullfile(tc.TestData.tmp, 'report');
files = h.exportReport(d);
verifyEqual(tc, numel(files), numel(h.views) + 2);
for i = 1:numel(files)
    verifyTrue(tc, isfile(files{i}), files{i});
end
txt = fileread(fullfile(d, 'summary.txt'));
verifySubstring(tc, txt, 'S_cue');
verifySubstring(tc, txt, 'VIF');
end

function test_new_design_and_close(tc)
h = tc.TestData.h;
h.setCfg(tc.TestData.syn);
h.newDesign();
verifyEmpty(tc, h.getCfg());
verifyEmpty(tc, h.Table.Data);
h.Figure.CloseRequestFcn(h.Figure, []);                  % hidden window: closes without asking
verifyFalse(tc, isvalid(h.Figure));
end

% --- helpers ------------------------------------------------------------------------

function set_param(h, i, value)
h.Params(i).Value = value;
h.Params(i).ValueChangedFcn(h.Params(i), []);
end

function edit_name(h, r, value)
prev = h.Table.Data{r, 1};
d = h.Table.Data; d{r, 1} = value; h.Table.Data = d;
evt.Indices = [r 1]; evt.PreviousData = prev; evt.NewData = value;
h.Table.CellEditCallback(h.Table, evt);
end
