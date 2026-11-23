function fig = plot_design_metrics(m, names, varargin)
%PLOT_DESIGN_METRICS Bar charts of VIF and SE-per-unit-noise per regressor.
%   fig = estfmri.plot_design_metrics(m, names)
%   m from estfmri.design_metrics, names = stimulus regressor names.
%   Left: VIF with reference lines at 5 (high) and 10 (severe), bars
%   coloured ok / high / severe. Right: SD of beta_hat per unit noise SD.
%   Option 'Parent': figure/uipanel/uitab to draw into (default: new figure).

ip = inputParser;
ip.addParameter('Parent', [], @(p) isempty(p) || isgraphics(p));
ip.parse(varargin{:});

K = numel(names);
C.ok = [0.30 0.60 0.85]; C.high = [0.95 0.65 0.15]; C.severe = [0.85 0.20 0.20];

[ctr, fig] = estfmri.prepare_container(ip.Results.Parent, 'Design metrics');
tl = tiledlayout(ctr, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('Design quality   (cond(X) = %s, rank %d/%d)', ...
    num2str(m.cond, 4), m.rank, m.ncols));

% --- VIF -------------------------------------------------------------------
ax1 = nexttile(tl);
v = m.vif;
vplot = v; vplot(~isfinite(vplot)) = max([10.5, vplot(isfinite(vplot)) * 1.1]);
b = bar(ax1, 1:K, vplot, 'FaceColor', 'flat', 'Tag', 'vif_bars');
for k = 1:K
    b.CData(k, :) = C.(m.level{k});
end
hold(ax1, 'on');
yline(ax1, 5, '--', 'high', 'Color', C.high, 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
yline(ax1, 10, '--', 'severe', 'Color', C.severe, 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
hold(ax1, 'off');
for k = 1:K
    if isfinite(v(k)), txt = sprintf('%.2f', v(k)); else, txt = 'Inf'; end
    text(ax1, k, vplot(k), txt, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end
ylim(ax1, [0, max([11, vplot * 1.15])]);
set(ax1, 'XTick', 1:K, 'XTickLabel', names, 'XTickLabelRotation', 30, ...
    'TickLabelInterpreter', 'none', 'Box', 'on');
grid(ax1, 'on');
ylabel(ax1, 'VIF');
title(ax1, 'Variance inflation (1 = independent)');

% --- SE per unit noise -------------------------------------------------------
ax2 = nexttile(tl);
se = m.se;
splot = se; splot(~isfinite(splot)) = 0;
bar(ax2, 1:K, splot, 'FaceColor', [0.45 0.45 0.55], 'Tag', 'se_bars');
for k = 1:K
    if isfinite(se(k)), txt = sprintf('%.3f', se(k)); else, txt = 'not estimable'; end
    text(ax2, k, splot(k), txt, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end
top = max(splot);
if top <= 0, top = 1; end
ylim(ax2, [0, top * 1.2]);
set(ax2, 'XTick', 1:K, 'XTickLabel', names, 'XTickLabelRotation', 30, ...
    'TickLabelInterpreter', 'none', 'Box', 'on');
grid(ax2, 'on');
ylabel(ax2, 'SD(\beta) / \sigma_{noise}');
title(ax2, 'Beta uncertainty per unit noise (lower is better)');
end
