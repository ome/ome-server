function [sets] = mb_mlptrainstoptestsets(nets,netin,trainidx,testidx,numsets,setsize,threshold,onlyone)
%  MB_MLPTRAINSTOPTESTSETS - Classify sets of instances by voting (plurality wins)
%
%  [SETS] = MB_MLPTRAINSTOPTESTSETS(NETS,NETIN,TRAINIDX,TESTIDX,NUMSETS,...
%            SETSIZE,THRESHOLD,ONLYONE) 
%
%    Outputs:
%     SETS - cell array of confusion matrices where the number of 
%             sets classified into each class is summed.  One entry
%             in the cell array per network.
%  
%    Inputs:
%     NETS - cell array of trained networks
%     NETIN - cell array of raw network inputs (NOT scaled mean=0, sdev=1)
%     TRAINIDX - cell array of indices used to generate training data
%     TESTIDX - cell array of indices used to generate test (stop) data
%     NUMSETS - number of sets to classify using each network
%     SETSIZE - size of each set
%     THRESHOLD - vector of values to test as a threshold on the 
%                  network outputs
%     ONLYONE - boolean value indicating whether the processing should 
%                consider a set of outputs to be unknown if more than one
%                of them is above the threshold.
%
%
%    M. Boland - 12 Apr 1999
%

% $Id$

if(~iscell(nets) | ~iscell(netin) | ~iscell(trainidx) | ~iscell(testidx))
  error('NETS, IDX, and NETIN must be cell arrays') ;
end

if (threshold ~= 0)
  if (length(threshold) ~= length(nets))
    error('The number of thresholds does not equal the number of networks.') ;
  end
else
  threshold = zeros(1,length(nets)) ;
end

%
% Reset the random number generator
rand('state',0) ;

%
% Number of classes
numc=nets{1}.nout ;

%
% Initialize the returned cell array
for i=1:length(nets)
  sets{i} = [] ;
end

for i=1:length(nets)
  trainall=[] ;
  %
  % Regenerate the training data for this network -- needed to normalize
  for j=1:numc
    trainall = [trainall ; netin{j}(trainidx{j}{i},:)] ;
  end

  for j=1:numc
    %
    % Normalize the test data for this class
    [trainnorm,testnorm] = mb_featurenorm(trainall,...
                                          netin{j}(testidx{j}{i},:)) ;
    sets{i} = [sets{i} ; mb_mlpsets(nets{i},testnorm,numsets,...
                                    setsize,threshold(i),onlyone)] ;
  end
end
