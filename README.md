# fibnetCalibration

## main_calibrateFibNetParameters
Main file to be run for the calibration of parameters in FibNet, with a given network (see generateNetwork and calibrationResults below) and corresponding experimental stress-strain curve (see experimentalData below) from a tensile test. Upon running the script, the user can
* choose which of the provided experimental data (see experimentalData below) are to be calibrated against, 
* which parameters should be calibrated, and 
* what starting values should be used for the network parameters.
  
The experimental and numerical stress-strain curves are graphically compared continously, allowing the user to adjust the starting guesses. Keep in mind that the calibration process is sensitive to the starting values, these may therefore need to be adjusted during the process. 
Additionally, the program path and the path to the custom executable must be defined (currently on line 12 and 13 in the main script).

## Folders
### auxFunctions
Contains the necessary functions called by the main file.
### calibrationResults
Collects the results generated during the calibration process. Each subfolder contains the files created when the respective network is generated network (see networkGeneration below). The main script creates subfolders within each network folder for each parameter setup solution.
### experimentalData
Stores the experimental stress-strain data in a .mat file. One mean curve is given for each network, which has been processed from the raw experimental data.
### networkGeneration
In the case when the networks are not generated (and not stored in the subfolders within the calibrationResults folder), the networks can be generated using the MyPacking.exe application contained here. The application uses the files BS_out.txt (containing fibre geometry measurements) and the input file ModelingData.txt. The latter is stored for each of the individual networks in the corresponding subfolders, where the grammage and thickness is the only difference. To generate the network, copy the input file for the desired network into the same directory as the MyPacking application and run it by double clicking (the generated output files should then be copied to the correct subfolder in calibrationResults in order for the main script to work correctly).
