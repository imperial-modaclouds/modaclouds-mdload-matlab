function MDL(config_file)
% MDL(A) configures the MDL server. 
% It reads the MDL configuration from the configuration file A
%
% Parameters:
% config_file:  filepath of the configuration file
% 
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.


import java.net.*;
import java.io.*;
import java.lang.StringBuilder;


%% Read parameters from config file
props = getPropsConfFile(config_file);
% port number
if sum(ismember(fieldnames(props),'port')) > 0
    portNumber = props.port;
else
    disp('Port not specified. Using default: 6350.');
    portNumber = 6350;
end 

%% Establish connection on specified port
try 
    serverSocket = ServerSocket(portNumber);
catch 
    disp(['Could not listen on port: ', int2str(portNumber) ]);
    return;
end
disp('MDL is running.');
disp(['Listening on port ', int2str(portNumber),'.']);

%% Accept client connections
% init communication protocol - persists over several connections
lp = MDLprotocol;
terminateMDL = 0;
numConns = 0; % connection counter
while terminateMDL == 0
    %accept connection
    try 
        clientSocket = serverSocket.accept();
    catch 
        disp('Socket accept failed.');
        return;
    end
    out = PrintWriter(clientSocket.getOutputStream(), true);
    in = BufferedReader(InputStreamReader(clientSocket.getInputStream()));
    numConns = numConns + 1;
    %initiate communication with the client
    out.println('MDL READY');
    out.flush();
    disp(['Connection #',int2str(numConns),' established']);
    disp('MDL READY');

    % parameters
    timeout = 10;
    interCheckTime = 0.5;   % time between check of job state
    maxLines = 10;
    %% communicate with the client
    inputLine = in.readLine();
    close = 0; % terminate connection
    while ~isempty(inputLine) && close == 0 %readLine waits for written input        
        totalLines = {inputLine};
        tstart = tic;
        numLines = 0;
        while in.ready() && numLines < maxLines
            innerInputLine = in.readLine();
            totalLines{end+1,:} = innerInputLine;
            numLines = numLines + 1;
            if toc(tstart) > timeout
                break
            end
        end
        if ~isempty(totalLines)
            [outputLines, lp] = lp.processInput(totalLines);
            quitting = 0;
            for j = 1:size(outputLines,1)
                outputLine = outputLines{j,1};
                out.println(outputLine);
                out.flush();
                if strcmp(outputLine, 'Closing connection') %close connection
                    close = 1;
                end
                if strcmp(outputLine, 'Quitting MDL') %break from server
                    quitting = 1;
                end


            end
        else
            quitting = 1;
        end
        if quitting == 1
            disp('Preparing to quit MDL.');
            terminateMDL = 1;
            outputLine = 'MDL STOP';
            out.println(outputLine);
            out.flush();
            disp(outputLine);
            break; 
        end

        if terminateMDL == 0 && close == 0 
            while ~in.ready()
                pause(interCheckTime);
                if toc(tstart) > timeout
                    disp('Connection timeout')
                    close = 1;
                    break;
                end
            end
            %if close == 0
            inputLine = in.readLine();
            %end
        end
    end
    %clean up by closing connections
    disp(['Closing connection #', int2str(numConns)]);
    out.close();
    in.close();
    clientSocket.close();
end
serverSocket.close();

end