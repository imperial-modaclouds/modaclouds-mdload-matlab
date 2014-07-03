classdef MDL_obj
% LINE_OBJ_SEFF defines the LINE object that processes the models, calling
% the necessary scripts to parse the XML description, solve the performance
% model, and export the resuls to an XML file
% 
% Properties:
% myCluster:    cluster to solve models in parallel
% myJobs:       list of jobs submitted to the cluster
% jobTasks:     list of file names of the tasks in each job 
% maxIter:      maximum number of iterations of the blending algorithm
%    
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.
    
properties
    myCluster;      % parallel cluster
    myJobs;         % list of jobs submitted to the cluster
    jobTasks;       % filenames (LQN-XML) of tasks (models) in each job
    jobTaskREs;     % filenames (RE-XML) of tasks (models) in each job
    maxIter;        % maximum number of iterations of the blending algorithm
end
    
methods
    %% contructor
    function obj = LINE_obj_SEFF(maxIter)
        %obj.model = [];
        parallel.defaultClusterProfile('local');
        obj.myCluster = parcluster();
        obj.myJobs = cell(0);
        obj.maxIter = maxIter;
    end

    %% Function to solve models in parallel
    function obj = solvePara(obj, XMLfiles, REfiles)
        myJob = createJob(obj.myCluster);
        createTask(myJob,@solve_multi,0,{{XMLfiles, REfiles, obj.maxIter}});
        
        submit(myJob);
        obj.myJobs{end+1,1} = myJob;
        obj.jobTasks{end+1,1} = XMLfiles;
        obj.jobTaskREs{end+1,1} = REfiles;
    end
    
    %% Function to solve models sequentially 
    function obj = solveSeq(obj, XMLfiles, REfiles)
        solve_multi(XMLfiles, REfiles, obj.maxIter);
    end
    
end
    
end

%% solves an LQN model from a serialized XML
function solve_multi(XMLfiles, REfiles, maxIter)
    n = size(XMLfiles,1);
    for j = 1:n
        XMLfile = XMLfiles{j};
        REfile = REfiles{j};
        if isempty(REfile)
            %% parse XML and build CMCQN object
            fprintf('\nReading input file\n');
            [myCQNCS,classMatch,SEFF, processors] = readXML_CMCQNCS_SEFF(XMLfile,0);
            if ~isempty(myCQNCS)
                %% perform fluid analysis
                fprintf('\nInitializing fluid analysis\n');
                delta_max = 1e-3;
                [Q, U, R, X, resSEFF] = CMCQN_CS_analysis_SEFF(myCQNCS, classMatch, SEFF, processors, maxIter, delta_max, 0);
                for i = 1:myCQNCS.M
                    if strcmp(myCQNCS.sched{i},'inf')
                        RT = sum(R([1:i-1 i+1:myCQNCS.M],:),1);
                        break;
                    end
                end
                %% write results
                writeXMLresults_SEFF(XMLfile, '', myCQNCS, U, X, RT, R, size(classMatch,1),resSEFF );
            end
        else
             %% parse XMLs and build CMCQN_CS_RE object
            fprintf('\nReading input file\n');
            [myCQNCSRE,classMatch,resetRules,SEFF, processors] = readXML_CMCQNCS_RE_SEFF(XMLfile, REfile, 0);
            
            if ~isempty(myCQNCSRE)
                %% perform fluid analysis
                fprintf('\nInitializing fluid analysis\n');
                delta_max = 1e-3;
                [~, U, R, X, resSEFF] = CMCQN_CS_RE_analysis_SEFF(myCQNCSRE, classMatch, resetRules, SEFF, processors, maxIter, delta_max, 0);
                for i = 1:myCQNCSRE.M
                    if strcmp(myCQNCSRE.sched{i},'inf')
                        RT = sum(R([1:i-1 i+1:myCQNCSRE.M],:),1);
                        break;
                    end
                end
                fprintf('\nFluid analysis completed\n');
                %% write results
                writeXMLresults_SEFF(XMLfile, REfile, myCQNCSRE, U, X, RT, R, size(classMatch,1), resSEFF );
            end
        end
    end
end