function  X = readxmat(filename)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Jan 2014
% -------------------------------------------------------------------------

fid = fopen(filename);
tline = fgets(fid);
 i = 0;
while ischar(tline) 
    if tline(1) ~= '#' && ~isempty(str2num(tline))
        i = i + 1;
        X(i,:) = str2num(tline);
    end  
    tline = fgets(fid);
end

fclose(fid);