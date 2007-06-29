function sigAssessment( results, print_path, target_classifier_name)
% SYNOPSIS
%	sigAssessment( results, print_path, target_classifier_name)

% Deal with optional input
if( ~exist( 'target_classifier_name', 'var' ) )
	ai_index = 1;
else
	for ai_index=1:length( results(1).Splits(1).SigSet.AI )
		if( strcmp( results(1).Splits(1).SigSet.AI(ai_index).name, target_classifier_name ) )
			break;
		end;
	end;
end;
target_classifier_name = results(1).Splits(1).SigSet(1).AI(ai_index).name;

% Compile information about signatures: names, number, breakdown into families,
% display ordering
sig_labels = results(1).Splits(1).SigSet(1).AI(1).classifier.sig_labels;
num_sigs  = length( sig_labels );
sigs_ordered_by_transform = OrderSigsByTransform( sig_labels );
[sig_family_vector sig_family_names] = getSigFamilies( sig_labels( sigs_ordered_by_transform ) );


% Work out the path to save the svg diagram to
svg_print_path = print_path;
svg_print_path = [svg_print_path( 1:strfind( svg_print_path, '.html' ) ) 'svg' ];
[dir base ext ] = fileparts( svg_print_path );
svg_rel_path = [ base ext ];

% Open the html report file
OUT = fopen( print_path, 'w' );
fprintf( OUT, ['<html><head><script type="text/javascript">' ...
	'function toggleVisibility( element_id ) { el = document.getElementById(element_id); '...
	'if (el.style.display=="none"){ el.style.display="inline"; } else { el.style.display="none"; } } </script>'...
	'</head><body>\n' ...
	'<h1>Description of signatures chosen by the pattern recognition method, %s</h1>\n' ], ...
	target_classifier_name ...
);

% Extract flattened data from the results structure
su_count        = zeros(1,num_sigs+1);
sig_scores_flat = zeros(1,num_sigs);
sig_scores_by_problem = {};
trial_num             = 1;
num_splits            = length( results(1).Splits );
num_problems = length( results );
for p=1:num_problems
	sig_scores_by_problem{p} = zeros( num_splits, num_sigs );
	for s = 1:num_splits
		sigs_used           = results(p).Splits(s).SigSet.AI(ai_index).classifier.sigs_used;
		su_count(sigs_used) = su_count(sigs_used) + 1;
		scores = results(p).Splits(s).SigSet.AI(ai_index).classifier.signature_scores( sigs_used );
		nanSigs = find( isnan( scores ) );
		for sig_index = nanSigs
			fprintf( 'Warning! sig score for %s (%d) is nan for %s, %s, %s\n', sig_labels{ sig_index }, sig_index, results(p).name, results(p).Splits(s).name, target_classifier_name );
		end;

		sig_scores_flat( trial_num, sigs_used ) = scores;
		sig_scores_by_problem{p}( s, sigs_used ) = scores;
		trial_num = trial_num + 1;
	end;
end;

% Convert signature scores into mean values
mean_sig_scores = [];
std_sig_scores  = [];
mean_sig_scores_by_problem = {};
std_sig_scores_by_problem = {};

% Normalize the signature scores across each problem so they sum to one
for i=1:size( sig_scores_flat, 1 )
	sig_scores_flat( i, : ) = sig_scores_flat( i, : ) / sum( sig_scores_flat( i, : ) );
end;

% Calculate two average scores for each signature: overall, and for each problem
for sig_index = 1:num_sigs
	mean_sig_scores( sig_index ) = mean( sig_scores_flat( :, sig_index ) );
	std_sig_scores( sig_index )  = std(  sig_scores_flat( :, sig_index ) );
	for p=1:num_problems
		mean_sig_scores_by_problem{ p }(sig_index) = mean( sig_scores_by_problem{p}(:, sig_index) );
		std_sig_scores_by_problem{ p }(sig_index)  = std(  sig_scores_by_problem{p}(:, sig_index) );
	end;
end;

unchosen_sigs = intersect( [1:num_sigs], find( su_count == 0 ) );
chosen_sigs = setdiff( [1:num_sigs], unchosen_sigs );
mean_chosen = mean( su_count( chosen_sigs ) );
std_chosen  = std( su_count( chosen_sigs ) );

fprintf( OUT, '<h3>%d of %d signatures were never chosen by %s</h3>\n', length( unchosen_sigs ), num_sigs, target_classifier_name );
fprintf( OUT, '<a href="#" onClick="toggleVisibility( ''unusedSigs'' );">see the list of unused signatures</a><br/>\n');
fprintf( OUT, '<ul id="unusedSigs" style="display:none;">\n' );
for c = 1:length( unchosen_sigs )
    fprintf( OUT, '<li>%d) %s</li>\n', unchosen_sigs( c ), sig_labels{ unchosen_sigs(c) } );
end;
fprintf( OUT, '</ul>' );

fprintf( OUT, '<a href="%s">An SVG figure of signature scores</a><br/>', svg_rel_path );


fprintf( OUT, '</body></html>\n' );
fclose( OUT );

SVG_OUT = fopen( svg_print_path, 'w' );
sig_width = 1;
sig_spacing = .1;
graph_top_margin = 5;
y_start = 80;
problem_height   = 20;
pixels_per_point = 700;
sig_family_font_size = 10;
bar_width = ( (num_sigs - 1) * (sig_width + sig_spacing ) );

header = [ ...
'<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>\n', ...
'<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN"\n', ...
'    "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [\n', ...
'    <!ATTLIST svg\n', ...
'              xmlns:a3 CDATA #IMPLIED\n', ...
'              a3:scriptImplementation CDATA #IMPLIED>\n', ...
'    <!ATTLIST script\n', ...
'              a3:scriptImplementation CDATA #IMPLIED>\n', ...
']>\n', ...
'<svg xml:space="preserve"\n', ...
'     xmlns="http://www.w3.org/2000/svg"\n', ...
'     xmlns:xlink="http://www.w3.org/1999/xlink"\n', ...
'     xmlns:a3="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"\n', ...
'     a3:scriptImplementation="Adobe">\n', ...
];
%'    <g id="titleLayer" transform="translate(10,25)">\n', ...
%%'		<text id="title" x="0" y="0" text-anchor="start" fill="black" style="font-size: 24pt;">', ...
%'			Each problem has a different set of optimal signatures</text>\n', ...
%'	</g>\n' ...

footer = [ ...
'</svg>\n', ...
];

fprintf( SVG_OUT, header );

% Overall sig scores
current_y        = y_start;
y_scale_height   =  max( mean_sig_scores );
pixels_per_point = problem_height / y_scale_height;
fprintf( SVG_OUT, '<g id="OverallSigScores" transform="translate( 0, %.0f)">\n', current_y );
fprintf( SVG_OUT, '<text x="-10" y="0" text-anchor="end" fill="black" style="font-size: 14pt;">%s</text>\n', ...
	'Overall scores' );
last_sig_family = 0;
for relative_sig_index = 1:num_sigs
	sig_index = sigs_ordered_by_transform( relative_sig_index );
	sig_family = sig_family_vector( relative_sig_index );
	if( sig_family ~= last_sig_family )
		% Close the last sig family block if there was one open
		if( last_sig_family > 0 )
			fprintf( SVG_OUT, '</g>\n' );
		end;
		fprintf( SVG_OUT, '<g id="OverallScore_SigBlock%.0f">\n', sig_family );			
		% Update the current sig family
		last_sig_family = sig_family;
	end;
	x_pos = (relative_sig_index - 1) * (sig_width + sig_spacing );

	y_max = mean_sig_scores( sig_index );
	y_max = -1 * pixels_per_point * y_max;
	fprintf( SVG_OUT, '<line x1="%.1f" x2="%.1f" y1="%.1f" y2="%.1f" stroke="black" stroke-width="%.1f" />\n', ...
		x_pos, x_pos, ....
		0, y_max, ...
		sig_width ...
	);
end;
% Close the last sig block
fprintf( SVG_OUT, '</g>\n' );
% Print the scale of this problem's row
fprintf( SVG_OUT, '<text x="%.1f" y="%.1f" text-anchor="start" fill="black" style="font-size: 14pt;">%.3f %%</text>\n', ...
	bar_width + 10, 0, y_scale_height );
% Close this problem's row
fprintf( SVG_OUT, '</g>\n' );
current_y = current_y + problem_height + graph_top_margin;

% Sig scores by problem
for p=1:num_problems
	y_scale_height = max( mean_sig_scores_by_problem{ p } );
	pixels_per_point = problem_height / y_scale_height;
	fprintf( SVG_OUT, '<g id="Problem%.0fSigScores" transform="translate( 0, %.0f)">\n', p, current_y );
	fprintf( SVG_OUT, '<text x="-10" y="0" text-anchor="end" fill="black" style="font-size: 14pt;">%s</text>\n', ...
		results(p).name );
	last_sig_family = 0;
	for relative_sig_index = 1:num_sigs
		sig_index = sigs_ordered_by_transform( relative_sig_index );
		sig_family = sig_family_vector( relative_sig_index );
		if( sig_family ~= last_sig_family )
			% Close the last sig family block if there was one open
			if( last_sig_family > 0 )
				fprintf( SVG_OUT, '</g>\n' );
			end;
			fprintf( SVG_OUT, '<g id="Prob%.0f_SigBlock%.0f">\n', p, sig_family );			
			% Print an alternating yellow rectangle to distinguish rows. Allow the 
			% rectangles to decompose into sig families.
			if( mod( p, 2 ) == 1 )
				min_sig_indx = min( find( sig_family_vector == sig_family ) );
				max_sig_indx = max( find( sig_family_vector == sig_family ) );
				x_min = (min_sig_indx - 1) * (sig_width + sig_spacing ) - sig_width/2;
				x_max = (max_sig_indx - 1) * (sig_width + sig_spacing ) + sig_width/2;
				if( p < num_problems )
					height = problem_height + graph_top_margin;
				else
					height = problem_height;
				end;
				fprintf( SVG_OUT, '\t\t<rect x="%.1f" y="%.1f" width="%.1f" height="%.0f" fill="yellow" opacity=".3"/>\n', ...
					(x_min - sig_width/2), ( -1 * problem_height ), ...
					(x_max - x_min), height ...
				);
			end;
			% Update the current sig family
			last_sig_family = sig_family;
		end;
		x_pos = (relative_sig_index - 1) * (sig_width + sig_spacing );
		y_mean = mean_sig_scores_by_problem{ p }( sig_index );
		y_mean = -1 * pixels_per_point * y_mean;
		fprintf( SVG_OUT, '<line x1="%.1f" x2="%.1f" y1="%.1f" y2="%.1f" stroke="black" stroke-width="%2.1f" />\n', ...
			x_pos, x_pos, ....
			0, y_mean, ...
			sig_width ...
		);
	end;
	% Close the last sig block
	fprintf( SVG_OUT, '</g>\n' );
	% Print the scale of this problem's row
	fprintf( SVG_OUT, '<text x="%.1f" y="%.1f" text-anchor="start" fill="black" style="font-size: 14pt;">%.1f FD units</text>\n', ...
		bar_width + 10, 0, y_scale_height );
	% Close this problem's row
	fprintf( SVG_OUT, '</g>\n' );
	current_y = current_y + problem_height + graph_top_margin;
end;

% Sig blocks
y_min = y_start - problem_height;
y_max = current_y - problem_height - graph_top_margin;
num_sig_blocks = length( sig_family_names );
fprintf( SVG_OUT, '<g id="SigBlocks">\n' );
for sb_index = 1:num_sig_blocks
	min_sig_indx = min( find( sig_family_vector == sb_index ) );
	max_sig_indx = max( find( sig_family_vector == sb_index ) );
	num_sigs_in_family = length( find( sig_family_vector == sb_index ) );
	x_min = (min_sig_indx - 1) * (sig_width + sig_spacing ) - sig_width/2;
	x_max = (max_sig_indx - 1) * (sig_width + sig_spacing ) + sig_width/2;
	fprintf( SVG_OUT, '\t<g id="SigBlock%.0f">\n', sb_index );
	if( mod( sb_index, 2 ) == 1 )
		fprintf( SVG_OUT, '\t\t<rect x="%.1f" y="%.0f" width="%.1f" height="%.0f" fill="blue" opacity=".2"/>\n', ...
			x_min, y_min, ....
			(x_max - x_min), (y_max - y_min ) ...
		);
	end;
	fprintf( SVG_OUT, '\t\t<text x="0" y="0" text-anchor="start" fill="black" style="font-size: %.0fpt;" transform="translate( %.1f,%.0f ) rotate(90)">%s (N=%d)</text>\n', ...
		sig_family_font_size, ...
		mean( [ x_min x_max ] ) - sig_family_font_size/2, ...
		(y_max + graph_top_margin), sig_family_names{ sb_index }, num_sigs_in_family ...
	);
	fprintf( SVG_OUT, '\t</g>\n' );
end;
fprintf( SVG_OUT, '</g>\n' );

fprintf( SVG_OUT, footer );
fclose( SVG_OUT );
