function mb_missclassnamesprint(filename,names,class)
% MB_MISSCLASSNAMESPRINT - prints NAMES next to the vector CLASS
%
%       Inputs:
%
%
%  M. Boland - 01 May 1999
%

% $Id$

if (~iscell(names))
  error('NAMES must be a cell array') ;
end

if (length(names)<1)
  error('NAMES contains no elements') ;
end

if (length(names) ~= length(class))
  error('NAMES and CLASS must be of the same length') ;
end

fid=fopen(filename,'w') ;
if(fid==-1)
	error('Unable to open the output file');
end

for i=1:length(names)
	fprintf(fid,'%d\t%s\n',class(i),char(names(i))) ;
end

fclose(fid) ;

