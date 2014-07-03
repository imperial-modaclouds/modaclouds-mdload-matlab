function [processors, tasks, entries, actProcs, requesters, providers] = parseXML_LQN(filename, verbose)
% PARSEXML_LQN parses an XML file containing an LQN model
%
% Parameters: 
% filename:     location of the XML file to parse
% verbose:      1 for screen output
% 
% Output: 
% processors:   actual description of the LQN by means of processors, tasks, entries and activities objects 
% tasks:        list of tasks (task name, task ID, proc name, proc ID)
% entries:      list of entries (entry name, task ID)
% actProcs:     list of physical processors and workload sources (proc name, proc ID, task name, task ID)
% requesters:   list of activities that demand a service from an entry
%                (act name, task ID, proc name, target entry, procID)
% providers:    list of activities/entries that provide services 
%                (act name, entry name, task name, proc name, proc ID)
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.


import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;


dbFactory = DocumentBuilderFactory.newInstance();
dBuilder = dbFactory.newDocumentBuilder();
try
    doc = dBuilder.parse(filename);
catch exception %java.io.FileNotFoundException
    if ~exist(filename, 'file')
        disp('Error: Input XML file not found');
        processors = [];
        tasks = [];
        entries = [];
        actProcs = [];
        requesters = [];
        providers = [];
        return;
    else 
        rethrow(exception);
    end
end
 
doc.getDocumentElement().normalize();
 
disp(['Root element :', char(doc.getDocumentElement().getNodeName()) ] );
 
%NodeList 
procList = doc.getElementsByTagName('processor');

processors = [];
providers = cell(0); % list of entries that provide services - Entry, Task, Proc
requesters = cell(0); % list of activities that request services - Act, Task, Proc
tasks = cell(0); %list of tasks - Task, task ID, Proc, ProcID - Row Index as task ID
entries = cell(0); %list of entries - Entry, Task ID
taskID = 1;
actProcs = cell(0); %list of actual processors, those thata receive demand for resources
                    %demand is always indicated in an entry activity
procID = 1;

clients = []; % list of tasks that act as pure clients (think time)
for i = 0:procList.getLength()-1
    %Node - Processor
    procNode = procList.item(i);
       
    if procNode.getNodeType() == Node.ELEMENT_NODE
        
        %Element 
        procElement = procNode;
        name = char(procElement.getAttribute('name')); 
        multiplicity = str2num(char(procElement.getAttribute('multiplicity'))); 
        scheduling = char(procElement.getAttribute('scheduling')); 
        quantum = str2double(char(procElement.getAttribute('quantum'))); 
        speedFactor = str2double(char(procElement.getAttribute('speed-factor'))); 
        tempProc = processor(name, multiplicity, scheduling, quantum, speedFactor);
        
        taskList = procNode.getElementsByTagName('task');
        for j = 0:taskList.getLength()-1
            %Node - Task
            taskNode = taskList.item(j);
            if taskNode.getNodeType() == Node.ELEMENT_NODE
            %Element 
            taskElement = taskNode;
            name = char(taskElement.getAttribute('name')); 
            multiplicity = str2num(char(taskElement.getAttribute('multiplicity'))); 
            scheduling = char(taskElement.getAttribute('scheduling')); 
            thinkTime = str2double(char(taskElement.getAttribute('think-time'))); 
            actGraph = char(taskElement.getAttribute('activity-graph')); 
            tempTask = task(name, multiplicity, scheduling, thinkTime, actGraph);
            
            % determine reference task
            if strcmp(tempTask.scheduling, 'ref')
                if thinkTime > 0 
                    clients = [clients; taskID];
                    if isempty(find(cell2mat( {actProcs{:,2}}) == procID))
                        actProcs{size(actProcs,1)+1,1} = tempProc.name;
                        actProcs{size(actProcs,1),2} = procID;
                        actProcs{size(actProcs,1),3} = tempTask.name;
                        actProcs{size(actProcs,1),4} = taskID;
                    end
                else
                    err = MException('ParseLQNXML:ZeroThinkTime', ...
                        ['The think time specified in ', tempProc.name, ' is zero.\nThink time must be a positive real']);
                    throw(err);
                    
                    
                end
            end
            
            
            entryList = taskNode.getElementsByTagName('entry');
            for k = 0:entryList.getLength()-1
                %Node - Task
                entryNode = entryList.item(k);
                if entryNode.getNodeType() == Node.ELEMENT_NODE
                %Element 
                entryElement = entryNode;
                name = char(entryElement.getAttribute('name')); 
                type = char(entryElement.getAttribute('type')); 
                tempEntry = entry(name, type);
                
                                
                actList = entryNode.getElementsByTagName('activity');
                for l = 0:actList.getLength()-1
                    %Node - Task
                    actNode = actList.item(l);
                    if actNode.getNodeType() == Node.ELEMENT_NODE
                    %Element 
                    actElement = actNode;
                    name = char(actElement.getAttribute('name')); 
                    phase = str2num(char(actElement.getAttribute('phase'))); 
                    demandMean = str2double(char(actElement.getAttribute('host-demand-mean'))); 
                    boundEntry = char(actElement.getAttribute('bound-to-entry')); 
                    tempAct = activity(name, phase, demandMean, boundEntry);
                    
                    providers{size(providers,1)+1,1} = tempAct.name;
                    providers{size(providers,1),2} = tempEntry.name;
                    providers{size(providers,1),3} = tempTask.name;
                    providers{size(providers,1),4} = tempProc.name;
                    providers{size(providers,1),5} = procID;
                    
                    %providers:
                    % activity - entry - task - processor
                    
                    %actual processors
                    if demandMean > 0 && isempty(find(cell2mat( {actProcs{:,2}}) == procID))
                        actProcs{size(actProcs,1)+1,1} = tempProc.name;
                        actProcs{size(actProcs,1),2} = procID;
                        actProcs{size(actProcs,1),3} = tempTask.name;
                        actProcs{size(actProcs,1),4} = taskID;
                    end
                    tempEntry = tempEntry.addActivity(tempAct);
                    end
                end
                
                
                entries{size(entries,1)+1,1} = tempEntry.name;
                entries{size(entries,1),2} = taskID;
                tempTask = tempTask.addEntry(tempEntry);
                end
            end
            
            %% task-activities
            if taskElement.getElementsByTagName('task-activities').getLength > 0
                actNames = cell(0); iterActNames = 1;
                actCalls = cell(0);
                actList = taskElement.getElementsByTagName('task-activities').item(0).getElementsByTagName('activity');
                for l = 0:actList.getLength()-1
                    %Node - Task
                    actNode = actList.item(l);
                    if actNode.getNodeType() == Node.ELEMENT_NODE && strcmp(char(actNode.getParentNode().getNodeName()),'task-activities')
                    %Element 
                    actElement = actNode;
                    name = char(actElement.getAttribute('name')); 
                    phase = str2num(char(actElement.getAttribute('phase'))); 
                    demandMean = str2double(char(actElement.getAttribute('host-demand-mean'))); 
                    boundEntry = char(actElement.getAttribute('bound-to-entry')); 
                    tempAct = activity(name, phase, demandMean, boundEntry);
                    actNames{iterActNames,1} = name;
                    if ~isempty(boundEntry)
                        tempTask = tempTask.setInitActivity(iterActNames);
                    end
                    
                    %add synch calls if any
                    synchCalls = actElement.getElementsByTagName('synch-call');
                    if synchCalls.getLength() > 0
                        for m = 0:synchCalls.getLength()-1
                            callElement = synchCalls.item(m);
                            dest = char(callElement.getAttribute('dest'));
                            mean = str2double(char(callElement.getAttribute('calls-mean')));
                            tempAct = tempAct.addSynchCall(dest,mean);
                            actCalls{iterActNames,1} = dest;
                            requesters{size(requesters,1)+1,1} = tempAct.name;
                            requesters{size(requesters,1),2} = taskID;
                            requesters{size(requesters,1),3} = tempProc.name;
                            requesters{size(requesters,1),4} = dest;
                            requesters{size(requesters,1),5} = procID;
                            %requesters:
                            % activity - task - processor - dest (entry) - procID
                        end
                    else
                        actCalls{iterActNames,1} = [];
                    end
                    iterActNames = iterActNames + 1; 
                    %add asynch calls if any
                    asynchCalls = actElement.getElementsByTagName('asynch-call');
                    if asynchCalls.getLength() > 0
                        for m = 0:asynchCalls.getLength()-1
                            callElement = asynchCalls.item(m);
                            dest = char(callElement.getAttribute('dest'));
                            mean = str2double(char(callElement.getAttribute('calls-mean')));
                            tempAct = tempAct.addAsynchCall(dest,mean);
                        end
                    end
                    tempTask = tempTask.addActivity(tempAct);
                    end
                end
                 %precedences
                precList = taskElement.getElementsByTagName('task-activities').item(0).getElementsByTagName('precedence');
                actGraph = zeros(length(actNames));
                for l = 0:precList.getLength()-1
                    %Node - Precedence
                    precNode = precList.item(l);
                    if precNode.getNodeType() == Node.ELEMENT_NODE 
                    %Element 
                    precElement = precNode;
                    
                   
                    %pre
                    presList = precElement.getElementsByTagName('pre');
                    if presList.getLength > 0 
                        pres = cell(1);
                        pres{1} = char(presList.item(0).getElementsByTagName('activity').item(0).getAttribute('name'));
                        preType = 'single';
                        
                        preIdxs = getIndexCellString(actNames,pres{1});
                    else
                        presList = precElement.getElementsByTagName('pre-OR').item(0).getElementsByTagName('activity');
                        pres = cell(presList.getLength,1);
                        preIdxs = zeros(presList.getLength,1);
                        for m = 1:presList.getLength
                            pres{m} = char(presList.item(m-1).getAttribute('name'));
                            preIdxs(m) = getIndexCellString(actNames,pres{m});
                        end
                        preType = 'OR';
                    end
                    
                    %post
                    postsList = precElement.getElementsByTagName('post');
                    if postsList.getLength > 0 
                        posts = cell(1);
                        postProbs = [];
                        posts{1} = char(postsList.item(0).getElementsByTagName('activity').item(0).getAttribute('name'));
                        postType = 'single';
                        
                        postIdxs = getIndexCellString(actNames,posts{1});
                    else
                        postsList = precElement.getElementsByTagName('post-OR').item(0).getElementsByTagName('activity');
                        posts = cell(postsList.getLength,1);
                        postProbs = zeros(postsList.getLength,1);
                        postIdxs = zeros(postsList.getLength,1);
                        for m = 1:postsList.getLength
                            posts{m} = char(postsList.item(m-1).getAttribute('name'));
                            postProbs(m) = str2double( char(postsList.item(m-1).getAttribute('prob')) );
                            postIdxs(m) = getIndexCellString(actNames,posts{m});
                        end
                        postType = 'OR';
                    end
                    tempPrec = precedence(pres, posts, preType, postType, postProbs);
                    tempTask = tempTask.addPrecedence(tempPrec);
                    
                    if length(postIdxs) == 1
                        for kIn = preIdxs
                            actGraph(kIn,postIdxs) = 1;
                        end
                    else
                        for kOut = 1:length(postIdxs)
                            actGraph(preIdxs, postIdxs(kOut)) = postProbs(kOut);
                        end
                    end
                    end
                end
                if nargin > 1 && verbose > 1; 
                    actNames2 = actNames;
                    actNames2{1} = [actNames2{1}, '  ', tempTask.name];
                    view(biograph(actGraph,actNames2)); 
                end
                tempTask = tempTask.setActGraph(actGraph,actNames,actCalls);
            end
            
            tasks{size(tasks,1)+1,1} = tempTask.name;
            tasks{size(tasks,1),2} = taskID;
            tasks{size(tasks,1),3} = tempProc.name;
            tasks{size(tasks,1),4} = procID;
            tempProc = tempProc.addTask(tempTask);
            taskID = taskID + 1;
            procID = procID + 1;
            end
        end
        if verbose > 0; disp(tempProc.toString()); end
        processors = [processors; tempProc];
    end
end


%% build graph relating tasks and processors
if nargin > 1 && verbose > 1
    T = size(tasks,1); %number of tasks
    adjTasks = sparse(T,T);
    for i = 1:size(requesters,1)
        IDSource = requesters{i,2};
        entryReq = requesters{i,4};
        for j = 1:size(entries,1)
            if strcmp(entryReq,entries{j,1})
                IDSink = entries{j,2};
                break;
            end
        end
        adjTasks(IDSource,IDSink) = adjTasks(IDSource,IDSink) + 1; 
    end

    spy(adjTasks)
    inCard = sum(adjTasks,1)';
    outCard = sum(adjTasks,2);
    totCard = inCard + outCard;

    irredIDs = full(find(totCard > 0));
    h = view(biograph(adjTasks(irredIDs, irredIDs),{tasks{irredIDs,1}}))
    order = irredIDs( graphtopoorder( adjTasks(irredIDs, irredIDs) ) );
    

    %% add procs to graph
    n0 = size(adjTasks,1);
    n1 = size(actProcs,1);
    taskProcGraph = [adjTasks zeros(n0,n1);
                     zeros(n1,n0+n1);];   

    for i = 1:size(actProcs,1)
        taskProcGraph(actProcs{i,4},n0+i) = 1;
    end
    nodeNames = {tasks{irredIDs,1}}';
    nodeNames = [nodeNames; {actProcs{:,1}}' ];
    irredIDs = [irredIDs; (n0+1:n0+n1)'];
    h = view(biograph(taskProcGraph(irredIDs, irredIDs),nodeNames))
end