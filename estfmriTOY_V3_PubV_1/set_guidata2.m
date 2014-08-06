function [simresult,opts] = set_guidata2(handles)
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

sgn_est_names{1} = 'Select Plot';
for i = 2: opts.num_stim + 1
    sgn_est_names{i} = [opts.regnames{i-1} ' (est)'];
end
sgn_est_names{i+1} = 'Signal (est)';


set(handles.listbox_signals,'String',sgn_names);                           %listbox_signals
set(handles.listbox_signals_est,'String',sgn_names);                       %listbox_signals
set(handles.listbox_ref,'String', opts.regnames);
set(handles.popupmenu_est,'String',sgn_est_names);
set(handles.listbox_plots,'String',[]);

set(handles.axes,'box','on');
set(handles.axes,'YtickLabel',[]);
grid on;

