function [start_idx, end_idx] = epoch_to_index(epoch_number, window, overlap, Fs)


%{
INPUTS
1) epoch_number
2) window (in seconds)
3) overlap (in percentage)
4) Fs: Sampling Frequency
%}


window_in_samples = floor(window*Fs);
overlap_in_samples = floor(overlap*window_in_samples);
%num_epochs = floor(totalSamples/(window_in_samples));
increment_in_samples = window_in_samples - overlap_in_samples;
start_idx = (epoch_number-1)*increment_in_samples+1;
end_idx = start_idx + window_in_samples - 1;



end