function stimulus_i = import_tfile_mod(filename,start_row,end_row)


% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------
% Load timing files
    
%     stimulus_i = importdata(filename);
stimulus_temp = importdata(filename,'\t');

for i = 1:size(stimulus_temp,1)
    n_stimsrow(i) = length(str2num(cell2mat(stimulus_temp(i,:))));
end

stimulus_i = zeros(size(stimulus_temp,1),max(n_stimsrow));

for i = 1:size(stimulus_temp,1)
    stimulus_i(i,1:n_stimsrow(i)) = str2num(cell2mat(stimulus_temp(i,:)));
end

stimulus_i = stimulus_i(start_row:end_row,:);
    


