function [summary]=mb_mlpclasssummary(confmats)
% MB_MLPCLASSSUMMARY - Summarize the output from MB_MLPCONFMAT
%
% M. Boland - 14 Apr 1999

% $Id$

if(~iscell(confmats))
  error('CONFMATS must be a cell array in which each element contains the output from mb_mlpconfmat') ;
end

if(length(confmats)<1)
  error('CONFMATS has no elements') ;
end

cmat = zeros(size(confmats{1}.cmat)) ;
crates = [] ;

%
% Fix this so that Pc_mean and Pc_var are calculated from the same
%  crates - M.B.
%
for i=1:length(confmats)
  crates = [crates ; confmats{i}.crate(:,1:2)] ; 
  cmat = cmat+confmats{i}.cmat ;
end

summary.confusion = cmat ./ (sum(cmat')' * ones(1,size(cmat,2))) ;

cmat_nounk = cmat(:,1:(end-1)) ;
summary.confusion_nounk = cmat_nounk ./ (sum(cmat_nounk')' * ...
                   ones(1,size(cmat_nounk,2))) ;

summary.Pc_mean = [mean(diag(summary.confusion)) ...
                   mean(diag(summary.confusion_nounk))] ;

summary.Pc_var = var(crates) ;

