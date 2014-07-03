classdef processor
% PROCESSOR defines processor objects, as part of a Layered Queueing Network (LQN) model. 
% More details on processors and their role in LQN models can be found 
% on the LINE documentation, available at http://code.google.com/p/line
%
% Properties:
% name:                 processor name (string)
% ID:                   unique identifier of the processor (integer)
% multiplicity:         processor multiplicity (integer)
% scheduling:           scheduling policy (string)
% quantum:              processor quantum (double)
% speedFactor:          factor to modify the processor's speed (double) 
% tasks:                list of the tasks deployed on this processor (string array)
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

properties
    name;               %string
    ID;                 %int
    multiplicity;       %int
    scheduling;         %char: ps, fcfs, inf, ref
    quantum = 0;        %double
    speedFactor = 1;    %double
    tasks = [];         %list of classes
end

methods
%public methods, including constructor

    %constructor
    function obj = processor(name, multiplicity, scheduling, quantum, speedFactor)
        if(nargin > 0)
            obj.name = name;
            obj.multiplicity = multiplicity;
            obj.scheduling = scheduling;
            obj.quantum = quantum;
            obj.speedFactor = speedFactor;
        end
    end
    
    
    %addTask
    function obj = addTask(obj, newTask)
        if(nargin > 1)
            obj.tasks = [obj.tasks; newTask];
        end
    end
    
    
    %toString
    function myString = toString(obj)
        myString = ['----------\nname: ', obj.name,'\n'];
        myString = [myString, 'multi: ', int2str(obj.multiplicity),'\n'];
        myString = [myString, 'sched: ', obj.scheduling,'\n'];
        myString = [myString, 'quant: ', num2str(obj.quantum),'\n'];
        myString = [myString, 'speed: ', num2str(obj.speedFactor),'\n'];
        myString = [myString, 'tasks:\n'];
        for j = 1:length(obj.tasks)
            myString = [myString, obj.tasks(j).toString()];
        end
        myString = sprintf(myString);
    end

end
    
end