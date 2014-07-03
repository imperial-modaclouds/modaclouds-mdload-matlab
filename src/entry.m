classdef entry
% ENTRY defines entry objects, as part of a Layered Queueing Network (LQN) model. 
% More details on entries and their role in LQN models can be found 
% on the LINE documentation, available at http://code.google.com/p/line
%
% Properties:
% name:                 entry name (string)
% type:                 entry type (string)
% activities:           list of activities executed by this entry (string array)
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.


properties
    name;
    type;
    activities = [];
end

methods
%public methods, including constructor

    %constructor
    function obj = entry(name, type)
        if(nargin > 0)
            obj.name = name;
            obj.type = type;
        end
    end
    
    %addActivity
    function obj = addActivity(obj, newActivity)
        if(nargin > 1)
            obj.activities = [obj.activities; newActivity];
        end
    end
        
    %toString
    function myString = toString(obj)
        myString = sprintf(['**********\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'type: ', obj.type,'\n']);
        myString = sprintf([myString, 'activities:\n']);
        for j = 1:length(obj.activities)
            myString = sprintf([myString, obj.activities(j).toString()]);
        end
    end
end
    
end