function pushbutton_save_mainfunc(handles)
%customtimes_main( handles): generate options for simulations based in
%provided timings files.

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

if isfield(handles,'simresult')
    opts = handles.opts;
    save([opts.prefix '_config_file'], 'opts');       % Saving configuration
end