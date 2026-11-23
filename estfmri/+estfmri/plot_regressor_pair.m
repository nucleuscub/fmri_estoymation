function [fig, stats] = plot_regressor_pair(X, i, j, labels)
%PLOT_REGRESSOR_PAIR Compare two regressors: scatter + linear fit + time courses.
%   [fig, stats] = estfmri.plot_regressor_pair(X, i, j, labels)
%   Plots column j against column i with the least-squares line
%   X(:,j) ~ slope*X(:,i) + intercept and the identity line, and both time
%   courses underneath. stats has fields r, slope, intercept.
%   Replaces the legacy regplot.m (no Deep Learning Toolbox needed).

if nargin < 4 || isempty(labels)
    labels = arrayfun(@(k) sprintf('Reg_%d', k), 1:size(X, 2), 'UniformOutput', false);
end
x = X(:, i);
y = X(:, j);
c = corrcoef(x, y);
pf = polyfit(x, y, 1);
stats.r = c(1, 2);
stats.slope = pf(1);
stats.intercept = pf(2);

fig = figure('Name', sprintf('%s vs %s', labels{j}, labels{i}), 'Color', 'w');
tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tl, 1);
lim = [min([x; y]), max([x; y])];
if diff(lim) == 0, lim = lim + [-1 1]; end
hold(ax1, 'on');
plot(ax1, x, y, 'o', 'MarkerSize', 4, 'Tag', 'data');
plot(ax1, lim, polyval(pf, lim), 'r-', 'LineWidth', 1.5, 'Tag', 'fit');
plot(ax1, lim, lim, 'k:', 'Tag', 'identity');
hold(ax1, 'off');
axis(ax1, 'square'); xlim(ax1, lim); ylim(ax1, lim); box(ax1, 'on'); grid(ax1, 'on');
xlabel(ax1, labels{i}, 'Interpreter', 'none');
ylabel(ax1, labels{j}, 'Interpreter', 'none');
title(ax1, sprintf('r = %.3f   y = %.2fx %+.2f', stats.r, stats.slope, stats.intercept));
legend(ax1, {'Samples', 'Fit', 'y = x'}, 'Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off');

ax2 = nexttile(tl, 2, [1 2]);
plot(ax2, [x y], 'LineWidth', 1.2);
legend(ax2, labels([i j]), 'Interpreter', 'none', 'Box', 'off');
xlabel(ax2, 'Sample'); xlim(ax2, [1 numel(x)]); grid(ax2, 'on'); box(ax2, 'on');
title(ax2, 'Time courses');
end
