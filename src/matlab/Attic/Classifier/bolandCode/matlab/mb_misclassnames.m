function [testnames,missed,assigned]=mb_missclassnames(names,testidx,confmatout)
% MB_MISSCLASSNAMES - Returns the file names of misclassified samples.
%
% [MISSED TRUTH]=MB_MISSCLASSNAMES(NAMES,TESTIDX,CONFMATOUT)
%       Outputs:
%
%       Inputs:
%
%
%  M. Boland - 01 May 1999
%

% $Id$

if (~iscell(names) | ~iscell(testidx) | ~iscell(confmatout))
  error('NETOUT, CLASS, and CONFMATOUT must be cell arrays') ;
end

if (length(names)<1)
  error('NAMES contains no elements') ;
end

numc = length(names) ;
numtrials = length(confmatout) ;

testnames={} ;
missed={} ;
assigned=[] ;

for i=1:numtrials 
  thesetestnames={} ;
  for j=1:numc
    thesetestnames = [thesetestnames ; names{j}(testidx{j}{i})] ;
  end

  testnames = [testnames ; thesetestnames] ;
  missed = [missed ; thesetestnames(confmatout{i}.missed.index)] ;
  assigned = [assigned ; confmatout{i}.missed.assigned'] ;
end

testnames = sort(testnames) ;
[missed, sortidx] = sort(missed) ;
assigned = assigned(sortidx) ;
