function [fig,strain_num,stress_num] = plotComparison(directory,folderName,simulationName,strain_exp,stress_exp)
% PLOTCOMPARISON Plots numerical and experimental curve for comparison
%   Detailed explanation goes here

% Read strain and stress from chosen simulation
[strainStress_num,~,~,~]=extractResults(directory,folderName,simulationName);

% Assign numerical stress and strain
strain_num=strainStress_num(:,1);
stress_num=strainStress_num(:,2);

if nargin<5
    load MeanCurves_SI.mat
    temp=res.(simulationName);
    strain_exp=temp.meanStrain; % [-]
    stress_exp=temp.meanStress; % [Pa]
end

% Plot latest simulation together with experimental result
fig=figure; clf(fig);
plotOpts={'LineWidth',1.5,'DisplayName'};
plot(strain_exp*1e2,stress_exp*1e-6,plotOpts{:},'Experimental'); hold on;
plot(strain_num*1e2,stress_num*1e-6,plotOpts{:},'Numerical'); hold off;
ylabel('Stress [MPa]')
xlabel('Strain [%]')
lgd=legend('Location','southeast','FontSize',14);
end