function fig = plot_design_matrix(X, labels, info, varargin)
%PLOT_DESIGN_MATRIX Image of the design matrix.
%   fig = estfmri.plot_design_matrix(X, labels, info)
%   fig = estfmri.plot_design_matrix(X, labels, info, 'ShowBaseline', true, 'TR', 2)
%   By default only the stimulus columns are shown (as the legacy GUI did).
%   With 'TR' the vertical axis is time in seconds, otherwise sample index.

ip = inputParser;
ip.addParameter('ShowBaseline', false, @islogical);
ip.addParameter('TR', [], @(x) isempty(x) || isscalar(x));
ip.parse(varargin{:});

cols = select_columns(info, ip.Results.ShowBaseline);
Xp = X(:, cols);
labs = labels(cols);

fig = figure('Name', 'Design matrix', 'Color', 'w');
ax = axes(fig);
if isempty(ip.Results.TR)
    y = 1:size(X, 1);
    ylab = 'Sample';
else
    y = (0:size(X, 1)-1) * ip.Results.TR;
    ylab = 'Time (s)';
end
imagesc(ax, 1:numel(cols), y, Xp);
colormap(ax, parula);
colorbar(ax);
set(ax, 'XTick', 1:numel(cols), 'XTickLabel', labs, 'XTickLabelRotation', 45, ...
    'TickLabelInterpreter', 'none');
xlabel(ax, 'Regressor');
ylabel(ax, ylab);
title(ax, 'Design matrix');
end

function cols = select_columns(info, showBase)
if showBase
    cols = 1:(info.nbase + info.nstim);
else
    cols = info.nbase + (1:info.nstim);
end
end
