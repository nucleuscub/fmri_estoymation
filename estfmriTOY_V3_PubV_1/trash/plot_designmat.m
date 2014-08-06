function plot_designmat(X,opts)
% plot_designmat(X,opts): Plot tye Design Matrix 'X', opts come from the
% simulation options (just for the nstims)
% Note to do it later: replace opts for nstims 

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Nov 2013
% -------------------------------------------------------------------------

scrsz = get(0,'ScreenSize');                                               % Getting screen size

% Ajusting figure size for dual monitors
if scrsz(3) > 2*scrsz(4)
    rf = 4;
else
    rf = 2;
end;
scrsz(3) = scrsz(3)/rf;                                                    % Adjusting width

figure('Name', 'Design Matrix','Position',scrsz);                          % Creating fig
title('Design Matrix','fontsize',14,'FontWeight','bold')                   % Title of fig
hold on;

nstims = size(opts.timings,1);                                             % Getting Number of stimulus
nbetas = size(X,2);                                                        % Getting Number of Betas
npolys = nbetas - nstims;                                                  % Getting Number of polynomials

% Step 1: Check setting for display polynomials
global glbopts
if glbopts.show_poly == 0
    Xplot =  X(:,end-nstims+1:end);
elseif glbopts.show_poly == 1
    Xplot = X;
end

% -------------------------- Plot Design Matrix --------------------------

% pcolor(Xplot);                                                             % Plot the design matrix
imagesc(Xplot);                                                             % Plot the design matrix
xlabel('Regressors','FontWeight','bold');                                  % X label
ylabel('TRs','FontWeight','bold');                                         % Y label
set(gca,'XLim',[0.5 size(Xplot,2) + 0.5]);                                 % Setting the X limits
set(gca,'YLim',[1,opts.npts*opts.num_runs]);                               % Setting the Y limits
set(gca, 'Xtick',1:nstims)                                                 % Setting the X ticks
grid on;
colorbar;
hold off
end

