function [cfg, X_afni, folder] = tutorial()
%TUTORIAL Load the bundled tutorial design.
%   cfg = estfmri.tutorial()
%   [cfg, X_afni, folder] = estfmri.tutorial()
%   cfg     : native cfg (4 classes S_cue, S_pict, T_cue, T_pict; TR 2 s,
%             210 volumes, 1 run, BLOCK responses, no baseline)
%   X_afni  : the design matrix AFNI 3dDeconvolve produced for this design
%             (reference used to validate estfmri.design_matrix)
%   folder  : estfmri/data/tutorial (timing files are in its 'timings' folder)

folder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data', 'tutorial');
s = load(fullfile(folder, 'tutorial_cfg.mat'));
cfg = s.cfg;
if nargout > 1
    r = load(fullfile(folder, 'ER_tutorial_config_file.mat'));
    X_afni = r.opts.X;
end
end
