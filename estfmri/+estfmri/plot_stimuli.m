function fig = plot_stimuli(cfg, varargin)
%PLOT_STIMULI Plot stimulus timing per class (boxcars or onset sticks).
%   fig = estfmri.plot_stimuli(cfg)
%   fig = estfmri.plot_stimuli(cfg, 'Style', 'onset', 'Stims', [1 3])
%   Options:
%     'Style' : 'boxcar' (default; onset..onset+duration, duration from
%               estfmri.stim_duration) or 'onset' (unit sticks at onsets)
%     'Stims' : indices into cfg.stims to show (default: all)
%   One tile per class plus an 'All' overlay. Time in seconds over the
%   concatenated runs; dashed lines mark run boundaries.

ip = inputParser;
ip.addParameter('Style', 'boxcar', @(s) any(strcmpi(s, {'boxcar', 'onset'})));
ip.addParameter('Stims', 1:numel(cfg.stims), @isnumeric);
ip.parse(varargin{:});
style = lower(ip.Results.Style);
idx = ip.Results.Stims(:)';

K = numel(idx);
runlen = cfg.npts * cfg.TR;
total = runlen * cfg.num_runs;
cmap = lines(max(K, 1));

fig = figure('Name', sprintf('Stimuli (%s)', style), 'Color', 'w');
tl = tiledlayout(fig, K + 1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
if strcmp(style, 'boxcar')
    title(tl, 'Stimulus');
else
    title(tl, 'Stimulus onset');
end

for n = 1:K
    k = idx(n);
    [tx, ty] = stim_trace(cfg, k, style);
    ax = nexttile(tl);
    plot(ax, tx, ty, 'Color', cmap(n, :), 'LineWidth', 1.5);
    format_axes(ax, cfg, total);
    ylabel(ax, cfg.stims(k).name, 'Interpreter', 'none');
    set(ax, 'XTickLabel', []);
end
axAll = nexttile(tl);
hold(axAll, 'on');
for n = 1:K
    [tx, ty] = stim_trace(cfg, idx(n), style);
    plot(axAll, tx, ty, 'Color', cmap(n, :), 'LineWidth', 1.5);
end
hold(axAll, 'off');
format_axes(axAll, cfg, total);
ylabel(axAll, 'All');
xlabel(axAll, 'Time (s)');
end

% ---------------------------------------------------------------------------
function [tx, ty] = stim_trace(cfg, k, style)
% Exact piecewise-linear trace (NaN-free) over the concatenated runs.
runlen = cfg.npts * cfg.TR;
on = cfg.stims(k).onsets;
if ~iscell(on), on = {on}; end
if strcmp(style, 'boxcar')
    d = estfmri.stim_duration(cfg.stims(k).hrf);
end
tx = 0; ty = 0;
for r = 1:numel(on)
    t0 = (r-1) * runlen;
    for o = sort(on{r}(:))'
        a = t0 + o;
        if strcmp(style, 'boxcar')
            b = min(a + d, t0 + runlen);
            tx = [tx, a, a, b, b]; %#ok<AGROW>
            ty = [ty, 0, 1, 1, 0]; %#ok<AGROW>
        else
            tx = [tx, a, a, a]; %#ok<AGROW>
            ty = [ty, 0, 1, 0]; %#ok<AGROW>
        end
    end
end
tx = [tx, numel(on) * runlen];
ty = [ty, 0];
end

function format_axes(ax, cfg, total)
xlim(ax, [0 total]);
ylim(ax, [0 1.1]);
set(ax, 'YTick', [0 1], 'TickLabelInterpreter', 'none', 'Box', 'on');
grid(ax, 'on');
estfmri.mark_runs(ax, cfg);
end
