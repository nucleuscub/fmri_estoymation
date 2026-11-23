function [fig, R] = plot_correlation(X, labels, info, varargin)
%PLOT_CORRELATION Regressor correlation matrix (|r|) with click-to-inspect.
%   [fig, R] = estfmri.plot_correlation(X, labels, info)
%   [fig, R] = estfmri.plot_correlation(X, labels, info, 'ShowBaseline', true)
%   Shows |corrcoef| of the selected columns on a fixed [0 1] scale, with
%   the r values (signed) written in the upper triangle and the regressor
%   names on the diagonal. Clicking an off-diagonal cell opens
%   estfmri.plot_regressor_pair for that pair. R is the signed matrix.
%   Constant columns (e.g. a Pol#0 baseline) give NaN correlations.

ip = inputParser;
ip.addParameter('ShowBaseline', false, @islogical);
ip.parse(varargin{:});

if ip.Results.ShowBaseline
    cols = 1:(info.nbase + info.nstim);
else
    cols = info.nbase + (1:info.nstim);
end
Xp = X(:, cols);
labs = labels(cols);
n = numel(cols);
R = corrcoef(Xp);

fig = figure('Name', 'Regressor correlation', 'Color', 'w');
ax = axes(fig);
im = imagesc(ax, abs(R), [0 1]);
im.Tag = 'corr_image';
colormap(ax, parula);
cb = colorbar(ax);
cb.Label.String = '|r|';
axis(ax, 'square');
set(ax, 'XTick', 1:n, 'YTick', 1:n, 'XTickLabel', labs, 'YTickLabel', labs, ...
    'XTickLabelRotation', 45, 'TickLabelInterpreter', 'none');
title(ax, {'Regressor correlation', '(click a cell to compare the pair)'});

for i = 1:n
    for j = 1:n
        if j > i
            txt = sprintf('%.2f', R(i, j));
        elseif j == i
            txt = '';
        else
            continue;
        end
        if isnan(R(i, j)), txt = 'NaN'; end
        if j ~= i
            c = 'k';
            if abs(R(i, j)) < 0.5, c = 'w'; end
            text(ax, j, i, txt, 'HorizontalAlignment', 'center', 'Color', c, ...
                'FontWeight', 'bold', 'Tag', 'corr_value', 'HitTest', 'off');
        end
    end
end

im.ButtonDownFcn = @(src, evt) on_click(evt, X, cols, labels, n);
end

function on_click(evt, X, cols, labels, n)
p = round(evt.IntersectionPoint(1:2));   % [x y] = [col row]
j = p(1); i = p(2);
if i < 1 || j < 1 || i > n || j > n || i == j
    return;
end
estfmri.plot_regressor_pair(X, cols(j), cols(i), labels);
end
