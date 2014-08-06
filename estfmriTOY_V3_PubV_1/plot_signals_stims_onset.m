function h = plot_signals_stims_onset(handles,~)
% Plot stimulus (Subplot Stimulus from timings files)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

plt_count = 0;                                           % Initializing Plot counter
% hold on;

index_selected = get(handles.listbox_ref,'Value');                    %Getting variables selected from listbox_reg
reg_list = get(handles.listbox_ref,'String');
sel_ref = reg_list(index_selected);

nstims     =length(index_selected);                                   % Getting Number of stimulus
cmap       = hsv(15);                                         % Vector of colors

num_runs   = handles.opts.num_runs;           % No runs
npts       = handles.opts.npts;               % npts
TR         = handles.opts.TR;                 % TR

sampling_rate = 1;
%--------------------------------------------------------------------------
% Loading Stimulus
time = 0:TR:TR*npts;

for i = 1:nstims
    stimulus_i = import_tfile_mod(deblank(handles.opts.timings(index_selected(i),:)), 1,num_runs);
    base = zeros(num_runs,length(time));
    for j = 1: num_runs
        run_j = stimulus_i(j,:);
        % Finding the closest value
        for t = 1:length(run_j)
            if run_j(t) ~=0
                [~,idx] = min(abs(time - run_j(t)));
                base(j,idx) = 1;
            end
        end
    end
    
    if num_runs > 1
        baseT = base';
        allruns_stim(i,:) = baseT(:);
    else
        allruns_stim(i,:) = base;
    end
end
allruns_stim = allruns_stim';
allruns_time = 0:TR/sampling_rate:(TR*npts*num_runs + (num_runs-1)*TR/sampling_rate) ;

%--------------------------------------------------------------------------
% -------------------------- Plot Stimulus -------------------------------
plot_off = 0.05;
% Figures of stimulus
% Counter


h = plot(allruns_stim(:,1),'Color',cmap(handles.c_cmap,:),'LineWidth',2);

%     ylabel(sel_ref(i,:),'FontWeight','bold','interpreter','none')                   % Lateral labels
set(gca,'XLim',[1,handles.opts.npts*handles.opts.num_runs]);  
% hold off;
end
