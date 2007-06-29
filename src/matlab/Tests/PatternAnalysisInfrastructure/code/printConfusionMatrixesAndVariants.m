function printConfusionMatrixesAndVariants( save_path, results, problem_index, sig_set_index, ai_index )

[REPORT_HTML] = fopen( save_path,'w');

fprintf( REPORT_HTML, '<html><head><script type="text/javascript">function toggleVisibility( element_id ) { el = document.getElementById(element_id); if (el.style.display=="none"){ el.style.display="inline"; } else { el.style.display="none"; } } </script></head><body>\n' );
fprintf( REPORT_HTML, '<h1>Confusion matrixes for problem %s, SigSet %s, AI %s.</h1>last updated %s<br>\n', ...
	results( problem_index ).name, results( 1 ).Splits( 1 ).SigSet(sig_set_index).name, ...
	results( 1 ).Splits( 1 ).SigSet(1).AI( ai_index ).name, datestr( now ) );

num_splits     = length( results( problem_index ).Splits );
num_classes    = size( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs, 2 );
category_names = load( results(problem_index).Splits(1).SigSet(1).test_path, 'category_names' );
category_names = category_names.category_names;

% Calculate confusion matrix & avg marg prob for the Test and Training sets
[te_confusion_matrixes te_avg_marg_probs te_avg_class_simiarlities te_unclassified te_std_confusion te_std_MPsimilarity] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index, 1 );
[tr_confusion_matrixes tr_avg_marg_probs tr_avg_class_simiarlities tr_unclassified tr_std_confusion tr_std_MPsimilarity] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index, 0 );

% Print results.
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3"><tr><td>Test predictions</td><td>Train predictions</td></tr>\n' );
fprintf( REPORT_HTML, '<tr><td align="center">\n\t' );
% Print test set confusion matrix
fprintf( REPORT_HTML, 'Confusion Matrix: rows are actual classes. Columns are predicted classes. Each cell contains the number of images from the actual class that received the given classification. A perfect performance would have zeros in every cell but the diagonals<br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '<td>Unclassified</td>\n</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			te_confusion_matrixes( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '<td>%.2f</td>\n</tr>\n', te_unclassified( actual_class_index ) );
end;
fprintf( REPORT_HTML, '</table>\n' );

% Print avg class probs for Test set
fprintf( REPORT_HTML, 'Avg Marg Prob scores: rows are actual classes. Columns are predicted classes. <br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			te_avg_marg_probs( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '</tr>\n' );
end;
fprintf( REPORT_HTML, '</table>\n' );

fprintf( REPORT_HTML, '</td><td align="center">\n' );

% Print Training set confusion matrix
fprintf( REPORT_HTML, 'Confusion Matrix: rows are actual classes. Columns are predicted classes. Each cell contains the number of images from the actual class that received the given classification. A perfect performance would have zeros in every cell but the diagonals<br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '<td>Unclassified</td>\n</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			tr_confusion_matrixes( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '<td>%.2f</td>\n</tr>\n', tr_unclassified( actual_class_index ) );
end;
fprintf( REPORT_HTML, '</table>\n' );

% Print avg class probs for Training set
fprintf( REPORT_HTML, 'Avg Marg Prob scores: rows are actual classes. Columns are predicted classes. <br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			tr_avg_marg_probs( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '</tr>\n' );
end;
fprintf( REPORT_HTML, '</table>\n' );
fprintf( REPORT_HTML, '</td></tr></table>\n' );





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print STDs of results.
fprintf( REPORT_HTML, '<h2>STDs of above averaged tables</h2>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3"><tr><td>Test predictions</td><td>Train predictions</td></tr>\n' );
fprintf( REPORT_HTML, '<tr><td align="center">\n\t' );
% Print test set confusion matrix
fprintf( REPORT_HTML, 'Confusion Matrix: ...<br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '\n</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			te_std_confusion( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '\n</tr>\n' );
end;
fprintf( REPORT_HTML, '</table>\n' );

% Print avg class probs for Test set
fprintf( REPORT_HTML, 'Avg Marg Prob scores: ... <br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			te_std_MPsimilarity( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '</tr>\n' );
end;
fprintf( REPORT_HTML, '</table>\n' );

fprintf( REPORT_HTML, '</td><td align="center">\n' );

% Print Training set confusion matrix
fprintf( REPORT_HTML, 'Confusion Matrix: ...<br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '\n</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			tr_std_confusion( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '\n</tr>\n' );
end;
fprintf( REPORT_HTML, '</table>\n' );

% Print avg class probs for Training set
fprintf( REPORT_HTML, 'Avg Marg Prob scores: ... <br/>\n' );
fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="3">\n' );
fprintf( REPORT_HTML, '<tr>\n' );
fprintf( REPORT_HTML, '<td></td>\n' );
for group_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ group_index } );
end;
fprintf( REPORT_HTML, '</tr>\n' );
% Confusion matrix contents
for actual_class_index = 1:length( category_names )
	fprintf( REPORT_HTML, '<tr>\n' );
	% label of actual class
	fprintf( REPORT_HTML, '<td>%s</td>\n', category_names{ actual_class_index } );
	for predicted_class_index = 1:length( category_names )
		fprintf( REPORT_HTML, '<td>%.2f</td>\n', ...
			tr_std_MPsimilarity( actual_class_index, predicted_class_index ) ...
		);
	end;
	fprintf( REPORT_HTML, '</tr>\n' );
end;
fprintf( REPORT_HTML, '</table>\n' );


fprintf( REPORT_HTML, '</td></tr></table></body></html>\n' );
fclose( REPORT_HTML );