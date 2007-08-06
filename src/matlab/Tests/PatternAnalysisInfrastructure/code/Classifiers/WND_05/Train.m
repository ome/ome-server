function Train( train_path, save_path, artifact_correction_vector_path)
% SYNOPSIS
%	Train( train_path, save_path, artifact_correction_vector_path)
% DESCRIPTION
%	Trains Weighted NN on the training data in train_path,
% and saves the resultant classifier and logging data to save_path.

tic;
% Load data
trainingSet = open( train_path );
feature_matrix = trainingSet.signature_matrix;
feature_labels = trainingSet.sig_labels;
percentage_of_features_to_use = 0.65;

save_vars = { 'sigs_used', 'sigs_used_ind', 'sig_labels', 'signature_scores', ...
	'features_used', 'feature_min', 'feature_max', 'feature_scores', ...
    'norm_train_matrix', 'feature_labels', 'README', 'total_computational_time' };


if( isfield( trainingSet, 'slide_class_vector' ) )
	[features_used, feature_scores, norm_train_matrix, feature_min, feature_max] ...
		= WND_Train(feature_matrix, percentage_of_features_to_use, 'slide_class_vector', trainingSet.slide_class_vector);
elseif( exist( 'artifact_correction_vector_path', 'var' ))
	artifact_correction_vector = load(artifact_correction_vector_path);
	fprintf( 'Using artifact_correction_vector from %s\n', artifact_correction_vector_path);
	[features_used, feature_scores, norm_train_matrix, feature_min, feature_max] ...
		= WND_Train(feature_matrix, percentage_of_features_to_use, 'artifact_correction_vector', artifact_correction_vector.avg_feature_scores);
elseif( isfield( trainingSet, 'artifact_correction_vector' ) )
	[features_used, feature_scores, norm_train_matrix, feature_min, feature_max] ...
		= WND_Train(feature_matrix, percentage_of_features_to_use, 'artifact_correction_vector', trainingSet.artifact_correction_vector);
else
	[features_used, feature_scores, norm_train_matrix, feature_min, feature_max] ...
		= WND_Train(feature_matrix, percentage_of_features_to_use);
end;


README = sprintf([ ...
'This is a Weighted Neighbor Distances classifier that used training data: ' train_path ...
'. Variables:\n' ...
'	features_used stores the indexes of the signatures used.\n'...
'	feature_min and feature_max are the minimum and maximum observed values of each feature, and are used for normalization.\n'...
'	feature_scores is a list of weights that describe the relative ability of each feature to discriminate between classes.\n'...
'	norm_train_matrix stores samples of known classes.\n'...
'	feature_labels stores labels for each feature.\n'...
]);

% order features_used by relative importance of the features
[junk order] = sort( feature_scores(features_used), 2, 'descend' );
features_used = features_used( order );

% Legacy aliases
sigs_used = features_used;
sigs_used_ind = feature_scores( features_used );
sig_labels = feature_labels;
signature_scores = feature_scores;

% copy all optional data fields from the original data file into the results file
% This makes many post-processing steps easier.
% Also, avoid copying certain variables such as the signature matrix
data_fields = fields( trainingSet );
exclude_vars = { 'signature_matrix', 'slide_correction_pattern', 'artifact_correction_vector', 'README', 'global_image_indexes' };
for field_index = 1:length( data_fields )
	field_name = data_fields{ field_index };
	if( length( find( strcmp( exclude_vars, field_name ) ) ) == 0 )
		eval( [ field_name ' = trainingSet.' field_name ';' ] );
		save_vars{end+1} = field_name;
	end;
end;

total_computational_time = toc;
save( save_path, save_vars{:});
