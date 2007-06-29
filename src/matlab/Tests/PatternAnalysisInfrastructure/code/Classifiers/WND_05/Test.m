function [confusion_matrix, marginal_probs, image_paths, ...
	correctness, net_accuracy, num_unclassified] = Test( classifier_path, test_path, save_path, predict_only )
% SYNOPSIS
%	Test( classifier_path, test_path, save_path, predict_only )
% DESCRIPTION
%	Tests a Weighted Neighbor Distances Classifier in classifier_path with the test data in test_path,
% and saves the results to save_path.
% INPUTS
%	The first three inputs specify file paths to data.
%	predict_only: An optional flag to generate predictions on data that may not have
%		the same categories as the controls. If this flag is set to true,
%		accuracy and other statistics that are specific to a Test set of 
%		control data will not be computed or saved. The default value is false.
tic;

if( ~exist( 'predict_only', 'var' ) )
	predict_only = 0;
end;

% Load classifier & data
classifier = open( classifier_path );
data       = open( test_path );

class_vector     = data.signature_matrix(end,:);
category_names   = data.category_names;
image_paths      = data.image_paths;
category_names   = data.category_names;
num_unclassified = 0;
classes          = unique( class_vector ); 
control_category_names = classifier.category_names;

save_vars = { 'marginal_probs', 'confusion_matrix', 'norm_confusion_matrix', ...
	'image_paths', 'class_predictions', 'avg_class_similarities', 'avg_marg_probs', ...
	'num_unclassified', 'README', 'class_similarities', 'category_names', ...
	'norm_avg_marg_probs', 'class_vector', 'total_computational_time', 'control_category_names' };

% Prepare variables for saving
README = sprintf([ ...
'These are the results of a WND classifier (' classifier_path ...
'). Predictions were generated on data in the file: ' test_path ...
'. Variables:\n' ...
'	marginal_probs stores the probability distributions for each image.\n' ...
'	confusion_matrix stores a summary of the classifier results. Rows indicate actual classes, columns indicate predicted classes. A number in row j, column i indicates how many images of class j were predicted to be class i.\n'...
'	image_paths stores the paths of the images.\n'...
'	num_unclassified stores the number of images that were unclassified\n', ...
]);


if( predict_only )
	[marginal_probs, class_predictions, class_similarities] = ...
		WND_Predict( data.signature_matrix, classifier.norm_train_matrix, ...
			classifier.features_used, classifier.feature_scores, ...
			classifier.feature_min, classifier.feature_max );
else
	[net_accuracy, mean_per_class_accuracy, junk, junk, ...
		class_predictions, marginal_probs, class_similarities] = ...
		WND_Test(data.signature_matrix, classifier.norm_train_matrix, ...
			classifier.features_used, classifier.feature_scores, ...
			classifier.feature_min, classifier.feature_max);
	correctness     = net_accuracy;
	better_accuracy = mean_per_class_accuracy;
	% Prepare variables for saving
	README = sprintf([ '%s' ...
	'	correctness stores the percentage of guesses the classifier got correct. This does not penalize the classifier for offering no predictions. e.g. num_correct / num_guesses \n' ...
	'	net_accuracy stores the percentage of correct answers. With this scoring method, skipping an answer is equivalent to getting it wrong. e.g. num_correct / num_questions \n' ...
	'	better_accuracy stores the mean-per-class accuracy (the mean of the trace of the normalized confusion matrix).\n' ...
	]);
	save_vars{end+1} = 'better_accuracy';
	save_vars{end+1} = 'net_accuracy';
	save_vars{end+1} = 'correctness';
end;

% Generate confusion matrixes and related summaries
for exp_class_index = classes
	exp_class_instances = find( class_vector == classes( exp_class_index ) );
	for control_class_index = 1:size( marginal_probs, 2 )
		confusion_matrix( exp_class_index, control_class_index ) = length( find( class_predictions( exp_class_instances ) == control_class_index ) );
	end;
	norm_confusion_matrix( exp_class_index, : )  = confusion_matrix( exp_class_index, : ) ./ sum( confusion_matrix( exp_class_index, : ) );
	avg_marg_probs( exp_class_index, : )         = mean( marginal_probs(exp_class_instances, :), 1 );
	avg_class_similarities( exp_class_index, : ) = mean( class_similarities(exp_class_instances, :), 1 );
	norm_avg_marg_probs( exp_class_index, : )    = avg_marg_probs( exp_class_index, : ) ./ sum( avg_marg_probs( exp_class_index, : ) );
end;

if( isfield( data, 'continuous_values' ) )
	known_values = data.continuous_values;
	save_vars{end+1} = 'known_values';
end;
if( isfield( classifier, 'class_numeric_values' ) )
	control_class_numeric_values = classifier.class_numeric_values;
	save_vars{end+1} = 'control_class_numeric_values';
	continuous_score = marginal_probs * classifier.class_numeric_values';
	continuous_score = continuous_score';
	save_vars{end+1} = 'continuous_score';

	if( ~exist( 'known_values', 'var' ) & ~predict_only)
		known_values = data.class_numeric_values( class_vector );
		save_vars{end+1} = 'known_values';
	end;
	if( exist( 'known_values', 'var' ) )
		[n_rows n_cols] = size( known_values );
		if( n_cols > n_rows )
			known_values = known_values';
		end;
		[n_rows n_cols] = size( continuous_score );
		if( n_cols > n_rows )
			continuous_score = continuous_score';
		end;
		correlation = corr( continuous_score, known_values );
		save_vars{end+1} = 'correlation';
	end;
end;

% copy all optional data fields from the original data file into the results file
% This makes many post-processing steps easier.
% Also, avoid copying certain variables such as the signature matrix
data_fields = fields( data );
exclude_vars = { 'signature_matrix', 'slide_correction_pattern' };
for field_index = 1:length( data_fields )
	field_name = data_fields{ field_index };
	if( length( find( strcmp( exclude_vars, field_name ) ) ) == 0 )
		eval( [ field_name ' = data.' field_name ';' ] );
		save_vars{end+1} = field_name;
	end;
end;

total_computational_time = toc;
save( save_path, save_vars{:} );
