% this function ultimately should be a clever hash. Currently its a stupid if/else logic
% block

% Feature extraction algorithms take a multidimensional array of pixels and return
% a one dimensional vector. But these vectors have no intrinisic interpretation. Thats why
% we associate with each signature vector a signature_id. Two signature vectors are logically
% comparable if they share the same signature_id. This function computes signature_id's as
% hashes of the name of the Matlab funciton file. That file implements the signature 
% extraction code. These signature_id's are unique because filenames are unique. 

% ultimately we will have to talk about the uber signature function that combines the
% signatures computed by the various signature extraction algorithms into a single 
% representative signature. This requires special features such as an unknown number of 
% signature_id+sig pairs

function id = signature_id (string)

if (strcmp (string, "general_signatures.m"))
	return 1;
elsif (strcmp (string, "edge_signatures.m"))
	return 2;
else
	return 12;
endif
