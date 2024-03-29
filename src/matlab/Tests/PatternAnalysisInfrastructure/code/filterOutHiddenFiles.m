function [out_paths] = filterOutHiddenFiles( in_paths, onlyKeepDirs )
% SYNOPSIS
%	paths = dir( '/Path/to/Images' );
%	[paths] = filterOutHiddenFiles( paths, onlyKeepDirs )
% DESCRIPTION
%	Screen out files starting with '.'
% INPUTS
%	onlyKeepDirs is optional. If set to 1, only directories will be kept. If set to 0,
%		all non-hidden files will be kept. If set to 2, directories will be excluded.

if( ~exist( 'onlyKeepDirs', 'var' ) )
	onlyKeepDirs = 0;
end;

keep_files = [];
for file_index = 1:length(in_paths)
	if( in_paths( file_index ).name(1) ~= '.' & ~strcmp( in_paths( file_index ).name, 'CVS') )
		if( onlyKeepDirs )
			if( onlyKeepDirs == 1 & in_paths( file_index ).isdir )
				keep_files( end + 1 ) = file_index;
			elseif( ( onlyKeepDirs == 2 ) & ~in_paths( file_index ).isdir )
				keep_files( end + 1 ) = file_index;
			end;
		else
			keep_files( end + 1 ) = file_index;
		end;
	end;
end;
out_paths = in_paths(keep_files);

% convert out_paths from array of structs into a cell of strings, then sort it
for file_index = 1:length(out_paths)
	new_out_path{file_index} = out_paths(file_index).name;
end;
out_paths = sort_nat(new_out_path);
return;
