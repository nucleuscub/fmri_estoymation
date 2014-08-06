function pushbutton_regadd_func(hObject,handles)
% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Feb 2014
% -------------------------------------------------------------------------

% 1- Getting variables selected from listbox_reg
index_selected = get(handles.listbox_ref,'Value');
reg_list = get(handles.listbox_ref,'String');
sel_reg = reg_list{index_selected};

% % 2- getting plot selected in popupmenu_selectplot
% list_plot   = get(handles.popupmenu_selectplot_ref,'String');
% index_plot  = get(handles.popupmenu_selectplot_ref,'Value');
% plot_type =list_plot{index_plot};

if ~isfield(handles,'c_cmap')
    handles.c_cmap = 1;
    guidata(hObject,handles);
end

% 3-  Then plotting 'Stimulus Convolved'


% Adding Reg to list box
reg_list2 = get(handles.listbox_reg,'String');
if isempty(reg_list2)
    
    X = handles.opts.X;
    Xtemp = X(:,(end - handles.opts.num_stim) + 1: end) ;
    
    handles.betas_plot_hand = plot_signals_stims_conv(Xtemp,handles);
    handles.betas_reg = Xtemp(:,index_selected);
    handles.betas_color = handles.c_cmap;
    handles.betas_beta  = handles.opts.beta(index_selected);
    
    set(handles.slider_beta,'value',handles.opts.beta(index_selected));
    set(handles.edit_beta,'String', handles.opts.beta(index_selected));
    
    set(handles.listbox_reg,'String', sel_reg);
else
    % Check if exist
    for i = 1:size(reg_list2,1)
        exist_reg(i) = strcmp(reg_list2(i,:),sel_reg);
    end
    if sum(exist_reg) == 1
        return;
    else
        
        X = handles.opts.X;
        Xtemp = X(:,(end - handles.opts.num_stim) + 1: end) ;
        handles.betas_plot_hand(size(reg_list2,1) + 1) = plot_signals_stims_conv(Xtemp,handles);
        handles.betas_reg(:,size(reg_list2,1) + 1)       = Xtemp(:,index_selected);
        handles.betas_color(size(reg_list2,1) + 1) = handles.c_cmap;
        handles.betas_beta(size(reg_list2,1) + 1)  = handles.opts.beta(index_selected);
        
        count = size(reg_list2,1) + 1;
%         reg_listed = {reg_list2; sel_reg};
        reg_listed = cellstr(get(handles.listbox_reg,'String'));
        reg_listed{count} = sel_reg;
        set(handles.listbox_reg,'String', reg_listed);
        
    end
end


handles.c_cmap = handles.c_cmap + 1;
guidata(hObject,handles);