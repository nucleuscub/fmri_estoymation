function h = regplot(Y,T,indx,plt_flag)
% h = regplot(Y,T) : Takes a target T and output data Y to generate a regression plot
%                    plt_flag : enable the plot of T and Y  

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Nov 2013
% -------------------------------------------------------------------------


y = Y(:)';
t = T(:)';

[r,m,b] = regression(t,y);
m = m(1); b = b(1); r = r(1);
lim = [min([y t]) max([y t])];
line = m*lim + b;

% Plot stuff
scrsz = get(0,'Screensize');
figsize = [scrsz(4)/3 scrsz(4)/3 890 250];
h{1} = figure('Name', 'Plot Reg','Toolbar', 'none','Position',figsize);    % Creating fig; hold on;
hold on;


if plt_flag
    %----------------------------------------------------------------------
    subplot(1,20,1:5);
    h = regplot_core(y,t,h,indx);
    
    %----------------------------------------------------------------------
    h2{1} = subplot(1,20,7:20);
    hold on;
    h2{2} = plot(y,'r');
    h2{3} = plot(t,'b');
    
    set(h2{1},'box', 'on');
    title('Regressors','fontsize',12,'FontWeight','bold');                     % Title of Fig
    xlabel('TR','FontWeight','bold');                                          % X label
    h{5} =legend([h2{2},h2{3}],{['Reg_' num2str(indx(1))],['Reg_' num2str(indx(2))]},'Location','NorthWest','fontsize',8); % Legend
    set(h{5},'box', 'off');
    grid on;
    hold off;
    
    
    
    spaceplots(gcf,[0 0 0 0],[.02 .02])
else
    h = regplot_core(y,t);
end

    function h = regplot_core(y,t,h,indx)
        hold on
        h{2} = plot(lim,line,'r');                                % Plot Regression Line
        h{3} = plot(t,y,'o');                                     % Plot Data Points
        h{4} = plot([0 lim(2)],[0 lim(2)],':');                   % Plot Line Y = T
        
        set(gca,'box','on')
        set(gca,'xlim',lim);
        set(gca,'ylim',lim);
        axis('square');
        
        ylabel(['Reg_' num2str(indx(2)) ' ~= ',num2str(m,2),'*Reg_'  num2str(indx(1))  ' + ', num2str(b,2)],'FontWeight','bold');                  % Y label
        xlabel(['Reg_'  num2str(indx(1)) ],'FontWeight','bold');                                                           % X label
        title(['R=' num2str(r)],'fontsize',12,'FontWeight','bold');                              % Title of Fig
        h{5} =legend([h{2},h{3},h{4}],{'Fit','Data',['Reg_' num2str(indx(1)) ' = Reg_' num2str(indx(2))]},'Location','NorthWest','fontsize',8); % Legend
        set(h{5},'box', 'off');
        
    end
end

