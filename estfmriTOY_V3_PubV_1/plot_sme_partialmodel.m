function plot_sme_partialmodel(X_est1,X_est2,betas_est1,betas_est2,signal,opts)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

% Creating est signals
for i = 1: size(X_est1,3)
    signal_est1(:,i) = sum(X_est1(:,:,i).*repmat(betas_est1(:,i)',size(X_est1,1),1),2);
    signal_est2(:,i) = sum(X_est2(:,:,i).*repmat(betas_est2(:,i)',size(X_est2,1),1),2);
end

% Getting MSE
 
MSE1 = mean((repmat(signal,1,size(signal_est1,2)) - signal_est1 ).^2,2);
MSE2 = mean((repmat(signal,1,size(signal_est2,2)) - signal_est2 ).^2,2);

% MSE1noise = mean((signal_wn - signal_est1).^2,2);
% MSE2noise = mean((signal_wn - signal_est2).^2,2);

% Plot
gap = 1;
plot_off = 0.05;
scrsz = get(0,'ScreenSize');
figure('Name', 'Simulated Signals','Position',scrsz);
hold on;

%--------------------------------------------------------------------------
% MSE 1 and 2
h0 = subplot(2,2,1:2);
hold on

h1 = plot(MSE1,'R','LineWidth',2);
h2 = plot(MSE2,'B','LineWidth',2);
xlabel('TR');
grid on;
ylabel('MSE', 'FontSize',12,'FontWeight','bold');    % LaTex Ylabel
title(h0,'Estimation Mean Square Error','FontWeight','bold')
legend([h1,h2],'Full Model','Partial Model');
set(gca,'XLim',[1,opts.npts*opts.num_runs]);                               % Setting the X limits
set(h0,'YLim',[min([MSE1;MSE2]) max([MSE1;MSE2]) + plot_off]);             % Setting the Y limits
legend('boxoff')
set(h0,'box','on');
hold off;

%--------------------------------------------------------------------------
% Hist MS1
h0 = subplot(2,2,3);

h_hist = histfit(MSE1,30); %%% Create the histogram
h1 = get(gca,'Children');
set(h1(2),'FaceColor',[.8 .8 1]);
set(h0,'XLim',[min(MSE1) max(MSE1)]);

hold on;
y_max = max(max(get(h_hist(2),'Ydata')));
h2 = plot(mean(MSE1),y_max,'--rs','MarkerSize',10, 'Color', [1 0 0], 'MarkerFaceColor',[1 0 0]);
h4 = legend([h2],'Mean MSE Full Model');
xlabel('MSE Full Model');
ylabel('f');
set(h4,'box', 'off');
grid on;

title(h0,[ 'MSE Full Model ( Mean = ' num2str(mean(MSE1)) '  Std = ' num2str(std(MSE1)) ')'],'LineWidth',2);

%--------------------------------------------------------------------------
% Hist MS2
h0 = subplot(2,2,4);

h_hist = histfit(MSE2,30); %%% Create the histogram
h1 = get(gca,'Children');
set(h1(2),'FaceColor',[.8 .8 1]);
set(h0,'XLim',[min(MSE2) max(MSE2)]);

hold on;
y_max = max(max(get(h_hist(2),'Ydata')));
h2 = plot(mean(MSE2),y_max,'--rs','MarkerSize',10, 'Color', [0 0 1], 'MarkerFaceColor',[0 0 1]);
h4 = legend([h2],'Mean MSE Partial Model');
xlabel('MSE Partial Model');
ylabel('f');
set(h4,'box', 'off');
grid on;

title(h0,[ 'MSE Partial Model ( Mean = ' num2str(mean(MSE2)) '  Std = ' num2str(std(MSE2)) ')'],'LineWidth',2);

