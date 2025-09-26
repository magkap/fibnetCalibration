function simData = solveNetwork(directory,simulationName,inputFile,customExecutable,programPath)
% SOLVENETWORK runs FibNet-simulation and retrieves data
% customExecutable='C:\Program Files\ANSYS Inc\v150\ansys\custom\user\Magda\ansys.exe';
% programPath='"C:\Program Files\ANSYS Inc\v150\ANSYS\bin\winx64\ansys150.exe" ';
productName='-p ansys ';
numProcs='-np 8 ';
dir=['-dir ',directory,' '];
job=['-j ',simulationName,' '];
readS='-s read ';
lang='-l en-us ';
mode='-b ';
input=['-i "',directory,'\',inputFile,'" '];
output=['-o "',directory,'\',simulationName,'.out" '];
custom=['-custom "',customExecutable,'" '];

system(['SET KMP_STACKSIZE=4096k & ',programPath,productName,dir,job,readS,lang,mode,input,output,custom]);

%     system(['SET KMP_STACKSIZE=4096k & "C:\Program Files\ANSYS Inc\v150\ANSYS\bin\winx64\ansys150.exe"  -p aa_t_a -np 4 -dir "' directory '" -j "' simulationName '" -s read -l en-us -b -i "' directory simulationName '.dat" -o "' directory simulationName '.out" -custom "' customExecutable '" ']);
%     simData=importdata([simulationName,'trial_job.rea']);

end