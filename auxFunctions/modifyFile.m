function modifyFile(inputFile,input1,var1,input2,var2,input3,var3,input4,var4)
% MODIFYFILE changes the input tile InputOrient_0 with chosen input
% parameters
    
% Define allowed inputs.
inputNames={'Ex','kof','kof_base','plast','Et','sigy',...
            'strain','fract','networkName'};

% If file name not given, use default.
if isempty(inputFile)
    inputFile='InputOrient_0.dat';
end
fileContent=readlines(inputFile);

% Check that there is sufficent number of inputs.
if nargin>9
    error('Too many input arguments.')
elseif nargin<3 || mod(nargin-1,2)>0
    error('Too few input arguments.')
elseif isequal(input1,'networkName')
    currLine=153;
    line=convertStringsToChars(fileContent(currLine));
    valuePos=strfind(line,"'");
    line=[line(1:valuePos(1)),var1,line(valuePos(2):end)];
    fileContent(currLine)=string(line);
else
    % Input variables to file.
    for i=(1:(nargin-1)/2)
        % Find current input variable.
        currInp=eval(['input',num2str(i)]);
        
        % Check that correct parameter name is used.
        if sum(contains(inputNames,currInp))
            % Find line on which parameter is defined.
            if isequal(currInp,'strain')
                currLine=find(contains(fileContent,'fs = '));
                currLine=currLine(1);
            elseif isequal(currInp,'fract')
                currLine=find(contains(fileContent,'fract = '));
            else
                currLine=find(startsWith(fileContent,[currInp,' = ']));
            end
            line=convertStringsToChars(fileContent(currLine(1)));

            % Find numerical value of parameter in line and replace.
            valuePos=find(isstrprop(line,'digit'));
            valuePos=valuePos(valuePos<strfind(line,'!')); % Exclude digits located in comments (if applicable)
            % If variable is multiplier
            if contains(line(valuePos(1):valuePos(end)),'*')
                line=[line(1:strfind(line,'*')),num2str(eval(['var',num2str(i)])),line(valuePos(end)+1:end)];
            % If variable is the value
            else
                line=[line(1:valuePos(1)-1),num2str(eval(['var',num2str(i)])),line(valuePos(end)+1:end)];
            end

            fileContent(currLine)=string(line);
         
        else
            error(['Wrong input argument. Allowed parameter names ' ...
                   'are Ex, kof, kof_base, plast, Et, and sigy, or '...
                   'strain (for changing the applied strain).'])
        end

    end
    
end

% Overwrite old file with modified.
writelines(fileContent,inputFile);

end