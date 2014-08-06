function [simresult,opts] = set_guidata_beta_gui(handles)
% retieving data from 'simulator' gui and setting that data in the this
% gui

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Feb 2014
% -------------------------------------------------------------------------

% Detrieving data
simresult = getappdata(0,'simresult');
opts      = getappdata(0,'opts');

% Setting data
for i = 1: opts.iter
    sgn_names{i} = [num2str(i) '-   Signal_' num2str(i) ];
end

set(handles.listbox_signals,'String',sgn_names);                           %listbox_signals
set(handles.listbox_reg,'String', []);
set(handles.listbox_ref,'String', opts.regnames);

set(handles.axes,'box','on');
set(handles.axes,'YtickLabel',[]);
grid on;

