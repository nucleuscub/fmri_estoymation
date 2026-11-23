function spec = parse_hrf(str)
%PARSE_HRF Parse an AFNI-style HRF model string.
%   spec = estfmri.parse_hrf('BLOCK(0.75,1)') returns a struct with fields
%   .model  (upper-case model name: 'GAM', 'BLOCK', 'MION' or 'MIONN')
%   .params (row vector of numeric parameters, possibly empty)
%   .str    (the original string, trimmed)

str = strtrim(char(str));
tok = regexp(str, '^([A-Za-z]+)\s*\((.*)\)$', 'tokens', 'once');
if isempty(tok)
    % No parentheses: bare model name, e.g. 'GAM'
    tok = regexp(str, '^([A-Za-z]+)$', 'tokens', 'once');
    if isempty(tok)
        error('estfmri:parse_hrf:badString', 'Cannot parse HRF string "%s".', str);
    end
    tok{2} = '';
end

spec.model = upper(tok{1});
spec.str   = str;
if isempty(strtrim(tok{2}))
    spec.params = [];
else
    parts = strsplit(tok{2}, ',');
    spec.params = cellfun(@str2double, parts);
    if any(isnan(spec.params))
        error('estfmri:parse_hrf:badParams', 'Non-numeric parameter in "%s".', str);
    end
end

known = {'GAM', 'BLOCK', 'MION', 'MIONN'};
if ~ismember(spec.model, known)
    error('estfmri:parse_hrf:unknownModel', ...
        'Unsupported HRF model "%s" (supported: %s).', spec.model, strjoin(known, ', '));
end
end
