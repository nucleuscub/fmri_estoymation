function plot_reg_signals(X_est,betas_est,signal_wn,signal,opts,index_selected,name)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Nov 2013
% -------------------------------------------------------------------------
gap = 1;
plot_off = 0.1;
scrsz = get(0,'ScreenSize');
figure('Name', 'Simulated Signals','Position',scrsz);
hold on;

%--------------------------------------------------------------------------


h0 = subplot(2,1,1);
hold on
% Shaded Area
plot_variance = @(x,lower,upper,color) set(fill([x,fliplr(x)],[upper,fliplr(lower)],color),'EdgeColor',color);
ext = minmax(signal_wn(1:gap:opts.npts*opts.num_runs,:));
t = 1:gap:opts.npts*opts.num_runs;
plot_variance(t,ext(:,1)',ext(:,2)',[0.95 0.95 0.98])
set(gca,'XLim',[1,opts.npts*opts.num_runs]);
%--------------------------------------------------------------------------

for i = 1: opts.iter
    H(i) = plot(1:gap:opts.npts*opts.num_runs, signal_wn(1:gap:end,i),'Color',[0.9,0.9,0.9]);hold on; % Fixed for multiples RUNs
end

h2 = plot(1:opts.npts*opts.num_runs,opts.beta(index_selected)*X_est(:,index_selected),'R','LineWidth',2);
xlabel('TR');
grid on;
ylabel('$\displaystyle\sum\limits_{i} \beta_i Stim_i + \epsilon $','interpreter','latex', 'FontSize',14,'FontWeight','bold');    % LaTex Ylabel
title(h0,['Signals Vs ' name],'FontWeight','bold')
legend([H(1),h2],['Signals', name]);
set(gca,'XLim',[1,opts.npts*opts.num_runs]);                               % Setting the X limits
set(h0,'YLim',[min(ext(:,1)) max(ext(:,2)) + plot_off]);                   % Setting the Y limits
legend('boxoff')
set(h0,'box','on');
set(H, 'ButtonDownFcn', {@LineSelected, H})

%--------------------------------------------------------------------------
h0 = subplot(2,1,2);
for i = 1: opts.iter
    signal_est(:,i) = sum(X_est(:,:,i).*repmat(betas_est(:,i)',size(X_est,1),1),2); hold on;
    H2(i) = plot(1:gap:opts.npts*opts.num_runs,signal_est(1:gap:opts.npts*opts.num_runs,i),'Color',[0.7,0.7,0.7]);  % Fixed for multiples RUNs
end

h2 = plot(1:opts.npts*opts.num_runs,opts.beta(index_selected)*X_est(:,index_selected,1),'R','LineWidth',2);                                      % Fixed for multiples RUNs
h3 = plot(1:opts.npts*opts.num_runs,mean(signal_est,2)+plot_off,'B','LineWidth',2);  

xlabel('TR');
grid on;

title(h0,['After Est: ' name ' Vs  Est. Signals'],'FontWeight','bold')
legend([H2(1),h2,h3],['Estimated Signals', name , 'Mean Estimated Signal']);
legend('boxoff');
set(gca,'XLim',[1,opts.npts*opts.num_runs]);                                                        % Setting the X limits
set(h0,'YLim',[min(min(signal_est)) - plot_off max(max(signal_est)) + plot_off]);                   % Setting the Y limits
set(h0,'box','on');
hold off;

    function LineSelected(ObjectH, EventData, H)
        set(ObjectH, 'LineWidth', 2,'Color',[0,0,0]);
        set(H(H ~= ObjectH), 'LineWidth', 0.5,'Color',[0.9,0.9,0.9]);
    end

end

