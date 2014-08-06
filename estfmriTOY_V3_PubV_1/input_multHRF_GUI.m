function [hrfs,stim_dur] = input_multHRF_GUI(~, hrf_est,regnames,handles)

if isfield(handles,'edit_num_stim')
    num_stim   = str2num(get(handles.edit_num_stim, 'String'));     % No stims

elseif isfield(handles,'num_stim')
    num_stim = handles.num_stim;
    
end

f = figure('Position',[400 200 375 200],'Name', 'HRFs','WindowStyle', 'modal');

dat = cell(num_stim,5);

% Generation names of Rows
rowname = cell(1,num_stim);
for i = 1: num_stim
    rowname{i} = ['Stim_' num2str(i)];
    dat{i,1} = 'Reg';
    dat{i,2} = 'HRF';
end

switch hrf_est
    case 'Multiples'
        columnname =   {'Reg','HRF', 'Par 1', 'Par 2', 'Par 3'};
        columnformat = {'char',{'GAM' 'BLOCK' 'MION', 'MIONN'},'numeric','numeric','numeric'};
        columneditable =  [false true true true true];
        for i = 1: num_stim
            dat{i,1} = regnames{i};
            dat{i,3} = '1';       % Default Values
            dat{i,4} = '1';       % Default Values 
            dat{i,5} = '0';       % Default Values  
        end        
        
        
    case 'BLOCK'
        columnname =   {'Reg','HRF', 'Par 1', 'Par 2','Par 3'};
        columnformat = {'char',{'BLOCK'},'numeric','numeric','numeric'};
        columneditable =  [false false true true true];
        for i = 1: num_stim
            dat{i,1} = regnames{i};
            dat{i,2} = 'BLOCK';
            dat{i,3} = '1';       % Default Values
            dat{i,4} = '1';       % Default Values   
            dat{i,5} = '0';       % Default Values  
        end
        
    case 'MION'
        columnname =   {'Reg','HRF', 'Par 1', 'Par 2','Par 3'};
        columnformat = {'char',{'MION'},'numeric','numeric','numeric'};
        columneditable =  [false false true true true];
        for i = 1: num_stim
            dat{i,1} = regnames{i};
            dat{i,2} = 'MION';
            dat{i,3} = '1';       % Default Values
            dat{i,4} = '0';       % Default Values
            dat{i,5} = '0';       % Default Values 
        end
        
    case 'MIONN'
        columnname =   {'Reg','HRF', 'Par 1', 'Par 2','Par 3'};
        columnformat = {'char',{'MIONN'},'numeric','numeric','numeric'};
        columneditable =  [false false true true true];
        for i = 1: num_stim
            dat{i,1} = regnames{i};
            dat{i,2} = 'MIONN';
            dat{i,3} = '1';       % Default Values
            dat{i,4} = '0';       % Default Values
            dat{i,5} = '0';       % Default Values 
        end
        
        % To add
    case 'GAM'
        columnname =   {'Reg','GAM', 'Par 1', 'Par 2','Par 3'};
        columnformat = {'char',{'GAM'},'numeric','numeric','numeric'};
        columneditable =  [false false true true true];
        for i = 1: num_stim
            dat{i,1} = regnames{i};
            dat{i,2} = 'GAM';
            dat{i,3} = '8.6';       % Default Values
            dat{i,4} = '0.6';     % Default Values
            dat{i,5} = '3.7';    % Default Values 
        end
end


t = uitable('Parent',f, 'Units','normalized','Position',...
    [0.1 0.3 0.8 0.7 ], 'Data', dat,...
    'ColumnName', columnname,...
    'RowName', rowname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', columneditable,...
    'RowName',[]);

h = uicontrol('Parent', f,'Position',[50 10 275 40],'String','Save & Exit',...
    'Callback','uiresume(gcbf)');
uiwait(gcf);

getdata = get(t, 'Data');

% Getting Data

for i = 1 : num_stim
    switch getdata{i,2}
        case 'BLOCK'
            % BLOCK(p)
            if isempty(getdata{i,4}) | isnan(getdata{i,4})                % Add chenck entries
                hrfs{i,1} = ['BLOCK(' getdata{i,3}  ')'];
                stim_dur(i) = str2num(getdata{i,3});
                
            elseif ~isnan(getdata{i,4})
                % BLOCK(p,d)
                hrfs{i,1} = ['BLOCK(' num2str(getdata{i,3}) ',' num2str(getdata{i,4})  ')'];
                stim_dur(i) = str2num(getdata{i,3});
            end
            
        case 'MION'
            
            hrfs{i,1} = ['MION(' num2str(getdata{i,3})  ')'];
            stim_dur(i) = str2num(getdata{i,3});
            
        case 'MIONN'
            
            hrfs{i,1} = ['MIONN(' num2str(getdata{i,3})  ')'];
            stim_dur(i,1) = str2num(getdata{i,3});
            
        case 'GAM'
            if str2num(getdata{i,5}) == 0
                hrfs{i,1} = ['GAM('  num2str(getdata{i,3}) ',' num2str(getdata{i,4})  ')'];
                stim_dur(i,1) = 2.3*sqrt(str2num(getdata{i,3}))*str2num(getdata{i,4});
            else
                hrfs{i,1} = ['GAM('  num2str(getdata{i,3}) ',' num2str(getdata{i,4}) ',' num2str(getdata{i,5}) ')'];
                stim_dur(i,1) = str2num(getdata{i,5});
            end
            %case 'dmBLOCK'
    end
end

close(f);