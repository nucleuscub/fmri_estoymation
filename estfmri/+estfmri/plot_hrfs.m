function fig = plot_hrfs(cfg, varargin)
%PLOT_HRFS Plot the response-curve shape used for each stimulus class.
%   fig = estfmri.plot_hrfs(cfg)
%   fig = estfmri.plot_hrfs(cfg, 'TMax', 40)
%   Each class's HRF is evaluated for a single event at t = 0 over
%   [0, TMax] seconds (default 30), with its duration shaded.

ip = inputParser;
ip.addParameter('TMax', 30, @(x) isscalar(x) && x > 0);
ip.parse(varargin{:});

t = linspace(0, ip.Results.TMax, 3001);
K = numel(cfg.stims);
cmap = lines(max(K, 1));

fig = figure('Name', 'HRFs', 'Color', 'w');
ax = axes(fig);
hold(ax, 'on');
names = cell(1, K);
for k = 1:K
    h = estfmri.hrf(cfg.stims(k).hrf, t);
    plot(ax, t, h, 'Color', cmap(k, :), 'LineWidth', 1.5, 'Tag', 'hrf');
    names{k} = sprintf('%s  %s', cfg.stims(k).name, cfg.stims(k).hrf);
end
yline(ax, 0, ':', 'HandleVisibility', 'off');
hold(ax, 'off');
xlim(ax, [0 ip.Results.TMax]);
grid(ax, 'on'); box(ax, 'on');
xlabel(ax, 'Time after onset (s)');
ylabel(ax, 'Response');
title(ax, 'Response model per stimulus class');
legend(ax, names, 'Interpreter', 'none', 'Box', 'off', 'Location', 'northeast');
end
