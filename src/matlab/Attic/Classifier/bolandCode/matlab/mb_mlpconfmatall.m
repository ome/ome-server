function [confmats]=mb_mlpconfmatall(netout,class,threshold,onlyone)
% MB_MLPCONFMATALL Compute confusion matrices for several nets.
%
% [CONFMATS]=MB_MLPCONFMAT(NETOUT,CLASS,THRESHOLD,ONLYONE)
%       Outputs:
%        CONFMATS - cell array of the following, one for each element of netout
%          CMAT - Confusion matrix in which the last column is 'unknown'
%          CRATE - five values: % of all samples classified correctly,
%                 % of attempts (total-unknown) classified correctly,
%                 the total number of samples,
%                 the number of samples classified correctly, and
%                 the number of samples classified as unknown.
%          MISSED - Structure with three components: a vector of indices
%                  indicating the misclassified samples, the true class
%                  of misclassified samples, and the assigned class
%                  of misclassified samples.
%
%       Inputs:
%        NETOUT - Cell array of network outputs
%        CLASS - Cell array of 1 of N classifications for the samples
%                 in NETOUT
%        THRESHOLD - Vector of thresholds to use when deciding which output 
%                     should be used for the classification (same length
%                     as NETOUT OR 0
%        ONLYONE - boolean value indicating whether the processing should 
%                   consider a set of outputs to be unknown if more than one
%                   of them is above the threshold.
%
%
%	In the confusion matrix, the rows represent the true classes and the
%	columns the predicted classes.  
%
%  M. Boland - 14 Apr 1999
%

% $Id$

if (~iscell(netout) | ~iscell(class))
  error('NETOUT and CLASS must be cell arrays') ;
end

if (length(netout)<1)
  error('NETOUT contains no elements') ;
end

if (threshold ~= 0)
  if (length(threshold) ~= length(netout))
    error('The number of thresholds does not equal the number of networks.') ;
  end
else
  threshold = zeros(1,length(netout)) ;
end

for i=1:length(netout)
  [cmat crate missed]=mb_mlpconfmat(netout{i},class{i},threshold(i),onlyone) ;

  confmats{i}.cmat = cmat ;
  confmats{i}.crate = crate ;
  confmats{i}.missed = missed ;
end

