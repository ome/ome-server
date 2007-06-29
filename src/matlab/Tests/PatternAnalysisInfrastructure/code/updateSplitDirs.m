function updateSplitDirs(sig_dirs, output_dir, training_perc, crossValidateRepeats, min_test_class_size)
% SYNOPSIS:
%	sig_dirs   = { '../Signatures/Pooled' };
%	output_dir = 'data/';
%	training_perc = .8;
%	crossValidateRepeats = 5;
%	updateSplitDirs(sig_dirs, output_dir, training_perc, crossValidateRepeats);
% INPUTS NEEDED:
%	sig_dirs      - one or more signature directories
%	output_dir    - path to a directory to output training & test sets 
%   training_perc - a) portion of class instances to use as training images
%	                b) number of class instances to use as training images
%	crossValidateRepeats - The number of different Training/Test divisions to make
%	min_test_class_size - optional. Specifies the smallest allowable size of a
%		single class in the test set. Will override training_perc. 
% OUTPUTS GIVEN:
%	Directories are made, training and test signature matrixes are compiled, 
% Train & Test directories are made which contain links to original image files.
%
% DESCRIPTION
% 	This scans through the images directory and compiles signatures for each problem.
% Only problems that have had all signatures calculated on them will be considered.
%
% Each file of control data is expected to store certain variables:
%	signature_matrix
%	image_paths
%	signature_labels
% 
% Optional variables that store information about each image:
%	sample_ids: like a class vector, but identifies biological replicate. 
%		if present, images from a given sample won't be split between training & test sets
%	image_ids: like a class vector, but identifies which image a 'tile' originated with
%		used in the same way as sample_ids, but sample_ids overrides this.
%	split_on: Specifies where to split on 'sample_ids', 'image_ids', or 'tiles'. 
%		Allows sample_ids and image_ids to be present for report generation, 
%		without being considered during training/test splits.
%	slide_class_vector: Stores what slide an image was collected from. Used to correct
%		for imaging artifacts that systematically vary from slide to slide that
%		come from identical experimantal treatments
%	continuous_values: The numeric experimental variable or observation that  
%		images' class assignments are based on.
%	image_thumbnail_href, image_metadata_href: may eventually be used by the report generator
% Optional variables that do not provide a piece of information for each image:
%	dataset_name, category_names: self explanatory
%	class_numeric_values: The values of a class that represents a numeric, not categorical, experimental variable.
%	slide_correction_pattern: A regular expression that can parse a slide identifier
%		from an image name. If present, will be used to generate slide_class_vector.
%
% Written by Josiah Johnston <siah@nih.gov>


rand('state',sum(100*clock));           % keeping the rand real



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find problem names by looking for pooled signature files in the signature 
% directories. Different signature directories may contain different problems.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
optional_image_metadata = { ...
	'slide_class_vector', 'continuous_values', 'image_ids', ...
	'sample_ids', 'image_thumbnail_href', 'image_metadata_href' ...
};
optional_dataset_metadata = { 'class_numeric_values', 'slide_correction_pattern' };
for sig_set_index = 1:length( sig_dirs )
	sig_set_dir      = sig_dirs{ sig_set_index };
	while( sig_set_dir(end) == '/' ), sig_set_dir = sig_set_dir(1:end-1); end;
	% One sig set has .'s in its name. fileparts will divide it into name 
	% & extension. If it does that, then put the name back together.
	[ path, sig_set_name, extension ] = fileparts( sig_set_dir );
	sig_set_name = [ sig_set_name extension ];
	
	%%%%%%%%%%%%%%%%%%%%%%%%
	% Find problem names
	file_listing  = dir( sig_set_dir );
	problem_names = {};
	problem_input_paths = {};
	for file_index = 1:length(file_listing)
		%%%%%%%%%%%%%%%%%%%%%%%%
		% Don't keep entries that start with '.'
		% Only keep files that end with '.mat'
		if( file_listing( file_index ).name(1) ~= '.' & ...
			length( file_listing( file_index ).name ) >= 4 & ...
			file_listing( file_index ).name(end-3:end) == '.mat' )
			problem_names{ end + 1 } = file_listing( file_index ).name(1:end-4);
			problem_input_paths{ end + 1 } = fullfile( sig_set_dir, file_listing( file_index ).name );
		end;
	end;

	%%%%%%%%%%%%%%%%%%%%%%%%
	% Create or update the split directories for this sigset & problem	
	for problem_index = 1:length( problem_names )
		problem_name = problem_names{ problem_index };
		dataset_name = problem_name;
		problem_input_path = problem_input_paths{ problem_index };
		problem_ouput_path = fullfile( output_dir, problem_name );
		
		%%%%%%%%%%%%%%%%%%%%%%%%
		% Load the problem set and derive lengths of data
		sig_data = load( problem_input_path );
		signature_matrix    = sig_data.signature_matrix;
		image_paths         = sig_data.image_paths;
		signature_labels    = sig_data.signature_labels;
		class_vector        = signature_matrix( end, : );
		num_classes         = length( unique( class_vector ) );
		num_instances_per_class = [];

		if( isfield( sig_data, 'dataset_name' ) )
			dataset_name = sig_data.dataset_name;
		end;
		category_names = {};
		if( isfield( sig_data, 'category_names' ) )
			category_names = sig_data.category_names;
		else
			for class_index = 1:num_classes
				category_names{ class_index } = sprintf( 'Class %.0f', class_index );
			end;
		end;
		% Load optional dataset metadata
		for var_name = optional_dataset_metadata
			if( isfield( sig_data, var_name{1} ) )
				eval( [var_name{1} ' = sig_data.' var_name{1} ';'] );
			elseif( exist( var_name{1}, 'var' ) )
				eval( ['clear ' var_name{1} ';' ] );
			end;
		end;
		% Load optional image metadata
		for var_name = optional_image_metadata
			if( isfield( sig_data, var_name{1} ) )
				eval( [var_name{1} ' = sig_data.' var_name{1} ';'] );
			elseif( exist( var_name{1}, 'var' ) )
				eval( ['clear ' var_name{1} ';' ] );
			end;
		end;
		
		if( exist( 'slide_correction_pattern', 'var' ) & ~exist( 'slide_class_vector', 'var' ) )
			[slide_class_vector] = getArtifactClassVector(image_paths, slide_correction_pattern);
		end;

		% Decide what to generate splits based on: tiles of an image, images that
		% contain several tiles, or biological samples that many images were collected
		% from.
		if( isfield( sig_data, 'split_on' ) )
			split_on = sig_data.split_on;
		else
			if( exist( 'sample_ids', 'var' ) )
				split_on = 'sample_ids';
			elseif( exist( 'image_ids', 'var' ) )
				split_on = 'image_ids';
			else
				split_on = 'tiles';
			end;
		end;
		for class_index = 1:num_classes
			class_instances                            = find( class_vector == class_index );
			if( strcmp( 'sample_ids', split_on ) )
				num_instances_per_class( class_index ) = length( unique( sample_ids(class_instances) ) );
			elseif( strcmp( 'image_ids', split_on ) )
				num_instances_per_class( class_index ) = length( unique( image_ids( class_instances) ) );
			else
				num_instances_per_class( class_index ) = length( class_instances );
			end;
		end;
		if( strcmp( 'sample_ids', split_on ) )
			ids_to_split_on = sample_ids;
		elseif( strcmp( 'image_ids', split_on ) )
			ids_to_split_on = image_ids;
		else
			ids_to_split_on = 1:length( class_vector );
		end;
		% Skip this problem if there is only one class.
		if( num_classes <= 1 ) 
			continue;
		end;
		if( ~exist( problem_ouput_path, 'dir' ) )
			mkdir( problem_ouput_path );
		end;


		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Calculate size of training set
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		for split_index = 1:crossValidateRepeats
			split_name    = sprintf( 'Split%.0f', split_index );
			split_dir     = fullfile( output_dir, problem_name, split_name );
			split_sig_dir = fullfile( split_dir, sig_set_name );
			split_path    = fullfile( split_dir, 'trainTestSplit.mat' );
			train_path    = fullfile( split_sig_dir, 'Train.mat' );
			test_path     = fullfile( split_sig_dir, 'Test.mat' );
			
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% Skip this directory if it has already been made
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			if( ~exist( split_dir, 'dir' ) )
				fprintf( 'Making split "%s" directory for problem "%s".\n', split_name, problem_name );
				mkdir( split_dir );
			end;
			if( ~exist( split_sig_dir, 'dir' ) )
				fprintf( 'Making signature set "%s" directory for split "%s", problem "%s".\n', sig_set_name, split_name, problem_name );
				mkdir( split_sig_dir );
			end;
			
	
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% divide the entries into training and testing groups 
			% Unless they have already been computed & saved
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			if( ~exist( split_path, 'file' ) )
				fprintf( 'Generating a new division of training and test sets.\n' );
				% Calculate the number of samples of each class to put in the training set.
				min_class_size = min( num_instances_per_class );
				if( training_perc < 1 )
					training_samples_per_class = ceil(training_perc*min_class_size);
				else
					training_samples_per_class = training_perc;
				end;
				if( training_samples_per_class == min_class_size )
					training_samples_per_class = min_class_size - 1;
				end;
				if( exist( 'min_test_class_size', 'var' ) )
					if( ( min_class_size - training_samples_per_class < min_test_class_size ) & ...
						( min_test_class_size < min_class_size ) )
						training_samples_per_class = min_class_size - min_test_class_size;
					end;
				end;
				
				% Randomly divide into training and test sets
				% This code is complicated because the atomic samples we have
				% represented in class_vector and the feature matrix may be 
				% grouped into larger clumps via ids_to_split_on. We assume
				% that every atomic sample in any given larger clump is in the same class.
				trainIndexes = [];
				testIndexes  = [];
				for class_index = 1:num_classes
					class_instances = find( class_vector == class_index );
					ids_in_class    = unique( ids_to_split_on( class_instances ) );
					random_order    = randperm( length( ids_in_class ) );

					train_ids = ids_in_class(random_order(1:training_samples_per_class));
					test_ids  = ids_in_class(random_order(training_samples_per_class+1:end));
					
					for id = train_ids
						class_instances = find (ids_to_split_on == id);
						trainIndexes = [trainIndexes class_instances];
					end

					for id = test_ids
						class_instances = find(ids_to_split_on == id);
						testIndexes = [testIndexes class_instances];
					end
				end;
				
				train_image_paths  = image_paths( trainIndexes );
				test_image_paths   = image_paths( testIndexes );
				train_class_vector = class_vector( trainIndexes );
				train_class_counts = [];
				for class_index = 1:num_classes
					train_class_counts( class_index ) = length( find( train_class_vector == class_index ) );
				end;
				test_class_vector = class_vector( testIndexes );
				test_class_counts = [];
				for class_index = 1:num_classes
					test_class_counts( class_index ) = length( find( test_class_vector == class_index ) );
				end;
				
				save( split_path, 'trainIndexes', 'testIndexes', 'train_image_paths', 'test_image_paths', 'train_class_counts', 'test_class_counts', 'test_class_vector', 'train_class_vector' );
			
			% Load the previously saved divisions of training & testing sets.
			else
				fprintf( 'Using an existing division of training and test sets for problem %s, Split %d.\n', problem_name, split_index );
				split_info        = load( split_path );
				trainIndexes      = split_info.trainIndexes;
				testIndexes       = split_info.testIndexes;				
				train_image_paths = split_info.train_image_paths;
				test_image_paths  = split_info.test_image_paths;
				train_class_vector = class_vector( trainIndexes );
				test_class_vector = class_vector( testIndexes );
			end;
			
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% Save compiled signature matrixes
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			README      = sprintf( [
							'signature_matrix is the 2D signature matrix. Rows are signatures. Columns are images. The last row is the class id.\n' ...
							'sig_labels amount to row labels for signature_matrix. It lacks an entry for the class row of the signature matrix.\n' ...
							'image_paths amount to column labels for signature_matrix.\n' ...
							'category_names are the names of the image classes.\n' ...
							'dataset_name is the name of the OME dataset from whence this problem has come.\n' ...
						] );	
			if( exist( 'class_numeric_values', 'var' ) ) 
				README = [ README sprintf( 'class_numeric_values stores a continuous value that class divisions were based on. It may represent an observation or an experimental manipulation.\n' ) ];
			end;
			sig_labels            = signature_labels;
			orig_image_paths      = image_paths;
			orig_signature_matrix = signature_matrix;
			orig_class_vector     = class_vector;
			for var_name = optional_image_metadata
				if( exist( var_name{1}, 'var' ) )
					eval( [ 'orig_' var_name{1} ' = ' var_name{1} ';' ] );
				end;
			end;
		
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% Save Training signature matrix.
			% Copy variables into normalized names
			if( ~exist( train_path, 'file' ) )
				signature_matrix     = orig_signature_matrix(:, trainIndexes );
				class_vector         = orig_class_vector( trainIndexes );
				global_image_indexes = trainIndexes;
				image_paths          = train_image_paths;
				save_vars = { 'signature_matrix', 'category_names', 'sig_labels', ...
						'README', 'image_paths', 'dataset_name', 'class_vector', 'global_image_indexes' };
				for var_name = optional_dataset_metadata
					if( exist( var_name{1}, 'var' ) )
						save_vars{end + 1 } = var_name{1};
					end;
				end;
				for var_name = optional_image_metadata
					if( exist( var_name{1}, 'var' ) )
						eval( [var_name{1} ' = orig_' var_name{1} '( trainIndexes );'] );
						save_vars{end + 1 } = var_name{1};
					end;
				end;
				save( train_path, save_vars{:} );
			end;
		
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% Save Testing signature matrix.
			% Copy variables into normalized names
			if( ~exist( test_path, 'file' ) )
				signature_matrix     = orig_signature_matrix(:, testIndexes );
				image_paths          = test_image_paths;
				class_vector         = orig_class_vector( testIndexes );
				global_image_indexes = testIndexes;
				save_vars = { 'signature_matrix', 'category_names', 'sig_labels', ...
						'README', 'image_paths', 'dataset_name', 'class_vector', 'global_image_indexes' };
				
				for var_name = optional_dataset_metadata
					if( exist( var_name{1}, 'var' ) )
						save_vars{end + 1 } = var_name{1};
					end;
				end;
				for var_name = optional_image_metadata
					if( exist( var_name{1}, 'var' ) )
						eval( [var_name{1} ' = orig_' var_name{1} '( testIndexes );'] );
						save_vars{end + 1 } = var_name{1};
					end;
				end;
				save( test_path, save_vars{:} );
			end;
		
			image_paths      = orig_image_paths;
			signature_matrix = orig_signature_matrix;
			class_vector     = orig_class_vector;
			for var_name = optional_image_metadata
				if( exist( var_name{1}, 'var' ) )
					eval( [ var_name{1} ' = orig_' var_name{1} ';' ] );
				end;
			end;


			%%%%%%%%%%%%%%%%%%%%%%%%
			% Find experimental datasets for this problem, and link them to the output dir of a 
			% particular signature set of each split
			problem_subdir = fullfile( sig_set_dir, problem_name );
			if( exist( problem_subdir, 'dir' ) )
				file_listing  = dir( problem_subdir );
				for file_index = 1:length(file_listing)
					%%%%%%%%%%%%%%%%%%%%%%%%
					% Don't keep entries that start with '.'
					% Only keep files that end with '.mat'
					if( file_listing( file_index ).name(1) ~= '.' & ...
						length( file_listing( file_index ).name ) >= 4 & ...
						file_listing( file_index ).name(end-3:end) == '.mat' )
						data_path = fullfile( problem_subdir, file_listing( file_index ).name );
						link_path = fullfile( split_sig_dir, file_listing( file_index ).name );
						num_subdirectories = length( strfind( link_path, filesep ) );
						for d = 1:num_subdirectories
							data_path = sprintf( '../%s', data_path );
						end;
						link_command = sprintf( 'ln -s %s %s; ', data_path, link_path );
						if( ~exist( link_path, 'file' ) )
							system( link_command );
						end;
					end;
				end;
			end;
		
		end; % Split loop
	end; % Problem loop
end; % Sig set loop

return;
