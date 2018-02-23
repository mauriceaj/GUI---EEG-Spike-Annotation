function plotFO_gui_v2(matFilename, epochs_spikes, epoch_window, overlap)

% INPUTS:
% MAT File, epoch_window, overlap, epochs_spikes
% MAT File contains: 'data_all', 'chans', 'Fs', 'fileID', 'num_samples'

% Plots WHOLE EEG, with spikes highlighted
% Click to label Data

%% Close all other MATLAB Windows
close all

%% Load MAT File
m = matfile(matFilename);

%% Extract Parameters
Fs = m.Fs;
chans = m.chans;
bipolChans = chans(2:7);
comRefChans = chans(8:end);
edfName = m.fileID;

%% Display Related Parameters
secondsPerFig = 15;
time_to_display = 0;
spikesPerFig = ceil(secondsPerFig/(epoch_window + time_to_display*2));    %epoch window and the time to display before and after
secondsPerFig = spikesPerFig*(epoch_window + time_to_display*2);
epochsPerFig = secondsPerFig/epoch_window;
samplesPerFig = secondsPerFig*Fs;
N_spikes = length(epochs_spikes);
n_samples = m.num_samples;

N_pages = floor(n_samples/samplesPerFig);

leftIdxCR = [8:11];
leftIdxBP = [2:4];
rightIdxCR = [12:15];
rightIdxBP = [5:7];
EKGIdx = [1];

numChanCR = length(leftIdxCR) + length(rightIdxCR);
numChanBP = length(leftIdxBP) + length(rightIdxBP);
numChans = numChanBP + numChanCR + 1;

leftChans = union({chans{leftIdxCR}}',{chans{leftIdxBP}}', 'stable');
rightChans = union({chans{rightIdxCR}}',{chans{rightIdxBP}}', 'stable');
allChans = union(leftChans, rightChans, 'stable');
allChans = union(allChans, {'EKG'}, 'stable');

%main structure holding EEG plotted
hEEG = zeros(numChanCR+numChanBP, samplesPerFig);

N_epochs = length(epochs_spikes);

pageNum = 1;

%% figure size and position
p = [100 100 1600 800];
hfig = figure('Position', p);
set(hfig, 'WindowButtonDownFcn', @clicker);

%% Create and Update Handles Structure
myhandles = guihandles(hfig);
myhandles.hfig = hfig;
myhandles.numberOfErrors = 0;
myhandles.samplesPerFig = samplesPerFig;
myhandles.secondsPerFig = secondsPerFig;
myhandles.numChanCR = numChanCR;
myhandles.numChanBP = numChanBP;
myhandles.numChans = numChans;
myhandles.m = m;
myhandles.leftIdxCR = leftIdxCR;
myhandles.leftIdxBP = leftIdxBP;
myhandles.rightIdxCR = rightIdxCR ;
myhandles.rightIdxBP = rightIdxBP;
myhandles.EKGIdx = EKGIdx;
myhandles.epochs_spikes = epochs_spikes;
myhandles.epoch_window = epoch_window;
myhandles.epochsPerFig = epochsPerFig;
myhandles.samplesPerFig = samplesPerFig;
myhandles.spikesPerFig = spikesPerFig;
myhandles.Fs = Fs;
myhandles.overlap = overlap;
myhandles.time_to_display = time_to_display;
myhandles.saveFileName = '';
myhandles.edfName = edfName;
myhandles.N_pages = N_pages;

%rFig is the index of the current spike, set to 1 to begin with
setappdata(hfig,'rFig',1);

% Scalp label
uicontrol('Style', 'text',...
    'Tag', 'scalpLabel', ...
    'String', 'Bipolar: 1.0',... %very silly way to label slider :(
    'Units','normalized',...
    'Position', [0.9 0.93 0.08 0.03], 'FontSize', 10);

% Scalp amplitude slider
hSscalp = uicontrol('Parent', hfig, 'style', 'slider', 'Tag', 'scalpScale', 'Min',0.1,'Max',50,'Value',1);
set(hSscalp, 'Units','normalized', 'Position', [.9, .9, .08, .03])
set(hSscalp, 'String', 'Bipolar')
set(hSscalp, 'callback', {@axisScaleScalp})

% FO label
uicontrol('Style', 'text',...
    'Tag', 'foLabel', ...
    'String', 'Comref: 2',... %very silly way to label slider :(
    'Units','normalized',...
    'Position', [0.9 0.86 0.08 0.03], 'FontSize', 10);

% FO amplitude slider
hSfo = uicontrol('Parent', hfig, 'style', 'slider', 'Tag', 'foScale', 'Min',0.1,'Max',50,'Value',2);
set(hSfo, 'Units','normalized', 'Position', [.9, .83, .08, .03])
set(hSfo, 'String', 'ComRef')
set(hSfo, 'callback', {@axisScaleFO})

% EKG label
uicontrol('Style', 'text',...
    'Tag', 'ekgLabel', ...
    'String', 'EKG: 2',... %very silly way to label slider :(
    'Units','normalized',...
    'Position', [0.9 0.79 0.08 0.03], 'FontSize', 10);

% EKG amplitude slider
hSfo = uicontrol('Parent', hfig, 'style', 'slider', 'Tag', 'ekgScale', 'Min',0.05,'Max',5,'Value',1);
set(hSfo, 'Units','normalized', 'Position', [.9, .76, .08, .03])
set(hSfo, 'String', 'EKG')
set(hSfo, 'callback', {@axisScaleEKG})

% Next Page button
hN = uicontrol('Parent', hfig, 'style', 'pushbutton', 'UserData', [], 'BackgroundColor',[.55 .7 1], 'FontSize', 10);
set(hN, 'Units','normalized', 'Position',[.9 .59 .08 .05]) %L/R, U/D, Length, Height
set(hN, 'string', 'Next Page >>')
set(hN, 'callback', {@plotNext})

% Previous Page button
hP = uicontrol('Parent', hfig, 'style', 'pushbutton', 'BackgroundColor',[.55 .7 1], 'FontSize', 10);
set(hP, 'Units','normalized', 'Position',[.9 .52 .08 .05]) %L/R, U/D, Length, Height
set(hP, 'string', '<< Previous Page')
set(hP, 'callback', {@plotPrev})

% Text Box to Go to Page
uicontrol('Style','edit','String','1',...
    'Units','normalized',...
    'Position',[0.9 0.42 0.08 .05],...
    'Tag', 'gotoPage');

% Go to Page Button
hGO = uicontrol('Parent', hfig, 'style', 'pushbutton', 'BackgroundColor',[.55 .7 1], 'FontSize', 10, 'Tag', 'gotoButton');
set(hGO, 'Units','normalized', 'Position',[.9 .36 .08 .05]) %L/R, U/D, Length, Height
set(hGO, 'string', 'Go to')
set(hGO, 'callback', {@goTo})

% Label for page number
r = getappdata(hN.Parent,'rFig');
spike_num_label = sprintf('Page #: %d out of %d', r, N_pages);
uicontrol('Style', 'text', ...
    'String', spike_num_label,... %very silly way to label slider :(
    'Tag', 'PageNum', ...
    'Units','normalized',...
    'Position', [0.89 0.30 0.1 0.08], 'FontWeight', 'bold', 'FontSize', 12);

% Save Labels button
hSave = uicontrol('Parent', hfig, 'style', 'pushbutton', 'BackgroundColor',[.55 .7 1], 'FontSize', 10);
set(hSave, 'Units','normalized', 'Position',[.9 .20 .08 .05]) %L/R, U/D, Length, Height
set(hSave, 'string', 'Save Labels')
set(hSave, 'callback', {@saveLabels})

% Load Labels button
hLoad = uicontrol('Parent', hfig, 'style', 'pushbutton', 'BackgroundColor',[.55 .7 1], 'FontSize', 10);
set(hLoad, 'Units','normalized', 'Position',[.9 .14 .08 .05]) %L/R, U/D, Length, Height
set(hLoad, 'string', 'Load Labels')
set(hLoad, 'callback', {@loadLabels})


%Generate Checkboxes for each channel
for i = 1:numChans
    hChan(i) = uicontrol('Parent', hfig, 'style', 'checkbox', 'FontSize', 10);
    set(hChan(i), 'Units','normalized', 'Position',[.005 (0.075+i*0.05) .012 .05]) %L/R, U/D, Length, Height
    set(hChan(i), 'Tag', ['hChan' +num2str(i)]);
    set(hChan(i), 'value', 1);
    set(hChan(i), 'callback', {@selectChannel})
end


%% Plot Initial EEG

%Channel Switches
myhandles.chanBool = ones(numChans, 1);

%Get Current Page
curPage = 1;

%Get Epochs related to the current Page
mainEpochStart = ((curPage-1)*spikesPerFig + 1);
mainEpochs = mainEpochStart:(mainEpochStart + spikesPerFig);
myhandles.mainEpochs = mainEpochs;

%Get Sample Numbers to display
sampleNumbers = [];
for i = 1:length(mainEpochs)
    sn1 = getSampleNumbers(mainEpochs(i), epoch_window, overlap, Fs);
    if sn1(1)-time_to_display*Fs >= 0
        sn0 = sn1(1)-time_to_display*Fs:sn1(1)-1;
    else
        sn0 = ones(time_to_display*Fs, 1)';
    end
    sn2 = sn1(end)+1:sn1(end)+time_to_display*Fs;
    sampleNumbers = [sampleNumbers sn0 sn1' sn2];
end

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
hEEG = plotEEG(m.data_all([leftIdxBP, rightIdxBP], sampleNumbers), m.data_all([leftIdxCR, rightIdxCR], sampleNumbers), m.data_all(EKGIdx, sampleNumbers), gainBP, gainCR, gainEKG, numChanBP, numChanCR, Fs, myhandles.chanBool);
myhandles.curData = hEEG;

%Plot Detected Spikes Patches
spikesHere = intersect(epochs_spikes, mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-mainEpochs(1))*epoch_window*Fs;
    plotPatch(x1, epoch_window*Fs, numChans, 'blue')
end

ax = gca;
ax.Position = [0.07 0.1000 0.80 0.850];
ax.YTick = 200:200:200*(myhandles.numChans);
ax.YTickLabel = flip(allChans);
ax.XTick = [0:myhandles.samplesPerFig/10:myhandles.samplesPerFig];
ax.XTickLabel = (curPage-1)*myhandles.secondsPerFig + (1/myhandles.Fs)*[0:myhandles.samplesPerFig/(10):myhandles.samplesPerFig];
ax.FontWeight = 'bold';


% Choose default command line output for simple_gui
myhandles.output = hfig;

% Update myhandles structure
guidata(hfig, myhandles);

% Prompt to Load File
if isempty(epochs_spikes)
    loadLabels(hN);
end



%% PLOT NEXT SPIKE
function plotNext(hN, ~)

r = getappdata(hN.Parent,'rFig');
myhandles = guidata(hN);
m = myhandles.m;

if r + 1 <= myhandles.N_pages

cla

S = r+1;%added by me
setappdata(hN.Parent, 'rFig', S)

%Get Current Page
curPage = S;

%Get Epochs related to the current Page
mainEpochStart = ((curPage-1)*myhandles.spikesPerFig + 1);
mainEpochs = mainEpochStart:(mainEpochStart + myhandles.spikesPerFig);
myhandles.mainEpochs = mainEpochs;

%Get Sample Numbers to display
sampleNumbers = [];
for i = 1:length(mainEpochs)
    sn1 = getSampleNumbers(mainEpochs(i), myhandles.epoch_window, myhandles.overlap, myhandles.Fs);
    if sn1(1)-myhandles.time_to_display*myhandles.Fs >= 0
        sn0 = sn1(1)-myhandles.time_to_display*myhandles.Fs:sn1(1)-1;
    else
        sn0 = ones(myhandles.time_to_display*myhandles.Fs, 1)';
    end
    sn2 = sn1(end)+1:sn1(end)+myhandles.time_to_display*myhandles.Fs;
    sampleNumbers = [sampleNumbers sn0 sn1' sn2];
end

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
try
    hEEG = plotEEG(m.data_all([myhandles.leftIdxBP, myhandles.rightIdxBP], sampleNumbers), m.data_all([myhandles.leftIdxCR, myhandles.rightIdxCR], sampleNumbers), m.data_all(myhandles.EKGIdx, sampleNumbers), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);
    myhandles.curData = hEEG;
catch
    
end

%Plot Detected Spikes Patches
spikesHere = intersect(myhandles.epochs_spikes, mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
    plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
end

%Format Axis
ax = gca;
ax.XTickLabel = (curPage-1)*myhandles.secondsPerFig + (1/myhandles.Fs)*[0:myhandles.samplesPerFig/(10):myhandles.samplesPerFig];
ax.FontWeight = 'bold';

% Page # label
spike_num_label = sprintf('Page #: %d out of %d', S, myhandles.N_pages);
lb = findobj('Tag', 'PageNum');
set(lb, 'String', spike_num_label);

% Choose default command line output for simple_gui
myhandles.output = hN;

% Update myhandles structure
guidata(hN, myhandles);

% Save Progress if Page is Multiple of 50
if mod(S,50) == 0
   saveLabels(hN);
end
%end
end

% Go to Page
function goTo(source, pageNum, ~)

myhandles = guidata(source);
m = myhandles.m;

if strcmp(source.Tag, 'gotoButton')
    pageNumObj = findobj('Tag', 'gotoPage'); pageNum = str2num(pageNumObj.String);
end


cla


S = pageNum;
setappdata(source.Parent, 'rFig', S)

%Get Current Page
curPage = S;

%Get Epochs related to the current Page
mainEpochStart = ((curPage-1)*myhandles.spikesPerFig + 1);
mainEpochs = mainEpochStart:(mainEpochStart + myhandles.spikesPerFig);
myhandles.mainEpochs = mainEpochs;

%Get Sample Numbers to display
sampleNumbers = [];
for i = 1:length(mainEpochs)
    sn1 = getSampleNumbers(mainEpochs(i), myhandles.epoch_window, myhandles.overlap, myhandles.Fs);
    if sn1(1)-myhandles.time_to_display*myhandles.Fs >= 0
        sn0 = sn1(1)-myhandles.time_to_display*myhandles.Fs:sn1(1)-1;
    else
        sn0 = ones(myhandles.time_to_display*myhandles.Fs, 1)';
    end
    sn2 = sn1(end)+1:sn1(end)+myhandles.time_to_display*myhandles.Fs;
    sampleNumbers = [sampleNumbers sn0 sn1' sn2];
end

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
try
    hEEG = plotEEG(m.data_all([myhandles.leftIdxBP, myhandles.rightIdxBP], sampleNumbers), m.data_all([myhandles.leftIdxCR, myhandles.rightIdxCR], sampleNumbers), m.data_all(myhandles.EKGIdx, sampleNumbers), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);
    myhandles.curData = hEEG;
catch
    
end

%Plot Detected Spikes Patches
spikesHere = intersect(myhandles.epochs_spikes, mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
    plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
end

%Format Axis
ax = gca;
ax.XTickLabel = (curPage-1)*myhandles.secondsPerFig + (1/myhandles.Fs)*[0:myhandles.samplesPerFig/(10):myhandles.samplesPerFig];
ax.FontWeight = 'bold';

% Page # label
spike_num_label = sprintf('Page #: %d out of %d', S, myhandles.N_pages);
lb = findobj('Tag', 'PageNum');
set(lb, 'String', spike_num_label);

% Choose default command line output for simple_gui
myhandles.output = source;

% Update myhandles structure
guidata(source, myhandles);


% PLOT PREVIOUS SPIKE
function plotPrev(hP, ~)

r = getappdata(hP.Parent,'rFig');


if r > 1
    S = r-1;  %S is previous spike
    cla
    
    myhandles = guidata(hP);
    setappdata(hP.Parent, 'rFig', S)
    m = myhandles.m;
    
    %Get Current Page
    curPage = S;
    
    %Get Epochs related to the current Page
    mainEpochStart = ((curPage-1)*myhandles.spikesPerFig + 1);
    mainEpochs = mainEpochStart:(mainEpochStart + myhandles.spikesPerFig);
    myhandles.mainEpochs = mainEpochs;
    
    %Get Sample Numbers to display
    sampleNumbers = [];
    for i = 1:length(mainEpochs)
        sn1 = getSampleNumbers(mainEpochs(i), myhandles.epoch_window, myhandles.overlap, myhandles.Fs);
        if sn1(1)-myhandles.time_to_display*myhandles.Fs >= 0
            sn0 = sn1(1)-myhandles.time_to_display*myhandles.Fs:sn1(1)-1;
        else
            sn0 = ones(myhandles.time_to_display*myhandles.Fs, 1)';
        end
        sn2 = sn1(end)+1:sn1(end)+myhandles.time_to_display*myhandles.Fs;
        sampleNumbers = [sampleNumbers sn0 sn1' sn2];
    end
    
    %Get the Gain for the channels
    bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
    crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
    ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;
    
    %Plot EEG and Epoch Separation
    hEEG = plotEEG(m.data_all([myhandles.leftIdxBP, myhandles.rightIdxBP], sampleNumbers), m.data_all([myhandles.leftIdxCR, myhandles.rightIdxCR], sampleNumbers), m.data_all(myhandles.EKGIdx, sampleNumbers), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);
    myhandles.curData = hEEG;
    
    spikesHere = intersect(myhandles.epochs_spikes, mainEpochs);
    myhandles.spikesHere = spikesHere;
    for i = 1:length(spikesHere)
        x1 = (spikesHere(i)-mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
        plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
    end
    
    %Format Axis
    ax = gca;
    ax.XTickLabel = (curPage-1)*myhandles.secondsPerFig + (1/myhandles.Fs)*[0:myhandles.samplesPerFig/(10):myhandles.samplesPerFig];
    ax.FontWeight = 'bold';
    
    % Page # label
    spike_num_label = sprintf('Page #: %d out of %d', S, myhandles.N_pages);
    lb = findobj('Tag', 'PageNum');
    set(lb, 'String', spike_num_label);
    
    % Choose default command line output for simple_gui
    myhandles.output = hP;
    
    % Update myhandles structure
    guidata(hP, myhandles);
else
    S = 1;
end




% ComRef AXIS SLIDER
function axisScaleFO(hSfo, ~, hEEG, timePts, samplesPerFig, Fs, EKG)

myhandles = guidata(hSfo);
val = get(hSfo,'value');
lb = findobj('Tag', 'foLabel');
set(lb, 'String', ['ComRef:' num2str(val)]);

cla
hEEG = myhandles.curData;

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
plotEEG(hEEG([5:7, 12:14], :), hEEG([1:4, 8:11],:), hEEG(myhandles.numChans,:), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);

%Plot Detected Spikes Patches
spikesHere = intersect(myhandles.epochs_spikes, myhandles.mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-myhandles.mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
    plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
end



% Bipol AXIS SLIDER
function axisScaleScalp(source, ~, hEEG, timePts, samplesPerFig, Fs, EKG)

myhandles = guidata(source);
val = get(source,'value');
lb = findobj('Tag', 'scalpLabel');
set(lb, 'String', ['Bipolar:' num2str(val)]);

cla
hEEG = myhandles.curData;

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
plotEEG(hEEG([5:7, 12:14], :), hEEG([1:4, 8:11],:), hEEG(myhandles.numChans,:), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);

%Plot Detected Spikes Patches
spikesHere = intersect(myhandles.epochs_spikes, myhandles.mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-myhandles.mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
    plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
end




function axisScaleEKG(source, ~, hEEG, timePts, samplesPerFig, Fs, EKG)

myhandles = guidata(source);
val = get(source,'value');
lb = findobj('Tag', 'ekgLabel');
set(lb, 'String', ['EKG:' num2str(val)]);

cla
hEEG = myhandles.curData;

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
plotEEG(hEEG([5:7, 12:14], :), hEEG([1:4, 8:11],:), hEEG(myhandles.numChans,:), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);

%Plot Detected Spikes Patches
spikesHere = intersect(myhandles.epochs_spikes, myhandles.mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-myhandles.mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
    plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
end


function plotEpochSeparation(spikesPerFig, time_to_display, epoch_window_samples, numChans)

%Plot the Epoch Separations
for i = 1:spikesPerFig
    x = (i-1)*(2*time_to_display + epoch_window_samples) + (time_to_display);
    plotPatch(x, epoch_window_samples, numChans, [0.7 0.7 0.7]);
    hold on;
end

function plotPatch(x1, winSize, numChans, color)

y1 = 0;
x2 = x1;
y2 = 200*(numChans+2);
x3 = x1 + winSize;
y3 = y2;
x4 = x3;
y4 = y1;
patch([x1 x2 x3 x4], [y1 y2 y3 y4],color,'FaceAlpha', .3, 'LineStyle', 'none');


function hEEG = plotEEG(bipolData, comRefData, EKG, gainBP, gainCR, gainEKG, numChanBP, numChanCR, Fs, chanBool, side)

numChans = numChanBP + numChanCR + 1;
hEEG = zeros(numChans, length(EKG));
samplesPerFig = length(bipolData);

counter = 1;
ylim([0 200*(numChans+2)])
xlim([1, samplesPerFig])
hold on

color_left = 'k';
color_right = 'k';

% if side == 0
%   color_right = [0.7 0.7 0.7];
% elseif side == 1
%   color_left = [0.7 0.7 0.7];
% end


%Plot Left CommonRef
for ii = 1:4
    if chanBool(numChans-counter+1) == 1
        plot(200*(numChans+1-counter)+ + gainCR*comRefData(ii, :), 'LineWidth', 1, 'Color', color_left);
    end
    hEEG(counter, :) = comRefData(ii,:);
    counter = counter + 1;
end

%Plot Left Bipolar
for ii = 1:3
    if chanBool(numChans-counter+1) == 1
        plot(200*(numChans+1-counter)+ + gainBP*bipolData(ii, :), 'LineWidth', 1, 'Color', color_left);
    end
    hEEG(counter, :) = bipolData(ii, :);
    counter = counter + 1;
end

%Plot Right Common Ref
for ii = 5:8
    if chanBool(numChans-counter+1) == 1
        plot(200*(numChans+1-counter)+ + gainCR*comRefData(ii, :), 'LineWidth', 1, 'Color', color_right);
    end
    hEEG(counter, :) = comRefData(ii,:);
    counter = counter + 1;
end

%Plot Right Bipolar

for ii = 4:6
    if chanBool(numChans-counter+1) == 1
        plot(200*(numChans+1-counter)+ + gainBP*bipolData(ii, :), 'LineWidth', 1, 'Color', color_right);
    end
    hEEG(counter, :) = bipolData(ii, :);
    counter = counter + 1;
end

if chanBool(numChans-counter+1) == 1
    plot(200+gainEKG*EKG, 'LineWidth', 1, 'Color', 'blue');
end
hEEG(numChans, :) = EKG;




function [curEpochs, mainEpochs] = getEpochs(curPage, spikesPerFig, epochs_spikes)

startEpochIdx = ((curPage-1)*spikesPerFig)+1;   %index of the first epoch number in epochs_spike
curSpikeEpochsIdx = startEpochIdx:startEpochIdx+spikesPerFig-1; %index of all the epoch numbers in epochs_spike to be displayed
curEpochs = []; %epoch numbers to display, including the main spike and the previous and subsequent epoch
mainEpochs = [];    %main epochs containing spikes
for i = 1:length(curSpikeEpochsIdx)
    if curSpikeEpochsIdx(i) <= length(epochs_spikes)
        spikeEpochNumber = epochs_spikes(curSpikeEpochsIdx(i));
        curEpochs = [curEpochs spikeEpochNumber - 1];
        curEpochs = [curEpochs spikeEpochNumber];
        mainEpochs = [mainEpochs spikeEpochNumber];
        curEpochs = [curEpochs spikeEpochNumber + 1];
    end
end

function displayEpochNumbers(epochNumbers, hfig)

N_epochs = length(epochNumbers);
length_label = 0.80/N_epochs;
for i = 1:N_epochs
    hLabel(i) = uicontrol('Parent', hfig, 'style', 'text', 'FontSize', 10);
    set(hLabel(i), 'Units','normalized', 'Position',[length_label*(i-1)+0.07 -0.8 length_label 0.850]) %L/R, U/D, Length, Height
    set(hLabel(i), 'string', num2str(epochNumbers(i)))
    %set(hPop, 'callback', {@popupSel})
end



function checkPage(source, ~)

myhandles = guidata(source);
r = getappdata(source.Parent,'rFig');
spikesPerFig = myhandles.spikesPerFig;
epochIdxStart = (r-1)*spikesPerFig + 1;
epochIdxEnd = epochIdxStart + spikesPerFig - 1;
checked_pages = myhandles.checked_pages;

if source.Value == 1
    checked_pages = [checked_pages r];
    myhandles.checked(epochIdxStart:epochIdxEnd) = ones(spikesPerFig, 1);
elseif source.Value == 0
    checked_pages = checked_pages(checked_pages ~= r);
    myhandles.checked(epochIdxStart:epochIdxEnd) = zeros(spikesPerFig, 1);
end
myhandles.checked_pages = checked_pages;

% Choose default command line output for simple_gui
myhandles.output = source;

% Update myhandles structure
guidata(source, myhandles);


function selectChannel(source, ~)
myhandles = guidata(source);

tag = source.Tag;   %tag of current popup menu
val = source.Value; %value of selected item
popNumber = str2num(tag(6:end));    %number of current popup menu
myhandles.chanBool(popNumber) = val;    %change value of channel boolean array

%% Replot Data
cla
hEEG = myhandles.curData;

%Get the Gain for the channels
bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;

%Plot EEG and Epoch Separation
plotEEG(hEEG([5:7, 12:14], :), hEEG([1:4, 8:11],:), hEEG(myhandles.numChans,:), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);

%Plot Detected Spikes Patches
spikesHere = intersect(myhandles.epochs_spikes, myhandles.mainEpochs);
myhandles.spikesHere = spikesHere;
for i = 1:length(spikesHere)
    x1 = (spikesHere(i)-myhandles.mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
    plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
end


% Choose default command line output for simple_gui
myhandles.output = source;

% Update myhandles structure
guidata(source, myhandles);

function saveLabels(source, ~)
myhandles = guidata(source);

if strcmp(myhandles.saveFileName, '')
    askForInput = 1;
else
    askForInput = 0;
end

if askForInput
    t = 'spikes';
    default_saveFile = [myhandles.edfName(1:end-3) '_' t];
    [fileNameOut, path] = uiputfile([default_saveFile '.csv'], 'Save File');
    fileNameOut = [path fileNameOut];
else
    fileNameOut = myhandles.saveFileName;
end

if fileNameOut ~= 0
    
    myhandles.saveFileName = fileNameOut;
    
    %Write Label File
    dlmwrite(fileNameOut, myhandles.epochs_spikes', 'precision', 9);
    
else
    fileNameOut = '';
    
end

% Choose default command line output for simple_gui
myhandles.output = source;

% Update myhandles structure
guidata(source, myhandles);



function loadLabels(source, ~)
myhandles = guidata(source);
[labelsFileID, folderID] =  uigetfile('*.csv', 'Choose CSV File to Load');
if labelsFileID ~= 0
    myhandles.saveFileName = [folderID labelsFileID];
    M = csvread([folderID labelsFileID]);
    
    myhandles.epochs_spikes = M(:,1)';

    S = getappdata(source.Parent,'rFig');   %Get Page number
    
    % Choose default command line output for simple_gui
    myhandles.output = source;
    
    % Update myhandles structure
    guidata(source, myhandles);

    goTo(source, S);
end



function clicker(h, ~)

myhandles = guidata(h);
Fs = myhandles.Fs;
selType = get(h, 'selectiontype');
% 'normal' for left mouse button
% 'alt' for right mouse button
% 'extend' for middle mouse button
% 'open' on double click

Pt = get(gca, 'currentpoint');
x = Pt(1);
y = Pt(1,2);
epochsIdx = (0:myhandles.epochsPerFig)*myhandles.epoch_window*Fs;

if y > 0 && x >= epochsIdx(1) && x <= epochsIdx(end) + myhandles.epoch_window*myhandles.Fs
for i = 1:length(epochsIdx)
    if x >= epochsIdx(i) && x <= epochsIdx(i) + myhandles.epoch_window*myhandles.Fs
        minIdx = i;
        break;
    end
end


%Get Corresponding Epoch Number
curEpoch = myhandles.mainEpochs(minIdx);

[C, ia, ib] = intersect(curEpoch, myhandles.epochs_spikes);


if isempty(C)
    myhandles.epochs_spikes = [myhandles.epochs_spikes curEpoch];
    x1 = epochsIdx(minIdx);
    plotPatch(x1, myhandles.epoch_window*Fs, myhandles.numChans, 'blue');
else
    myhandles.epochs_spikes(ib) = [];
    cla
    hEEG = myhandles.curData;
    
    %Get the Gain for the channels
    bpScale = findobj('Tag','scalpScale'); gainBP = bpScale.Value;
    crScale = findobj('Tag','foScale'); gainCR = crScale.Value;
    ekgScale = findobj('Tag', 'ekgScale'); gainEKG = ekgScale.Value;
    
    %Plot EEG and Epoch Separation
    plotEEG(hEEG([5:7, 12:14], :), hEEG([1:4, 8:11],:), hEEG(myhandles.numChans,:), gainBP, gainCR, gainEKG, myhandles.numChanBP, myhandles.numChanCR, myhandles.Fs, myhandles.chanBool);
    
    %Plot Detected Spikes Patches
    spikesHere = intersect(myhandles.epochs_spikes, myhandles.mainEpochs);
    myhandles.spikesHere = spikesHere;
    for i = 1:length(spikesHere)
        x1 = (spikesHere(i)-myhandles.mainEpochs(1))*myhandles.epoch_window*myhandles.Fs;
        plotPatch(x1, myhandles.epoch_window*myhandles.Fs, myhandles.numChans, 'blue')
    end
    
    
end

% Choose default command line output for simple_gui
myhandles.output = h;

% Update myhandles structure
guidata(h, myhandles);
end


