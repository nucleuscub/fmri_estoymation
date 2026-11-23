function h = app(cfg, varargin)
%APP Front-end window for estfmri (no GUIDE, no AFNI).
%   estfmri.app                 opens an empty window
%   estfmri.app(cfg)            opens it with a cfg struct (see design_matrix)
%   h = estfmri.app(..., 'Visible', 'off')   for scripting and tests
%
%   Layout
%     Menu bar   File (New, Open, Import timing files, Save, Save as, Export
%                report), Edit (add/remove/move classes), View, Help.
%     Toolbar    New, Open, Save, Import timing files, Export report.
%     Left       Acquisition (TR, volumes per run, runs, baseline drift),
%                Stimulus classes (table with VIF and SE/sigma; + - up down),
%                Response model of the selected class (model-specific
%                fields, curve preview, source file).
%     Right      Design tab: view list, view options, plot. Simulation tab is
%                a placeholder until native estimation exists.
%     Status bar design summary, warnings (hover for the list), save state.
%   Every edit rebuilds the design matrix and redraws the current view.
%
%   Returned struct h (scripting/tests; file functions take paths, no dialogs):
%     h.Figure, h.views, h.setCfg(cfg), h.getCfg(), h.getDesign(),
%     h.getMetrics(), h.showView(name), h.status(), h.isDirty(),
%     h.selectClass(k), h.addClassFromFile(path), h.importTimingFiles(paths),
%     h.removeClass(k), h.moveClass(k, +-1), h.openFile(path),
%     h.saveTo(path), h.exportReport(folder), h.newDesign(),
%     controls: h.Table, h.TR, h.Volumes, h.Runs, h.Baseline, h.ViewList,
%     h.ViewOption, h.Model, h.Params (1x3), h.Preview, h.PlotPanel.

ip = inputParser;
ip.addParameter('Visible', 'on');
ip.parse(varargin{:});

VIEWS = {'Stimuli', 'Onsets', 'HRF shapes', 'Regressors', 'Design matrix', ...
    'Correlation', 'Design quality'};
MODEL_CODES = {'BLOCK', 'GAM', 'MION', 'MIONN'};
MODEL_NAMES = {'Block', 'Gamma', 'MION', 'MION (negative)'};
BASE_DATA   = {'-1', 'A', '0', '1', '2', '3', '4', '5'};
BASE_NAMES  = {'None', 'Auto', 'Constant (0)', 'Linear (1)', 'Quadratic (2)', ...
    'Cubic (3)', 'Order 4', 'Order 5'};
ICONS = fullfile(matlabroot, 'toolbox', 'matlab', 'icons');
DOT = [' ' char(183) ' '];
SIGMA = char(963);
RED = [0.75 0.1 0.1]; AMBER = [0.6 0.4 0.0]; GREY = [0.35 0.35 0.35];

% ------------------------------------------------------------------ state
S.stims    = struct('name', {}, 'hrf', {}, 'rows', {}, 'source', {});
S.sel      = 0;
S.cfg      = []; S.X = []; S.labels = {}; S.info = []; S.metrics = [];
S.summary  = ''; S.messages = {}; S.error = ''; S.alert = '';
S.file     = ''; S.title = 'Untitled'; S.dirty = false; S.savedAt = [];
S.opt.showStim = true; S.opt.base = false;
warn_late = {};

% ------------------------------------------------------------------ window
fig = uifigure('Name', 'estfmri', 'Position', [60 60 1320 820], ...
    'Visible', ip.Results.Visible, 'CloseRequestFcn', @(~,~) on_close());

% --- menus
mFile = uimenu(fig, 'Text', '&File');
uimenu(mFile, 'Text', 'New', 'Accelerator', 'N', 'MenuSelectedFcn', @(~,~) on_new());
uimenu(mFile, 'Text', 'Open...', 'Accelerator', 'O', 'MenuSelectedFcn', @(~,~) on_open());
uimenu(mFile, 'Text', 'Import timing files...', 'Accelerator', 'I', 'MenuSelectedFcn', @(~,~) on_import());
uimenu(mFile, 'Text', 'Save', 'Accelerator', 'S', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) on_save());
uimenu(mFile, 'Text', 'Save as...', 'MenuSelectedFcn', @(~,~) on_save_as());
uimenu(mFile, 'Text', 'Export report...', 'Accelerator', 'E', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) on_export());
uimenu(mFile, 'Text', 'Close', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) on_close());

mEdit = uimenu(fig, 'Text', '&Edit');
uimenu(mEdit, 'Text', 'Add class from timing file...', 'MenuSelectedFcn', @(~,~) on_add());
uimenu(mEdit, 'Text', 'Remove class', 'MenuSelectedFcn', @(~,~) remove_class(S.sel));
uimenu(mEdit, 'Text', 'Move class up', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) move_class(S.sel, -1));
uimenu(mEdit, 'Text', 'Move class down', 'MenuSelectedFcn', @(~,~) move_class(S.sel, +1));

mView = uimenu(fig, 'Text', '&View');
mViewItems = gobjects(1, numel(VIEWS));
for iv = 1:numel(VIEWS)
    mViewItems(iv) = uimenu(mView, 'Text', VIEWS{iv}, ...
        'MenuSelectedFcn', @(src,~) show_view(src.Text));
end
uimenu(mView, 'Text', 'Pop out current view', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) on_popout());

mHelp = uimenu(fig, 'Text', '&Help');
uimenu(mHelp, 'Text', 'Quick start (README)', 'MenuSelectedFcn', @(~,~) on_readme());
uimenu(mHelp, 'Text', 'Response models', 'MenuSelectedFcn', @(~,~) doc('estfmri.hrf'));
uimenu(mHelp, 'Text', 'About estfmri', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) on_about());

root = uigridlayout(fig, [3 1]);
root.RowHeight = {36, '1x', 26};
root.Padding = [0 0 0 0];
root.RowSpacing = 0;

% --- toolbar
tb = uigridlayout(root, [1 8]);
tb.ColumnWidth = {70, 76, 70, 8, 160, 8, 130, '1x'};
tb.Padding = [8 5 8 5];
tb.ColumnSpacing = 4;
tool_button(1, 'New', 'file_new.png', 'New design (Ctrl+N)', @on_new);
tool_button(2, 'Open', 'file_open.png', 'Open a config (Ctrl+O)', @on_open);
tool_button(3, 'Save', 'file_save.png', 'Save the config (Ctrl+S)', @on_save);
tool_button(5, 'Import timing files...', '', 'Replace the classes with AFNI .1D timing files (Ctrl+I)', @on_import);
tool_button(7, 'Export report...', '', 'Save config, every view as PNG and a summary to a folder (Ctrl+E)', @on_export);

% --- body
body = uigridlayout(root, [1 2]);
body.ColumnWidth = {340, '1x'};
body.Padding = [8 6 8 6];
body.ColumnSpacing = 8;

left = uigridlayout(body, [3 1]);
left.RowHeight = {'fit', '1x', 'fit'};
left.Padding = [0 0 0 0];
left.RowSpacing = 8;

% Acquisition
pAcq = uipanel(left, 'Title', 'Acquisition', 'FontWeight', 'bold');
gA = uigridlayout(pAcq, [4 3]);
gA.ColumnWidth = {120, '1x', 22};
gA.RowHeight = {24, 24, 24, 24};
gA.Padding = [8 8 8 8];
gA.RowSpacing = 6;
uilabel(gA, 'Text', 'Repetition time');
hTR = uieditfield(gA, 'numeric', 'Value', 2, 'Limits', [0.01 100], ...
    'ValueDisplayFormat', '%.3g', 'ValueChangedFcn', @(~,~) on_acq(), ...
    'Tooltip', 'Time between volumes (TR)');
uilabel(gA, 'Text', 's', 'FontColor', GREY);
uilabel(gA, 'Text', 'Volumes per run');
hVol = uispinner(gA, 'Value', 200, 'Limits', [1 1e6], 'Step', 1, ...
    'RoundFractionalValues', 'on', 'ValueChangedFcn', @(~,~) on_acq());
uilabel(gA, 'Text', '');
uilabel(gA, 'Text', 'Runs');
hRuns = uispinner(gA, 'Value', 1, 'Limits', [1 1000], 'Step', 1, ...
    'RoundFractionalValues', 'on', 'ValueChangedFcn', @(~,~) on_acq());
uilabel(gA, 'Text', '');
uilabel(gA, 'Text', 'Baseline drift');
hBase = uidropdown(gA, 'Items', BASE_NAMES, 'ItemsData', BASE_DATA, 'Value', '-1', ...
    'ValueChangedFcn', @(~,~) on_acq(), ...
    'Tooltip', ['Per-run Legendre polynomials for slow drift (AFNI -polort). ' ...
    'Auto uses 1 + floor(run length / 150 s).']);
uilabel(gA, 'Text', '');

% Stimulus classes
pCls = uipanel(left, 'Title', 'Stimulus classes', 'FontWeight', 'bold');
gC = uigridlayout(pCls, [2 1]);
gC.RowHeight = {'1x', 26};
gC.Padding = [8 8 8 8];
gC.RowSpacing = 6;
hTable = uitable(gC, 'ColumnName', {'Name', 'Model', 'VIF', ['SE/' SIGMA]}, ...
    'ColumnEditable', [true false false false], ...
    'ColumnWidth', {'auto', 100, 50, 56}, 'RowName', {}, 'Data', cell(0, 4), ...
    'SelectionType', 'row', 'Multiselect', 'off', ...
    'SelectionChangedFcn', @(~,evt) on_table_select(evt), ...
    'CellEditCallback', @(~,evt) on_name_edit(evt), ...
    'Tooltip', ['Double-click a name to rename. VIF: variance inflation ' ...
    '(1 = independent, >5 high, >10 severe). SE/' SIGMA ': SD of the ' ...
    'estimated beta per unit noise SD.']);
gCb = uigridlayout(gC, [1 5]);
gCb.ColumnWidth = {28, 28, 28, 28, '1x'};
gCb.Padding = [0 0 0 0];
gCb.ColumnSpacing = 4;
uibutton(gCb, 'Text', '+', 'FontWeight', 'bold', 'Tooltip', 'Add a class from a timing file', ...
    'ButtonPushedFcn', @(~,~) on_add());
uibutton(gCb, 'Text', char(8722), 'FontWeight', 'bold', 'Tooltip', 'Remove the selected class', ...
    'ButtonPushedFcn', @(~,~) remove_class(S.sel));
uibutton(gCb, 'Text', char(8593), 'Tooltip', 'Move the selected class up', ...
    'ButtonPushedFcn', @(~,~) move_class(S.sel, -1));
uibutton(gCb, 'Text', char(8595), 'Tooltip', 'Move the selected class down', ...
    'ButtonPushedFcn', @(~,~) move_class(S.sel, +1));
hCount = uilabel(gCb, 'Text', '', 'HorizontalAlignment', 'right', 'FontColor', GREY);

% Response model (detail of the selected class)
pDet = uipanel(left, 'Title', 'Response model', 'FontWeight', 'bold');
gD = uigridlayout(pDet, [6 3]);
gD.ColumnWidth = {120, '1x', 22};
gD.RowHeight = {24, 24, 24, 24, 80, 'fit'};
gD.Padding = [8 8 8 8];
gD.RowSpacing = 6;
uilabel(gD, 'Text', 'Model');
hModel = uidropdown(gD, 'Items', MODEL_NAMES, 'ItemsData', MODEL_CODES, 'Value', 'GAM', ...
    'ValueChangedFcn', @(~,~) on_model_change());
uilabel(gD, 'Text', '');
hPLab = gobjects(1, 3); hPar = gobjects(1, 3); hPUnit = gobjects(1, 3);
for ipar = 1:3
    hPLab(ipar) = uilabel(gD, 'Text', '');
    hPar(ipar) = uieditfield(gD, 'numeric', 'ValueDisplayFormat', '%.4g', ...
        'ValueChangedFcn', @(~,~) on_param_change());
    hPUnit(ipar) = uilabel(gD, 'Text', '', 'FontColor', GREY);
end
hPrev = uiaxes(gD);
hPrev.Layout.Column = [1 3];
hPrev.Toolbar.Visible = 'off';
disableDefaultInteractivity(hPrev);
hSource = uilabel(gD, 'Text', '', 'FontColor', GREY, 'WordWrap', 'on');
hSource.Layout.Column = [1 3];

% Right: tabs
tabs = uitabgroup(body);
tDesign = uitab(tabs, 'Title', 'Design');
tSim = uitab(tabs, 'Title', 'Simulation', ...
    'Tooltip', 'Available once native estimation is in place');
gS = uigridlayout(tSim, [1 1]);
uilabel(gS, 'Text', {'Simulation and estimation are not available yet.', ...
    'They arrive with the native estimation step (replacing estimatex.m and AFNI).'}, ...
    'HorizontalAlignment', 'center', 'FontColor', GREY);

gR = uigridlayout(tDesign, [1 2]);
gR.ColumnWidth = {150, '1x'};
gR.Padding = [6 6 6 6];
hViews = uilistbox(gR, 'Items', VIEWS, 'Value', 'Regressors', ...
    'ValueChangedFcn', @(~,~) on_view_change());
gP = uigridlayout(gR, [2 1]);
gP.RowHeight = {26, '1x'};
gP.Padding = [0 0 0 0];
gP.RowSpacing = 4;
gO = uigridlayout(gP, [1 3]);
gO.ColumnWidth = {'fit', '1x', 90};
gO.Padding = [0 0 0 0];
hOpt = uicheckbox(gO, 'Text', 'Show stimuli', 'Value', true, ...
    'ValueChangedFcn', @(~,~) on_view_option());
uilabel(gO, 'Text', '');
uibutton(gO, 'Text', 'Pop out', 'Tooltip', 'Open this view in its own window', ...
    'ButtonPushedFcn', @(~,~) on_popout());
hPanel = uipanel(gP, 'BorderType', 'line', 'BackgroundColor', 'w');

% --- status bar
sb = uigridlayout(root, [1 3]);
sb.ColumnWidth = {'1x', 150, 170};
sb.Padding = [10 3 10 3];
sb.BackgroundColor = [0.94 0.94 0.94];
hSum = uilabel(sb, 'Text', '');
hWarn = uilabel(sb, 'Text', '', 'HorizontalAlignment', 'right');
hSaved = uilabel(sb, 'Text', '', 'HorizontalAlignment', 'right', 'FontColor', GREY);

% ------------------------------------------------------------------ API
h.Figure = fig;
h.views = VIEWS;
h.setCfg = @(c) set_cfg(c, 'cfg');
h.getCfg = @get_cfg;
h.getDesign = @get_design;
h.getMetrics = @get_metrics;
h.showView = @show_view;
h.status = @get_status;
h.isDirty = @is_dirty;
h.selectClass = @select_class;
h.addClassFromFile = @add_class_file;
h.importTimingFiles = @import_files;
h.removeClass = @remove_class;
h.moveClass = @move_class;
h.openFile = @open_file;
h.saveTo = @save_to;
h.exportReport = @export_report;
h.newDesign = @new_design;
h.Table = hTable; h.TR = hTR; h.Volumes = hVol; h.Runs = hRuns; h.Baseline = hBase;
h.ViewList = hViews; h.ViewOption = hOpt; h.Model = hModel; h.Params = hPar;
h.Preview = hPrev; h.PlotPanel = hPanel;

update_view_controls();
if nargin >= 1 && ~isempty(cfg)
    set_cfg(cfg, 'cfg');
else
    refresh(false);
end

% ======================================================================
%  Building and drawing
% ======================================================================
    function tool_button(col, text, icon, tip, fcn)
        b = uibutton(tb, 'Text', text, 'Tooltip', tip, 'ButtonPushedFcn', @(~,~) fcn());
        if ~isempty(icon), b.Icon = fullfile(ICONS, icon); end
        b.Layout.Column = col;
    end

    function c = build_cfg()
        c.TR = hTR.Value;
        c.npts = hVol.Value;
        c.num_runs = hRuns.Value;
        c.polort = data_to_polort(hBase.Value);
        K = numel(S.stims);
        if K == 0
            error('estfmri:app:noStims', 'No stimulus classes yet.');
        end
        stims = struct('name', cell(1, K), 'onsets', cell(1, K), 'hrf', cell(1, K));
        runlen = c.npts * c.TR;
        for k = 1:K
            rows = S.stims(k).rows;
            if numel(rows) < c.num_runs
                error('estfmri:app:tooFewRows', ...
                    '"%s" has onsets for %d run(s) but Runs = %d.', ...
                    S.stims(k).name, numel(rows), c.num_runs);
            end
            stims(k).name = S.stims(k).name;
            stims(k).onsets = rows(1:c.num_runs);
            stims(k).hrf = S.stims(k).hrf;
            last = max([rows{1:c.num_runs}, -Inf]);
            if last >= runlen
                warn_late{end+1} = sprintf('%s: onset at %.1f s is after the run ends (%.1f s).', ...
                    S.stims(k).name, last, runlen); %#ok<AGROW>
            end
        end
        c.stims = stims;
    end

    function refresh(markDirty)
        if nargin && markDirty
            S.dirty = true;
        end
        S.alert = '';
        warn_late = {};
        update_auto_item();
        try
            c = build_cfg();
            [S.X, S.labels, S.info] = estfmri.design_matrix(c);
            S.cfg = c;
            S.metrics = estfmri.design_metrics(S.X, S.info);
            m = S.metrics;
            S.error = '';
            S.summary = sprintf('X %d x %d%s%d baseline + %d stimulus columns%scond %.3g', ...
                size(S.X, 1), size(S.X, 2), DOT, S.info.nbase, S.info.nstim, DOT, m.cond);
            if S.info.nstim > 1
                S.summary = [S.summary sprintf('%smax |r| %.2f', DOT, max(m.max_abs_r))];
            end
            msgs = {};
            names = S.labels(S.info.nbase + 1:end);
            for k = find(~strcmp(m.level, 'ok'))
                msgs{end+1} = sprintf('%s: VIF %.1f (%s collinearity)', names{k}, m.vif(k), m.level{k}); %#ok<AGROW>
            end
            S.messages = [msgs, m.warnings, warn_late];
        catch err
            S.cfg = []; S.X = []; S.info = []; S.labels = {}; S.metrics = [];
            S.messages = {};
            if strcmp(err.identifier, 'estfmri:app:noStims')
                S.error = '';
                S.summary = 'No design yet';
            else
                S.error = err.message;
                S.summary = err.message;
            end
        end
        fill_table();
        update_detail();
        update_status();
        update_title();
        render();
    end

    function render()
        update_view_controls();
        if isempty(S.cfg)
            hOpt.Visible = 'off';   % view options only make sense with a design
            if isempty(S.error)
                show_message('Start a design', ...
                    'Import AFNI timing files (one per stimulus class) or open a saved config.', false);
            else
                show_message('The design can''t be built', S.error, true);
            end
            return;
        end
        render_view(hViews.Value, hPanel);
    end

    function render_view(name, parent)
        c = S.cfg; X = S.X; info = S.info; labs = S.labels;
        switch name
            case 'Stimuli'
                estfmri.plot_stimuli(c, 'Parent', parent);
            case 'Onsets'
                estfmri.plot_stimuli(c, 'Style', 'onset', 'Parent', parent);
            case 'HRF shapes'
                estfmri.plot_hrfs(c, 'Parent', parent);
            case 'Regressors'
                estfmri.plot_regressors(c, X, info, 'ShowStimuli', S.opt.showStim, 'Parent', parent);
            case 'Design matrix'
                estfmri.plot_design_matrix(X, labs, info, 'ShowBaseline', S.opt.base, ...
                    'TR', c.TR, 'Parent', parent);
            case 'Correlation'
                estfmri.plot_correlation(X, labs, info, 'ShowBaseline', S.opt.base, 'Parent', parent);
            case 'Design quality'
                estfmri.plot_design_metrics(S.metrics, labs(info.nbase + 1:end), 'Parent', parent);
        end
    end

    function show_message(heading, body, isError)
        delete(hPanel.Children);
        g = uigridlayout(hPanel, [5 3]);
        g.RowHeight = {'1x', 'fit', 'fit', 30, '1x'};
        g.ColumnWidth = {'1x', 420, '1x'};
        g.BackgroundColor = [1 1 1];
        t = uilabel(g, 'Text', heading, 'FontSize', 16, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
        t.Layout.Row = 2; t.Layout.Column = 2;
        b = uilabel(g, 'Text', body, 'WordWrap', 'on', 'HorizontalAlignment', 'center', ...
            'Tag', 'message_body');
        if isError, b.FontColor = RED; else, b.FontColor = GREY; end
        b.Layout.Row = 3; b.Layout.Column = 2;
        gb = uigridlayout(g, [1 2]);
        gb.Padding = [0 0 0 0];
        gb.BackgroundColor = [1 1 1];
        gb.Layout.Row = 4; gb.Layout.Column = 2;
        uibutton(gb, 'Text', 'Import timing files...', 'ButtonPushedFcn', @(~,~) on_import());
        uibutton(gb, 'Text', 'Open config...', 'ButtonPushedFcn', @(~,~) on_open());
    end

    function fill_table()
        K = numel(S.stims);
        data = cell(K, 4);
        removeStyle(hTable);
        m = S.metrics;
        for k = 1:K
            spec = estfmri.parse_hrf(S.stims(k).hrf);
            data{k, 1} = S.stims(k).name;
            data{k, 2} = MODEL_NAMES{strcmp(MODEL_CODES, spec.model)};
            if ~isempty(m)
                data{k, 3} = fmt_num(m.vif(k), '%.2f');
                data{k, 4} = fmt_num(m.se(k), '%.3f');
            else
                data{k, 3} = ''; data{k, 4} = '';
            end
        end
        hTable.Data = data;
        if ~isempty(m)
            col = struct('high', [1 0.86 0.6], 'severe', [1 0.68 0.68]);
            for k = find(~strcmp(m.level, 'ok'))
                addStyle(hTable, uistyle('BackgroundColor', col.(m.level{k})), 'cell', [k 3]);
            end
        end
        if S.sel > K, S.sel = K; end
        if S.sel == 0 && K > 0, S.sel = 1; end
        if S.sel > 0
            hTable.Selection = S.sel;
        else
            hTable.Selection = [];
        end
        hCount.Text = sprintf('%d class%s', K, plural_es(K));
    end

    function update_detail()
        on = S.sel > 0;
        en = matlab.lang.OnOffSwitchState(on);
        hModel.Enable = en;
        for i = 1:3, hPar(i).Enable = en; end
        if ~on
            pDet.Title = 'Response model';
            for i = 1:3
                hPLab(i).Text = ''; hPUnit(i).Text = '';
                hPar(i).Visible = 'off';
            end
            cla(hPrev); hPrev.Visible = 'off'; hSource.Text = '';
            return;
        end
        hPrev.Visible = 'on';
        st = S.stims(S.sel);
        pDet.Title = sprintf('Response model %s %s', char(8212), st.name);
        spec = estfmri.parse_hrf(st.hrf);
        hModel.Value = spec.model;
        [defs, vals] = model_fields(spec);
        for i = 1:3
            if i <= numel(defs)
                hPLab(i).Text = defs(i).label;
                hPUnit(i).Text = defs(i).unit;
                hPar(i).Visible = 'on';
                hPar(i).Limits = [-Inf Inf];
                hPar(i).Value = vals(i);
                hPar(i).Limits = defs(i).limits;
                hPar(i).Tooltip = defs(i).tip;
                gD.RowHeight{1 + i} = 24;
            else
                hPLab(i).Text = ''; hPUnit(i).Text = '';
                hPar(i).Visible = 'off';
                gD.RowHeight{1 + i} = 0;
            end
        end
        t = linspace(0, 30, 601);
        plot(hPrev, t, estfmri.hrf(spec, t), 'LineWidth', 1.5, 'Color', [0.22 0.54 0.87]);
        hPrev.XLim = [0 30];
        hPrev.XTick = 0:10:30; hPrev.YTick = [];
        hPrev.FontSize = 9;
        hPrev.XLabel.String = 's';
        box(hPrev, 'on');
        nrun = min(hRuns.Value, numel(st.rows));
        nev = numel([st.rows{1:nrun}]);
        hSource.Text = sprintf('%s%s%d run row%s in file%s%d events used', st.source, DOT, ...
            numel(st.rows), plural_s(numel(st.rows)), DOT, nev);
    end

    function update_status()
        if ~isempty(S.alert)
            hSum.Text = S.alert; hSum.FontColor = RED;
        elseif ~isempty(S.error)
            hSum.Text = S.error; hSum.FontColor = RED;
        else
            hSum.Text = S.summary; hSum.FontColor = [0 0 0];
        end
        n = numel(S.messages);
        hWarn.Text = sprintf('%d warning%s', n, plural_s(n));
        if n > 0
            hWarn.FontColor = AMBER;
            hWarn.Tooltip = strjoin(S.messages, newline);
        else
            hWarn.FontColor = GREY;
            hWarn.Tooltip = '';
        end
        if S.dirty
            hSaved.Text = 'Unsaved changes';
        elseif ~isempty(S.savedAt)
            hSaved.Text = ['Saved ' char(S.savedAt, 'HH:mm')];
        else
            hSaved.Text = '';
        end
    end

    function update_title()
        star = '';
        if S.dirty, star = ' *'; end
        fig.Name = sprintf('estfmri %s %s%s', char(8212), S.title, star);
    end

    function update_auto_item()
        p = 1 + floor(hVol.Value * hTR.Value / 150);
        items = BASE_NAMES;
        items{2} = sprintf('Auto (order %d)', p);
        hBase.Items = items;
    end

    function update_view_controls()
        v = hViews.Value;
        switch v
            case 'Regressors'
                hOpt.Visible = 'on'; hOpt.Text = 'Show stimuli'; hOpt.Value = S.opt.showStim;
            case {'Design matrix', 'Correlation'}
                hOpt.Visible = 'on'; hOpt.Text = 'Include baseline'; hOpt.Value = S.opt.base;
            otherwise
                hOpt.Visible = 'off';
        end
        for i = 1:numel(VIEWS)
            mViewItems(i).Checked = matlab.lang.OnOffSwitchState(strcmp(VIEWS{i}, v));
        end
    end

% ======================================================================
%  Callbacks
% ======================================================================
    function on_acq()
        refresh(true);
    end

    function on_view_change()
        render();
    end

    function on_view_option()
        if strcmp(hViews.Value, 'Regressors')
            S.opt.showStim = hOpt.Value;
        else
            S.opt.base = hOpt.Value;
        end
        render();
    end

    function on_table_select(evt)
        sel = evt.Selection;
        if isempty(sel), return; end
        S.sel = sel(1);
        update_detail();
    end

    function on_name_edit(evt)
        r = evt.Indices(1);
        name = strtrim(char(evt.NewData));
        others = {S.stims([1:r-1, r+1:end]).name};
        if isempty(name) || ismember(name, others)
            hTable.Data{r, 1} = S.stims(r).name;
            alert('Class names must be non-empty and unique.', 'Rename class');
            return;
        end
        S.stims(r).name = name;
        S.sel = r;
        refresh(true);
    end

    function on_model_change()
        if S.sel == 0, return; end
        spec.model = hModel.Value; spec.params = [];
        [defs, vals] = model_fields(spec);
        S.stims(S.sel).hrf = spec_string(spec.model, vals(1:numel(defs)));
        refresh(true);
    end

    function on_param_change()
        if S.sel == 0, return; end
        spec = estfmri.parse_hrf(S.stims(S.sel).hrf);
        defs = model_fields(spec);
        vals = arrayfun(@(f) f.Value, hPar(1:numel(defs)));
        S.stims(S.sel).hrf = spec_string(spec.model, vals);
        refresh(true);
    end

    function on_new()
        if confirm_discard(), new_design(); end
    end

    function on_open()
        if ~confirm_discard(), return; end
        [f, p] = uigetfile('*.mat', 'Open estfmri config or legacy *_config_file.mat');
        figure(fig);
        if isequal(f, 0), return; end
        try
            open_file(fullfile(p, f));
        catch err
            alert(err.message, 'Open');
        end
    end

    function on_import()
        if ~confirm_discard(), return; end
        [f, p] = uigetfile({'*.1D;*.txt', 'AFNI stim_times (*.1D, *.txt)'}, ...
            'Import timing files (one per stimulus class)', 'MultiSelect', 'on');
        figure(fig);
        if isequal(f, 0), return; end
        try
            import_files(fullfile(p, cellstr(f)));
        catch err
            alert(err.message, 'Import timing files');
        end
    end

    function on_add()
        [f, p] = uigetfile({'*.1D;*.txt', 'AFNI stim_times (*.1D, *.txt)'}, 'Add class from timing file');
        figure(fig);
        if isequal(f, 0), return; end
        try
            add_class_file(fullfile(p, f));
        catch err
            alert(err.message, 'Add class');
        end
    end

    function ok = on_save()
        if isempty(S.file)
            ok = on_save_as();
        else
            ok = do_save(S.file);
        end
    end

    function ok = on_save_as()
        ok = false;
        start = 'estfmri_cfg.mat';
        if ~isempty(S.file), start = S.file; end
        [f, p] = uiputfile('*.mat', 'Save estfmri config', start);
        figure(fig);
        if isequal(f, 0), return; end
        ok = do_save(fullfile(p, f));
    end

    function ok = do_save(path)
        ok = false;
        try
            save_to(path);
            ok = true;
        catch err
            alert(err.message, 'Save');
        end
    end

    function on_export()
        d = uigetdir(pwd, 'Folder for the report');
        figure(fig);
        if isequal(d, 0), return; end
        try
            files = export_report(d);
            S.alert = '';
            hSum.Text = sprintf('Report written: %d files in %s', numel(files), d);
            hSum.FontColor = [0 0 0];
        catch err
            alert(err.message, 'Export report');
        end
    end

    function on_popout()
        if isempty(S.cfg)
            alert('There is no valid design to show.', 'Pop out');
            return;
        end
        f = figure('Name', hViews.Value, 'Color', 'w');
        render_view(hViews.Value, f);
    end

    function on_readme()
        readme = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'README.md');
        if isfile(readme)
            edit(readme);
        else
            alert('README.md was not found next to the estfmri folder.', 'Quick start');
        end
    end

    function on_about()
        msg = sprintf(['estfmri: explore fMRI event-related designs without AFNI.\n' ...
            'Native rebuild of estfmriTOY (R. Martinez-Cancino, 2013-14).\n' ...
            'MATLAB %s'], version('-release'));
        if strcmp(fig.Visible, 'on')
            uialert(fig, msg, 'About estfmri', 'Icon', 'info');
        end
    end

    function on_close()
        if confirm_discard()
            delete(fig);
        end
    end

    function ok = confirm_discard()
        ok = true;
        if ~S.dirty || ~strcmp(fig.Visible, 'on')
            return;
        end
        choice = uiconfirm(fig, sprintf('Save changes to %s?', S.title), 'Unsaved changes', ...
            'Options', {'Save', 'Discard', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 3, ...
            'Icon', 'warning');
        switch choice
            case 'Save',    ok = on_save();
            case 'Discard', ok = true;
            otherwise,      ok = false;
        end
    end

    function alert(msg, ttl)
        S.alert = sprintf('%s: %s', ttl, msg);
        update_status();
        if strcmp(fig.Visible, 'on')
            uialert(fig, msg, ttl);
        end
    end

% ======================================================================
%  Operations (also exposed through h for scripting and tests)
% ======================================================================
    function set_cfg(c, sourceLabel)
        hTR.Value = c.TR;
        hVol.Value = c.npts;
        hRuns.Value = c.num_runs;
        update_auto_item();
        hBase.Value = polort_to_data(c.polort);
        K = numel(c.stims);
        st = struct('name', cell(1, K), 'hrf', cell(1, K), 'rows', cell(1, K), 'source', cell(1, K));
        for k = 1:K
            on = c.stims(k).onsets;
            if ~iscell(on), on = {on}; end
            st(k).name = c.stims(k).name;
            spec = estfmri.parse_hrf(c.stims(k).hrf);   % validates the string
            st(k).hrf = spec.str;
            st(k).rows = on;
            st(k).source = sourceLabel;
        end
        S.stims = st;
        S.sel = min(1, K);
        refresh(false);
    end

    function import_files(paths)
        paths = cellstr(paths);
        st = struct('name', {}, 'hrf', {}, 'rows', {}, 'source', {});
        for k = 1:numel(paths)
            st(k) = class_from_file(paths{k}, {st.name}); %#ok<AGROW>
        end
        S.stims = st;
        S.sel = min(1, numel(st));
        S.file = ''; S.title = 'Untitled'; S.savedAt = [];
        refresh(true);
    end

    function add_class_file(path)
        S.stims(end+1) = class_from_file(path, {S.stims.name});
        S.sel = numel(S.stims);
        refresh(true);
    end

    function remove_class(k)
        if k < 1 || k > numel(S.stims), return; end
        S.stims(k) = [];
        S.sel = min(k, numel(S.stims));
        refresh(true);
    end

    function move_class(k, d)
        j = k + d;
        if k < 1 || j < 1 || j > numel(S.stims), return; end
        S.stims([k j]) = S.stims([j k]);
        S.sel = j;
        refresh(true);
    end

    function select_class(k)
        if k < 1 || k > numel(S.stims)
            error('estfmri:app:badClass', 'No class %d.', k);
        end
        S.sel = k;
        hTable.Selection = k;
        update_detail();
    end

    function open_file(path)
        s = load(path);
        [~, name, ext] = fileparts(path);
        if isfield(s, 'cfg')
            set_cfg(s.cfg, [name ext]);
            S.file = path;
        elseif isfield(s, 'opts')
            tdir = fullfile(fileparts(path), 'timings');
            if ~isfolder(tdir)
                if ~strcmp(fig.Visible, 'on')
                    error('estfmri:app:noTimings', 'No "timings" folder next to %s.', [name ext]);
                end
                tdir = uigetdir(fileparts(path), 'Folder with the timing files');
                figure(fig);
                if isequal(tdir, 0), return; end
            end
            set_cfg(estfmri.cfg_from_legacy_opts(s.opts, tdir), [name ext ' (legacy)']);
            S.file = '';   % saving writes the new format, so ask for a name
        else
            error('estfmri:app:badFile', '%s holds neither ''cfg'' nor ''opts''.', [name ext]);
        end
        S.title = [name ext];
        S.dirty = false; S.savedAt = [];
        update_status(); update_title();
    end

    function save_to(path)
        if isempty(S.cfg)
            error('estfmri:app:nothingToSave', 'The current design is not valid, so there is nothing to save.');
        end
        out.cfg = S.cfg;
        save(path, '-struct', 'out');
        [~, name, ext] = fileparts(path);
        S.file = path; S.title = [name ext];
        S.dirty = false; S.savedAt = datetime('now');
        update_status(); update_title();
    end

    function files = export_report(folder)
        if isempty(S.cfg)
            error('estfmri:app:nothingToExport', 'The current design is not valid, so there is nothing to export.');
        end
        if ~isfolder(folder), mkdir(folder); end
        files = {};
        out.cfg = S.cfg;
        files{end+1} = fullfile(folder, 'estfmri_cfg.mat');
        save(files{end}, '-struct', 'out');
        for i = 1:numel(VIEWS)
            f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1100 700]);
            c = onCleanup(@() close(f));
            render_view(VIEWS{i}, f);
            files{end+1} = fullfile(folder, [lower(strrep(VIEWS{i}, ' ', '_')) '.png']); %#ok<AGROW>
            exportgraphics(f, files{end}, 'Resolution', 110);
            clear c
        end
        files{end+1} = fullfile(folder, 'summary.txt');
        write_summary(files{end});
    end

    function write_summary(path)
        m = S.metrics; c = S.cfg;
        fid = fopen(path, 'w');
        cl = onCleanup(@() fclose(fid));
        fprintf(fid, 'estfmri design summary (%s)\n\n', char(datetime('now'), 'yyyy-MM-dd HH:mm'));
        fprintf(fid, 'TR %.4g s, %d volumes per run, %d run(s), baseline %s\n', ...
            c.TR, c.npts, c.num_runs, hBase.Items{strcmp(hBase.ItemsData, hBase.Value)});
        fprintf(fid, 'X: %d x %d (%d baseline, %d stimulus), cond %.4g, rank %d\n\n', ...
            size(S.X, 1), size(S.X, 2), S.info.nbase, S.info.nstim, m.cond, m.rank);
        fprintf(fid, '%-16s %-16s %8s %8s %10s %8s  %s\n', 'class', 'model', 'VIF', 'SE/sd', ...
            'efficiency', 'max|r|', 'level');
        for k = 1:S.info.nstim
            fprintf(fid, '%-16s %-16s %8.3f %8.4f %10.3f %8.3f  %s\n', c.stims(k).name, ...
                c.stims(k).hrf, m.vif(k), m.se(k), m.efficiency(k), m.max_abs_r(k), m.level{k});
        end
        if ~isempty(S.messages)
            fprintf(fid, '\nWarnings:\n');
            fprintf(fid, '  %s\n', S.messages{:});
        end
    end

    function new_design()
        S.stims = struct('name', {}, 'hrf', {}, 'rows', {}, 'source', {});
        S.sel = 0; S.file = ''; S.title = 'Untitled'; S.dirty = false; S.savedAt = [];
        refresh(false);
    end

% ======================================================================
%  Getters
% ======================================================================
    function c = get_cfg()
        c = S.cfg;
    end

    function [X, labs, info] = get_design()
        X = S.X; labs = S.labels; info = S.info;
    end

    function m = get_metrics()
        m = S.metrics;
    end

    function t = get_status()
        parts = {S.summary};
        if ~isempty(S.alert), parts = [{S.alert}, parts]; end
        t = strjoin([parts, S.messages], newline);
    end

    function d = is_dirty()
        d = S.dirty;
    end

    function show_view(name)
        if ~ismember(name, VIEWS)
            error('estfmri:app:badView', 'Unknown view "%s".', name);
        end
        hViews.Value = name;
        render();
    end
end

% ========================================================================
%  Local helpers (no access to app state)
% ========================================================================
function st = class_from_file(path, existingNames)
rows = estfmri.read_timings(path);
if isempty(rows)
    error('estfmri:app:emptyTimings', '%s contains no onset rows.', path);
end
[~, name, ext] = fileparts(path);
base = name; n = 1;
while ismember(name, existingNames)
    n = n + 1;
    name = sprintf('%s_%d', base, n);
end
st.name = name;
st.hrf = 'GAM(8.6,0.547)';
st.rows = rows;
st.source = [base ext];
end

function [defs, vals] = model_fields(spec)
% Field definitions and current values for a parsed HRF spec.
prm = spec.params;
f = @(label, unit, lim, tip) struct('label', label, 'unit', unit, 'limits', lim, 'tip', tip);
switch spec.model
    case 'BLOCK'
        defs = [f('Duration', 's', [0.001 Inf], 'Stimulus duration d'), ...
                f('Peak height', '', [0 Inf], 'Peak of the response; 0 = unscaled (AFNI BLOCK(d))')];
        vals = [getp(prm, 1, 1), getp(prm, 2, 1)];
        if isscalar(prm), vals(2) = 0; end
    case 'GAM'
        defs = [f('Shape p', '', [0.1 Inf], 'Gamma shape; peak at p*q seconds'), ...
                f('Scale q', 's', [0.01 Inf], 'Gamma scale'), ...
                f('Duration', 's', [0 Inf], 'Stimulus duration; 0 = brief event')];
        vals = [getp(prm, 1, 8.6), getp(prm, 2, 0.547), getp(prm, 3, 0)];
    otherwise   % MION, MIONN
        defs = f('Duration', 's', [0.001 Inf], 'Stimulus duration d');
        vals = getp(prm, 1, 1);
end
end

function v = getp(prm, i, default)
if numel(prm) >= i, v = prm(i); else, v = default; end
end

function s = spec_string(model, vals)
switch model
    case 'BLOCK'
        if vals(2) > 0
            s = sprintf('BLOCK(%g,%g)', vals(1), vals(2));
        else
            s = sprintf('BLOCK(%g)', vals(1));
        end
    case 'GAM'
        if numel(vals) >= 3 && vals(3) > 0
            s = sprintf('GAM(%g,%g,%g)', vals(1), vals(2), vals(3));
        else
            s = sprintf('GAM(%g,%g)', vals(1), vals(2));
        end
    otherwise
        s = sprintf('%s(%g)', model, vals(1));
end
end

function t = fmt_num(x, fmt)
if isfinite(x), t = sprintf(fmt, x); else, t = 'Inf'; end
end

function d = polort_to_data(p)
if ischar(p) || isstring(p)
    s = upper(strtrim(char(p)));
    if any(strcmp(s, {'-1', 'NONE'})), d = '-1'; else, d = s; end
elseif p < 0
    d = '-1';
else
    d = num2str(p);
end
end

function p = data_to_polort(d)
if strcmp(d, 'A'), p = 'A'; else, p = str2double(d); end
end

function s = plural_s(n)
if n == 1, s = ''; else, s = 's'; end
end

function s = plural_es(n)
if n == 1, s = ''; else, s = 'es'; end
end
