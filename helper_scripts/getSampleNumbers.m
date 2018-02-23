function sampleNumbers = getSampleNumbers(curEpochs, epoch_window, overlap, Fs)
    
samplesPerFig = length(curEpochs)*epoch_window*Fs;
sampleNumbers = zeros(samplesPerFig, 1);    %sample numbers to display
epoch_window_samples = epoch_window*Fs;

i = 1;
for j = 1:length(curEpochs)
    ep = curEpochs(j);
    [epIdx, ~] = epoch_to_index(ep, epoch_window, overlap, Fs);
    if ep == 0  %Special Case: Epoch Number is 0, plot a random constant signal
        sampleNumbers(i:i+epoch_window_samples-1) = ones(epoch_window_samples, 1);
    else
        sampleNumbers(i:i+epoch_window_samples-1) = epIdx:epIdx+epoch_window_samples - 1;
    end
    i = i+epoch_window_samples;
end