% SYNOPSIS
%	[svgPath pngPath] = drawDendrogram( distanceMatrix, saveDir, codeDir, sampleLabels, sampleCategories, sampleNumericValues)
% DESCRIPTION
%	draw a dendrogram from the given information
%
function [svgPath pngPath] = drawDendrogram( distanceMatrix, saveDir, codeDir, sampleLabels, sampleCategories, sampleNumericValues)
reuseResults = 1;

num_samples = length( sampleLabels );

pairwiseDistPath = fullfile( saveDir, 'PairwiseDist.txt' );

sampleLabelsCmdParameter = '';
sampleCategoriesCmdParameter = '';
sampleValuesCmdParameter = '';

% Print the results to file.
if( ~exist( pairwiseDistPath, 'file' ) | ~reuseResults)
	DIST_DUMP = fopen( pairwiseDistPath, 'w' );
	fprintf( DIST_DUMP, '%d\n', num_samples );
	for i = 1:num_samples

		% Fitch/drawtree uses Sample%d to produce a PS but ps2SVG replaces 
		% Sample%d with sampleNames using sampleLabels;
		fprintf( DIST_DUMP, 'Sample%d', i);
		sampleLabelsCmdParameter     = [sampleLabelsCmdParameter     sprintf( '--label="%s" ',sampleLabels{i})];
	
		sampleCategoriesCmdParameter = [sampleCategoriesCmdParameter sprintf( '--category="%s" ',sampleCategories{i})];
		
		if( ~exist( 'sampleNumericValues', 'var' ) )
			sampleValuesCmdParameter = [sampleValuesCmdParameter     sprintf( '--value="%d" ',sampleNumericValues{i})];
		end;

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
svg_convert_command = sprintf( '%s plotfile dendrogram.svg %s %s %s; ', svg_convert_path, ...
	sampleLabelsCmdParameter, sampleCategoriesCmdParameter, sampleValuesCmdParameter);
	
labelled_svg_convert_command = sprintf( '%s plotfile dendrogram.labelled.svg --showLabels %s %s %s; ', svg_convert_path, ...
	sampleLabelsCmdParameter, sampleCategoriesCmdParameter, sampleValuesCmdParameter);

perlLibIncludes = sprintf( 'export PERL5LIB=%s; ', codeDir );

% Commands to generate a dendrogram
if (num_samples > 3)
	fitch_command    = sprintf( '%s < %s &> %s; ', fitch_path, fitch_infile_path, fitch_log_path );
else
	% we need to use kitsch if there are fewer than 4 classes.
	fitch_command    = sprintf( '%s < %s &> %s; ', kitsch_path, fitch_infile_path, fitch_log_path );
end

drawtree_command = sprintf( 'ln -s %s fontfile; %s < %s &> %s; ', font_path, drawtree_path, drawtree_infile_path, drawtree_log_path );
png_command  = 'convert -density 32x32 dendrogram.labelled.svg dendrogram.labelled.gif; convert -density 32x32 dendrogram.svg dendrogram.gif; ';

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
