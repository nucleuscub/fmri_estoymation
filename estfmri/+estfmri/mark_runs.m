function h = mark_runs(ax, cfg)
%MARK_RUNS Draw dashed vertical lines at run boundaries (time axis in s).
%   h = estfmri.mark_runs(ax, cfg) returns the line handles (empty for 1 run).
%   Lines are tagged 'run_boundary' and hidden from legends.
h = gobjects(0);
runlen = cfg.npts * cfg.TR;
for r = 1:cfg.num_runs-1
    h(end+1) = xline(ax, r * runlen, '--', 'Color', [0.4 0.4 0.4], ...
        'Tag', 'run_boundary', 'HandleVisibility', 'off'); %#ok<AGROW>
end
end
