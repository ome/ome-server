function mb_latextable(filename,data,names)
% MB_LATEXTABLE - print a matrix to a file for easy inclusion in latex
%
% M. Boland - 29 Apr 1999

% $Id$

if(~isstr(filename))
	error('FILENAME must be a string containing the full name of the file to be written') ;
end

if(ndims(data)>2)
	error('DATA must be a vector or 2D matrix') ;
end

if(length(names)>size(data,1) | ~iscell(names))
	error('NAMES must be a cell array and have the same number of elements as DATA has rows') ;
end

fid=fopen(filename,'w') ;
if(fid==-1)
	error('Unable to open the input file');
end

for i=1:size(data,1)
  fprintf(fid,'\\textbf{%s} & ', names{i}) ;
  for j=1:size(data,2)
    fprintf(fid,'%0.0f\\%%',data(i,j)) ;
    if(j<size(data,2))
      fprintf(fid,' & ') ;
    else
      fprintf(fid,' \\\\[0.1in]\n') ;
    end
  end
end

fclose(fid) ;
