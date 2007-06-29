function [ results ] = scanAndTrainAndTest( compiled_sig_dir, classifier_dir, sig_sets, results_path, problem_dirs, compile_results_only)
% SYNOPSIS:
%	compiled_sig_dir = 'data/classifiers';
%	classifier_dir   = 'code/Classifiers/';
%	sig_sets          = { 'computedInOME_AE' };
%	results_path     = 'data/results.mat';
%	scanAndTrainAndTest(compiled_sig_dir, classifier_dir, sig_sets, results_path);
% OUTPUTS GIVEN:
%	For each classification problem, this makes directories for each 
% classification strategy, trains and tests each classification strategy,
% and saves the results to disk.
%
% DESCRIPTION
% 	This scans through the compiled signature directory, trains, and tests
% classifiers for each problem. The compiled signature directory has structure:
%	/path_to_compiled_dir/PROBLEM_NAME/SplitX/Images/CLASS_NAME/
%		Contains Links to image files.
%	/path_to_compiled_dir/PROBLEM_NAME/SplitX/SIGNATURE_SET_NAME/
%		Contains Train.mat and Test.mat
% This function makes subdirectories in the latter directory for each type of 
% classifier. e.g. BayesMultiWay, SVM_OneAgainstAll, etc.
%
% ADDITIONAL BEHAVIOR
% There is an optional flag to compile results only that can be passed at
% the end of the function. So if you call the function like this:
%	scanAndTrainAndTest(compiled_sig_dir, classifier_dir, sig_sets, 'compile_results_only');
% or this
%	scanAndTrainAndTest(compiled_sig_dir, classifier_dir, sig_sets, 1);
% The function will not train or test, but with scan through the entire
% problem space and compile the existing results.
%
% Written by Josiah Johnston <siah@nih.gov>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find problem names by scanning the compiled signature directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Problems are stored as subdirectories
% Skip the scan if problems were given as a parameter.
if( ~exist( 'problem_dirs', 'var' ) | length( problem_dirs ) == 0 )
	problem_dirs = dir( compiled_sig_dir );
	keep_files = [];
	for file_index = 1:length(problem_dirs)
		% Don't keep entries that start with '.'
		% Don't treat the 'logs' directory as a problem directory
		% Don't treat the 'code' directory as a problem directory
		% Don't treat files as problem directories
		if( problem_dirs( file_index ).name(1) ~= '.' & ...
			~strcmp( problem_dirs( file_index ).name, 'logs' ) & ...
			~strcmp( problem_dirs( file_index ).name, 'code' ) & ...
			problem_dirs( file_index ).isdir)
			keep_files( end + 1 ) = file_index;
		end;
	end;
	problem_dirs = problem_dirs(keep_files);
	problem_dirs = { problem_dirs.name };
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find available classifiers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classifiers = dir( classifier_dir );
keep_these = [];
for file_index = 1:length(classifiers)
	% Don't keep entries that start with '.'
	% Don't keep files. Only keep directories
	if( classifiers( file_index ).name(1) ~= '.' & ...
	    classifiers( file_index ).isdir)
		keep_these( end + 1 ) = file_index;
	end;
end;
classifiers = classifiers(keep_these);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the hostname of this machine.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[ junk hostname ] = system( 'hostname' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Train & Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for problem_number = 1:length( problem_dirs )
	problem_path = fullfile( compiled_sig_dir, problem_dirs{ problem_number } );
	% initialize the problem name
	results( problem_number ).name = '';
	
	% Scan for Split directories
	split_dirs = dir( problem_path );
	split_dirs = filterOutHiddenFiles( split_dirs, 1 ); % removes '.' & '..', and only keeps directories
	for split_index = 1:length( split_dirs )
		split_path = fullfile( problem_path, split_dirs( split_index ).name );
		results( problem_number ).Splits( split_index ).name = split_dirs( split_index ).name;
		% Begin with the assumption that everything is finished. Change this assumption if we find something unfinished.
		results( problem_number ).Splits( split_index ).finished = 1;
		% This next line creates a structure with fields trainIndexes and testIndexes
		results( problem_number ).Splits( split_index ).divisions_path = fullfile( split_path, 'trainTestSplit.mat' );
		
		% Work through each signature set
		for sig_set_index = 1:length( sig_sets )
			sig_set_path    = fullfile( split_path, sig_sets{ sig_set_index } );
			train_path      = fullfile( sig_set_path, 'Train.mat' );
			test_path       = fullfile( sig_set_path, 'Test.mat' );
			results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).name = ...
				sig_sets{ sig_set_index };
			results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).train_path = ...
				train_path;
			results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).test_path = ...
				test_path;
			
			% Figure out a name for this problem if we don't have one yet.
			if( strcmp( results( problem_number ).name, '' ) )
				trainDat = load( train_path );
				if( isfield( trainDat, 'dataset_name' ) )
					results( problem_number ).name = trainDat.dataset_name;
				else
					results( problem_number ).name = problem_dirs{ problem_number };
				end;
				clear trainDat;
			end;

			% Work through each classifier
			for ai_index = 1:length( classifiers )
				% Set up file and directory paths
				classifier_name      = classifiers( ai_index ).name;
				ai_path              = fullfile( classifier_dir, classifier_name );
				classifier_save_dir  = fullfile( sig_set_path, classifier_name );
				classifier_path      = fullfile( classifier_save_dir, 'Classifier.mat' );
				training_flag        = [ classifier_path '.in.progress' ];
				test_save_path       = fullfile( classifier_save_dir, 'TestResults.mat' );
				testing_flag         = [ test_save_path '.in.progress' ];
				training_pred        = fullfile( classifier_save_dir, 'TrainResults.mat' );
				training_pred_flag   = [ training_pred '.in.progress' ];

	 			% Record the paths
				results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).name = ...
					classifier_name;
				results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).ai_path = ...
					ai_path;
				results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).classifier_path = ...
					classifier_path;
				results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).results_path = ...
					test_save_path;
				results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).train_predictions_path = ...
					training_pred;

				% Make the directory if needed
				if( ~exist( classifier_save_dir, 'dir' ) & ~exist( 'compile_results_only', 'var' ) )
					mkdir( classifier_save_dir );
				end;
				
				% Is this training problem up for grabs?
				if( ~exist( training_flag, 'file' ) & ~exist( classifier_path, 'file' ) & ~exist( 'compile_results_only', 'var' ) )
					fprintf( 'Training %s with classifier %s\n', train_path, classifier_name );
					foo = 1;
					save( training_flag, 'foo' );
					save( [ training_flag '.by.' hostname ], 'foo' );
					addpath( genpath( ai_path ) );
					Train( train_path, classifier_path );
					rmpath( genpath( ai_path ) );
					delete( training_flag );
					delete( [ training_flag '.by.' hostname ] );
					fprintf( '\tFinished\n');
				else
					fprintf( 'Skipping training problem %s with classifier %s\n', train_path, classifier_name );
				end;

				% Mark problem as unfinished if the classifier hasn't been trained
				if( ~exist( classifier_path, 'file' ) )
					results( problem_number ).Splits( split_index ).finished = 0;
				end;

				% Do the same stuff for testing.
				if( ~exist( testing_flag, 'file' ) & ~exist( test_save_path, 'file' ) & exist( classifier_path, 'file' ) & ~exist( 'compile_results_only', 'var' ) )
					fprintf( 'Testing %s with classifier %s\n', test_path, classifier_name );
					foo = 1;
					save( testing_flag, 'foo' );
					save( [ testing_flag '.by.' hostname ], 'foo' );
					addpath( genpath( ai_path ) );
					Test( classifier_path, test_path, test_save_path );
					rmpath( genpath( ai_path ) );
					delete( testing_flag );
					delete( [ testing_flag '.by.' hostname ] );
					fprintf( '\tFinished\n');
				else
					fprintf( 'Skipping testing problem %s with classifier %s\n', test_path, classifier_name );
				end;
				
				% Mark problem as unfinished if predictions haven't been made on the test set
				if( ~exist( test_save_path, 'file' ) )
					results( problem_number ).Splits( split_index ).finished = 0;
				end;

				% Generate predictions for the training set.
				if( ~exist( training_pred_flag, 'file' ) & ~exist( training_pred, 'file' ) & exist( classifier_path, 'file' ) & ~exist( 'compile_results_only', 'var' ) )
					fprintf( 'Generating predictions for %s with classifier %s\n', train_path, classifier_name );
					foo = 1;
					save( training_pred_flag, 'foo' );
					save( [ training_pred_flag '.by.' hostname ], 'foo' );
					addpath( genpath( ai_path ) );
					Test( classifier_path, train_path, training_pred );
					rmpath( genpath( ai_path ) );
					delete( training_pred_flag );
					delete( [ training_pred_flag '.by.' hostname ] );
					fprintf( '\tFinished\n');
				else
					fprintf( 'Skipping prediction generation %s with classifier %s\n', train_path, classifier_name );
				end;
				
				% Mark problem as unfinished if predictions haven't been made on the training set
				if( ~exist( training_pred, 'file' ) )
					results( problem_number ).Splits( split_index ).finished = 0;
				end;
				
				%%%%%%%%%%%%%%%%%%%%%%%%
				% Generate predictions on experimental data		
				% Scan for experimental datasets
				skip_files = { 'Train.mat', 'Test.mat' };
				experimental_datasets = dir( sig_set_path );
				experimental_datasets = filterOutHiddenFiles( experimental_datasets, 2 ); % removes '.' & '..', and only keeps files
				% Generate predictions for each experimental data set
				for d = 1:length( experimental_datasets )
					if( length( find( strcmp( experimental_datasets(d).name, skip_files ) ) ) > 0 )
						continue;
					end;
					%%%%%%%%%%%%%%%%%%%%%%%%
					% Determine experimental dataset names & paths
					experimental_dataset_name         = experimental_datasets(d).name(1:end-4);
					experimental_dataset_input_path   = fullfile( sig_set_path, experimental_datasets(d).name );
					experimental_dataset_results_path = fullfile( classifier_save_dir, [ experimental_dataset_name '.Results.mat' ] );
					in_progress_flag                  = [ experimental_dataset_results_path '.in.progress' ];
					%%%%%%%%%%%%%%%%%%%%%%%%
					% Generate predictions for this data set.
					if( ~exist( in_progress_flag, 'file' ) & ~exist( experimental_dataset_results_path, 'file' ) & exist( classifier_path, 'file' ) & ~exist( 'compile_results_only', 'var' ) )
						fprintf( 'Generating predictions for %s with classifier %s\n', experimental_dataset_input_path, classifier_name );
						foo = 1;
						save( in_progress_flag, 'foo' );
						save( [ in_progress_flag '.by.' hostname ], 'foo' );
						addpath( genpath( ai_path ) );
						Test( classifier_path, experimental_dataset_input_path, experimental_dataset_results_path, 1 );
						rmpath( genpath( ai_path ) );
						delete( in_progress_flag );
						delete( [ in_progress_flag '.by.' hostname ] );
						fprintf( '\tFinished\n');
					else
						fprintf( 'Skipping prediction generation %s with classifier %s\n', experimental_dataset_input_path, classifier_name );
					end;
					%%%%%%%%%%%%%%%%%%%%%%%%
					% Save the predictions's paths into the results object
					exp.name         = experimental_dataset_name;
					exp.data_path    = experimental_dataset_input_path;
					exp.results_path = experimental_dataset_results_path;
					if( ~isfield( results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
						results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets        = exp;
					else
						results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(end+1) = exp;
					end;
					% Mark problem as unfinished if predictions haven't been made on the training set
					if( ~exist( exp.results_path, 'file' ) )
						results( problem_number ).Splits( split_index ).finished = 0;
					end;
				end;

			end; % End classifier loop
			
		end; % End Sig Set loop

		% This is the easiest way of getting the name of the test images in this split
		if( ~isfield( results( problem_number ).Splits( split_index ).SigSet( end ), 'AI' ) )
			fprintf( 'Something is wierd. results( %d ).Splits( %d ).SplitSet( %d ) is not populated with the field AI.\n', ...
				problem_number, split_index, length(  results( problem_number ).Splits( split_index ).SigSet ) ...
			);
		elseif( isfield( results( problem_number ).Splits( split_index ).SigSet( end ).AI( end ), 'results' ) )
			results( problem_number ).Splits( split_index ).image_paths = ...
				results( problem_number ).Splits( split_index ).SigSet( end ).AI( end ).results.image_paths;
		end;

	end; % End Split loop
	
end; % End Problem loop

save( results_path, 'results' );

return;
