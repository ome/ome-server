function [classes] = mb_mlpsets(net,netin,numsets,setsize,threshold,onlyone)
%  MB_MLPSETS - Classify sets of instances by voting (plurality wins)
%
%  [CLASSES] = MB_MLPSETS(NET,NETIN,NUMSETS,SETSIZE,THRESHOLD,ONLYONE)
%
%    Outputs:
%     CLASSES - vector containing the cumulative number of sets of size 
%                SETSIZE in I that were classified into each of the possible
%                output categories. The elements of CLASSES sum to NUMSETS.
%
%    Inputs:
%     NET - neural network AFTER training
%     NETIN - array of samples to be classified (columns=features),
%              ALL from the same class
%     NUMSETS - number of random sets to classify
%     SETSIZE - size of each set
%     THRESHOLD - Threshold to use when deciding which output 
%                  should be used for the classification
%     ONLYONE - boolean value indicating whether the processing should 
%                consider a set of outputs to be unknown if more than one
%                of them is above the threshold.
%
%
%    M. Boland - 01 Mar 1999
%

% $Id$

%
% Confirm that the setsize is >= the number of samples in NETIN
if(setsize > size(netin,1))
  error('SETSIZE is greater than the number of input samples.') ;
end

%
% Reset the random number generator
rand('state',0) ;

%
% Number of classes
numc = net.nout ;

%
% Use one of N encoding for summing the classification results
%  Include one extra class for 'unknown'
class = eye(numc+1) ;
classes = zeros(1,numc+1) ;

%
% Iterate...
for count=1:numsets,

%
% Output of NET for a random set of the input data, NETIN
randidx = randperm(size(netin,1)) ;
netout = mlpfwd(net,netin(randidx(1:setsize),:)) ;

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
% Make the unknowns the last class (i.e. numc+1)
threshclass = ((threshclass==0) .* (numc+1)) + threshclass ;

%
% Histogram of the output classifications
h=hist(threshclass,[1:numc+1]) ;

%
% Identify the plurality class
[hmax,hidx] = max(h) ;

%
% Confirm that there is only ONE plurality class
h(hidx) = [] ;
[h2max,h2idx] = max(h) ;
if (h2max == hmax)
 classes = classes + class(numc+1,:) ;
else
 classes = classes + class(hidx,:) ;
end

%
% end for
end
