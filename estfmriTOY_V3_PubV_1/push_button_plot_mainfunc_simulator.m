function push_button_plot_mainfunc_simulator(handles)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

% 1- Getting variables selected from listbox_reg
index_selected = get(handles.listbox_reg,'Value');
reg_list = get(handles.listbox_reg,'String');
sel_reg = reg_list{index_selected};

% 2- getting plot selected in popupmenu_selectplot
list_plot   = get(handles.popupmenu_selectplot,'String');
index_plot  = get(handles.popupmenu_selectplot,'Value');
plot_type =list_plot{index_plot};

name = get(handles.listbox_reg,'String');

% 3-  Then plotting each case

switch plot_type
    case 'Select Plot'
        msgbox('Select Plot','Error');
% -------------------------------------------------------------------------    
    case 'Reg+Signals'  % temporal for LUIZ
        
        X_est     = handles.simresult.X_est;
        betas_est = handles.simresult.betas_est;
        signal_wn = handles.simresult.signal_wn;
        signal    = handles.simresult.signal;
        opts      = handles.opts;
        opts.iter = handles.iter;
        
        set(gcf,'NumberTitle','off') %don't show the figure number
        set(gcf,'Name','Signals with Noise + Real Signal') %select the name you want
        
        plot_reg_signals(X_est,betas_est,signal_wn,signal,opts,index_selected,name(index_selected));
% -------------------------------------------------------------------------
    case 'Signal PLUS'
        
        setappdata(0,'simresult',handles.simresult);
        setappdata(0,'opts',handles.opts);
        
        Signal_PLUS;
        
    case 'Betas play'
        
        setappdata(0,'simresult',handles.simresult);
        setappdata(0,'opts',handles.opts);
        betas_play;
        
    case 'MSE partial model'
       
        X_est2     = handles.simresult.X_est2;
        betas_est2 = handles.simresult.betas_est2;
        
        X_est1     = handles.simresult.X_est;
        betas_est1 = handles.simresult.betas_est;
        
        signal_wn = handles.simresult.signal_wn;
        signal    = handles.simresult.signal;
        opts      = handles.opts;
        opts.iter = handles.iter;
        
        plot_sme_partialmodel(X_est1,X_est2,betas_est1,betas_est2,signal,opts);
        
        set(gcf,'NumberTitle','off') %don't show the figure number
        set(gcf,'Name','MSE Partial Model') %select the name you want
        
        
    case 'Partial model signal'
        
        X_est     = handles.simresult.X_est2;
        betas_est = handles.simresult.betas_est2;
        signal_wn = handles.simresult.signal_wn;
        signal    = handles.simresult.signal;
        opts      = handles.opts;
        opts.iter = handles.iter;

        plot_all_sgnnoise_realsgn(X_est,betas_est,signal_wn,signal,opts);
        
        set(gcf,'NumberTitle','off') %don't show the figure number
        set(gcf,'Name','Partial Model Signal') %select the name you want
        
    case 'Est Betas histogram'
        plot_betahist(handles.simresult.betas_est2,handles.opts.beta(index_selected),handles.regname(index_selected));
        
        set(gcf,'NumberTitle','off') %don't show the figure number
        set(gcf,'Name','Est Betas histogram') %select the name you want
        
    case 'Signals with Noise + Real Signal'
        X_est     = handles.simresult.X_est;
        betas_est = handles.simresult.betas_est;
        signal_wn = handles.simresult.signal_wn;
        signal    = handles.simresult.signal;
        opts      = handles.opts;
        opts.iter = handles.iter;
        
        set(gcf,'NumberTitle','off') %don't show the figure number
        set(gcf,'Name','Signals with Noise + Real Signal') %select the name you want
        
        plot_all_sgnnoise_realsgn(X_est,betas_est,signal_wn,signal,opts);
    
    case 'All Est Betas histogram '
        
        betas_est_temp = handles.simresult.betas_est((end - handles.num_stim) + 1: end,:) ;
        
        plot_betahist(handles.simresult.betas_est,handles.opts.beta,handles.regname);
        set(gcf,'NumberTitle','off') %don't show the figure number
        set(gcf,'Name','All Est Betas histogram') %select the name you want       

end

