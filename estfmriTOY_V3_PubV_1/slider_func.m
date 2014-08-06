function slider_func(hObject,handles)
% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Feb 2014
% -------------------------------------------------------------------------

% 1- Getting variables selected from listbox_reg
index_selected = get(handles.listbox_reg,'Value');
reg_list = get(handles.listbox_reg,'String');
sel_reg = reg_list(index_selected,:);

% Get slider value
bval = get(hObject,'Value');

% Delete signal selected
delete(handles.betas_plot_hand(index_selected));

% replot signal with new beta
plt_count = 0;                                           % Initializing Plot counter
hold on;

nstims     =length(index_selected);                                   % Getting Number of stimulus
cmap       = hsv(10);                                                 % Vector of colors

num_runs   = handles.opts.num_runs;           % No runs
npts       = handles.opts.npts;               % npts
TR         = handles.opts.TR;                 % TR
beta       = handles.opts.beta;               % beta

handles.betas_plot_hand(index_selected) = plot(bval*handles.betas_reg(:,index_selected),'Color',cmap(handles.betas_color(index_selected),:),'LineWidth',2);
grid on;
hold off;

%
set(handles.edit_beta,'String', num2str(bval))
handles.betas_beta(index_selected) = bval;
% update hanldes
guidata(hObject,handles);
