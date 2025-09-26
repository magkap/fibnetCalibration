function [output] = getOutput(ctrl,directory,simulationName,inputFile,input,var,reqOut)
% GETOUTPUT Modifies file, runs the simulation, extracts results and
% determines output values

% Measure the time elapsed for solving
tic;

% Modify input file
if isa(input,'char')
    modifyFile(inputFile,input,var);
elseif isa(input,'cell')
    inpArr=cell(1,2*length(input));
    for i=1:length(input)
        inpArr{1,2*i-1}=input{i};
        inpArr{1,2*i}=var(i);
    end
    modifyFile(inputFile,inpArr{:});
else
    error(['Wrong input variable "input" for fibre modification, use either ' ...
           'one parameter as string followed by numerical value for "var", ' ...
           'or the parameter names in a cell array followed with a vector ' ...
           'of numerical values for "var".'])
end

% Read all variables from input file
values=readParam(inputFile);
% Check if simulation is elastic
plastPos=strfind(values,'plast')+6;
% If elastic, shorten folder name
elastic=~str2double(values(plastPos));
if elastic
    values=values(1:plastPos);
end
% Create new folder name for current simulation
newFolder=[simulationName,values];

% Check if the new folder name already exists
if isfolder(newFolder)
    % Check if the input files are the same
    oldFile=readlines([directory,'\',newFolder,'\',inputFile]);
    oldFile=splitlines(oldFile);
    newFile=readlines([directory,'\',inputFile]);
    newFile=splitlines(newFile);
    
    % Check the two files line by line
    if ~length(oldFile)==length(newFile)
        error('Input file has diverging number of lines compared to previous runs.')
    else
        linDiff=[];
        for line=1:length(oldFile)
            if ~isequal(oldFile(line),newFile(line))
                % Store the line numbers that are different
                linDiff=[linDiff; line];
            end
        end
    end

    % If the difference is not only the plastic parameters in an elastic 
    % solution or concerns lines other than:
    % 114 - the prescribed strain
    % 715 - the solver call
    % 69 - first part of file (where input parameters are set)
    if ~isempty(linDiff) && ~all(contains(newFile(linDiff),{'Et','sigy'})) && ~all(ismember(linDiff(linDiff>69),[114 715]))
        % Create new folder with different name
        c=1;
        while isfolder([newFolder,'_',num2str(c)])
            c=c+1;
        end
        newFolder=[newFolder,'_',num2str(c)];
    else
        % Do not solve the same problem again
        noSolve=1;
        % Rewrite the first line of the file to update the time stamp
        fid=fopen([directory,'\',newFolder,'\',inputFile],'rt+');
        pos=ftell(fid);
        line1=fgetl(fid);
        fseek(fid,pos,'bof');
        fprintf(fid, '%s\n', line1);
        fclose(fid);
    end
end

% If simulation does not already exist
if ~exist('noSolve','var')
    % Create new folder to run and save simulation data in
    mkdir(directory,newFolder)

    % Solve for selected network
    solveNetwork(directory,simulationName,inputFile,ctrl.customExecutable,ctrl.programPath);

    % Copy/move files to the new folder
    copyfile(inputFile,[directory,'\',newFolder])  % Copy modified input file
    % Move all files generated in the solution
    files=dir; % Find all files in current folder
    files=files(~[files.isdir]); % Remove all directories
    files={files.name}; % Extract file names
    for file=files(contains(files,simulationName)) % Only move simulation files
        movefile(file{:},newFolder)
    end
end

% Read results and assign output
[strainStress,elasticModulus,strength,strainAtBreak]=extractResults(directory,newFolder,simulationName);
% If one variable requested
if isa(reqOut,'char') && exist(reqOut,'var')
    output=eval(reqOut);
% If several variable requested
elseif isa(reqOut,'cell') && all(cellfun(@exist,reqOut,repmat({'var'},1,length(reqOut))))
    for r=1:length(reqOut)
        output.(reqOut{r})=eval(reqOut{r});
    end
% If any of the requested variables do not exist
else
    error(['Wrong input argument. Allowed parameter names ' ...
           'are strainStress, elasticModulus, strength and strainAtBreak' ...
           ' (input as string or strings in cell array).'])
end

% Plot simulation results on top of experimental
global plotObj
if exist('plotObj','var')
    set(0,'currentfigure',plotObj.fig)
    plotObj.p{end+1}=plot(strainStress(:,1)*1e2, ...
                          strainStress(:,2)*1e-6, ...
                          'Color',[.85 .325 .098], ...
                          'LineWidth',1.5,'HandleVisibility','off');
    for n=1:length(plotObj.p)
        plotObj.p{n}.Color(4)=0.5^(length(plotObj.p)-n);
    end
    drawnow;
end

% Report the time elapsed for solving
toc;
% time=duration(0,0,toc,'Format','hh:mm:ss');
% fprintf(['Elapsed time is ',char(time),'.'])

end