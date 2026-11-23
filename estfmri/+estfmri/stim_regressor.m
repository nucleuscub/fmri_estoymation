function x = stim_regressor(onsets, hrfspec, TR, npts)
%STIM_REGRESSOR Build one convolved stimulus regressor over concatenated runs.
%   x = estfmri.stim_regressor(onsets, hrfspec, TR, npts)
%     onsets  : cell array, one vector of run-local onset times (s) per run
%     hrfspec : HRF string (e.g. 'BLOCK(0.75,1)') or struct from parse_hrf
%     TR      : repetition time (s)
%     npts    : number of time points per run
%   Returns a column vector of length npts*numel(onsets). Sample i of a run
%   is taken at time (i-1)*TR; each run's response is the sum of the HRF
%   shifted to every onset in that run, and does not spill into the next run.

if ~iscell(onsets)
    onsets = {onsets};
end
if ~isstruct(hrfspec)
    hrfspec = estfmri.parse_hrf(hrfspec);
end

t = (0:npts-1)' * TR;
nruns = numel(onsets);
x = zeros(npts * nruns, 1);
for r = 1:nruns
    xr = zeros(npts, 1);
    for o = onsets{r}(:)'
        xr = xr + estfmri.hrf(hrfspec, t - o);
    end
    x((r-1)*npts + (1:npts)) = xr;
end
end
