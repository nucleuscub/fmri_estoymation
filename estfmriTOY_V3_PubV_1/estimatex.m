function [betas_est,X_est,signal_noise] = estimatex(signal,opts)

% -------------------------------------------------------------------------
% Author: Ramon Martinez-Cancino
% Maryland Neuroimaging Center, UMD
% Nov 2013
% -------------------------------------------------------------------------

sp = blanks(1);
ntimings = size(opts.timings,1);

% Adding noise from the same distribution
% signal_wn = awgn(signal,opts.snr,'measured');
signal_wn = awgn(signal,opts.snr);
signal_noise = signal_wn;

save('signal_wn.txt','signal_wn','-ascii');
signal_wn = 'signal_wn.txt';

% Creating index othe beginnnig of each RUN
indexr = zeros(1,opts.num_runs);
for i=2:opts.num_runs
    indexr(i) = indexr(i-1) + opts.npts;
end

% ------------------- EStimation 3dDeconvolve -------------------
to3ddeconv = ['3dDeconvolve -input1D' sp signal_wn sp ...
    '-TR_1D' sp num2str(opts.TR) sp ...
    '-concat ''1D: ' num2str(indexr) '''' sp ...
    '-polort' sp num2str(opts.polort_est) sp ...
    '-num_stimts' sp num2str(ntimings) sp];

% Adding stim_times
for i = 1: ntimings
    to3ddeconv = [to3ddeconv ...
        '-stim_times' sp num2str(i) sp opts.timings(i,:) sp '''' opts.hrf_est{i} '''' sp];
    %       '-stim_times_AM1' sp num2str(i) sp opts.timings(i,:) sp opts.hrf_est sp];
end

% Adding stim_labels
for i = 1: ntimings
    to3ddeconv = [to3ddeconv ...
        '-stim_label' sp num2str(i) sp 'reg_' num2str(i) sp];
end

to3ddeconv = [to3ddeconv sp '-bucket' sp 'betas_est.1D' sp ...
    '-x1D' sp 'Xest.1D' sp '-quiet' sp '-jobs' sp num2str(4) sp...
    '-fdisp' sp num2str(1000000)];

unix(to3ddeconv);
%--------------------------------------------------------------------------

% Loading results
X_est = readxmat('Xest.1D');
betas_est = load('betas_est.1D');

% Clear files
delete('betas_est.1D');
%  delete('betas_est.REML_cmd');
delete('Xest.1D')

