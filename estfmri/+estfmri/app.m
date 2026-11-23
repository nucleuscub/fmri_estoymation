function h = app(cfg, varargin)
%APP Front-end window for estfmri (no GUIDE, no AFNI).
%   estfmri.app            opens an empty window
%   estfmri.app(cfg)       opens it with a cfg struct (see design_matrix)
%   h = estfmri.app(..., 'Visible', 'off')   for scripting/tests
%
%   Design tab (left: experiment, right: plots):
%     - 'Load timing files...' picks AFNI .1D stim_times files (one class
%       per file, one row per run).
%     - 'Open config...' loads a .mat holding either a native 'cfg' or a
%       legacy estfmriTOY 'opts' (timing files are looked up in a 'timings'
%       folder next to the .mat, else you are asked for the folder).
%     - 'Save config...' writes the current cfg (onsets included).
%     - TR, points per run, runs, baseline (polort) and, per class, the
%       name, HRF model and its parameters. Every edit rebuilds X and
%       redraws the selected view.
%   Simulation tab: placeholder until native estimation exists.
%
%   Returned struct h (for scripting and tests):
%     h.Figure, h.setCfg(cfg), h.getCfg(), h.getDesign() -> [X,labels,info],
%     h.showView(name), h.views (cell of view names), h.status() -> text,
%     h.Table, h.PlotPanel, h.TR, h.Npts, h.Runs, h.Polort.

ip = inputParser;
ip.addParameter('Visible', 'on');
ip.parse(varargin{:});

VIEWS = {'Stimuli', 'Onsets', 'Response models (HRFs)', 'Regressors', ...
    'Regressors + stimuli', 'Design matrix', 'Correlation', 'Design metrics'};
MODELS = {'GAM', 'BLOCK', 'MION', 'MIONN'};
POLORTS = {'None', 'A', '0', '1', '2', '3', '4', '5'};

% ---------------------------------------------------------------- state
S.rows   = {};      % per class: cell of onset rows (one per run in file)
S.files  = {};      % per class: source description
S.X      = [];
S.labels = {};
S.info   = [];
S.metrics = [];
S.cfg    = [];
S.error  = '';
warn_late = {};     % shared by build_cfg/refresh (nested-function scope)

% ---------------------------------------------------------------- layout
fig = uifigure('Name', 'estfmri', 'Position', [80 80 1280 760], ...
    'Visible', ip.Results.Visible);
main = uigridlayout(fig, [1 2]);
main.ColumnWidth = {480, '1x'};

% Left: experiment
L = uigridlayout(main, [11 2]);
L.RowHeight = {22, 28, 28, 10, 24, 24, 24, 24, 22, '1x', 60};
L.ColumnWidth = {'1x', '1x'};

lbl = uilabel(L, 'Text', 'Experiment', 'FontWeight', 'bold', 'FontSize', 14);
lbl.Layout.Row = 1; lbl.Layout.Column = [1 2];

bLoad = uibutton(L, 'Text', 'Load timing files...', 'ButtonPushedFcn', @(~,~) on_load_timings());
bLoad.Layout.Row = 2; bLoad.Layout.Column = [1 2];
bOpen = uibutton(L, 'Text', 'Open config...', 'ButtonPushedFcn', @(~,~) on_open());
bOpen.Layout.Row = 3; bOpen.Layout.Column = 1;
bSave = uibutton(L, 'Text', 'Save config...', 'ButtonPushedFcn', @(~,~) on_save());
bSave.Layout.Row = 3; bSave.Layout.Column = 2;

hTR    = labelled_field(5, 'TR (s)', 2);
hNpts  = labelled_field(6, 'Points per run', 200);
hRuns  = labelled_field(7, 'Runs', 1);
hNpts.RoundFractionalValues = 'on';
hRuns.RoundFractionalValues = 'on';
hTR.Limits = [0.01 Inf]; hNpts.Limits = [1 Inf]; hRuns.Limits = [1 Inf];

l = uilabel(L, 'Text', 'Baseline (polort)'); l.Layout.Row = 8; l.Layout.Column = 1;
hPol = uidropdown(L, 'Items', POLORTS, 'Value', 'None', 'ValueChangedFcn', @(~,~) refresh());
hPol.Layout.Row = 8; hPol.Layout.Column = 2;

l = uilabel(L, 'Text', 'Stimulus classes (edit name, HRF, parameters)', 'FontWeight', 'bold');
l.Layout.Row = 9; l.Layout.Column = [1 2];

% VIF and SE/sigma (SD of beta per unit noise SD) are filled by refresh().
hTable = uitable(L, 'ColumnName', {'Name', 'HRF', 'Params', 'VIF', ['SE/' char(963)], 'Source'}, ...
    'ColumnEditable', [true true true false false false], ...
    'ColumnFormat', {'char', MODELS, 'char', 'char', 'char', 'char'}, ...
    'ColumnWidth', {80, 70, 75, 45, 50, 'auto'}, ...
    'RowName', {}, 'Data', cell(0, 6), ...
    'CellEditCallback', @on_table_edit);
hTable.Layout.Row = 10; hTable.Layout.Column = [1 2];

hStatus = uitextarea(L, 'Editable', 'off', 'Value', {'Load timing files or open a config.'});
hStatus.Layout.Row = 11; hStatus.Layout.Column = [1 2];

% Right: tabs
tg = uitabgroup(main);
tDesign = uitab(tg, 'Title', 'Design');
tSim    = uitab(tg, 'Title', 'Simulation');

R = uigridlayout(tDesign, [2 1]);
R.RowHeight = {30, '1x'};
C = uigridlayout(R, [1 4]);
C.ColumnWidth = {200, 130, 150, '1x'};
C.Padding = [0 0 0 0];
hView = uidropdown(C, 'Items', VIEWS, 'Value', 'Regressors + stimuli', ...
    'ValueChangedFcn', @(~,~) render());
hBase = uicheckbox(C, 'Text', 'Show baseline', 'ValueChangedFcn', @(~,~) render());
uibutton(C, 'Text', 'Open in window', 'ButtonPushedFcn', @(~,~) render([]));
hPanel = uipanel(R, 'BorderType', 'none', 'BackgroundColor', 'w');

Ls = uigridlayout(tSim, [1 1]);
uilabel(Ls, 'Text', {'Simulation and estimation are not available yet.', ...
    'They arrive with the native estimation slice (replacing estimatex.m / AFNI).'}, ...
    'HorizontalAlignment', 'center', 'FontColor', [0.4 0.4 0.4]);

% ---------------------------------------------------------------- API
h.Figure    = fig;
h.views     = VIEWS;
h.setCfg    = @set_cfg;
h.getCfg    = @get_cfg;       % nested handles see live state
h.getDesign = @get_design;
h.getMetrics = @get_metrics;
h.showView  = @show_view;
h.status    = @get_status;
h.Table     = hTable;
h.PlotPanel = hPanel;
h.TR = hTR; h.Npts = hNpts; h.Runs = hRuns; h.Polort = hPol;

if nargin >= 1 && ~isempty(cfg)
    set_cfg(cfg);
end

% ================================================================ helpers
    function f = labelled_field(row, text, value)
        lb = uilabel(L, 'Text', text);
        lb.Layout.Row = row; lb.Layout.Column = 1;
        f = uieditfield(L, 'numeric', 'Value', value, 'ValueChangedFcn', @(~,~) refresh());
        f.Layout.Row = row; f.Layout.Column = 2;
    end

    function set_cfg(c)
        hTR.Value = c.TR;
        hNpts.Value = c.npts;
        hRuns.Value = c.num_runs;
        hPol.Value = polort_to_item(c.polort);
        K = numel(c.stims);
        data = cell(K, 6);
        S.rows = cell(1, K);
        S.files = cell(1, K);
        for k = 1:K
            spec = estfmri.parse_hrf(c.stims(k).hrf);
            on = c.stims(k).onsets;
            if ~iscell(on), on = {on}; end
            S.rows{k} = on;
            S.files{k} = sprintf('cfg (%d run rows)', numel(on));
            data(k, :) = {c.stims(k).name, spec.model, params_to_text(spec.params), '', '', S.files{k}};
        end
        hTable.Data = data;
        refresh();
    end

    function c = get_cfg()
        c = S.cfg;
    end

    function [X, labs, info] = get_design()
        X = S.X; labs = S.labels; info = S.info;
    end

    function t = get_status()
        t = strjoin(cellstr(hStatus.Value), newline);
    end

    function show_view(name)
        if ~ismember(name, VIEWS)
            error('estfmri:app:badView', 'Unknown view "%s".', name);
        end
        hView.Value = name;
        render();
    end

    function c = build_cfg()
        c.TR = hTR.Value;
        c.npts = hNpts.Value;
        c.num_runs = hRuns.Value;
        c.polort = item_to_polort(hPol.Value);
        data = hTable.Data;
        K = size(data, 1);
        if K == 0
            error('estfmri:app:noStims', 'No stimulus classes: load timing files or a config.');
        end
        stims = struct('name', cell(1, K), 'onsets', cell(1, K), 'hrf', cell(1, K));
        for k = 1:K
            rows = S.rows{k};
            if numel(rows) < c.num_runs
                error('estfmri:app:tooFewRows', ...
                    '"%s" has %d run row(s) but Runs = %d.', data{k, 1}, numel(rows), c.num_runs);
            end
            stims(k).name = data{k, 1};
            stims(k).onsets = rows(1:c.num_runs);
            stims(k).hrf = hrf_string(data{k, 2}, data{k, 3});
            last = max([rows{1:c.num_runs}, -Inf]);
            if last >= c.npts * c.TR
                warn_late{end+1} = sprintf('%s: onset %.1f s is past the run end (%.1f s).', ...
                    data{k, 1}, last, c.npts * c.TR); %#ok<AGROW>
            end
        end
        c.stims = stims;
    end

    function refresh()
        warn_late = {};   % reset shared list; build_cfg appends to it
        try
            c = build_cfg();
            [S.X, S.labels, S.info] = estfmri.design_matrix(c);
            S.cfg = c;
            S.error = '';
            S.metrics = estfmri.design_metrics(S.X, S.info);
            m = S.metrics;
            msg = {sprintf('X: %d samples x %d columns (%d baseline, %d stimulus).', ...
                size(S.X, 1), size(S.X, 2), S.info.nbase, S.info.nstim), ...
                sprintf('cond(X) = %s', num2str(m.cond, 4))};
            if S.info.nstim > 1
                msg{end+1} = sprintf('Max |r| between stimulus regressors: %.2f', max(m.max_abs_r));
            end
            names = S.labels(S.info.nbase + 1:end);
            for k = find(~strcmp(m.level, 'ok'))
                msg{end+1} = sprintf('%s: VIF %.1f (%s collinearity)', names{k}, m.vif(k), m.level{k}); %#ok<AGROW>
            end
            fill_metrics_columns();
            hStatus.Value = [msg, m.warnings, warn_late];
            hStatus.FontColor = [0 0 0];
            render();
        catch err
            S.cfg = []; S.X = []; S.info = []; S.labels = {}; S.metrics = [];
            clear_metrics_columns();
            S.error = err.message;
            hStatus.Value = {err.message};
            hStatus.FontColor = [0.75 0 0];
            delete(hPanel.Children);
        end
    end

    function render(parent)
        if nargin < 1, parent = hPanel; end
        if isempty(S.cfg)
            return;
        end
        c = S.cfg; X = S.X; info = S.info; labs = S.labels;
        base = hBase.Value;
        switch hView.Value
            case 'Stimuli'
                estfmri.plot_stimuli(c, 'Parent', parent);
            case 'Onsets'
                estfmri.plot_stimuli(c, 'Style', 'onset', 'Parent', parent);
            case 'Response models (HRFs)'
                estfmri.plot_hrfs(c, 'Parent', parent);
            case 'Regressors'
                estfmri.plot_regressors(c, X, info, 'Parent', parent);
            case 'Regressors + stimuli'
                estfmri.plot_regressors(c, X, info, 'ShowStimuli', true, 'Parent', parent);
            case 'Design matrix'
                estfmri.plot_design_matrix(X, labs, info, 'ShowBaseline', base, 'TR', c.TR, 'Parent', parent);
            case 'Correlation'
                estfmri.plot_correlation(X, labs, info, 'ShowBaseline', base, 'Parent', parent);
            case 'Design metrics'
                estfmri.plot_design_metrics(S.metrics, labs(info.nbase + 1:end), 'Parent', parent);
        end
    end

    function fill_metrics_columns()
        m = S.metrics;
        data = hTable.Data;
        removeStyle(hTable);
        colours = struct('high', [1 0.85 0.55], 'severe', [1 0.6 0.6]);
        for k = 1:size(data, 1)
            data{k, 4} = fmt_num(m.vif(k), '%.2f');
            data{k, 5} = fmt_num(m.se(k), '%.3f');
            if ~strcmp(m.level{k}, 'ok')
                addStyle(hTable, uistyle('BackgroundColor', colours.(m.level{k})), 'cell', [k 4]);
            end
        end
        hTable.Data = data;
    end

    function clear_metrics_columns()
        data = hTable.Data;
        if isempty(data), return; end
        data(:, 4:5) = {''};
        hTable.Data = data;
        removeStyle(hTable);
    end

    function m = get_metrics()
        m = S.metrics;
    end

    function alert(msg, ttl)
        % uialert needs a visible window; otherwise report in the status box.
        hStatus.Value = {sprintf('%s: %s', ttl, msg)};
        hStatus.FontColor = [0.75 0 0];
        if strcmp(fig.Visible, 'on')
            uialert(fig, msg, ttl);
        end
    end

    % ------------------------------------------------------------ callbacks
    function on_table_edit(src, evt)
        r = evt.Indices(1); col = evt.Indices(2);
        data = src.Data;
        if col == 2
            % new model: reset parameters to its defaults
            data{r, 3} = default_params(data{r, 2});
        end
        if col == 1 && isempty(strtrim(data{r, 1}))
            data{r, 1} = evt.PreviousData;
        end
        try
            estfmri.parse_hrf(hrf_string(data{r, 2}, data{r, 3}));
        catch err
            data{r, col} = evt.PreviousData;
            src.Data = data;
            alert(err.message, 'Invalid HRF');
            return;
        end
        src.Data = data;
        refresh();
    end

    function on_load_timings()
        [f, p] = uigetfile({'*.1D;*.txt', 'AFNI stim_times (*.1D, *.txt)'}, ...
            'Select timing files (one per stimulus class)', 'MultiSelect', 'on');
        figure(fig);
        if isequal(f, 0), return; end
        f = cellstr(f);
        K = numel(f);
        data = cell(K, 6);
        S.rows = cell(1, K);
        S.files = cell(1, K);
        for k = 1:K
            try
                rows = estfmri.read_timings(fullfile(p, f{k}));
            catch err
                alert(sprintf('%s: %s', f{k}, err.message), 'Cannot read timing file');
                return;
            end
            [~, name] = fileparts(f{k});
            S.rows{k} = rows;
            S.files{k} = sprintf('%s (%d rows)', f{k}, numel(rows));
            data(k, :) = {name, 'GAM', default_params('GAM'), '', '', S.files{k}};
        end
        hTable.Data = data;
        refresh();
    end

    function on_open()
        [f, p] = uigetfile('*.mat', 'Open estfmri cfg or legacy config');
        figure(fig);
        if isequal(f, 0), return; end
        try
            s = load(fullfile(p, f));
            if isfield(s, 'cfg')
                set_cfg(s.cfg);
            elseif isfield(s, 'opts')
                tdir = fullfile(p, 'timings');
                if ~isfolder(tdir)
                    tdir = uigetdir(p, 'Folder with the timing files');
                    figure(fig);
                    if isequal(tdir, 0), return; end
                end
                set_cfg(estfmri.cfg_from_legacy_opts(s.opts, tdir));
            else
                error('estfmri:app:badFile', '%s holds neither ''cfg'' nor ''opts''.', f);
            end
        catch err
            alert(err.message, 'Cannot open config');
        end
    end

    function on_save()
        if isempty(S.cfg)
            alert('Nothing to save: the current design is not valid.', 'Save config');
            return;
        end
        [f, p] = uiputfile('*.mat', 'Save estfmri cfg', 'estfmri_cfg.mat');
        figure(fig);
        if isequal(f, 0), return; end
        out.cfg = S.cfg;
        save(fullfile(p, f), '-struct', 'out');
        hStatus.Value = [hStatus.Value(:)', {sprintf('Saved %s', fullfile(p, f))}];
    end
end

% ==================================================================== local
function s = hrf_string(model, params)
params = strtrim(char(params));
if isempty(params)
    s = model;
else
    s = sprintf('%s(%s)', model, params);
end
end

function t = fmt_num(x, fmt)
if isfinite(x), t = sprintf(fmt, x); else, t = 'Inf'; end
end

function t = params_to_text(p)
t = strjoin(arrayfun(@(x) num2str(x, 6), p, 'UniformOutput', false), ',');
end

function p = default_params(model)
switch model
    case 'GAM',   p = '8.6,0.547';
    case 'BLOCK', p = '1,1';
    otherwise,    p = '1';
end
end

function item = polort_to_item(p)
if ischar(p) || isstring(p)
    s = upper(strtrim(char(p)));
    if strcmp(s, '-1') || strcmp(s, 'NONE'), item = 'None'; else, item = s; end
elseif p < 0
    item = 'None';
else
    item = num2str(p);
end
end

function p = item_to_polort(item)
switch item
    case 'None', p = -1;
    case 'A',    p = 'A';
    otherwise,   p = str2double(item);
end
end
