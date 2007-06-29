function [slide_class_vector] = getArtifactClassVector(image_paths, slide_id_pattern)
% SYNOPSIS
%	[slide_class_vector] = getArtifactClassVector(image_paths, slide_id_pattern);

% Learn how to ignore systematic differences in data collection.
slide_class_vector = [];
% Identify each distinct slide, or data-collection time
slide_name_list = {};
for i = 1:length( image_paths );
	t = regexp( image_paths{i}, slide_id_pattern, 'tokens' );
	if( length( t ) == 0 )
		error( sprintf( 'Could not parse slide id from image path "%s" using regular expression "%s".', image_paths{i}, slide_id_pattern ) );
	else
		slide_name = t{1}{1};
		slide_index = find( strcmp( slide_name_list, slide_name ) );
		if( length( slide_index ) == 0 )
			slide_index = length( slide_name_list ) + 1;
			slide_name_list{ slide_index } = slide_name;
		end;
		slide_class_vector( i ) = slide_index;
	end;
end;
