CONTENTS OF THIS FILE
---------------------

 * Description
 * Compatibility
 * Starting the GUI
 * Using the GUI
 * Future Developments
 * Contact


DESCRIPTION
------------

This is a Graphical User Interface (GUI) that enables the annotation of Foramen Ovale electrode (FOe) EEG.


COMPATIBILITY
------------

This software has been tested using MATLAB R2017 on Windows Platforms.

STARTING THE GUI
------------

In the file "main_LaunchGUI.m", replace the value of the variable fileMAT with the path of the corresponding recording file. 

The input should be a ".mat" file with the following fields:
* Fs, the sampling Frequency
* chans, a 15 x 1 cell that contains the name of the channels to display:
 * Channel 1: EKG
 * Channels 2-4: Bipolar montage for the left FOes (LFO1-LFO2, LFO2-LFO3, LFO3-LFO4)
 * Channels 5-7: Bipolar montage for the right FOes (RFO1-RFO2, RFO2-RFO3, RFO3-RFO4)
 * Channels 8-11: Referential montage for the left FOes (LFO1-CII, LFO2-CII, LFO3-CII, LFO4-CII)
 * Channels 12-15: Referential montage for the right FOes (RFO1-CII, RFO2-CII, RFO3-CII, RFO4-CII)
* data_all: a 15 x num_samples matrix where num_samples is the number of samples for the recording. The order of the channels is the same as in "chans".
* fileID: a string that represents the ID of the file in use.
* num_samples: the number of samples for each channel in data_all.

Then, run the matlab script "main_LaunchGUI.m".


USING THE GUI
------------
* After the initial launch, the GUI will ask if you would like to load previously saved annotations. Click Cancel if that is not required.

* The GUI will display 15 seconds of FOe EEG data. Use the Buttons and 
sliders on the right to navigate the recording and adjust the gains for each group of channels. You can also hide/show channels using the checkboxes on the left.

* To annotate an epoch, click on the display. To remove an annotation, click on it again. Epochs are defined as 250ms segments.

* Save/Load labels by using the appropriate buttons on the right. The GUI will prompt you for the name of a savefile if saving annotations for the first time.

* The annotations are saved as a .csv file containing one column containing the epoch numbers that were annotated.


FUTURE DEVELOPMENTS
-------------------

Future Developments for this GUI will include a more modular design that would enable it to take a custom number of channels.


CONTACT
------------

* Maurice Abou Jaoude - maboujaoude@mgh.harvard.edu