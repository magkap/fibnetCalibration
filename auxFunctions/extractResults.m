function [strainStress,elasticModulus,strength,strainAtBreak] = extractResults(directory,folder,simulationName)
% EXTARCTRESULTS Estimate mechanical properties from REA-file.

% Read data and assign strain, determine stress
simData=importdata([directory,'\',folder,'\',simulationName,'.rea']);
headerLine=simData(1,:);
thickness=headerLine(1)*1e-6;   % [m]
width=headerLine(2)*1e-6;       % [m]
strain=simData(2:end,1)*1e-2; % [-]
stress=1e-6*((simData(2:end,2)+simData(2:end,3))/2)/(width*thickness); % [Pa]=[1e-6*uN/m^2]

% Estimate elastic modulus, strength and strain at break
elasticModulus=max(diff(stress)./diff(strain));
[strength,pos]=max(stress);
if pos==length(stress)
    strength=Inf;
    strainAtBreak=Inf;
else
    strainAtBreak=strain(pos);
end

strainStress=[strain,stress];

end