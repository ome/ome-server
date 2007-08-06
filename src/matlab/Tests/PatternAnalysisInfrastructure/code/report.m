% SYNOPSIS
%  [classDendrograms_rel_paths, sampleDendrograms_rel_paths] = report(results, report_root);
% INPUTS
%	results can be either the path to the 'results' file, typically 'data/classifiers/results.mat',
%		or it can be the results structure that has been loaded from the results file via loadResults()
%	the second parameter is the root directory to write reports to
% DESCRIPTION
%	Generate a html report that allows easy comparision of the performance of
% the classifier against different Signature Sets.
function [classDendrograms_rel_paths, sampleDendrograms_rel_paths] = report( results, report_root )

if( strcmp( class( results ), 'char' ) )
	[results] = loadResults( results );
end;

num_ais = length( results( 1 ).Splits( 1 ).SigSet(1).AI );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate paths for the report overview and all major subcomponents
report_rel_path = 'index.html';
report_path     = fullfile( report_root, 'index.html' );
sig_assess_rel_path = 'sigAssessment.html';
sig_assess_path     = fullfile( report_root, sig_assess_rel_path );
assess_sigs_w_classifiter = 'WND_05';
for problem_index = 1:length( results )
	prob_report_rel_paths{ problem_index } = sprintf( 'Prob%.0f.html', problem_index );
	prob_report_paths{ problem_index } = ...
		fullfile( report_root, prob_report_rel_paths{ problem_index } );
	num_splits = length( results( problem_index ).Splits );
	for split_index = 1:num_splits
		for sig_set_index = 1:length( results( 1 ).Splits( 1 ).SigSet )
			for ai_index = 1:length( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI )
				problem_rel_path = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f_Overview.html', problem_index, split_index, sig_set_index, ai_index );
				prob_and_treatment_rel_paths{ problem_index, split_index, sig_set_index, ai_index } = ...
					problem_rel_path;
				prob_and_treatment_paths{ problem_index, split_index, sig_set_index, ai_index } = ...
					fullfile( report_root, problem_rel_path );

				confMatrix_rel_path = sprintf( 'confMatrix_Prob%.0f_SigSet%.0f_AI%.0f.html', problem_index, sig_set_index, ai_index );
				confMatrix_rel_paths{ problem_index, sig_set_index, ai_index } = ...
					confMatrix_rel_path;
				confMatrix_paths{ problem_index, sig_set_index, ai_index } = ...
					fullfile( report_root, confMatrix_rel_path );

				% set up paths for class-based dendrograms
				classDendrograms_rel_path = sprintf( 'classDendrograms_Prob%.0f_SigSet%.0f_AI%.0f.html', problem_index, sig_set_index, ai_index );
				classDendrograms_rel_paths{ problem_index, sig_set_index, ai_index } = ...
					classDendrograms_rel_path;
				classDendrograms_paths{ problem_index, sig_set_index, ai_index } = ...
					fullfile( report_root, classDendrograms_rel_path );

				% set up paths for sample-based dendrograms
				sampleDendrograms_rel_path = sprintf( 'sampleDendrograms_Prob%.0f_SigSet%.0f_AI%.0f.html', problem_index, sig_set_index, ai_index );
				sampleDendrograms_rel_paths{ problem_index, sig_set_index, ai_index } = ...
					sampleDendrograms_rel_path;
				sampleDendrograms_paths{ problem_index, sig_set_index, ai_index } = ...
					fullfile( report_root, sampleDendrograms_rel_path );
			end;
		end;
	end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate an overview of everything
[REPORT_HTML] = fopen( report_path,'w');
if (REPORT_HTML == -1)
	error(sprintf ('Failed to open %s for writing', report_path));
end;
fprintf( REPORT_HTML, '<html><head><script type="text/javascript">function toggleVisibility( element_id ) { el = document.getElementById(element_id); if (el.style.display=="none"){ el.style.display="inline"; } else { el.style.display="none"; } } </script></head><body>\n' );
fprintf( REPORT_HTML, '<h1>Results.</h1>last updated %s<br>\n', datestr( now ) );
fprintf( REPORT_HTML, '<a href="%s">Signature assessments</a><br>\n', sig_assess_rel_path );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make an overview table for each signature set in the main report
for sig_set_index = 1:length( results( 1 ).Splits( 1 ).SigSet )
	fprintf( REPORT_HTML, '<h2><center>Results from signature set %s</center></h2>\n', ...
		results( 1 ).Splits( 1 ).SigSet(sig_set_index).name );
	toggleAll = '';
	for problem_index = 1:length( results )
		for ai_index = 1:length( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI )
			toggleAll = sprintf( '%s toggleVisibility( ''Prob%d_SigSet%d_AI%d'');', ...
				toggleAll, problem_index, sig_set_index, ai_index ...
			);
		end;
	end;
	fprintf( REPORT_HTML, ...
		'<table border="1"><tr><td> </td><td colspan="%.0f" align="center">Average performance of a given classifier on %.0f runs with distinct training sets. <a href="#" onClick="%s return false;">show/hide all details</a></td></tr>\n', ...
		length( results( 1 ).Splits( 1 ).SigSet(sig_set_index).AI ), ...
		length( results( 1 ).Splits ),  ...
		toggleAll ...
	);
	fprintf( REPORT_HTML, '<tr><td>Problem</td>' );
	for ai_index = 1:length( results( 1 ).Splits( 1 ).SigSet(1).AI )
		fprintf( REPORT_HTML, '<td>%s</td>', ...
			results( 1 ).Splits( 1 ).SigSet(1).AI( ai_index ).name ...
		);
	end;
	fprintf( REPORT_HTML, '</tr>\n' );
	flattened_accuracies_by_ai = cell( num_ais, 1 );
	% Measurements of how well distance measurements correlate with known class differences
	distanceFunctionCorrelationsByProblemAndFunction       = [];
	sampleDistanceFunctionCorrelationsByProblemAndFunction = [];
	continuousClassProblems                                = [];
	% Add a row for this problem to the overview of this signature set
	for problem_index = 1:length( results )
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Print the general description of this problem
		num_classes = length( results( problem_index ).Splits( split_index ).divisions.train_class_counts );
		fprintf( REPORT_HTML, '<tr>\n\t<td><b><a href="%s">%s</a></b><br/>\n%.0f classes<br/>\n%.0f training images per class<br/>\n%.0f total test images<br/>\n', ...
			prob_report_rel_paths{ problem_index }, ...
			results( problem_index ).name, ...
			num_classes, ...
			results( problem_index ).Splits( split_index ).divisions.train_class_counts(1), ...
			length( results( problem_index ).Splits( split_index ).divisions.testIndexes ) ...
		);
		train_set_overlap    = [];
		for split_index = 1:num_splits
			for split_index_2 = 1:num_splits
				if( split_index_2 == split_index )
					continue;
				end;
				train_set_overlap( end + 1 ) = ...
					length( intersect( results(problem_index).Splits(split_index).divisions.trainIndexes, results(problem_index).Splits(split_index_2).divisions.trainIndexes ) ) / ...
					length( results(problem_index).Splits(split_index).divisions.trainIndexes );
			end;
		end;
		fprintf( REPORT_HTML, '\t\t%.0f %% overlap btwn train sets<br/>\n</td>\n', ...
			round( mean( train_set_overlap ) * 100 ) ...
		);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Print the overall performance of each distinct classification strategy on this problem
		% First, compile the information, then print it
		for ai_index = 1:num_ais
			num_splits           = length( results( problem_index ).Splits );
			correct_of_attempted = [];
			correct_of_total     = [];
			avg_per_class_correct_of_attempted = [];
			unclassified         = [];
			sig_selected_overlap = [];
			num_sigs_used        = [];
			per_class_correct_of_total = [];
			individual_correlations = [];
			group_correlations      = [];
			for split_index = 1:num_splits
				correct_of_attempted( end + 1 ) = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.correctness;
				correct_of_total( end + 1 )     = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.net_accuracy;
				unclassified( end + 1 )         = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.num_unclassified;				
				for split_index_2 = 1:num_splits
					if( split_index_2 == split_index )
						continue;
					end;
					try
						sig_selected_overlap( end + 1 ) = ...
							length( intersect( ...
								results(problem_index).Splits(split_index  ).SigSet(sig_set_index).AI(ai_index).classifier.sigs_used, ...
								results(problem_index).Splits(split_index_2).SigSet(sig_set_index).AI(ai_index).classifier.sigs_used ...
							) ) / ...
							mean( [ ...
								length( results(problem_index).Splits(split_index  ).SigSet(sig_set_index).AI(ai_index).classifier.sigs_used ), ...
								length( results(problem_index).Splits(split_index_2).SigSet(sig_set_index).AI(ai_index).classifier.sigs_used ) ...
							] );
					catch
						sig_selected_overlap( end + 1 ) = ...
							length( intersect( ...
								results(problem_index).Splits(split_index  ).SigSet(sig_set_index).AI(ai_index).classifier.features_used, ...
								results(problem_index).Splits(split_index_2).SigSet(sig_set_index).AI(ai_index).classifier.features_used ...
							) ) / ...
							mean( [ ...
								length( results(problem_index).Splits(split_index  ).SigSet(sig_set_index).AI(ai_index).classifier.features_used ), ...
								length( results(problem_index).Splits(split_index_2).SigSet(sig_set_index).AI(ai_index).classifier.features_used ) ...
							] );
					end;
				end;
				num_sigs_used(split_index) = length( results(problem_index).Splits(split_index).SigSet(sig_set_index).AI(ai_index).classifier.sigs_used );
				% Calculate a normalized correctness value. First we calculate the accuracy for each class, then we average those accuracies together.
				for class_index = 1:num_classes
					per_class_correct_of_total( class_index, split_index ) = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.confusion_matrix( class_index, class_index ) / ...
						sum( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.confusion_matrix( class_index, : ) );
					flattened_accuracies_by_ai{ ai_index }( end + 1 ) = per_class_correct_of_total( class_index, split_index );
				end;
				% Calculate correlations of predictions to known values if class values are available
				if( isfield( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results, 'class_numeric_values' ) )
					class_numeric_values = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.class_numeric_values;
				else
					class_numeric_values = [];
				end;		
				if( length( class_numeric_values ) > 0 )
					num_images       = length( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.image_paths );
					class_vector     = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.class_vector;
					predicted_values = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.continuous_score;
					predictions_available = [];
					for i = 1:num_images
						if( sum( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs( i, : ) ) > 0 )
							predictions_available(end+1) = i;
						end;
					end;
					individual_correlations(end+1) = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.correlation;
					% Calculate group correlations
					group_predictions = [];
					for i = 1:length( class_numeric_values )
						ci = find( class_vector == i );
						ci = intersect( ci, predictions_available );
						group_predictions( i ) = mean( predicted_values( ci ) );
					end;
					[n_rows n_cols] = size( class_numeric_values );
					if( n_cols > n_rows )
						class_numeric_values = class_numeric_values';
					end;
					[n_rows n_cols] = size( group_predictions );
					if( n_cols > n_rows )
						group_predictions = group_predictions';
					end;
					group_correlations(end+1) = corr( class_numeric_values, group_predictions );
				end;
			end;

			fprintf( REPORT_HTML, '\t<td>\n' );
			if( length( class_numeric_values ) > 0 )
				fprintf( REPORT_HTML, '\t\tCorrelation: <b>%.2f &plusmn; %.2f</b> <a href="#" onClick="alert( ''The correlation between individual''s predicted value to their true value. Only calculated when class numeric values are available.'' );">?</a><br/>\n', ...
					mean( individual_correlations ), ...
					std( individual_correlations )  ...
				);
			else
				fprintf( REPORT_HTML, '\t\tPer-class accuracy: <b>%.0f &plusmn; %.0f %%</b> <a href="#" onClick="alert( ''The accuracy for each class is calculated by dividing the number of images correctly identified by the total test images in that class. This is repeated for every class in every training/test set. The numbers presented here are the average and std of those per-class accuracies.'' );">?</a><br/>\n', ...
					round( mean( per_class_correct_of_total(:) ) * 100 ), ...
					round( std( per_class_correct_of_total(:) ) * 100 ) ...
				);
			end;
			overview_id = sprintf( 'Prob%d_SigSet%d_AI%d', ...
				problem_index, sig_set_index, ai_index ...
			);
			fprintf( REPORT_HTML, '<a href="#" onClick="toggleVisibility(''%s''); return false;">More stats</a> \n', ...
				overview_id ...
			);
			fprintf( REPORT_HTML, '\t\t<div id="%s" style="display: none"><br/>\n', overview_id );
			fprintf( REPORT_HTML, '\t\t%.0f &plusmn; %.0f %% Avg per Class Correct of total <a href="#" onClick="alert( ''The accuracy for each class is calculated by dividing the number of images correctly identified by the total test images in that class. This is repeated for every class in every training/test set. The numbers presented here are the average and std of those per-class accuracies.'' );">?</a><br/>\n', ...
				round( mean( per_class_correct_of_total(:) ) * 100 ), ...
				round( std( per_class_correct_of_total(:) ) * 100 ) ...
			);
			if( length( class_numeric_values ) > 0 )
				fprintf( REPORT_HTML, '\t\t%.2f &plusmn; %.2f Ind. Corr. <a href="#" onClick="alert( ''The correlation between individual''s predicted value to their true value. Only calculated when class numeric values are available.'' );">?</a><br/>\n', ...
					mean( individual_correlations ), ...
					std( individual_correlations )  ...
				);
				fprintf( REPORT_HTML, '\t\t%.2f &plusmn; %.2f Group Corr. <a href="#" onClick="alert( ''The correlation between predicted value of a group to its true value. Only calculated when class numeric values are available.'' );">?</a><br/>\n', ...
					mean( group_correlations ), ...
					std( group_correlations ) ...
				);
			end;
			fprintf( REPORT_HTML, '\t\t%.0f &plusmn; %.0f %% Correct of total <a href="#" onClick="alert( ''The accuracy for each run of this problem was calculated by dividing the number of images correctly identified by the total test images. The numbers given here are the mean and std of those accuracies. This number will be different than the per-class accuracies when the number of images per class is unbalanced.'' );">?</a><br/>\n', ...
				round( mean( correct_of_total ) * 100 ), ...
				round( std( correct_of_total ) * 100 ) ...
			);
			fprintf( REPORT_HTML, '\t\t%.0f &plusmn; %.0f not attempted <a href="#" onClick="alert( ''Some methods are unable to generate predictions on some test image. The numbers given here are the mean and std of the number of images lacking predictions.'' );">?</a><br/>\n', ...
				round( mean( unclassified ) ), ...
				round( std( unclassified ) ) ...
			);
			fprintf( REPORT_HTML, '\t\t%.0f &plusmn; %.0f %% Correct of attempted <a href="#" onClick="alert( ''The accuracy for each run of this problem was calculated by dividing the number of images correctly identified by the number of predictions attempted. The numbers given here are the mean and std of those accuracies.'' );">?</a><br/>\n', ...
				round( mean( correct_of_attempted ) * 100), ...
				round( std( correct_of_attempted ) * 100) ...
			);
			fprintf( REPORT_HTML, '\t\t%.0f %% overlap in sigs selected <a href="#" onClick="alert( ''This is the overlap in signatures this method selects in from one split to another. This indicates the degree of self-consistency the method has from one particular training set to another. A perfectly consistent method would 100 percent overlap. A completely inconsistent method would have 0 percent overlap.'' );">?</a><br/>\n', ...
				round( mean( sig_selected_overlap ) * 100 ) ...
			);
			fprintf( REPORT_HTML, '\t\t%.0f &plusmn; %.1f: Number of signatures used <a href="#" onClick="alert( ''This is the mean and std of how many signatures this classification method selected.'' );">?</a><br/>\n', ...
				mean( num_sigs_used ), std( num_sigs_used ) ...
			);
			fprintf( REPORT_HTML, '\t\t</div>\n' );
			fprintf( REPORT_HTML, '\t\t<a href="%s">Confusion Matrixes</a> \n', ...
				confMatrix_rel_paths{ problem_index, sig_set_index, ai_index } ...
			);
			printConfusionMatrixesAndVariants( confMatrix_paths{ problem_index, sig_set_index, ai_index }, results, problem_index, sig_set_index, ai_index );

			% Links to Dendograms
			fprintf( REPORT_HTML, '\t\t<a href="%s">Class Based Dendrograms </a> \n', ...
				classDendrograms_rel_paths{ problem_index, sig_set_index, ai_index } ...
			);
			fprintf( REPORT_HTML, '\t\t<a href="%s">Sample Based Dendrograms </a> \n', ...
				sampleDendrograms_rel_paths{ problem_index, sig_set_index, ai_index } ...
			);

			fprintf( REPORT_HTML, '\t</td>\n' );

		end; % end AI loop
		fprintf( REPORT_HTML, '</tr>\n', results( problem_index ).name );
	end; % end Problem loop
	fprintf( REPORT_HTML, '</table><br/><br/><br/>\n' );
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Cross-compare each different classifier
	ai_comparison_id = sprintf( 'ai_comp_%d', sig_set_index );
	fprintf( REPORT_HTML, '<h2>Cross-comparison of the AI''s. <a href="#" onClick="toggleVisibility(''%s''); return false;">show results</a>.</h2>\n', ...
		ai_comparison_id );
	fprintf( REPORT_HTML, ...
		'<table border="1" cellspacing="0" cellpadding="5" id="%s" style="display: none;"><caption>Cell entries are the probability that the classifier in the column outperformed the classifier in the row. Results are based on a paired ttest. Significant entries are given in bold.</caption>\n', ...
		ai_comparison_id ...
	);
	fprintf( REPORT_HTML, '<tr>\n\t<td> </td>\n' );
	for ai_indexA = 1:num_ais
		fprintf( REPORT_HTML, '\t<td>%s</td>\n', results( 1 ).Splits( 1 ).SigSet(1).AI(ai_indexA).name );	
	end;
	fprintf( REPORT_HTML, '</tr>\n' );
	for ai_indexA = 1:num_ais
		fprintf( REPORT_HTML, '<tr>\n\t<td>%s</td>\n', results( 1 ).Splits( 1 ).SigSet(1).AI(ai_indexA).name );	
		for ai_indexB = 1:num_ais
			[h p] = ttest( ...
				flattened_accuracies_by_ai{ ai_indexA }, ...
				flattened_accuracies_by_ai{ ai_indexB }, ...
				0.05, 'left' ...
			);
			style = '';
			if( h ==1 )
				style = 'font-weight: bold;';
			end;
			fprintf( REPORT_HTML, '\t<td style="%s">%.2f</td>\n', style, p );
		end;
		fprintf( REPORT_HTML, '</tr>\n' );
	end;
	fprintf( REPORT_HTML, '</table>\n' );
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make links to each particular problem
for sig_set_index = 1:length( results( 1 ).Splits( 1 ).SigSet )
	for problem_index = 1:length( results )
		for ai_index = 1:length( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI )
			num_splits           = length( results( problem_index ).Splits );
			for split_index = 1:num_splits
				problem_rel_path = ...
					prob_and_treatment_rel_paths{ problem_index, split_index, sig_set_index, ai_index };
				fprintf( REPORT_HTML, '<li><a href="%s">%s, %s, %s, %s</a></li>', problem_rel_path, ...
					results( problem_index ).name, ...
					results( problem_index ).Splits( split_index ).name, ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).name, ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).name ...
				);
			end;
		end;
	end;
end;
fprintf( REPORT_HTML, '\n</body>\n</html>\n' );
fclose( REPORT_HTML );

% Evaluate signatures
sigAssessment( results, sig_assess_path, assess_sigs_w_classifiter );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make a report for each general problem
for problem_index = 1:length( results )
	[PROB_OVERVIEW] = fopen( prob_report_paths{ problem_index },'w');
	if( PROB_OVERVIEW == -1 )
		error( sprintf( 'Could not open report file: %s', prob_report_paths{ problem_index } ) );
	end;
	% print section header
	fprintf( PROB_OVERVIEW, '<h1>%s</h1><hr/>', ...
		results( problem_index ).name ...
	);

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Print the number of images in each training set & test set
	category_names = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.category_names;
	num_classes = length( category_names );
	if( isfield( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions, 'class_numeric_values' ) )
		[junk class_order] = sort( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.class_numeric_values );
	else
		class_order = 1:num_classes;
	end;
	fprintf( PROB_OVERVIEW, '<table border="1" cellspacing="0" cellpadding="3" align="center">\n' );
	fprintf( PROB_OVERVIEW, '<caption>Number of Images from Training & Testing</caption>\n' );
	fprintf( PROB_OVERVIEW, '<tr>\n' );
	fprintf( PROB_OVERVIEW, '<td></td>\n');
	fprintf( PROB_OVERVIEW, '<td>%s</td>\n', category_names{ : } );
	fprintf( PROB_OVERVIEW, '<td>Total</td>\n' );
	fprintf( PROB_OVERVIEW, '</tr>\n' );
	fprintf( PROB_OVERVIEW, '<tr>\n' );
	fprintf( PROB_OVERVIEW, '<td>Training</td>\n');
	fprintf( PROB_OVERVIEW, '<td>%.0f</td>\n', results( problem_index ).Splits( split_index ).divisions.train_class_counts( : ) );
	fprintf( PROB_OVERVIEW, '<td>%.0f</td>\n', length( results( problem_index ).Splits( split_index ).divisions.trainIndexes ) );
	fprintf( PROB_OVERVIEW, '</tr>\n' );
	fprintf( PROB_OVERVIEW, '<tr>\n' );
	fprintf( PROB_OVERVIEW, '<td>Testing</td>\n');
	fprintf( PROB_OVERVIEW, '<td>%.0f</td>\n', results( problem_index ).Splits( split_index ).divisions.test_class_counts( : ) );
	fprintf( PROB_OVERVIEW, '<td>%.0f</td>\n', length( results( problem_index ).Splits( split_index ).divisions.testIndexes ) );
	fprintf( PROB_OVERVIEW, '</tr>\n' );
	fprintf( PROB_OVERVIEW, '</table>\n' );

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% print a table for each set of signatures. 
	% columns are AI's, and rows are splits
	% each cell describes performance and lists sigs used.
	for sig_set_index = 1:length( results( 1 ).Splits( 1 ).SigSet )
		num_ais = length( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI );
		fprintf( PROB_OVERVIEW, '<h2><center>Results from signature set %s</center></h2>\n', ...
			results( 1 ).Splits( 1 ).SigSet(sig_set_index).name );

		% Print the sigs used table's header
		fprintf( PROB_OVERVIEW, '<table border="1" align="center">' );
		fprintf( PROB_OVERVIEW, '<tr>\n\t<td> </td>\n' );
		for ai_index = 1:length( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI )
			fprintf( PROB_OVERVIEW, '\t<td>%s</td>\n', ...
				results( 1 ).Splits( 1 ).SigSet(1).AI( ai_index ).name ...
			);
		end;
		fprintf( PROB_OVERVIEW, '</tr>\n' );
	
		% Print a row per split
		num_splits = length( results( problem_index ).Splits );
		for split_index = 1:num_splits
			fprintf( PROB_OVERVIEW, '<tr>\n\t<td>%s</td>\n', ...
				results( problem_index ).Splits( split_index ).name ...
			);
			% Print a cell per AI
			for ai_index = 1:num_ais
				
				fprintf( PROB_OVERVIEW, '\t<td align="center" valign="top">\n' );
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Collate performance metrics
				correct_of_attempted = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.correctness;
				correct_of_total     = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.net_accuracy;
				unclassified         = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.num_unclassified;				
				% Calculate a normalized correctness value. First we calculate the accuracy for each class, then we average those accuracies together.
				per_class_correct_of_total = [];
				for class_index = 1:num_classes
					per_class_correct_of_total( class_index ) = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.confusion_matrix( class_index, class_index ) / ...
						sum( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.confusion_matrix( class_index, : ) );
				end;
				% Print performance metrics
				fprintf( REPORT_HTML, '\t\t<b>%.0f &plusmn; %.0f %% Avg per Class Correct of total</b><br/>\n', ...
					round( mean( per_class_correct_of_total ) * 100 ), ...
					round( std( per_class_correct_of_total ) * 100 ) ...
				);
				fprintf( PROB_OVERVIEW, '\t\t%.0f %% Correct of total<br/>\n', ...
					round( correct_of_total * 100 ) ...
				);
				fprintf( PROB_OVERVIEW, '\t\t%.0f %% Correct of those attempted<br/>\n', ...
					round( correct_of_attempted * 100) ...
				);
				fprintf( PROB_OVERVIEW, '\t\t%.0f not attempted of %.0f<br/>\n', ...
					unclassified, ...
					length( results( problem_index ).Splits( split_index ).divisions.testIndexes ) ...
				);
				problem_rel_path = prob_and_treatment_rel_paths{ problem_index, split_index, sig_set_index, ai_index };
				fprintf( PROB_OVERVIEW, '<a href="%s">Full details</a><br/>\n', problem_rel_path );
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Print signatures used
				sigs_used = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier.sigs_used;
				num_sigs_used = length( sigs_used );
				sig_labels = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier.sig_labels;
				ind_sig_scores = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier.sigs_used_ind;
				sig_used_id = sprintf( 'Splt%.0fAI%.0f', split_index, ai_index );
				fprintf( PROB_OVERVIEW, '%.0f Sigs selected. <a href="#" onClick="sigs_used=document.getElementById(''%s''); if (sigs_used.style.display==''none''){ sigs_used.style.display=''inline''; } else { sigs_used.style.display=''none''; }">Toggle sigs used</a><br/>\n', ...
					num_sigs_used, sig_used_id ...
				);
				if( num_sigs_used > 10 )
					default_style = 'display: none;';
				else
					default_style = 'display: inline;';
				end;
				fprintf( PROB_OVERVIEW, '<table border="1" id="%s" style="%s"><tr><td><b>Signature Name</b></td><td><b>Signature score</b></td></tr>\n', ...
					sig_used_id, default_style ...
				);
				for sig_used_index = 1:length( sigs_used )
					sig_index = sigs_used( sig_used_index );
					sig_label = sig_labels{ sig_index };
					readable_sig_label = sig_label;
					readable_sig_label = regexprep( readable_sig_label, '(', '( ' );
					readable_sig_label = regexprep( readable_sig_label, ')', ' )' );
					readable_sig_label = regexprep( readable_sig_label, '\.', '. ' );
					fprintf( PROB_OVERVIEW, '<tr><td>%s</td><td>%.2f</td></tr>\n', ...
						readable_sig_label, ...
						ind_sig_scores( sig_used_index ) ...
					);
				end;
				fprintf( PROB_OVERVIEW, '</table>\n' ); % Close the sigs used table
				fprintf( PROB_OVERVIEW, '</td>\n' ); % Close the AI cell
			end; % end AI loop
			fprintf( PROB_OVERVIEW, '</tr>\n' );
		end; % end split loop
		fprintf( PROB_OVERVIEW, '</table>\n' );

		
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Print summary results for each experimental group ran on this sig set
		if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
			fprintf( PROB_OVERVIEW, '<hr/><h1>Experimental datasets</h1>\n' );
			fprintf( PROB_OVERVIEW, '<p>Predictions and other statistics were averaged across all splits</p>\n' );
			for exp_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
				% Make up a predictions that averages predictions from all the splits
				
				%% FIX ME optionally inject 'continuous_score'
				changing_fields = {'norm_avg_marg_probs', 'avg_class_similarities', 'avg_marg_probs', 'norm_confusion_matrix', 'class_predictions', 'num_unclassified', 'marginal_probs', 'confusion_matrix' };
				for split_index = 1:num_splits
					predictions = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).results;
					for field = changing_fields
						if( split_index == 1 )
							eval( [ 'sum_' field{1} ' = predictions.' field{1} ';' ] );
						else
							eval( [ 'sum_' field{1} ' = sum_' field{1} ' + predictions.' field{1} ';' ] );
						end;
					end;
				end;
				for field = changing_fields
					eval( [ 'predictions.' field{1} ' = sum_' field{1} ' ./ num_splits;'  ] );
				end;
				if( isfield( predictions, 'dataset_name' ) )
					exp_name = predictions.dataset_name;
				else
					exp_name = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).name;
				end;
				predictions_html_dump = sprintf( 'Prob%.0f_SigSet%.0f_AI%.0f_ExpResults%.0f.html', problem_index, sig_set_index, ai_index, exp_index );
				predictions_text_dump = sprintf( 'Prob%.0f_SigSet%.0f_AI%.0f_ExpResults%.0f.tsv',  problem_index, sig_set_index, ai_index, exp_index );
				overview_rel_path = prob_report_rel_paths{ problem_index };
				[html_chunk] = reportPredictions( predictions, report_root, predictions_html_dump, predictions_text_dump, report_rel_path, overview_rel_path  );
				fprintf( PROB_OVERVIEW, '<div style="background-color: #FFC; margin: 10pt; padding: 5pt;">\n' );
				fprintf( PROB_OVERVIEW, '<h2>%s predictions</h2>\n', exp_name );
				fprintf( PROB_OVERVIEW, '%s\n', html_chunk );
				fprintf( PROB_OVERVIEW, '</div>\n' );
			end;

		end;

			fprintf( PROB_OVERVIEW, '<hr/><hr/><hr/>\n' );
	end; % End sig set loop


	fprintf( PROB_OVERVIEW, '\n</body>\n</html>\n' );
	fclose( PROB_OVERVIEW );
end; % end problem loop



reportEachRun( results, prob_and_treatment_rel_paths, prob_and_treatment_paths, report_root, report_rel_path );
