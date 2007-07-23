% SYNOPSIS
%	[svgPath pngPath] = drawDendrogram( distanceMatrix, sampleNames, classNumericValues, saveDir, codeDir, reuseResults )
% DESCRIPTION
%	draw a dendrogram from the given information

function [svgPath pngPath] = drawDendrogram( distanceMatrix, sampleNames, classNumericValues, saveDir, codeDir, reuseResults )

if( ~exist( 'reuseResults', 'var' ) )
	reuseResults = 0;
end;
num_samples = length( sampleNames );

pairwiseDistPath = fullfile( saveDir, 'PairwiseDist.txt' );
% Print the results to file.
if( ~exist( pairwiseDistPath, 'file' ) | ~reuseResults)
	DIST_DUMP = fopen( pairwiseDistPath, 'w' );
	fprintf( DIST_DUMP, '%d\n', num_samples );
	for i = 1:num_samples
		fprintf( DIST_DUMP, '%-15s', sampleNames{i} );
		% Print the distances from that sample to every other sample
		for j = 1:num_samples
			fprintf( DIST_DUMP, '%13.4f', distanceMatrix(i, j) );
		end;
		fprintf( DIST_DUMP, '\n');
	end;
	% close the file
	fclose( DIST_DUMP );
else
	fprintf( 'Cancelling save. File already exists: %s\n', pairwiseDistPath );
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use phylip to generate a dendrogram

% get paths to all utilities
svg_convert_path     = fullfile( codeDir, 'ps2SVG_coloredTree.pl' );
fitch_path           = fullfile( codeDir, 'phylip3.65_src/fitch' );
kitsch_path          = fullfile( codeDir, 'phylip3.65_src/kitsch' );
fitch_infile_path    = fullfile( codeDir, 'fitch.infile' );
drawtree_path        = fullfile( codeDir, 'phylip3.65_src/drawtree' );
drawtree_infile_path = fullfile( codeDir, 'drawtree.infile' );
font_path            = fullfile( codeDir, 'font1' );

fitch_log_path       = 'fitch.log';
drawtree_log_path    = 'drawtree.log';

% Commands to convert from postscript output to svg
svg_convert_command = sprintf( '%s plotfile dendrogram.svg ', svg_convert_path );
labelled_svg_convert_command = sprintf( '%s plotfile dendrogram.labelled.svg ', svg_convert_path );
comma_delimited_bins = '';
if( length( classNumericValues ) > 0 )
	classNumericValues = sort( classNumericValues );
	for b = 1:length( classNumericValues )
		if( b < length( classNumericValues ) )
			comma_delimited_bins = [comma_delimited_bins sprintf( '%.0f,', classNumericValues(b) )];
		else
			comma_delimited_bins = [comma_delimited_bins sprintf( '%.0f', classNumericValues(b) )];
		end;
	end;
else
	for b = 0:length( sampleNames )-1
		if( b < length( sampleNames )-1 )
			comma_delimited_bins = [comma_delimited_bins sprintf( '%.0f,', b )];
		else
			comma_delimited_bins = [comma_delimited_bins sprintf( '%.0f', b )];
		end;
	end;
end;
svg_convert_command = [ svg_convert_command comma_delimited_bins '; ' ];
labelled_svg_convert_command = [ labelled_svg_convert_command comma_delimited_bins ' 1; ' ];
perlLibIncludes = sprintf( 'export PERL5LIB=%s; ', codeDir );

% Commands to generate a dendrogram
if (num_samples > 3)
	fitch_command    = sprintf( '%s < %s &> %s; ', fitch_path, fitch_infile_path, fitch_log_path );
else
	% we need to use kitsch if there are fewer than 4 classes.
	fitch_command    = sprintf( '%s < %s &> %s; ', kitsch_path, fitch_infile_path, fitch_log_path );
end

drawtree_command = sprintf( 'ln -s %s fontfile; %s < %s &> %s; ', font_path, drawtree_path, drawtree_infile_path, drawtree_log_path );
png_command  = 'convert -density 96x96 dendrogram.svg dendrogram.gif; convert -density 96x96 dendrogram.labelled.svg dendrogram.labelled.gif;';

% Make the system calls to generate a dendrogram figure in png and svg formats.
current_dir = pwd;
command = [ 'cd ' saveDir '; ' perlLibIncludes ];
if( ~reuseResults & exist( fullfile( saveDir, 'outtree'), 'file' ) )
	command = [ command 'rm outtree outfile plotfile; ' ];
end;
if( ~exist( fullfile( saveDir, 'outtree'), 'file' ) | ~reuseResults )
	command = [ command fitch_command ];
end;
if( ~exist( fullfile( saveDir, 'plotfile'), 'file' ) | ~reuseResults )
	command = [ command drawtree_command ];
end;
if( ~exist( fullfile( saveDir, 'dendrogram.svg'), 'file' ) | ~reuseResults )
	command = [ command svg_convert_command ];
end;
if( ~exist( fullfile( saveDir, 'dendrogram.labelled.svg'), 'file' ) | ~reuseResults )
	command = [ command labelled_svg_convert_command ];
end;
if( ( ~exist( fullfile( saveDir, 'dendrogram.gif'), 'file' ) | ~exist( fullfile( saveDir, 'dendrogram.labelled.gif'), 'file' ) ) | ~reuseResults )
	command = [ command png_command ];
end;
command = [command sprintf( 'cd %s; ', current_dir ) ];
system( command );

svgPath = fullfile( saveDir, 'dendrogram.labelled.svg' );
pngPath = fullfile( saveDir, 'dendrogram.labelled.gif' );
