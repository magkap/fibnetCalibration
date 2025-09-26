function err = plastFit(strainStress_exp,strainStress_num,optVar)
% PLASTIFT determines the least sqaure error between the experimental and
% numerical curves, based on discrepancy in either stress or strain.

% Divide matrix into columns
strain_exp=strainStress_exp(:,1);
stress_exp=strainStress_exp(:,2);
strain_num=strainStress_num(:,1);
stress_num=strainStress_num(:,2);

if isequal(optVar,'both')
%     err=sum([(strain_num(end)-max(strain_exp))/max(strain_exp) (max(stress_num)-max(stress_exp))/max(stress_exp)].^2);
    if strain_num(end)>=strain_exp(end)
        stress_intp=interp1(strain_num,stress_num,strain_exp(end));
    else
        stress_intp=0;
    end

    err=((stress_intp-stress_exp(end))/stress_exp(end))^2;
    
else
    % Assign vectors based on which optimisation variable to use
    if isequal(optVar,'stress')
        % Strain is the independent variable...
        x_exp=strain_exp;
        x_num=strain_num;
        % ...and stress dependent.
        y_exp=stress_exp;
        y_num=stress_num;
    elseif isequal(optVar,'strain')
        % Stress is the independent variable...
        x_exp=stress_exp;
        x_num=stress_num;
        % ...and strain is dependent.
        y_exp=strain_exp;
        y_num=strain_num;
    else
        error('Wrong optimisation value input, optimise for either "strain", "stress" or "both".')
    end
    
    % Check if the numerical data extends beyond the experimental or not
    if max(x_num)<max(x_exp)
        cutOff=find(x_exp<max(x_num),1,'last');
    else
        cutOff=length(x_exp);
    end
    start=find(stress_exp>0.5*max(stress_exp),1,'first');
    
    % Resample the numerical data to the x-values of the experimental
    y_num_intp=interp1(x_num,y_num,x_exp(start:cutOff));
    
    % Include the failure stress and failure strain
    % [~,posE]=max(stress_exp);
    % [~,posN]=max(stress_num);
    
    % Determine the least square error
    err=sum([(y_num_intp-y_exp(start:cutOff))./y_exp(start:cutOff) ...
    %           10*(stress_exp(posE)-stress_num(posN))./stress_exp(posE)
    %           10*(strain_exp(posE)-strain_num(posN))./strain_exp(posE) ...
%                 (y_num(end)-y_exp(end))/y_exp(end)...
                ].^2);
end

end