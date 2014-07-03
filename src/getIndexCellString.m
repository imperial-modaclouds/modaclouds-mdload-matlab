function idx = getIndexCellString(myCell, myStr)
% [I] = GETINDEXCELLSTRING(A, B) returns the row index I
% corresponding to the string B in a cell of strings B.
% It returns -1 if the string BA is not in A. 
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.

idx = -1;

k = 1;
n = size(myCell,1);
while k <= n
    if strcmp(myCell{k,1},myStr)
        idx = k;
        k = n + 1;
    end
    k = k + 1;
end