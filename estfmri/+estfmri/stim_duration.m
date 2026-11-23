function d = stim_duration(hrfspec)
%STIM_DURATION Display duration (s) of a stimulus for a given HRF model.
%   d = estfmri.stim_duration('BLOCK(0.75,1)')  % -> 0.75
%   Used only to draw stimulus boxcars. Follows the legacy HRF dialog:
%     BLOCK(d,...), MION(d), MIONN(d) -> d
%     GAM(p,q,d)                      -> d
%     GAM(p,q) / GAM                  -> 2.3*sqrt(p)*q  (approx. FWHM)

if ~isstruct(hrfspec)
    hrfspec = estfmri.parse_hrf(hrfspec);
end
prm = hrfspec.params;
switch hrfspec.model
    case {'BLOCK', 'MION', 'MIONN'}
        d = prm(1);
    case 'GAM'
        p = 8.6; q = 0.547;
        if numel(prm) >= 1, p = prm(1); end
        if numel(prm) >= 2, q = prm(2); end
        if numel(prm) >= 3 && prm(3) > 0
            d = prm(3);
        else
            d = 2.3 * sqrt(p) * q;
        end
end
end
