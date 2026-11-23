function onsets = read_timings(filename)
%READ_TIMINGS Read an AFNI -stim_times file (one row per run, onsets in s).
%   onsets = estfmri.read_timings(filename) returns a column cell array with
%   one row vector of onsets per non-blank line. Ragged rows are allowed and
%   a line holding only '*' marks a run with no events (empty vector).
%   Comment lines starting with '#' are skipped.

txt = fileread(filename);
lines = regexp(txt, '\r?\n', 'split');
onsets = {};
for i = 1:numel(lines)
    ln = strtrim(lines{i});
    if isempty(ln) || ln(1) == '#'
        continue;
    end
    ln = strrep(ln, '*', ' ');
    vals = sscanf(ln, '%f')';
    onsets{end+1, 1} = vals; %#ok<AGROW>
end
end
