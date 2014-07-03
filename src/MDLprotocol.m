classdef MDLprotocol
% MDLPROTOCOL defines an object to control the interaction between the
% MDL client and the server. It handles a set of instructions from the
% MDL client and returns responses according to the results from the
% solver
%
% MDLPROTOCOL maintains the LINE object that solves the model,
% processes the input instructions for the solver in the LINE object, 
% and call these solvers. 
%
% Properties:
% state:        state of the protocol
%               values:  
%               EMPTY:  no model has been loaded
%               INIT:   a model has been loaded, no model has been run
%               SOLVED: a model has been run
% myLINE:       LINE object
% SEQ:          1 if LINE operates sequentially
%               0 (default) if LINE operates in parallel
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

properties
    EMPTY = 0;      % no model has been loaded
    INIT = 1;       % a model has been loaded
    %SOLVED = 2;     % a model has been run
    state;          % initial state = waiting
    %myLINE;         % LINE object
    model;          % LQN model to derive requests
    refTask;        % Index of the reference task in the model
    reqs;           % Set of requests' names (activities names in the reference task)
    reqCalls;       % Set of requests' calls (activities calls in the reference task)
    P;              % Request transition matrix (activity graph in the reference task)
    currReq;        % Index of the current request (activitity in the reference task)
    initReq;        % Index of the initial request (activity) 
end


methods
    % Constructor
    function obj = MDLprotocol()
        obj.state = obj.EMPTY;                  % initial state = empty
        %obj.myLINE = LINE_obj_SEFF(maxIter);    % LINE object (version for SEFF reporting)
        obj.currReq = 0;                        % Initially in request 0
    end

    % This function process the (single) input lines 
    % The three accepted commands are those staring with LOAD, NEXT, and QUIT
    function [theOutput, obj] = processInput(obj, theInput) 
        theOutput = cell(0,1);
        try 
            n = size(theInput,1);
            quitCommand = 0;
            closeCommand = 0;
            for i = 1:n
                myInput = char(theInput{i});
                % QUIT
                if length(myInput)==4 && strcmpi( myInput, 'QUIT')
                    quitCommand = 1;
                    break;
                elseif length(myInput)==5 && strcmpi( myInput, 'CLOSE')
                    closeCommand = 1;
                    break;
                % LOAD model
                elseif length(myInput)>6 && strcmpi( myInput(1:4), 'LOAD')
                    disp(['Executing ',myInput]);
                    myInput = myInput(6:end); 
                    breakIdx = strfind(myInput, '.xml');
                    if length(breakIdx) == 1
                        XMLfile = myInput(1:breakIdx(1)+3); 
                        % load model
                        obj.model = parseXML_LQN(XMLfile,0);
                        if ~isempty(obj.model)
                            % determine reference task
                            for j=1:length(obj.model)
                               if strcmp(obj.model(j).tasks.scheduling, 'ref')
                                   obj.refTask = j;
                                   obj.reqs = obj.model(j).tasks.actNames;
                                   obj.reqCalls = obj.model(j).tasks.actCalls;
                                   obj.P = obj.model(j).tasks.actGraph;
                                   obj.currReq = 1;
                                   obj.initReq = obj.model(j).tasks.initActID;
                                   theOutput{end+1,1} = ['Model ', XMLfile, ' succesfully loaded.']; 
                                   disp(['Model ', XMLfile, ' succesfully loaded.'] ); 
                                   break;
                               end
                            end
                            if isempty(obj.refTask) 
                                theOutput{end+1,1} = ['ERROR: File ', myInput, 'does not contain a reference task.']; 
                                break;
                            end
                            % model loaded and ready 
                            obj.state = obj.INIT;
                        else
                            theOutput{end+1,1} = ['ERROR: File ', myInput, 'is not a valid LQN XML instance.']; 
                        end
                    else
                        theOutput{end+1,1} = ['ERROR: File ', myInput, 'not recognized.']; 
                    end
                % NEXT request
                elseif length(myInput)==4 && strcmpi( myInput(1:4), 'NEXT')
                    if obj.state == obj.INIT
                        if obj.currReq <= size(obj.reqs,1); 
                            %theOutput{end+1,:} = obj.reqs{obj.currReq};
                            %obj.currReq = obj.currReq + 1;
                            %generate a full string of requests
                            reqList = [];
                            %obj.currReq = 1;
                            req = obj.initReq; %request index
                            reqCompleted = 0;
                            disp('Executing NEXT');
                            while reqCompleted == 0
                                reqName = obj.reqs{req};
                                %disp(reqName);
                                if length(reqName) >= 5 && strcmpi( reqName(1:5), 'Start')
                                    % first activity (otherwise ignore and continue to the next)
                                    if req == obj.initReq;
                                        reqList = [reqList,'Start:'];
                                    end
                                    req = nextReq(req, obj.P(req,:));
                                elseif length(reqName) >= 4 && strcmpi( reqName(1:4), 'Stop')
                                    % final activity
                                    if sum(obj.P(req,:)) == 0
                                        reqList = [reqList,'Stop'];
                                        reqCompleted = 1;
                                    % middle stop activity (e.g. within a branch)
                                    else
                                        req = nextReq(req, obj.P(req,:));
                                    end
                                elseif length(reqName) >= 6 && strcmpi( reqName(1:6), 'Branch')
                                    req = nextReq(req, obj.P(req,:));
                                elseif length(reqName) >= 20 && strcmpi( reqName(1:20), 'EntryLevelSystemCall')
                                    reqList = [reqList, parseCallRequest(obj.reqCalls{req}), ':'];
                                    req = nextReq(req, obj.P(req,:));
                                else
                                    theOutput{end+1,1} = ['ERROR: Unexpected request name in PCM model: ',reqName,'.'];
                                    reqCompleted = 1;
                                end
                            end
                            theOutput{end+1,1} = reqList;
                        else
                            theOutput{end+1,1} = 'MODEL COMPLETED';
                        end
                    else
                        theOutput{end+1,1} = ['ERROR: No model has been loaded. NEXT cannot be processed.']; 
                    end
                else
                    theOutput{end,1} = ['ERROR: Command not recognized. Please try again.'];
                end
                
            end
                
        catch ME
            theOutput{end+1,1} = ['ERROR: An error has occurred while executing LINE.'];
            theOutput{end+1,1} = ['ERROR: ', ME.message];
            for j = 1:length(ME.stack)
                theOutput{end+1,1} = ['ERROR: Error in line ', int2str(ME.stack(j).line), ' of LINE script ', ME.stack(j).name];
            end
        end
            
        if closeCommand == 1
            theOutput{end+1,1} = 'Closing connection';
        end
        if quitCommand == 1
            theOutput{end+1,1} = 'Quitting MDL';
        end
    end
end
end

%% determines the next request
function newReq = nextReq(req, prob)
    nonZeroIdx = find(prob>0);
    % single next request
    if sum(prob>0) == 1
        newReq = nonZeroIdx;
    % multiple next requests
    else
        rn = rand;
        i = 1;
        cum = prob(nonZeroIdx(i));
        while rn > cum
            i = i + 1; 
            cum = cum + prob(nonZeroIdx(i));
        end
        newReq = nonZeroIdx(i);
    end
end

%% Parses the call in the reference task of the PCM model into a request of the application
function reqName = parseCallRequest(callName)
    reqName = '';
    if length(callName) >= 26 && strcmpi( callName(1:24), 'RequestHandler_HandlerIF')
        reqName = strtok(callName(26:end), '_');
        switch reqName
            case 'main'
                reqName = 'Main';
            case 'checkLogin'
                reqName = 'Login:LoginDetails';
            case 'quickadd'
                reqName = 'QuickAddMain';
            case 'addcartbulk'
                reqName = 'CartAddAll';
            case 'checkoutoptions'
                reqName = 'CheckOut';
            case 'processorder'
                reqName = 'OrderHistory';
            case 'orderhistory'
                reqName = 'OrderHistory';
            case 'orderstatus'
                reqName = 'CartView';
            case 'logout'
                reqName = 'Logout';
        end

    end

end