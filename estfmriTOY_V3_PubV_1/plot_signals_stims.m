function h = plot_signals_stims(handles)
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
cmap       = hsv(15);                                                 % Vector of colors

num_runs   = handles.opts.num_runs;           % No runs
npts       = handles.opts.npts;               % npts
TR         = handles.opts.TR;                 % TR
beta       = handles.opts.beta;               % beta
stim_dur   = handles.opts.stim_dur;



% % Step 1: Check setting for display polynomials
% global glbopts
% if glbopts.show_poly == 0
%     nplots = nstims + 1;             % Nplots without polynomials
%     cmap = hsv(nplots);              % Vector of colors
% %     cmap = jet(nplots);              % Vector of colors
%
% elseif glbopts.show_poly == 1
%     nplots = npolys + nstims + 1;    % Nplots with polynomials
%     cmap = hsv(nplots);              % Vector of colors
% %     cmap = jet(nplots);              % Vector of colors
%
%     % Step 2: Check if X have polynomials embeded and plot them
%     if npolys ~= 0
%         % Plot polys
%         for i = 1 : npolys
%             h0 = subplot(npolys/2 + nstims + 1 ,2,i);
%             plot(X(:,i));
%             ylabel(['P_' num2str(i-1)],'LineWidth',2);
%             plt_count = plt_count + 1;
%         end
%     end
% end

% -------------------------------------------------------------------------

sampling_rate = 1;
%--------------------------------------------------------------------------
% Loading Stimulus
%   time = 0:TR/sampling_rate:TR*npts;
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
                base(j,idx:idx+ceil(stim_dur(i)/TR)) = 1;
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

% -------------------------- Plot Stimulus --------------------------------
plot_off = 0.05;

% Figures of stimulus conv

h = plot(allruns_stim(:,1),'-','Color',cmap(handles.c_cmap,:),'LineWidth',2);
%     ylabel(sel_ref(i,:),'FontWeight','bold','interpreter','none')                   % Lateral labels
set(gca,'XLim',[1,handles.opts.npts*handles.opts.num_runs]);  

grid on;
% hold off;
end
