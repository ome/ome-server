function [bestthresh] = mb_mlpthreshtest(netout,class,thresholds,onlyone)
%  MB_MLPTHRESHTEST - Threshold output of mlp for classification
%
%  [BESTTHRESH] = MB_MLPTHRESHTEST(NETOUT,CLASS,THRESHOLDS,ONLYONE)
%
%    Outputs:
%     BESTTHRESH - a vector of the best thresholds for all nets in netout
%                   where best = max(accuracy.^2 + recall.^2))
%
%    Inputs:
%     NETOUT - cell array of neural network outputs (rows=instances)
%     CLASS - cell array of one-of-N arrays indicating the true class of the 
%              outputs in NETOUT
%     THRESHOLD - vector of values to test as a threshold on the 
%              network outputs
%     ONLYONE - boolean value indicating whether the processing should 
%                consider a set of outputs to be unknown if more than one
%                of them is above the threshold.
%
%
%    M. Boland - 10 Apr 1999
%

% $Id$

if(~iscell(netout) | ~iscell(class))
  error('NETOUT and CLASS must be cell arrays') ;
end

bestthresh = [] ;

%
% For each network...
for i=1:length(netout),

  accuracy   = [] ;
  recall     = [] ;

  %
  % Try each threshold with each network
  for j=1:length(thresholds),
    [acc rec] = mb_mlpthresh(netout{i},class{i},thresholds(j),onlyone) ;
    accuracy = [accuracy acc] ;
    recall   = [recall rec] ;
  end

  [maxval,maxidx] = max(accuracy.^2 + recall.^2) ;

  bestthresh = [bestthresh thresholds(maxidx)] ;

end
