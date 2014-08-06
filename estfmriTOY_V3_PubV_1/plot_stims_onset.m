function plot_stims_onset(handles,all)
% Plot stimulus (Subplot Stimulus from timings files)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

plt_count = 0;                                           % Initializing Plot counter
scrsz = get(0,'ScreenSize');                             % Getting screen size
figure('Name', 'Stimulus Onset','Position',scrsz);             % Creating fig
hold on;

index_selected = get(handles.listbox_reg,'Value');                    %Getting variables selected from listbox_reg
reg_list = get(handles.listbox_reg,'String');
sel_reg = reg_list(index_selected);

nstims     =length(index_selected);                                   % Getting Number of stimulus
cmap       = hsv(nstims);                                             % Vector of colors
num_runs   = str2num(get(handles.edit_num_runs, 'String'));           % No runs
npts       = str2num(get(handles.edit_npoints, 'String'));            % npts
TR         = str2num(get(handles.edit_TR, 'String'));                 % TR

sampling_rate = 10;
%--------------------------------------------------------------------------
% Loading Stimulus
  time = 0:TR/sampling_rate:TR*npts;
  
for i = 1:nstims
%     stimulus_i = import_tfile(deblank(handles.timings(index_selected(i),:)), 1,num_runs);
     stimulus_i = import_tfile_mod(deblank(handles.timings(index_selected(i),:)), 1,num_runs);
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
c = 0;                                                                              % Counter
for i = 1 : nstims
    h0 = subplot(plt_count/2 + nstims + 1 ,2, [plt_count+i+c plt_count+i+1+c]);
    plot(allruns_time,allruns_stim(:,plt_count + i),'Color',cmap(i,:),'LineWidth',2);
    if i==1
        title(h0,'Stimulus Onset','FontWeight','bold');                             % Just the Title on the top
    end
    ylabel(sel_reg(i,:),'FontWeight','bold','interpreter','none')                   % Lateral labels
    c = c+1;
    set(h0,'XLim',[0,npts*num_runs*TR]);                                            % Setting the limits
    set(h0,'YLim',[0 1 + plot_off]);  
    grid on;
end

% Plot Simulated Signal
                                                                                             % Off of the plot of the signal to allow visualize underlaying stims
h0 = subplot(plt_count/2 + nstims + 1 ,2, [2*(plt_count/2 + nstims+1)-1 2*(plt_count/2 + nstims + 1)]);   % Where to plot it
hold on;
for i = 1 : nstims
    plot(allruns_time,allruns_stim(:,plt_count + i),'-','Color',cmap(i,:),'LineWidth',2);                 % Subplot Stims
end
%title(h0,'All Stimulus','FontWeight','bold');                                                            % Setting Title
ylabel('All','FontWeight','bold','interpreter','none')                                                    % LaTex Ylabel
set(h0,'XLim',[1,npts*num_runs*TR]);                                                                      % Setting the X limits
set(h0,'YLim',[0 1 + plot_off]);                                                                          % Setting the Y limits
xlabel('Time (s)','FontWeight','bold');                                                                   % Setting the lower X label (TR)
grid on;
box on;

end
