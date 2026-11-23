function [X, labels, info] = design_matrix(cfg)
%DESIGN_MATRIX Build the GLM design matrix without AFNI.
%   [X, labels, info] = estfmri.design_matrix(cfg)
%   cfg fields:
%     TR, npts (points per run), num_runs
%     polort            -1 | 'A' | integer degree
%     stims(k).name     regressor name
%     stims(k).onsets   cell {num_runs x 1} of run-local onsets (s)
%     stims(k).hrf      HRF string, e.g. 'BLOCK(0.75,1)'
%   Column order matches AFNI 3dDeconvolve -x1D: baseline columns first,
%   then one column per stimulus class (so X(:, end-K+1:end) are the
%   stimulus regressors). info.nbase / info.nstim give the column counts.

[B, blabels] = estfmri.baseline(cfg.npts, cfg.num_runs, cfg.polort, cfg.TR);

K = numel(cfg.stims);
S = zeros(cfg.npts * cfg.num_runs, K);
slabels = cell(1, K);
for k = 1:K
    on = cfg.stims(k).onsets;
    if ~iscell(on), on = {on}; end
    if numel(on) ~= cfg.num_runs
        error('estfmri:design_matrix:runMismatch', ...
            'Stimulus "%s" has %d runs of onsets but cfg.num_runs = %d.', ...
            cfg.stims(k).name, numel(on), cfg.num_runs);
    end
    S(:, k) = estfmri.stim_regressor(on, cfg.stims(k).hrf, cfg.TR, cfg.npts);
    slabels{k} = cfg.stims(k).name;
end

X = [B, S];
labels = [blabels, slabels];
info.nbase = size(B, 2);
info.nstim = K;
end
