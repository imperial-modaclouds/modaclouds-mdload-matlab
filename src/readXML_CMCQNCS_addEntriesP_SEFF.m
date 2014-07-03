function [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch,SEFFcalls_proc,SEFFcalls_act,SEFF,numActs] = ...
                                readXML_CMCQNCS_addEntriesP_SEFF(...
                                actGraph, processors, tasks, entries, actCalls, actProcs, K,...
                                fullP, fullMeanDemands, visited, currentClass, classMatch, origClass,...
                                curActIdx, curProcID, pBranch,...
                                SEFFcalls_proc,SEFFcalls_act, LQNprocIdx,LQNactIdx,SEFF,numActs)
% READXML_CMCQNCS_ADDENTRIESP_SEFF is a recursive function that helps to build 
% the queueing network model for analysis, starting from the XML file 
% that describes an LQN model. 
% 
% Parameters:                            
% actGraph:         activity graph linking the activities currently under analysis
% processors:       full list and characterization of the processors
% tasks:            list of task names and their corresponding processors
% entries:          list of entries and their corresponding tasks
% actCalls:         calls made by each of the activities under analysis
% actProcs:         actual (hardware) processors
% K:                total number of classes (may vary along the search)
% fullP:            full routing matrix (for all classes)
% meanDemands:      mean demands for current class
% fullMeanDemands:  mean demands for all classes
% visited:          boolean vector with 1 if entry i if processor i was already
%                   visited by the current class
% currentClass:     current class under analysis
% curActIdx:        index of the current activity 
% curProcID:        ID of the current processor
% pBranch:          last known probability of a branch                        
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

M = size(visited,1); %number of stations
if ~isempty(curActIdx)
    %next activities to visit - columns
    nextActIdx = actGraph(curActIdx,:)>0;
    
    newPBranch = zeros(1,length(find(nextActIdx>0)));
    nextProcID = [];
    k = 1;
    for j = find(nextActIdx>0)
        LQNactIdx(end) = j; %updates activity that is being called in the current processor
        if ~isempty(actCalls{j,1})
            targetEntry = actCalls{j,1};
            targetEntryIdx = getIndexCellString({entries{:,1}}', targetEntry);
            targetTaskID = entries{targetEntryIdx,2};
            targetProcID = tasks{targetTaskID,4};
            if find( cell2mat( {actProcs{:,2}}) == targetProcID)
                % target processor is a physical processor 
                % proceed to determine mean demand and transition probs
                
                targetProcIdx = find(cell2mat({actProcs{:,2}}) == targetProcID);
                numCurProcs = length(curProcID);
                curProcIdx = zeros(numCurProcs,1);
                for p = 1:numCurProcs
                    curProcIdx(p) = find(cell2mat({actProcs{:,2}}) == curProcID(p));
                end
                
                if sum(visited(targetProcIdx,currentClass),2) == size(currentClass,1) % next processor already visited by the current class - consider multiple current classes
                    % create a new class, and tie the two classes
                    %CS def
                    newClass = K+1;
                    
                    newIdx = 1:M*(K+1);
                    newIdx = reshape(newIdx,K+1,M);
                    newIdx = reshape(newIdx(1:K,:) ,1,[]);
                    newfullP = zeros(M*(K+1), M*(K+1));
                    newfullP(newIdx,newIdx) = fullP;
                    fullP = newfullP;
                    for p = 1:numCurProcs  
                        fullP((curProcIdx(p)-1)*(K+1)+currentClass(p), (targetProcIdx-1)*(K+1)+newClass ) = pBranch;%*ones(size(currentClass));
                    end
                    
                    fullMeanDemands = [fullMeanDemands zeros(M,1)];
                    fullMeanDemands(targetProcIdx,newClass) =...
                        processors(targetProcID).tasks(1).getMeanHostDemand(targetEntry);
                    
                    %mark SEFF
                    for procs = 1:length(LQNprocIdx)
                        if isempty(SEFF{LQNprocIdx(procs),1})
                            SEFF{LQNprocIdx(procs),1,1} = processors(LQNprocIdx(procs)).tasks.actNames{j};
                            SEFF{LQNprocIdx(procs),2,1} = [targetProcIdx newClass LQNactIdx(procs)];
                            numActs(LQNprocIdx(procs)) = 1;
                        else
                            actIndex = getIndexCellString( {SEFF{LQNprocIdx(procs),1,:}}', processors(LQNprocIdx(end)).tasks.actNames{j});
                            if actIndex == -1
                                numActs(LQNprocIdx(procs)) = numActs(LQNprocIdx(procs))+1; 
                                SEFF{LQNprocIdx(procs),1,numActs(LQNprocIdx(procs))} = processors(LQNprocIdx(end)).tasks.actNames{j} ;
                                SEFF{LQNprocIdx(procs),2,numActs(LQNprocIdx(procs))} = [targetProcIdx newClass LQNactIdx(procs)];
                            else
                                SEFF{LQNprocIdx(procs),2,actIndex} = [SEFF{LQNprocIdx(procs),2,actIndex};targetProcIdx newClass LQNactIdx(procs)];
                            end
                        end
                    end
                    
                    %if the probability is used, reset it to 1
                    pBranch = 1; 
                    % update current Class and class number
                    currentClass = newClass;
                    K = K+1;
                    %update visited
                    visited = [visited zeros(M,1)];
                    visited(targetProcIdx,end) = 1;
                    
                    
                    %update matching between classes
                    classMatch = [classMatch zeros(size(classMatch,1),1)];
                    classMatch(origClass,end) = 1;
                else %next processor different from current processor
                   
                    %CD def
                    nonVis = find(visited(targetProcIdx,currentClass) == 0); %indices of the current classes that have not visited the current processor
                    newClass = currentClass(nonVis(end)); %choose the last class among the current classes - it's enough to keep this one as the current one from now on
                    for p = 1:numCurProcs
                        fullP((curProcIdx(p)-1)*K+currentClass(p), (targetProcIdx-1)*K+newClass ) = pBranch;
                    end
                    currentClass = newClass;
                    
                    fullMeanDemands(targetProcIdx,currentClass) = processors(targetProcID).tasks(1).getMeanHostDemand(targetEntry);
                    %visited(targetProcIdx) = 1;
                    visited(targetProcIdx,currentClass) = 1;
                    
                    %mark SEFF
                    for procs = 1:length(LQNprocIdx)
                        if isempty(SEFF{LQNprocIdx(procs),1})
                            SEFF{LQNprocIdx(procs),1,1} = processors(LQNprocIdx(procs)).tasks.actNames{j};
                            SEFF{LQNprocIdx(procs),2,1} = [targetProcIdx currentClass LQNactIdx(procs)];
                            numActs(LQNprocIdx(procs)) = 1;
                        else
                            actIndex = getIndexCellString( {SEFF{LQNprocIdx(procs),1,:}}', processors(LQNprocIdx(end)).tasks.actNames{j});
                            if actIndex == -1
                                numActs(LQNprocIdx(procs)) = numActs(LQNprocIdx(procs))+1; 
                                SEFF{LQNprocIdx(procs),1,numActs(LQNprocIdx(procs))} = processors(LQNprocIdx(end)).tasks.actNames{j} ;
                                SEFF{LQNprocIdx(procs),2,numActs(LQNprocIdx(procs))} = [targetProcIdx currentClass LQNactIdx(procs)];
                            else
                                SEFF{LQNprocIdx(procs),2,actIndex} = [SEFF{LQNprocIdx(procs),2,actIndex};targetProcIdx currentClass LQNactIdx(procs)];
                            end
                        end
                    end
                    %if the probability is used, reset it to 1
                    pBranch = 1;
                end
                nextProcID = [nextProcID; targetProcID];
                
                
            else
                % target processor is not a physical processor
                % an additional layer must be covered

                myProc = processors(targetProcID);
                myActGraph = myProc.tasks.actGraph;
                myActCalls = myProc.tasks.actCalls;
                myInitAct = myProc.tasks.initActID;
                myCurActIdx = myInitAct; %current activities - rows
                myCurProcID = curProcID; %delayNodeIndex;
                
                LQNprocIdx = [LQNprocIdx targetProcID];
                LQNactIdx = [LQNactIdx myInitAct];
                pBranch = 1;

                [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch,SEFFcalls_proc,SEFFcalls_act,SEFF,numActs] =...
                                    readXML_CMCQNCS_addEntriesP_SEFF(...
                                    myActGraph, processors, tasks, entries, myActCalls, actProcs, K, ...
                                    fullP, fullMeanDemands, visited, currentClass, classMatch, origClass,...
                                    myCurActIdx, myCurProcID, pBranch,...
                                    SEFFcalls_proc,SEFFcalls_act, LQNprocIdx,LQNactIdx,SEFF,numActs);%
                K = size(fullP,1)/M;
            end
        end
        newPBranch(k) = actGraph(curActIdx,j);
        k = k + 1;
    end
    
    curActIdx = find(nextActIdx(1,:)>0);
    
    if ~isempty(nextProcID)
        curProcID = nextProcID;
    end
    
    %recursion for each "next" activity in the graph
    %baseClass is the currentClass that is the basis for all the next activities
    baseClass = currentClass; 
    %baseProcID is the curProcID that is the basis for all the next activities
    baseProcID = curProcID;
    %finalClasses of each branch
    finalClasses = [];
    finalProcIDs = [];
    for j = 1:length(curActIdx)
        [fullP, fullMeanDemands, curProcID, visited, currentClass, classMatch,SEFFcalls_proc,SEFFcalls_act,SEFF,numActs] =...
                                    readXML_CMCQNCS_addEntriesP_SEFF(...
                                    actGraph, processors, tasks, entries, actCalls, actProcs, K,...
                                    fullP, fullMeanDemands, visited, baseClass, classMatch, origClass,...
                                    curActIdx(j), baseProcID, pBranch*newPBranch(j),...
                                    SEFFcalls_proc,SEFFcalls_act, LQNprocIdx,LQNactIdx,SEFF,numActs);
        if ~isempty(currentClass)
            finalClasses = [finalClasses; currentClass]; %consider multiple current classes
            finalProcIDs = [finalProcIDs; curProcID];
        else
            finalClasses = [finalClasses; baseClass];
            finalProcIDs = [finalProcIDs; baseProcID];
        end
        K = size(fullP,1)/M;
    end
    % return all the final classes as the current class
    currentClass = finalClasses;
    curProcID = finalProcIDs; 
end
