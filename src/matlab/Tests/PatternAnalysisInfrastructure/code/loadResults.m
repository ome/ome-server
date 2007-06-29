function [results] = loadResults( results_path )

if( ~exist( 'results_path', 'var' ) )
	results_path = 'data/classifiers/results.mat';
	if( ~exist( results_path, 'file' ) )
		error( sprintf( 'Results cannot be loaded because the results_path parameter was not given, and no file exists at the default path, %s.', results_path ) );
	end;
end;
results = load( results_path );
results = results.results;

for problem_number = 1:length( results )
	for split_index = 1:length( results( problem_number ).Splits )
		if( ~results( problem_number ).Splits( split_index ).finished )
			fprintf( 'problem "%s" Split %d is not finished\n', ...
				results( problem_number ).name, split_index );
			continue;
		end;
		divisions_path = results( problem_number ).Splits( split_index ).divisions_path;
		if( ~exist( divisions_path, 'file' ) )
			fprintf( 'divisions_path: %s does not exist. Something is wrong.\n', ...
				divisions_path );
		end;
		results( problem_number ).Splits( split_index ).divisions = open( divisions_path );
		for sig_set_index = 1:length( results( problem_number ).Splits( split_index ).SigSet )
			for ai_index = 1:length( results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI )
				classifier_path = results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).classifier_path;
				if( exist( classifier_path, 'file' ) )
					results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).classifier = ...
						open( classifier_path );
				end;
				results_path = results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).results_path;
				if( exist( results_path, 'file' ) )
					results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).results = ...
						open( results_path );
				end;
				train_predictions_path = results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).train_predictions_path;
				if( exist( train_predictions_path, 'file' ) )
					results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).train_predictions = ...
						open( train_predictions_path );
				end;
				if( isfield( results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
					for exp_index = 1:length( results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
						results_path = results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).results_path;
						if( exist( results_path, 'file' ) )
							results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).results = ...
								open( results_path );
						end;
					end;
				end;
			end;
		end;
	end;
end;

return;
