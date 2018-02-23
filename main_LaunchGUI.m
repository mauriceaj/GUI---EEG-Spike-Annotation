%Run this script to launch the GUI for annotating FOe EEG files.

path_to_add = '\path_to_folder\';  % Full path to the folder containing the GUI scripts and MAT file
addpath(genpath(path_to_add));

fileMAT = ['sample_mat_file.mat'];  % Path to the .mat file to annotate

epoch_window = 0.250;  % Defined as 250ms
overlap = 0;    % No overlap
epochs_spikes = []; % Initial annotations

plotFO_gui_v2(fileMAT, epochs_spikes, epoch_window, overlap);
