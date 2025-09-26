function values = readParam(inputFile)
% INPUTPARAM find the value of parameters in the infput file InputOrient_0

% Input parameters to find
inputNames={'Ex','kof','kof_base','plast','Et','sigy'};
values=[];

% If file name not given, use default.
if ~exist('inputFile','var')
    inputFile='InputOrient_0.dat';
end
fileContent=readlines(inputFile);

% Loop over variable names and find their values
for inp=inputNames
    currInp=inp{:};
    
    % Find line on which parameter is defined.
    currLine=find(startsWith(fileContent,[currInp,' = ']));
    line=convertStringsToChars(fileContent(currLine));

    % Find numerical value of parameter in line and replace.
    valuePos=find(isstrprop(line,'digit')); % Find where the digits are located
    valuePos=valuePos(valuePos<strfind(line,'!')); % Exclude digits located in comments (if applicable)
        % If variable is multiplier
        if contains(line(valuePos(1):valuePos(end)),'*')
            values=[values,'_',currInp,'_',line(strfind(line,'*')+1:valuePos(end))];
        % If variable is the value
        else
            values=[values,'_',currInp,'_',line(valuePos(1):valuePos(end))];
        end
end
% [Ex,kof,kof_base,plast,Et,sigy]=values;
end