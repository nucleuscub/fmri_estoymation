function cfg = cfg_from_legacy_opts(opts, timings_dir)
%CFG_FROM_LEGACY_OPTS Convert a legacy estfmriTOY opts struct to a cfg struct.
%   cfg = estfmri.cfg_from_legacy_opts(opts, timings_dir)
%     opts        : the 'opts' struct saved in <prefix>_config_file.mat
%     timings_dir : folder holding the timing files. The legacy configs store
%                   absolute Linux paths; only the file names are kept and
%                   looked up in timings_dir.
%   AFNI reads one row of a -stim_times file per run, so only the first
%   opts.num_runs rows of each file are used (extra rows are ignored, as
%   in the tutorial config: 1 run, 6-row files, AFNI used row 1).

cfg.TR       = opts.TR;
cfg.npts     = opts.npts;
cfg.num_runs = opts.num_runs;
cfg.polort   = opts.polort_gen;

files = cellstr(opts.timings);
K = numel(files);
if numel(opts.hrf_gen) ~= K
    error('estfmri:cfg_from_legacy_opts:hrfMismatch', ...
        '%d timing files but %d HRFs.', K, numel(opts.hrf_gen));
end

stims = struct('name', cell(1, K), 'onsets', cell(1, K), 'hrf', cell(1, K));
for k = 1:K
    legacy = strtrim(files{k});
    parts = regexp(legacy, '[\\/]', 'split');
    fname = parts{end};
    path = fullfile(timings_dir, fname);
    if ~isfile(path)
        error('estfmri:cfg_from_legacy_opts:missingTimings', ...
            'Timing file "%s" not found in %s.', fname, timings_dir);
    end
    rows = estfmri.read_timings(path);
    if numel(rows) < cfg.num_runs
        error('estfmri:cfg_from_legacy_opts:tooFewRows', ...
            '%s has %d rows but num_runs = %d.', fname, numel(rows), cfg.num_runs);
    end
    [~, name] = fileparts(fname);
    if isfield(opts, 'regnames') && numel(opts.regnames) >= k
        name = opts.regnames{k};
    end
    stims(k).name   = name;
    stims(k).onsets = rows(1:cfg.num_runs);
    stims(k).hrf    = strtrim(opts.hrf_gen{k});
end
cfg.stims = stims;
end
