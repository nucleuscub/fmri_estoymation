function plot_stims_conv(X,handles)
% Plot stimulus (Subplot Stimulus from timings files)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

plt_count = 0;                                           % Initializing Plot counter
scrsz = get(0,'ScreenSize');                             % Getting screen size
figure('Name', 'Stimulus Conv','Position',scrsz);             % Creating fig
hold on;

index_selected = get(handles.listbox_reg,'Value');                    %Getting variables selected from listbox_reg
reg_list = get(handles.listbox_reg,'String');
sel_reg = reg_list(index_selected);

nstims     =length(index_selected);                                   % Getting Number of stimulus
cmap       = hsv(nstims + 1);                                             % Vector of colors
num_runs   = str2num(get(handles.edit_num_runs, 'String'));           % No runs
npts       = str2num(get(handles.edit_npoints, 'String'));            % npts
TR         = str2num(get(handles.edit_TR, 'String'));                 % TR 
beta    = get(handles.uitable_beta,'Data');



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
% Figures of stimulus conv
plot_off = 0.05; 
c = 0;                                                                              % Counter
for i = 1 : nstims
    h0 = subplot(plt_count/2 + nstims + 1 ,2, [plt_count+i+c plt_count+i+1+c]);
    plot(X(:,plt_count + index_selected(i)),'Color',cmap(i,:),'LineWidth',2);
    if i==1
        title(h0,'Convolution of the stimulus','FontWeight','bold');               % Just the Title on the top
    end
    ylabel(sel_reg(i,:),'FontWeight','bold','interpreter','none')                   % Lateral labels
    c = c+1;
    set(h0,'XLim',[0,npts*num_runs]);                                            % Setting the limits
    set(h0,'YLim',[0 max(X(:,plt_count + index_selected(i))) + plot_off]);
    grid on;
end

% Getting SIGNAL
Xsignal = X(:,index_selected);
betas = beta(index_selected);

% Creating signal
signal = sum(Xsignal.*repmat(betas,size(Xsignal,1),1),2);

% signal = sum(X.*repmat(opts.realB,size(X,1),1),2);

% Plot Simulated Signal                                                                                             % Off of the plot of the signal to allow visualize underlaying stims
h0 = subplot(plt_count/2 + nstims + 1 ,2, [2*(plt_count/2 + nstims+1)-1 2*(plt_count/2 + nstims + 1)]);   % Where to plot it
plot(signal + plot_off,'Color',cmap(end,:),'LineWidth',2.5);                                                    % Plot signal (Signal = sum(Stims))
hold on;
for i = 1 : nstims
    plot(X(:,plt_count + index_selected(i)),'--','Color',cmap(i,:),'LineWidth',2);                 % Subplot Stims
end
%title(h0,'All Stimulus','FontWeight','bold');                                                                       % Setting Title
ylabel('$\displaystyle\sum\limits_{i} \beta_i Stim_i$','interpreter','latex', 'FontSize',12,'FontWeight','bold');    % LaTex Ylabel
set(h0,'XLim',[1,npts*num_runs]);                                                                                    % Setting the X limits
set(h0,'YLim',[0 ,max(signal) + 2*plot_off]);                                                                           % Setting the Y limits
xlabel('TR ','FontWeight','bold');                                                                                   % Setting the lower X label (TR)
grid on;
box on;

end
