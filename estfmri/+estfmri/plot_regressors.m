function fig = plot_regressors(cfg, X, info, varargin)
%PLOT_REGRESSORS Plot the convolved stimulus regressors of X.
%   fig = estfmri.plot_regressors(cfg, X, info)
%   fig = estfmri.plot_regressors(cfg, X, info, 'ShowStimuli', true, 'Stims', [1 2])
%   X, info come from estfmri.design_matrix(cfg). One tile per class plus
%   an 'All' overlay; with 'ShowStimuli' the stimulus boxcars are drawn
%   underneath in grey.

ip = inputParser;
ip.addParameter('ShowStimuli', false, @islogical);
ip.addParameter('Stims', 1:info.nstim, @isnumeric);
ip.parse(varargin{:});
idx = ip.Results.Stims(:)';
showStim = ip.Results.ShowStimuli;

S = X(:, info.nbase + 1:end);
t = (0:size(X, 1)-1)' * cfg.TR;
total = cfg.npts * cfg.TR * cfg.num_runs;
K = numel(idx);
cmap = lines(max(K, 1));
ymax = max(1, max(max(S(:, idx)))) * 1.05;
ymin = min(0, min(min(S(:, idx)))) * 1.05;

fig = figure('Name', 'Convolved regressors', 'Color', 'w');
tl = tiledlayout(fig, K + 1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
if showStim
    title(tl, 'Convolved regressors + stimuli');
else
    title(tl, 'Convolved regressors');
end

for n = 1:K
    k = idx(n);
    ax = nexttile(tl);
    hold(ax, 'on');
    if showStim
        draw_stim(ax, cfg, k);
    end
    plot(ax, t, S(:, k), 'Color', cmap(n, :), 'LineWidth', 1.5, 'Tag', 'regressor');
    hold(ax, 'off');
    format_axes(ax, cfg, total, ymin, ymax);
    ylabel(ax, cfg.stims(k).name, 'Interpreter', 'none');
    set(ax, 'XTickLabel', []);
end
ax = nexttile(tl);
hold(ax, 'on');
for n = 1:K
    plot(ax, t, S(:, idx(n)), 'Color', cmap(n, :), 'LineWidth', 1.2, 'Tag', 'regressor');
end
hold(ax, 'off');
format_axes(ax, cfg, total, ymin, ymax);
ylabel(ax, 'All');
xlabel(ax, 'Time (s)');
end

% ---------------------------------------------------------------------------
function draw_stim(ax, cfg, k)
runlen = cfg.npts * cfg.TR;
on = cfg.stims(k).onsets;
if ~iscell(on), on = {on}; end
d = estfmri.stim_duration(cfg.stims(k).hrf);
for r = 1:numel(on)
    for o = on{r}(:)'
        a = (r-1)*runlen + o;
        patch(ax, [a a+d a+d a], [0 0 1 1], [0.8 0.8 0.8], ...
            'EdgeColor', 'none', 'Tag', 'stimulus', 'HandleVisibility', 'off');
    end
end
end

function format_axes(ax, cfg, total, ymin, ymax)
xlim(ax, [0 total]);
ylim(ax, [ymin ymax]);
set(ax, 'TickLabelInterpreter', 'none', 'Box', 'on');
grid(ax, 'on');
estfmri.mark_runs(ax, cfg);
end
