classdef precedence
% PRECEDENCE defines precedence objects, which are used to determine 
% the order in which the activities, in a Layered Queueing Network (LQN) model, are executed. 
% More details on activities and their role in LQN models can be found 
% on the LINE documentation, available at http://code.google.com/p/line
%
% Properties:
% pres:                 list of predecessor activies that must be completed to activite this precedence rule (string array)
% posts:                list of sucessor activities that can start execution when this precedence rule is active (string array)
% preType:              type of the condition among the predecessor activities, either 'single' or 'OR' (string)
% postType:             type of the condition among the sucessor activities, either 'single' or 'OR' (string) 
% postProbs:            in the case of postType=OR, this array lists the probabilities
%                       of executing each of the successor activities in postsProbs (double array) 
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

properties
    pres  = cell(0);        %string array
    posts = cell(0);        %string array
    preType = 'single';     %string \in {'single', 'OR'} 
    postType = 'single';    %string \in {'single', 'OR'}
    postProbs = [];         %double array (column)
end

methods
%public methods, including constructor

    %constructor
    function obj = precedence(pres, posts, preType, postType, postProbs)
        if nargin == 3
            obj.pres = pres;
            obj.posts = posts;
        else
            obj.pres = pres;
            obj.posts = posts;
            obj.preType = preType;
            obj.postType = postType;
            obj.postProbs = postProbs;
        end
    end
            
     %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nprecedence: \n']);
        if size(obj.pres,1) > 1 
            myString = sprintf([myString, 'pres:\n']);
        end
        if size(obj.pres,1) > 0 
            for j = 1:size(obj.pres,1)
                myString = sprintf([myString, 'pre-act: ',obj.pres{j},'\n']);
            end
        end
        if size(obj.posts,1) == 1 
            for j = 1:size(obj.posts,1)
                myString = sprintf([myString, 'post-act: ',obj.posts{j},'\n']);
            end
        elseif size(obj.posts,1) > 1 
            myString = sprintf([myString, 'posts:\n']);
            for j = 1:size(obj.posts,1)
                myString = sprintf([myString, 'post-act: ',obj.posts{j},'( ', num2str(obj.postProbs(j)) ,' )\n']);
            end
        end
    end

end
    
end