function [myCMCQNCS, classMatch, SEFF, processors] = readXML_CMCQNCS_SEFF(filename,verbose)
% Q = READXML_CMCQNCS_2(A) reads an XML file A, that holds the  
% description of an LQN model, and builds a Closed Multi-Class Queueing 
% Network with Class Switching (Q) for analysis. 
%
% Parameters:
% filename:     filepath of the XML that describes an LQN model 
% verbose:      1 for screen output
% 
% Output:
% myCMCQNCS:    Queueing Network model for analysis
% classMatch:   0-1 matrix that describes how artificial classes correspond
%               to the original classes in the model. These artificial
%               classes are created for analysis.
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

if nargin == 1; verbose = 0; end

[processors, tasks, entries, actProcs, requesters, providers] = parseXML_LQN(filename,verbose);

if ~isempty(processors)
%% build CQN model
% M: number of stations
% N: population
% S: number of servers
% rates: service rate at each node
% sched: scheduling policy in each node  \in {'inf'; 'fcfs'}; 
% nodeNames: {'delay', 'CPU'};%node names
% P: routing probabilities 

M = size(actProcs,1); % number of stations: #actual processors: processing and delay stations
S = zeros(1,M);
sched = cell(M,1);
nodeNames = cell(M,1);

check = zeros(1,M); %check nodes corresponding to processing, leaving delay as zero
for k = 1:M
    if ~isempty( find(cell2mat({providers{:,5}}) == actProcs{k,2},1 ) ) % if the proc is a provider (processing, not delay)
        procIndex = actProcs{k,2}; %index according to procID
        myProc = processors(procIndex);
        nodeNames{k} = myProc.name;
        S(k) = myProc.multiplicity;
        sched{k} = myProc.scheduling;
        check(k) = 1;
    end
end

% delay node
delayNodeIndex = find(check==0);
delayProcIndex = actProcs{delayNodeIndex,2};
myDelay = processors(delayProcIndex);
N = myDelay.tasks(1).multiplicity;
S(delayNodeIndex) = -1;
sched{delayNodeIndex} = 'inf';
nodeNames{delayNodeIndex} = myDelay.name;

actGraph = myDelay.tasks.actGraph;
actCalls = myDelay.tasks.actCalls;
initAct = myDelay.tasks.initActID;

% determine branching node
callIdx = -1;
for i = 1:size(actCalls,1)
    if ~isempty(actCalls{i})
        callIdx = i; %index of activity that generates a call
        break;
    end
end
branchIdx = find(actGraph(:,i-1)>0); % index of branching activity is that if the one that precedes the callIdx
if isempty(branchIdx)%% no branching - single class
    K = 1;
    NK = N;
    afterBranch = callIdx-1;
    branchProbs = 1;
else
    K = size(find(actGraph(branchIdx,:)),2); %number of classes: number of different patterns defined in the delay node
    NK = zeros(K,1);
    afterBranch = find(actGraph(branchIdx,:));
    branchProbs = zeros(1,K);
    
    % no rounding
    for k = 1:K
        NK(k) = N*actGraph(branchIdx, afterBranch(k));
        branchProbs(k) = actGraph(branchIdx, afterBranch(k));
    end
    
end
classNames = cell(K,1); %a name for each job class
rates = zeros (M,K);


%at this point: missing rates per class and station, and routing matrices per class
P = cell(K,1);
fullP = zeros(M*K,M*K);
fullMeanDemands = zeros(M,K);
actK = K; %actual number of classes, initially = K, may increase
classMatch = eye(K); % matching between original classes (rows) and all 
                     % classes (cols)
SEFFcalls_proc = cell(M,K); % names of the processors with the SEFF calls
SEFFcalls_act = cell(M,K);  % names of the activities with the SEFF calls
SEFF = cell(size(processors,1),2);
numActs = zeros(size(processors,1),1);
for k = 1:K
    P{k} = zeros(M);
    %determine relevant entry - task -activities
    callAct = afterBranch(k) + 1; %two acts after the branch 
    
    if ~isempty(actCalls{callAct,1})
        targetEntry = actCalls{callAct,1};
        targetEntryIdx = getIndexCellString(entries, targetEntry);
        targetTaskIdx = entries{targetEntryIdx,2};
        targetProcIdx = tasks{targetTaskIdx,4};
        myProc = processors(targetProcIdx);
        myActGraph = myProc.tasks.actGraph;
        myActCalls = myProc.tasks.actCalls;
        myInitAct = myProc.tasks.initActID;
        myCurActIdx = myInitAct; %current activities - rows
        
        LQNprocIdx = targetProcIdx;
        LQNactIdx = myCurActIdx;
        
        myCurProcID = delayProcIndex;
        pBranch = 1;
        
        visited = zeros(M,K); % by class k
        visited(delayNodeIndex,k) = 1;
        currentClass = k;
        fullMeanDemands(delayNodeIndex,k) = myDelay.tasks.thinkTime;
        [fullP, fullMeanDemands, myCurProcID, visited, currentClass, classMatch,SEFFcalls_proc,SEFFcalls_act,SEFF,numActs] = ...
                            readXML_CMCQNCS_addEntriesP_SEFF(...
                            myActGraph, processors, tasks, entries, myActCalls, actProcs, actK, ...
                            fullP, fullMeanDemands, visited, currentClass, classMatch, k,...
                            myCurActIdx, myCurProcID, pBranch,...
                            SEFFcalls_proc,SEFFcalls_act, LQNprocIdx, LQNactIdx, SEFF,numActs);%
        actK = size(fullP,1)/M;
        classNames{k,1} = targetEntry;
        nextActs = find(actGraph(callAct,:)>0);
        while ~isempty(nextActs) && ~isempty(actCalls{nextActs(1),1})
            callAct = nextActs(1);
            targetEntry = actCalls{callAct,1};
            targetEntryIdx = getIndexCellString(entries, targetEntry);
            targetTaskIdx = entries{targetEntryIdx,2};
            targetProcIdx = tasks{targetTaskIdx,4};
            myProc = processors(targetProcIdx);
            myActGraph = myProc.tasks.actGraph;
            myActCalls = myProc.tasks.actCalls;
            myInitAct = myProc.tasks.initActID;
            myCurActIdx = myInitAct; %current activities - rows
            LQNprocIdx = targetProcIdx;
            LQNactIdx = myInitAct; 
            pBranch = 1;
            
            [fullP, fullMeanDemands, myCurProcID, visited, currentClass, classMatch,SEFFcalls_proc,SEFFcalls_act,SEFF,numActs] = ...
                                readXML_CMCQNCS_addEntriesP_SEFF(...
                                myActGraph, processors, tasks, entries, myActCalls, actProcs, actK, ...
                                fullP, fullMeanDemands, visited, currentClass, classMatch, k,...
                                myCurActIdx, myCurProcID, pBranch,...
                                SEFFcalls_proc,SEFFcalls_act, LQNprocIdx, LQNactIdx, SEFF,numActs);%
            actK = size(fullP,1)/M;
            nextActs = find(actGraph(callAct,:)>0);
        end
        
        % transitions back to the delay node
        lastProc = processors(myCurProcID);
        lastProcIdx = getIndexCellString({actProcs{:,1}}', lastProc.name);
        
        % transitions back to the delay node - full CS representation
        fullP((lastProcIdx-1)*actK+currentClass, (delayNodeIndex-1)*actK+currentClass ) = 1;
    end
end

%total number of classes
fullK = size(fullP,1)/M;
%rates for all the classes
fullRates = zeros(M*fullK,1);
fullRates(fullMeanDemands > 0) = 1./fullMeanDemands(fullMeanDemands > 0);
fullRates = reshape(fullRates, M, fullK);
%numbers per class
fullNK = [NK;zeros(fullK-K,1)];
%classnames
fullClassNames = cell(fullK,1);
fullClassNames(1:K) = classNames;
for k = K+1:fullK
    fullClassNames{k} = ['artificialClass', int2str(k-K)];
end

% eliminate unnecesary classes (zero demand) - full representation
for j = 1:fullK
    % classes with routing probabilities == 0
    if max(max(fullP(:,j:fullK:fullK*M) )) == 0
        idx = [1:j-1 j+1:fullK];
        idx2 = [1:j-1 j+1:K];
        fullIdx = reshape(1:M*fullK,fullK,M);
        fullIdx = reshape(fullIdx(idx,:),1,[]);
        
        %new distribution of job numbers - no rounding
        fullNK = fullNK(idx);   % removing jobs from irrelevant classes
        branchProbs = branchProbs(idx2)/sum(branchProbs(idx2));
       
        fullRates = fullRates(:,idx);
        fullP = fullP(fullIdx,fullIdx);
        N = sum(fullNK);        % removing jobs from irrelevant classes
        fullClassNames = fullClassNames(idx,:);
        fullK = fullK - 1; 
       
        classMatch = [classMatch(idx2,idx2) classMatch(idx2,K+1:end)];
        K = K-1;
    end
    

end

%% correct transitions to delay node to account for class switching 
delayCols = (delayNodeIndex-1)*fullK+1:delayNodeIndex*fullK;
fullP(:,delayCols) = sum(fullP(:,delayCols),2) * [branchProbs zeros(1,fullK-K)];

%% final model
myCMCQNCS = CMCQNCS(M, fullK, N, S, fullRates, sched, fullP, fullNK, nodeNames, fullClassNames);

else
   disp('Error: XML file empty or unexistent');
   myCMCQNCS = [];
   branchProbs = [];
end

