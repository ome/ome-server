function [html_chunk] = reportPredictions( predictions, report_root, predictions_html_dump, predictions_text_dump, master_report_path, run_overview_path  );

category_names         = predictions.category_names;
control_category_names = predictions.control_category_names;
if( isfield( predictions, 'class_numeric_values' ) )
	[junk class_order] = sort( predictions.class_numeric_values );
else
	class_order = unique( predictions.class_vector );
end;
if( isfield( predictions, 'control_class_numeric_values' ) )
	[junk control_class_order] = sort( predictions.control_class_numeric_values );
else
	control_class_order = 1:length( control_category_names );
end;
for c = class_order
	class_counts(c) = length( find( predictions.class_vector == c ) );
end;

html_chunk = '';

% print the overview
if( isfield( predictions, 'correctness' ) )
	html_chunk = [ html_chunk ...
		sprintf( 'Correctness <b>%.2f</b> (number correct of number attempted)<br>\n', ...
			predictions.correctness ) ];
end;
if( isfield( predictions, 'net_accuracy' ) )
	html_chunk = [ html_chunk ...
		sprintf( 'Net Accuracy <b>%.2f</b> (number correct of total number)<br>\n', ...
			predictions.net_accuracy ) ];
end;
html_chunk = [ html_chunk ...
	sprintf( 'Total Unclassified <b>%.0f</b><br><hr>\n', ...
		predictions.num_unclassified ) ...
];

% print the Confusion Matrix
html_chunk = [ html_chunk ...
	sprintf( 'Confusion Matrix: rows are actual classes. Columns are predicted classes. Each cell contains the number of images from the actual class that received the given classification. A perfect performance would have zeros in every cell but the diagonals<br>\n' ) ...
	sprintf( '<table border="1" cellspacing="0" cellpadding="3">\n' ) ...
	sprintf( '<tr>\n' ) ...
	sprintf( '<td></td>\n' ) ...
];
% A row of Column names of the control classes
row = sprintf( '<td>%s</td>\n', control_category_names{ control_class_order } );
html_chunk = [ html_chunk row ];
html_chunk = [ html_chunk ...
	sprintf( '<td>Unclassified</td><td>Total</td>\n' ) ...
	sprintf( '</tr>\n' ) ...
];
% Confusion matrix contents
for known_class_index = class_order
	html_chunk = [ html_chunk ...
		sprintf( '<tr>\n' ) ...
		... % label of known class
		sprintf( '<td>%s</td>\n', category_names{ known_class_index } ) ...
	];
	row = sprintf( '<td>%.0f</td>\n', predictions.confusion_matrix( known_class_index, control_class_order ) );
	html_chunk = [ html_chunk  row ];
	num_images_in_class = class_counts( known_class_index );
	classified_count    = sum( predictions.confusion_matrix( known_class_index, : ) );
	unclassified_count = num_images_in_class - classified_count;
	html_chunk = [ html_chunk ...
		sprintf( '<td>%.0f</td>\n', unclassified_count ) ...
		sprintf( '<td>%.0f</td>\n', num_images_in_class ) ...
		sprintf( '</tr>\n' ) ...
	];
end;
html_chunk = [ html_chunk sprintf( '</table>\n' ) ];


ind_probs_path = fullfile( report_root, predictions_html_dump );
html_chunk = [ html_chunk sprintf( 'Individual image predictions: <a href="%s">html </a>\n', predictions_html_dump ) ];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print the predictions for each image.
[IND_PROBS_HTML] = fopen( ind_probs_path,'w');
fprintf( IND_PROBS_HTML, '<h1>Individual image scores</h1>\n' );
fprintf( IND_PROBS_HTML, '<a href="%s">Back to run overview</a>\n', run_overview_path );
fprintf( IND_PROBS_HTML, '<a href="%s">Back to master report</a>\n', master_report_path );

fprintf( IND_PROBS_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
% print the header
fprintf( IND_PROBS_HTML, '<tr>\n' );
fprintf( IND_PROBS_HTML, '<td></td><td></td>\n');
if( isfield( predictions, 'known_values' ) )
	fprintf( IND_PROBS_HTML, '<td></td>\n');
end;
if( isfield( predictions, 'continuous_score' ) )
	fprintf( IND_PROBS_HTML, '<td></td>\n');
end;
fprintf( IND_PROBS_HTML, '<td colspan="%.0f"><b>Marginal Probabilities</b></td>\n', length( category_names ) );
fprintf( IND_PROBS_HTML, '</tr>\n' );
fprintf( IND_PROBS_HTML, '<tr>\n' );
fprintf( IND_PROBS_HTML, '<td><b>Image name</b></td><td>Known category</td>\n');
if( isfield( predictions, 'known_values' ) )
	fprintf( IND_PROBS_HTML, '<td>Known value</td>\n');
end;
if( isfield( predictions, 'continuous_score' ) )
	fprintf( IND_PROBS_HTML, '<td>Predicted score</td>\n');
end;
fprintf( IND_PROBS_HTML, '<td><b>%s</b></td>\n', control_category_names{ control_class_order } );
fprintf( IND_PROBS_HTML, '</tr>\n' );

% print a row at a time
[ junk sorted_image_indexes ] = sort( predictions.image_paths );
for i = 1:length( sorted_image_indexes )
	image_index = sorted_image_indexes(i);
	image_path = predictions.image_paths{ image_index };
	marginal_probs = predictions.marginal_probs( image_index, : );
	fprintf( IND_PROBS_HTML, '<td>%s</td><td>%s</td>\n', image_path, category_names{predictions.class_vector( image_index ) });
	if( isfield( predictions, 'known_values' ) )
		fprintf( IND_PROBS_HTML, '<td>%.2f</td>\n', predictions.known_values( image_index ) );
	end;
	if( isfield( predictions, 'continuous_score' ) )
		fprintf( IND_PROBS_HTML, '<td>%.2f</td>\n', predictions.continuous_score( image_index ) );
	end;
	fprintf( IND_PROBS_HTML, '<td><b>%.2f</b></td>\n', marginal_probs( control_class_order ) );
	fprintf( IND_PROBS_HTML, '</tr>\n' );
end;
fprintf( IND_PROBS_HTML, '</table>\n' );
fprintf( IND_PROBS_HTML, '</table>\n</body>\n</html>\n' );
fclose( IND_PROBS_HTML );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print same data to a spreadsheet
ind_probs_path = fullfile( report_root, predictions_text_dump );
html_chunk = [ html_chunk sprintf( ', <a href="%s">spreadsheet</a>\n', predictions_text_dump ) ];
[IND_PROBS_TSV] = fopen( ind_probs_path,'w');
% print the detailed breakdown
fprintf( IND_PROBS_TSV, 'Image name\t');
if( isfield( predictions, 'known_values' ) )
	fprintf( IND_PROBS_TSV, 'Known value\t');
end;
if( isfield( predictions, 'continuous_score' ) )
	fprintf( IND_PROBS_TSV, 'Predicted score\t');
end;
fprintf( IND_PROBS_TSV, 'Known Category\t');
fprintf( IND_PROBS_TSV, '%s\t', control_category_names{ control_class_order } );
fprintf( IND_PROBS_TSV, '\n' );

% print a row at a time
[ junk sorted_image_indexes ] = sort( predictions.image_paths );
for i = 1:length( sorted_image_indexes )
	image_index = sorted_image_indexes(i);
	image_path = predictions.image_paths{ image_index };
	marginal_probs = predictions.marginal_probs( image_index, : );
	fprintf( IND_PROBS_TSV, '%s\t', image_path);
	if( isfield( predictions, 'known_values' ) )
		fprintf( IND_PROBS_TSV, '%.2f\t', predictions.known_values( image_index ) );
	end;
	if( isfield( predictions, 'continuous_score' ) )
		fprintf( IND_PROBS_TSV, '%.2f\t', predictions.continuous_score( image_index ) );
	end;
	fprintf( IND_PROBS_TSV, '%s\t', category_names{predictions.class_vector( image_index ) });
	fprintf( IND_PROBS_TSV, '%.2f\t', marginal_probs( control_class_order ) );
	fprintf( IND_PROBS_TSV, '\n' );
end;
fclose( IND_PROBS_TSV );
