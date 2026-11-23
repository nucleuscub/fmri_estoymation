%DEMO_DESIGN_MATRIX Build the tutorial design matrix without AFNI or GUIDE.
%   Run from anywhere:  run('estfmri/examples/demo_design_matrix.m')
%   Rebuilds X for ER_tutorial_config_file.mat natively, compares it with the
%   X that AFNI produced (stored in the config), and plots both.

here   = fileparts(mfilename('fullpath'));
repo   = fileparts(fileparts(here));
legacy = fullfile(repo, 'estfmriTOY_V3_PubV_1');
addpath(fullfile(repo, 'estfmri'));

s = load(fullfile(legacy, 'ER_tutorial_config_file.mat'));
cfg = estfmri.cfg_from_legacy_opts(s.opts, fullfile(legacy, 'timings'));
[X, labels] = estfmri.design_matrix(cfg);

fprintf('Native X: %d x %d   max |X - X_afni| = %.2g\n', ...
    size(X, 1), size(X, 2), max(abs(X(:) - s.opts.X(:))));

t = (0:size(X, 1)-1) * cfg.TR;
figure('Name', 'estfmri design matrix', 'Color', 'w');

subplot(1, 3, 1);
imagesc(1:size(X, 2), t, X);
colorbar; xlabel('Regressor'); ylabel('Time (s)');
set(gca, 'XTick', 1:size(X, 2), 'XTickLabel', labels, 'XTickLabelRotation', 45, ...
    'TickLabelInterpreter', 'none');
title('Design matrix (native)');

subplot(1, 3, [2 3]);
nk = size(X, 2);
off = 1.5 * (0:nk-1);
plot(t, X + off, 'LineWidth', 1.2); hold on;
plot(t, s.opts.X + off, 'k:', 'LineWidth', 1);
hold off;
set(gca, 'YTick', off, 'YTickLabel', labels, 'TickLabelInterpreter', 'none');
xlabel('Time (s)'); xlim([t(1) t(end)]);
title('Regressors: native (colour) vs AFNI (dotted)');
