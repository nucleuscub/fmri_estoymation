%DEMO_DESIGN_VIEWS All design-stage views for the tutorial, without GUIDE.
%   run('estfmri/examples/demo_design_views.m')
%   Builds X for the bundled tutorial design and shows every design view.
%   PNG copies are written to <tempdir>/estfmri_design_views/.

here   = fileparts(mfilename('fullpath'));
repo   = fileparts(fileparts(here));
addpath(fullfile(repo, 'estfmri'));

cfg = estfmri.tutorial();
[X, labels, info] = estfmri.design_matrix(cfg);

figs = struct();
figs.stimuli        = estfmri.plot_stimuli(cfg);
figs.onsets         = estfmri.plot_stimuli(cfg, 'Style', 'onset');
figs.hrfs           = estfmri.plot_hrfs(cfg);
figs.regressors     = estfmri.plot_regressors(cfg, X, info, 'ShowStimuli', true);
figs.design_matrix  = estfmri.plot_design_matrix(X, labels, info, 'TR', cfg.TR);
[figs.correlation, R] = estfmri.plot_correlation(X, labels, info);
figs.pair           = estfmri.plot_regressor_pair(X, 1, 3, labels);

disp('Regressor correlation (r):');
disp(array2table(R, 'VariableNames', labels(info.nbase+1:end), ...
    'RowNames', labels(info.nbase+1:end)));

outdir = fullfile(tempdir, 'estfmri_design_views');
if ~isfolder(outdir), mkdir(outdir); end
names = fieldnames(figs);
for i = 1:numel(names)
    f = figs.(names{i});
    f.Position(3:4) = [1000 650];
    exportgraphics(f, fullfile(outdir, [names{i} '.png']), 'Resolution', 110);
end
fprintf('Saved %d PNGs to %s\n', numel(names), outdir);
