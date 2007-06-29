function reportEachRun( results, prob_and_treatment_rel_paths, prob_and_treatment_paths, report_root, master_report_path )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make a report for each approach to each split of each problem
for problem_index = 1:length( results )

	for split_index = 1:length( results( problem_index ).Splits )
		if( results( problem_index ).Splits( split_index ).finished == 0 )
			continue;
		end;
		for sig_set_index = 1:length( results( problem_index ).Splits( split_index ).SigSet )
			train_path = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).train_path;
			train_dat = open( train_path );
			category_names = train_dat.category_names;
			num_classes = length( category_names );

			for ai_index = 1:length( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI )

				run_overview_path     = prob_and_treatment_paths{ problem_index, split_index, sig_set_index, ai_index };
				run_overview_rel_path = prob_and_treatment_rel_paths{ problem_index, split_index, sig_set_index, ai_index };
				[PROB_AND_TREATMENT_OVERVIEW] = fopen( run_overview_path,'w');
				
				% print section header
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<html><body>\n<h2>Problem name: %s<br>\nTrain/Test division: %s<br>\nSignature set: %s<br>\nAI algorithm: %s</h2>\n', ...
					results( problem_index ).name, ...
					results( problem_index ).Splits( split_index ).name, ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).name, ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).name ...
				);
				% Print the paths to the real data. Make a guess at the relative paths to the .mat files
				slash_count = length( strfind( report_root, '/' ) );
				relative_path = '../';
				for i = 1:slash_count
					relative_path = [relative_path '../'];
				end;
				fprintf( PROB_AND_TREATMENT_OVERVIEW, [ ...
					'<table align="center"><caption>Data in .mat files:</caption>\n<tr><td>\n' ...
					'<ul>\n' ...
					'<li><a href="%s">Training data</a></li>\n' ...
					'<li><a href="%s">Testing data</a></li>\n' ...
					'<li><a href="%s">Training/Testing divisions</a></li>\n' ...
					'</ul>\n</td>\n<td>\n<ul>\n' ...					
					'<li>AI path: %s</li>\n' ...
					'<li><a href="%s">Trained Classifier</a></li>\n' ...
					'<li><a href="%s">Predictions made on test data</a></li>\n' ...
					'<li><a href="%s">Predictions made on training data</a></li>\n' ...
					'</ul>\n</td>\n</tr>\n</table>\n' ...
					], ...
					[ relative_path train_path ], ...
					[ relative_path results( problem_index ).Splits( split_index ).SigSet(sig_set_index).test_path ], ...
					[ relative_path results( problem_index ).Splits( split_index ).divisions_path ], ...
					[ relative_path results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).ai_path ], ...
					[ relative_path results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier_path ], ...
					[ relative_path results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results_path ], ...
					[ relative_path results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions_path ] ...
				);
					
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<a href="%s">Back to master report</a><br/>\n', master_report_path );
			
				%%%%%%%%%%%%%%%%%%%%%%%%%
				% print the overview

				% Calculate a normalized correctness value. First we calculate the accuracy for each class, then we average those accuracies together.
				per_class_correct_of_total = [];
				for class_index = 1:num_classes
					per_class_correct_of_total( class_index ) = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.confusion_matrix( class_index, class_index ) / ...
						results( problem_index ).Splits( split_index ).divisions.test_class_counts( class_index );
				end;
				% Start the first column of the first row of the overview table
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<table width="100%%" align="center"><tr><td>\n' );
				% Print performance metrics
				fprintf( PROB_AND_TREATMENT_OVERVIEW, 'Avg per Class Correct of total <b>%.0f &plusmn; %.0f %%</b><br/>\n', ...
					round( mean( per_class_correct_of_total ) * 100 ), ...
					round( std( per_class_correct_of_total ) * 100 ) ...
				);
				fprintf( PROB_AND_TREATMENT_OVERVIEW, 'Correctness <b>%.2f</b> (number correct of number attempted)<br>\n', ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.correctness ...
				);
				fprintf( PROB_AND_TREATMENT_OVERVIEW, 'Net Accuracy <b>%.2f</b> (number correct of total number)<br>\n', ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.net_accuracy ...
				);
				fprintf( PROB_AND_TREATMENT_OVERVIEW, 'Total Unclassified <b>%.0f</b><br>\n', ...
					results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.num_unclassified ...
				);
				% Start the second column of the first row of the overview table
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</td><td>\n' );

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Print number of images in train & test.
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<table border="1" cellspacing="0" cellpadding="3">\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<caption>Number of Images from Training & Testing</caption>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<tr>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td> </td>\n');
				for group_index = 1:num_classes
					fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td>%s</td>\n', category_names{ group_index } );
				end;
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</tr>\n<tr>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td>Training</td>\n');
				train_dat = load( results( problem_index ).Splits(split_index).SigSet.train_path, 'signature_matrix', 'image_paths' );
				for group_index = 1:num_classes
					img_list_rel_path = sprintf( 'Prob%.0f_Split%.0f_TrainImgs_G%d.txt', problem_index, split_index, group_index );
					img_list_path = fullfile( report_root, img_list_rel_path );
					[IMG_LIST] = fopen( img_list_path,'w');
					image_indexes = find( train_dat.signature_matrix( end, : ) == group_index );
					fprintf( IMG_LIST, 'Training images in group "%s"\n', category_names{ group_index } );
					for i = 1:length( image_indexes )
						image_path = train_dat.image_paths{ image_indexes( i ) };
						fprintf( IMG_LIST, '%s\n', image_path );
					end;
					fclose( IMG_LIST );

					fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td><a href="%s" title="Click to see the names of these images">%.0f</a></td>\n', img_list_rel_path, results( problem_index ).Splits( split_index ).divisions.train_class_counts( group_index ) );
				end;
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</tr>\n<tr>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td>Testing</td>\n');
				test_dat = load( results( problem_index ).Splits(split_index).SigSet.test_path, 'signature_matrix', 'image_paths' );
				for group_index = 1:num_classes
					img_list_rel_path = sprintf( 'Prob%.0f_Split%.0f_TestImgs_G%d.txt', problem_index, split_index, group_index );
					img_list_path = fullfile( report_root, img_list_rel_path );
					[IMG_LIST] = fopen( img_list_path,'w');
					image_indexes = find( test_dat.signature_matrix( end, : ) == group_index );
					fprintf( IMG_LIST, 'Testing images in group "%s"\n', category_names{ group_index } );
					for i = 1:length( image_indexes )
						image_path = test_dat.image_paths{ image_indexes( i ) };
						fprintf( IMG_LIST, '%s\n', image_path );
					end;
					fclose( IMG_LIST );

					fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td><a href="%s" title="Click to see the names of these images">%.0f</a></td>\n', img_list_rel_path, results( problem_index ).Splits( split_index ).divisions.test_class_counts( group_index ) );
				end;
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</tr>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</table>\n' );

				% Start the second row of the overview table
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</td></tr><tr><td colspan="2" align="center">\n' );


				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Print signatures used if there are less than 1k
				sigs_used = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier.sigs_used;
				sig_labels = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier.sig_labels;
				ind_sig_scores = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).classifier.sigs_used_ind;
				num_sigs_used = length( sigs_used );
				if( num_sigs_used < 1000 )
					fprintf( PROB_AND_TREATMENT_OVERVIEW, '%.0f Sigs selected. <a href="#" onClick="sigs_used=document.getElementById(''SigsUsed''); if (sigs_used.style.display==''none''){ sigs_used.style.display=''inline''; } else { sigs_used.style.display=''none''; }">Toggle sigs used</a><br/>\n', ...
						num_sigs_used...
					);
					if( num_sigs_used > 10 )
						default_style = 'display: none;';
					else
						default_style = 'display: inline;';
					end;
					fprintf( PROB_AND_TREATMENT_OVERVIEW, '<br><table id="SigsUsed" border="1" style="%s"><tr><td><b>Signature Name</b></td><td><b>Signature score</b></td></tr>\n', ...
						default_style ...
					);
					for sig_used_index = 1:length( sigs_used )
						sig_index = sigs_used( sig_used_index );
						fprintf( PROB_AND_TREATMENT_OVERVIEW, '<tr><td>%.0f: %s</td><td>%.2f</td></tr>\n', ...
							sig_index, sig_labels{ sig_index }, ind_sig_scores( sig_used_index ) ...
						);
					end;
					fprintf( PROB_AND_TREATMENT_OVERVIEW, '</table>\n' ); % Close the signature table
				else
					fprintf( PROB_AND_TREATMENT_OVERVIEW, '%.0f Sigs selected.<br/>\n', num_sigs_used );
				end;
				
				% Close the overview table
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</td></tr></table>\n' );

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Print Results table header
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<table border="1" cellspacing="0" cellpadding="3">\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<tr>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td><h2>Test predictions</h2></td>\n');
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<td><h2>Training predictions</h2></td>\n');
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</tr>\n' );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '<tr>\n<td>\n' );
				
				
				
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% print Test results
				predictions       = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results;
				predictions_html_dump = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f.html', problem_index, split_index, sig_set_index, ai_index );
				predictions_text_dump = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f.tsv', problem_index, split_index, sig_set_index, ai_index );
				[html_chunk] = reportPredictions( predictions, report_root, predictions_html_dump, predictions_text_dump, master_report_path, run_overview_rel_path );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '%s\n', html_chunk );

				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</td><td>\n' );

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% print Training results
				predictions        = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions;
				predictions_html_dump = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f_TrainingPredictions.html', problem_index, split_index, sig_set_index, ai_index );
				predictions_text_dump = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f_TrainingPredictions.tsv', problem_index, split_index, sig_set_index, ai_index );
				[html_chunk] = reportPredictions( predictions, report_root, predictions_html_dump, predictions_text_dump, master_report_path, run_overview_rel_path  );
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '%s\n', html_chunk );

				fprintf( PROB_AND_TREATMENT_OVERVIEW, '</td></tr></table>\n' );
				
				
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% print separate divs for experimental results
				if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
					for exp_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
						fprintf( PROB_AND_TREATMENT_OVERVIEW, '<div style="float: left; background-color: #FFC; padding: 5pt; margin: 10pt;">\n' );

						predictions = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).results;
						if( isfield( predictions, 'dataset_name' ) )
							exp_name = predictions.dataset_name;
						else
							exp_name = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).name;
						end;
						predictions_html_dump = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f_ExpResults%.0f.html', problem_index, split_index, sig_set_index, ai_index, exp_index );
						predictions_text_dump = sprintf( 'Prob%.0f_Split%.0f_SigSet%.0f_AI%.0f_ExpResults%.0f.tsv',  problem_index, split_index, sig_set_index, ai_index, exp_index );
						[html_chunk] = reportPredictions( predictions, report_root, predictions_html_dump, predictions_text_dump, master_report_path, run_overview_rel_path  );
						fprintf( PROB_AND_TREATMENT_OVERVIEW, '<h2>%s predictions</h2>\n', exp_name );
						fprintf( PROB_AND_TREATMENT_OVERVIEW, '%s\n', html_chunk );
						fprintf( PROB_AND_TREATMENT_OVERVIEW, '</div>\n' );
					end;
				end;
				
				fprintf( PROB_AND_TREATMENT_OVERVIEW, '\n</body></html>' );
				fclose( PROB_AND_TREATMENT_OVERVIEW );

			end; % end AI loop
		end; % end sig set loop
	end; % end split loop
end; % end problem loop

