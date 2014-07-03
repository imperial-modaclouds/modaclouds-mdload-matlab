function props = getPropsConfFile(filename)
% GETPROPSCONFFILE Reads a properties file and returns the properties 
% values as a struct. 
% P = getPropsConfFile(F) reads the file F and 
% returns the properties in the struct P
% 
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.


import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

prop = java.util.Properties();
try 
    prop.load(java.io.FileInputStream(filename));
catch ex
    ex.printStackTrace();
end

props = [];
port = prop.get('port');
if ~isempty(port) 
    props.port = str2num(port);
end
