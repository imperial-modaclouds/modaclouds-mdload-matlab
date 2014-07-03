classdef task
% TASK defines task objects, as part of a Layered Queueing Network (LQN) model. 
% More details on tasks and their role in LQN models can be found 
% on the LINE documentation, available at http://code.google.com/p/line
%
% Properties:
% name:                 task name (string)
% multiplicity:         task multiplicity (integer)
% scheduling:           scheduling policy (string)
% thinkTime:            mean think time of the workload associated with the task, if any (double)
% activityGraph:        string
% entries:              array of entries associated to the 
% activities:           activities executed by the task
% initActID:            index of the initial activity (integer)
% precedences:          array of the precedences among the activities 
% replyEntry:           entry called when the task is called
% actGraph:             mxm matrix representing the activity graph  
% actNames:             names of the task activities (mx1 cell)
% actCalls:             names of the entries that each task activity calls (mx1 cell) 
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.
    
properties
    name;               %string
    multiplicity;       %int
    scheduling;         %string
    thinkTime;          %double
    activityGraph;      %string
    entries = [];
    activities = [];     %task-activities
    initActID = 0;       %integer that indicates which is the initial activity
    precedences = [];
    replyEntry;
    actGraph = [];      %mxm matrix representing activity graph (m number of activities) 
    actNames = cell(0); %mx1 cell with the names of the task activities
    actCalls = cell(0); %mx1 cell with the names of the entries that each task activity calls
end


methods
%public methods, including constructor

    %constructor
    function obj = task(name, multiplicity, scheduling, thinkTime, activityGraph)
        if(nargin > 0)
            obj.name = name;
            obj.multiplicity = multiplicity;
            obj.scheduling = scheduling;
            obj.thinkTime = thinkTime;
            obj.activityGraph = activityGraph;
        end
    end
    
    %addEntry
    function obj = addEntry(obj, newEntry)
        if(nargin > 1)
            obj.entries = [obj.entries; newEntry];
        end
    end
    
    %addActivity
    function obj = addActivity(obj, newAct)
        if(nargin > 1)
            obj.activities = [obj.activities; newAct];
        end
    end
    
    %setInitActivity
    function obj = setInitActivity(obj, initActID)
        if(nargin > 1)
            obj.initActID = initActID;
        end
    end
        
    %addPrecedence
    function obj = addPrecedence(obj, newPrec)
        if(nargin > 1)
            obj.precedences = [obj.precedences; newPrec];
        end
    end
    
    %setReplyEntry
    function obj = setReplyEntry(obj, newReplyEntry)
        if(nargin > 1)
            obj.replyEntry = newReplyEntry;
        end
    end
    
    %setActGraph   setActGraph
    function obj = setActGraph(obj, actGraph, actNames, actCalls)
        if nargin > 2
            obj.actGraph = actGraph;
            obj.actNames = actNames;
            obj.actCalls = actCalls;
        end
    end
        
    function meanHostDemand = getMeanHostDemand(obj, entryName)
        % determines the demand posed by the entry entryName
        % the demand is located in the activity of the corresponding entry
        
        meanHostDemand = -1;
        for j = 1:length(obj.entries)
            if strcmp(obj.entries(j).name, entryName)
                meanHostDemand = obj.entries(j).activities(1).hostDemandMean;
                break;
            end
        end
    
    end    
        
    %toString
    function myString = toString(obj)
        myString = sprintf(['+++++++++\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'multi: ', int2str(obj.multiplicity),'\n']);
        myString = sprintf([myString, 'sched: ', obj.scheduling,'\n']);
        myString = sprintf([myString, 'think: ', num2str(obj.thinkTime(1)),'\n']);
        for j =2:length(obj.thinkTime)
            myString = sprintf([myString, 'think',int2str(j-1),': ', num2str(obj.thinkTime(j)),'\n']);
        end
        myString = sprintf([myString, 'actGr: ', num2str(obj.activityGraph),'\n']);
        myString = sprintf([myString, 'entries:\n']);
        for j = 1:length(obj.entries)
            myString = sprintf([myString, obj.entries(j).toString()]);
        end
        myString = sprintf([myString, 'task-activities:\n']);
        for j = 1:length(obj.activities)
            myString = sprintf([myString, obj.activities(j).toString()]);
        end
        myString = sprintf([myString, 'task-precedences:\n']);
        for j = 1:length(obj.precedences)
            myString = sprintf([myString, obj.precedences(j).toString()]);
        end
    end
end
    
end