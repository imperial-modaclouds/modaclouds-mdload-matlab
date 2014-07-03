classdef activity
% ACTIVITY defines activity objects, as part of a Layered Queueing Network (LQN) model. 
% More details on activities and their role in LQN models can be found 
% on the LINE documentation, available at http://code.google.com/p/line
%
% Properties:
% name:                 activity name (string)
% phase:                number of phases in the activity (integer, 1 or 2)
% hostDemandMean:       mean demand posed by the activity on the processor (double)
% boundToEntry:         name of the entry that calls this activity as its first activity
% synchCallDests:       list of entries called synchronously (string array)
% synchCallMeans:       list of the mean number of each synchronous call (integer array)
% asynchCallDests:      list of entries called asynchronously (string array)
% asynchCallMeans:      list of the mean number of each asynchronous call (integer array)
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

properties
    name;                 %string
    phase = 1;            %int
    hostDemandMean = 0;   %double
    boundToEntry;         %string
    synchCallDests = cell(0);  %string array
    synchCallMeans = [];  %integer array
    asynchCallDests = cell(0); %string array
    asynchCallMeans = []; %integer array
end

methods
%public methods, including constructor

    %constructor
    function obj = activity(name, phase, hostDemandMean, boundToEntry)
        if(nargin > 0)
            obj.name = name;
            obj.phase = phase;
            obj.hostDemandMean = hostDemandMean;
            obj.boundToEntry = boundToEntry;
        end
    end
    
    %addSynchCall
    function obj = addSynchCall(obj, synchCallDest, synchCallMean)
        if nargin == 3
            obj.synchCallDests{length(obj.synchCallDests)+1} = synchCallDest;
            obj.synchCallMeans = [obj.synchCallMeans; synchCallMean];
        end
    end
    
    %addAsynchCall
    function obj = addAsynchCall(obj, asynchCallDest, asynchCallMean)
        if nargin == 3
            obj.asynchCallDests{length(obj.asynchCallDests)+1} =  asynchCallDest;
            obj.asynchCallMeans = [obj.asynchCallMeans; asynchCallMean];
        end
    end
    
    
     %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'phase: ', int2str(obj.phase),'\n']);
        myString = sprintf([myString, 'meanD: ', num2str(obj.hostDemandMean(1)),'\n']);
        for j = 2:length(obj.hostDemandMean)
            myString = sprintf([myString, 'meanD',int2str(j-1),': ', num2str(obj.hostDemandMean(j)),'\n']);
        end
        myString = sprintf([myString, 'bound: ', obj.boundToEntry,'\n']);
        if ~isempty(obj.synchCallDests) 
            myString = sprintf([myString, 'synchCalls:\n']);
            for j = 1:size(obj.synchCallDests,1)
                myString = sprintf([myString, 'dest: ',obj.synchCallDests{j},'\n']);
                myString = sprintf([myString, 'mean calls: ', num2str(obj.synchCallMeans(j)),'\n']);
            end
        end
        if ~isempty(obj.asynchCallDests)  
            myString = sprintf([myString, 'synchCalls:\n']);
            for j = 1:size(obj.asynchCallDests,1)
                myString = sprintf([myString, 'dest: ',obj.asynchCallDests{j},'\n']);
                myString = sprintf([myString, 'mean calls: ', num2str(obj.asynchCallMeans(j)),'\n']);
            end
        end
    end

end
    
end