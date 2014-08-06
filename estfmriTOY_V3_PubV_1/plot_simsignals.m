function plot_simsignals(X,signal,opts)
% Plot simulated signals (Subplot A: Simulated Signals and Simulated Signals with noise)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Nov 2013
% -------------------------------------------------------------------------

plt_count = 0;                                           % Initializing Plot counter

scrsz = get(0,'ScreenSize');                             % Getting screen size
figure('Name', 'Simulated Signals','Position',scrsz);    % Creating fig
hold on;

nstims = size(opts.timings,1);  % Getting Number of stimulus
nbetas = size(X,2);             % Getting Number of Betas
npolys = nbetas - nstims;       % Getting Number of polynomials

% Step 1: Check setting for display polynomials
global glbopts
if glbopts.show_poly == 0
    nplots = nstims + 1;             % Nplots without polynomials
    cmap = hsv(nplots);              % Vector of colors
%     cmap = jet(nplots);              % Vector of colors
    
elseif glbopts.show_poly == 1
    nplots = npolys + nstims + 1;    % Nplots with polynomials
    cmap = hsv(nplots);              % Vector of colors
%     cmap = jet(nplots);              % Vector of colors
    
    % Step 2: Check if X have polynomials embeded and plot them
    if npolys ~= 0
        % Plot polys
        for i = 1 : npolys
            h0 = subplot(npolys/2 + nstims + 1 ,2,i);
            plot(X(:,i));
            ylabel(['P_' num2str(i-1)],'LineWidth',2);
            plt_count = plt_count + 1;
        end
    end
end

% -------------------------- Plot Stimulus --------------------------

% Figures of stimulus
c = 0;                                  % Counter
for i = 1 : nstims
    h0 = subplot(plt_count/2 + nstims + 1 ,2, [plt_count+i+c plt_count+i+1+c]);
    plot(X(:,plt_count + i),'Color',cmap(i,:),'LineWidth',2);
    if i==1
        title(h0,'Stimulus','FontWeight','bold');                                % Just the Title on the top
    end
    ylabel(['Stim_' num2str(i)],'FontWeight','bold')                             % Lateral labels
    c = c+1;
    set(h0,'XLim',[1,opts.npts*opts.num_runs]);                                  % Setting the limits
    grid on;
end

% Plot Simulated Signal
plot_off = 0.15;                                                                                                % Off of the plot of the signal to allow visualize underlaying stims
h0 = subplot(plt_count/2 + nstims + 1 ,2, [2*(plt_count/2 + nstims+1)-1 2*(plt_count/2 + nstims + 1)]);         % Where to plot it
plot(signal + plot_off,'Color',cmap(end,:),'LineWidth',2.5);                                                    % Plot signal (Signal = sum(Stims))
hold on;
for i = 1 : nstims
    plot(X(:,plt_count + i),'--','Color',cmap(i,:),'LineWidth',2);                                              % Subplot Stims
end
title(h0,'Simulated Signal','FontWeight','bold');                                                               % Setting Title
ylabel('$\displaystyle\sum\limits_{i} \beta_i Stim_i$','interpreter','latex', 'FontSize',12,'FontWeight','bold');    % LaTex Ylabel
set(h0,'XLim',[1,opts.npts*opts.num_runs]);                                                                     % Setting the X limits
set(h0,'YLim',[0 max(signal) + plot_off]);                                                                      % Setting the Y limits
xlabel('TR','FontWeight','bold');                                                                               % Setting the lower X label (TR)
grid on;

% spaceplots(gcf,[0.015 0.017 0.05 0.05],[.02 .02])
end
