function [accuracy, recall] = mb_mlpthresh(netout,class,threshold,onlyone)
%  MB_MLPTHRESH - Threshold output of mlp for classification
%
%  [ACCURACY RECALL] = MB_MLPTHRESH(NETOUT,CLASS,THRESHOLD,ONLYONE)
%
%    Outputs:
%     ACCURACY - number of correct classifications / total classifications
%                 attempted (not including unknowns)
%     RECALL - number of correct classifications / total instances
%
%    Inputs:
%     NETOUT - output of neural network (rows=instances)
%     CLASS - one-of-N array indicating the true class of the 
%              outputs in NETOUT
%     THRESHOLD - value to use as a threshold on the network outputs
%     ONLYONE - boolean value indicating whether the processing should 
%                consider a set of outputs to be unknown if more than one
%                of them is above the threshold.
%
%
%    M. Boland - 01 Mar 1999
%

% $Id$

%
% How many classes?
numc = size(netout,2) ;

%
% Convert the 1 of N format of class to single digits per instance
trueclass = [1:numc]*class' ;

%
% Find those outputs that are above the threshold
netthresh = netout .* (netout>=threshold) ;

%
% Find the largest output for each instance
[nmax, threshclass] = max(netthresh') ;

%
% Don't consider classifications where max=0
threshclass = threshclass .* (nmax>0) ;

%
% Identify those sets of outputs for which only one value is above threshold
if(onlyone)
  justone = (sum((netout>=threshold)') == 1) ;
  threshclass=justone.*threshclass ;
end

%
% Number of correctly classified samples
numcorrect = sum(threshclass == trueclass) ;

numinstances = size(netout,1) ;
numattempted = sum(threshclass>0) ;

if(numattempted>0),
  accuracy = numcorrect/numattempted ;
else
  accuracy=0 ;
end

if(numinstances>0),
  recall = numcorrect/numinstances ;
else
  recall = 0 ;
end
