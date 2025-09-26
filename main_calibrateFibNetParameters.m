% Calibration script for FibNet.
% Magdalena Kaplan (mkaplan@kth.se), KTH 2025.

% Change current directory to that of this file and add function directory
% to path
cd(fileparts(matlab.desktop.editor.getActiveFilename));
addpath([cd,'\auxFunctions']);
clear all; clc; clf(figure(1));

% Define inputs needed in functions (see separate files)
inputFile='InputOrient_0.dat';
ctrl.customExecutable='C:\Program Files\ANSYS Inc\v150\ansys\custom\user\Magda\ansys.exe';
ctrl.programPath='"C:\Program Files\ANSYS Inc\v150\ANSYS\bin\winx64\ansys150.exe" ';

% Read experimental data and input correct network file
dat=load('experimentalData/MeanCurves.mat');
datNam=fieldnames(dat);
dat=dat.(datNam{1});
datNam=fieldnames(dat);
lst=listdlg('ListString',datNam,'SelectionMode','single');
simulationName=datNam{lst};
% Read experimental results
temp=dat.(simulationName);
strain_exp=temp.meanStrain; % [-]
stress_exp=temp.meanStress; % [Pa]
% Find where linear part of curve ends (inflexion point)
infl=find(ischange(diff(stress_exp)./diff(strain_exp),'linear'),1,'first');
E_exp=max(diff(stress_exp(1:infl))./diff(strain_exp(1:infl))); % Elastic modulus
sMax_exp=max(stress_exp);   % Tensile strength
eMax_exp=max(strain_exp);   % Strain at break

% Plot experimental curve
global plotObj
plotObj.fig=figure(1);
plotObj.p={};
plot(strain_exp*1e2,stress_exp*1e-6,'LineWidth',1.5); hold on; drawnow;
ylabel('Stress [MPa]'); xlabel('Strain [%]')
title(simulationName)
axis([0 eMax_exp*1e2*1.5 0 sMax_exp*1e-6*1.1])

% Change directory for current simulation
par=cd;
cd(['calibrationResults\',simulationName])
addpath(par)
directory=cd;

% Input network geometry file
modifyFile(inputFile,'networkName',erase(dir('*.seed').name,'.seed')); % NOTE! Only works if the network name is on line 153, se modifyFile.m

%% Prepare input for optimisation
% Settings for fminsearch
opts=optimset('Display','iter','TolFun',0.05,'TolX',0.05);

% Ask user for starting guesses for the input variables
prompt={'Fibre modulus mulitplier (E_f)',...
        'Fibre joint stiffness multiplier (k)',...
        'Fibre joint strength multiplier (\sigma_j)',...
        'Fibre yield stress [MPa] (\sigma_y)',...
        'Fibre tangent modulus divider (E_t)',...
        'Fraction of retained joints (f)'};
dlgtitle='Define starting guesses';
fieldsize=1;
definput={'2.5','1','1','155','20','1'};
opts.Interpreter='tex';
inputParam=inputdlg(prompt,dlgtitle,fieldsize,definput,opts);
inputVal=zeros(length(inputParam),1);
% Check that all input are numerical values
for i=1:length(inputParam)
    [num,status]=str2num(inputParam{i});
    if ~status
        error('Wrong input, starting guesses must be numbers.')
    else
        inputVal(i)=num;
    end
end

% Change input file to starting guesses and so that plasticity is not considered
modifyFile(inputFile,'Ex',inputVal(1),'kof',inputVal(2),'kof_base',inputVal(3))
modifyFile(inputFile,'plast',0,'sigy',inputVal(4),'Et',inputVal(5))

% Ask user which parameters should be calibrated.
dlgtitle2='Define which parameters should be calibrated (1 - yes, 0 - no).';
definput2={'1','0','1','1','0','0'};
calibrateYesNo=inputdlg(prompt,dlgtitle2,fieldsize,definput2,opts);
calibrateYesNo=str2num(cell2mat(calibrateYesNo));
% Check that the answers are only given as 0 or 1
if ~all(sum(calibrateYesNo==[1,0],2))
    error('Wrong input, if a parameter should not be calibrated, put 0, otherwise 1.')
end

%% Optimisation process
fprintf('* * * Optimisation process starts. * * *\n\n')

% * * * Elastic modulus * * *
% Only solve for 1/3 of the experimental strain (elastic regime)
modifyFile(inputFile,'strain',eMax_exp/3*1e2)
xl=xline(eMax_exp*1.1*1e2,'LineWidth',0.6); % Plot maximum stress in graph

% Fibre modulus
if calibrateYesNo(1) 
    fprintf('* * Calibration of fibre modulus starts. * *\n\n')
    E_sim=@(E_f)(getOutput(ctrl,directory,simulationName,inputFile,'Ex',E_f,'elasticModulus'));
    E_err=@(E_f)(abs(E_sim(E_f)-E_exp)/E_exp);
    title({simulationName;'Optimising fibre modulus'});
    [Ef_out,E_err_out,~,optOutput.Ef]=fminsearch(E_err,inputVal(1),opts); % Starting guess
    fprintf('\b* Fibre modulus calibrated. *\n\n')
    modifyFile(inputFile,'Ex',Ef_out)
else
    Ef_out=inputVal(1);
end

% Joint stiffness
if calibrateYesNo(2)
    fprintf('* * Calibration of joint stiffness starts. * *\n\n')
    E_sim=@(k)(getOutput(ctrl,directory,simulationName,inputFile,'kof',k,'elasticModulus'));
    E_err=@(k)(abs(E_sim(k)-E_exp)/E_exp);
    title({simulationName;'Optimising joint stiffness'});
    [k_out,E_err_out,~,optOutput.k]=fminsearch(E_err,inputVal(2),opts); % Starting guess
    fprintf('\b* Joint stiffness calibrated. *\n\n')
    modifyFile(inputFile,'kof',k_out)
else
    k_out=inputVal(2);
end

% * * * Plastic parameters * * *
modifyFile(inputFile,'plast',1);
% Solve for 10% more than the experimental strain
modifyFile(inputFile,'strain',eMax_exp*1.1*1e2)
xl.Value=eMax_exp*1.1*1e2; % Plot maximum stress in graph

if any(calibrateYesNo(4:5))
    fprintf('* * Calibration with plastic parameters starts. * *\n\n')
    if all(calibrateYesNo(4:5))
        % Yield strength and tangent modulus in unison
        strainStress_sim=@(x)(getOutput(ctrl,directory,simulationName,inputFile,{'sigy','Et'},x,'strainStress'));
        plast_err=@(x)(plastFit([strain_exp,stress_exp],strainStress_sim(x),'stress'));
        title({simulationName;'Calibrating fibre plastic parameters';'(yield strength and tangent modulus)'});
        [x_out,plast_err_out,~,optOutput.plast]=fminsearch(plast_err,[inputVal(4) inputVal(5)],opts);
        sigy_out=x_out(1); Et_out=x_out(2);
    elseif calibrateYesNo(4)
        % Only yield strength
        strainStress_sim=@(sigy)(getOutput(ctrl,directory,simulationName,inputFile,'sigy',sigy,'strainStress'));
        plast_err=@(sigy)(plastFit([strain_exp,stress_exp],strainStress_sim(sigy),'stress'));
        title({simulationName;'Calibrating yield strength'});
        [sigy_out,plast_err_out,~,optOutput.plast]=fminsearch(plast_err,inputVal(4),opts);
        Et_out=inputVal(5);
    elseif calibrateYesNo(5)
        % Only tangent modulus
        strainStress_sim=@(Et)(getOutput(ctrl,directory,simulationName,inputFile,'Et',Et,'strainStress'));
        plast_err=@(Et)(plastFit([strain_exp,stress_exp],strainStress_sim(Et),'stress'));
        title({simulationName;'Calibrating tagent modulus'});
        [Et_out,plast_err_out,~,optOutput.plast]=fminsearch(plast_err,inputVal(5),opts);
        sigy_out=inputVal(4);
    end
    fprintf('\b* Plastic parameters calibrated. *\n\n')
    modifyFile(inputFile,'sigy',sigy_out,'Et',Et_out)
else
    sigy_out=inputVal(4);
    Et_out=inputVal(5);
end

% * * * Tensile strength * * *
% Solve for 50% more than the experimental strain
modifyFile(inputFile,'strain',eMax_exp*1.5*1e2)
xl.Value=eMax_exp*1.5*1e2; % Plot maximum stress in graph

% Calibrate joint strength 
if calibrateYesNo(3)
    fprintf('* * Calibration of joint strength starts. * *\n\n')
    sMax_sim=@(sig_j)(getOutput(ctrl,directory,simulationName,inputFile,'kof_base',sig_j,'strength'));
    sMax_err=@(sig_j)(abs(sMax_sim(sig_j)-sMax_exp)/sMax_exp);
    title({simulationName;'Calibrating fibre joint strength'});
    opts_sig_j=optimset('Display','iter','TolFun',0.01,'TolX',0.01);
    [sig_j_out,tot_err_out,~,optOutput.sig_j]=fminsearch(sMax_err,inputVal(3),opts_sig_j);
    fprintf('\b* Joint strength calibrated. *\n\n')
    modifyFile(inputFile,'kof_base',sig_j_out)
else
    sig_j_out=inputVal(3);
end

% * * * Retained joint fraction * * *
if calibrateYesNo(6)
    fprintf('* * Calibration of retained joint fraction starts. * *\n\n')
    E_sim=@(f)(getOutput(ctrl,directory,simulationName,inputFile,'fract',f,'elasticModulus'));
    E_err=@(f)(abs(E_sim(f)-E_exp)/E_exp);
    title({simulationName;'Optimising retained joint fraction'});
    [f_out,E_err_out,~,optOutput.f]=fminsearch(E_err,inputVal(6),opts); % Starting guess
    fprintf('\b* Retained joint fraction calibrated. *\n\n')
    modifyFile(inputFile,'fract',f_out)
else
    f_out=inputVal(6);
end

% Print resulting input parameters
outTbl=table(Ef_out,k_out,sig_j_out,sigy_out,Et_out,f_out);
disp(outTbl)
fprintf('* * * Calibration finished. * * *\n')

%% Plot latest simulation together with experimental result
lgd=legend('Location','southeast','FontSize',14);
[fig,strain_num,stress_num]=plotComparison(directory,[simulationName,readParam(inputFile)],simulationName,strain_exp,stress_exp);
title({simulationName;'Final calibrated result'})

