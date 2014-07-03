function MDL(config_file)
% MDL is the main (wrapper) script of the MDL tool
% This function sets the profile of the parallel server using the default 
% local profile
% 
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

    %setmcruserdata('ParallelProfile', 'local.settings');
    MDLserver(config_file)
end