%command line mcc
%% COMPILE EXEC

%% windows
mcc -m -I ./src MDL.m -a ./src/*.m -d ./bin -v -N -p 'C:\Program Files\MATLAB\R2012b\toolbox\matlab\iofun\' 


%% linux
%works
%mcc -m -I ./r0.5 LINE.m -a ./r0.5/*.m -d ./r0.5/compiledExecParaLinux -a ./r0.5/localLinux.settings -v -N -p '/usr/lib/matlab/R2012a/toolbox/bioinfo/' -p '/usr/lib/matlab/R2012a/toolbox/distcomp/' 

%mcc -m -I ./PE_CS_KA LINEserver_XMLmulti_para.m -a ./PE_CS_KA/*.m -d ./PE_CS_KA/compiledExecLinux -v -N -p '/usr/lib/matlab/R2012a/toolbox/bioinfo/' -p '/usr/lib/matlab/R2012a/toolbox/distcomp/'