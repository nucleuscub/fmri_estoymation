function  pushbutton_loadsim_mainfunc(hObject,handles)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------
% Loading  Configuration File
[FileName,PathName,Ext]= uigetfile('*.mat');

try
    load([PathName FileName]);
    
    set(handles.edit_loadsim,'String',[PathName filesep FileName Ext],'ForegroundColor',[0 0 0]);        % 1- edit Loadsim
    set(handles.text_loadsim,'String',FileName(1:end-16),'ForegroundColor',[0 0 0]);                     % 2- text Loadsim (length('_config_fil.mat') = 16)
    
    if isfield(opts,'iter')
        set(handles.edit_iter,'String',opts.iter,'ForegroundColor',[0 0 0]);                             % 3- edit iter
        handles.iter = opts.iter;
    else
        set(handles.edit_iter,'String',25,'ForegroundColor',[0 0 0]);                                    
    end
        
    set(handles.edit_snr,'String',opts.snr,'ForegroundColor',[0 0 0]);                                   % 4- edit snr
    
    % 5-  POLORT 
    list = {'None'; 'A'; '2'; '3'; '4'; '5'};
    
    if opts.polort_gen == -1
        set(handles.popupmenu_polort_est,'Value',1);
    else
        polort = find(opts.polort_gen==char(list));
        set(handles.popupmenu_polort_est,'Value',polort);
    end
    
    % 6- HRFs
    handles.hrfs_est = opts.handles.hrfs_gen_temp;
    set(handles.popupmenu_hrf_est,'Value',opts.hrf_gen_value);
    
    % 7-  HRFs Listbox
    regnames = opts.handles.regname;
    
    for i = 1:size(opts.handles.timings,1)
        hrflist_temp{i} = [ regnames{i} '   ' opts.hrf_gen{i}];
    end
    
    hrflist_text    = cell(1,length(hrflist_temp) + 1);
    hrflist_text{1} = 'All';
    hrflist_text(2:end) = hrflist_temp;
    
    %hrflist_text{end+1} = 'All';
    set(handles.listbox_hrf,'String', hrflist_text)
    
    % 8- Data
    if isfield(opts,'datasim')
        regtemp = regnames;
        regtemp{end + 1} = 'All';
        set(handles.listbox_reg,'String',regtemp)
    end
    
    % 9- Sim load
    if isfield(opts,'simresult')
        handles.simresult = opts.simresult;
        
        % Update Reg ListBox
        if opts.index_selected ~= opts.isAll
            regtemp = handles.regname(opts.index_selected);
        else
            regtemp = regnames;
        end
        regtemp{end + 1} = 'All';
        set(handles.listbox_reg,'String',regtemp);
    else
        set(handles.listbox_reg,'String','No Simulations loaded');
    end
    
    
    
    % Other vars to set up
    
    handles.regname  = opts.handles.regname;
    handles.num_stim = size(opts.handles.timings,1);
    handles.timings  = opts.handles.timings;
    handles.opts     = opts;
    guidata(hObject,handles) ;
    
catch err
    return;
end