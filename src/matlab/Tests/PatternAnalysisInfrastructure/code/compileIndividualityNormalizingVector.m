% By Tom Macura, scans up "Per Mouse" classification problems from 'classifier_data_root'
% to compose an individuality normalizing vector saved to output_sig_file
function [] = compileIndividualityNormalizingVector( output_sig_file, classifier_data_root, sig_sets)

% Scan for Split directories
classifier_dirs = dir( classifier_data_root );
classifier_dirs = filterOutHiddenFiles( classifier_dirs ); % removes '.' & '..'
num_classifiers=0;

for classifier_index = 1:length( classifier_dirs )
	classifier_path = fullfile( classifier_data_root, classifier_dirs{classifier_index});
	if (exist(classifier_path, 'dir'))
		num_classifiers = num_classifiers+1;
		
		split_path = sprintf('Split1/%s/WND_05/Classifier.mat',sig_sets{1});
		classifier_path = fullfile(classifier_path, split_path);
		fprintf( 'Analyzing Feature Scores from %s \n', classifier_path );

		classifier = load(classifier_path);
		
		feature_scores{num_classifiers} = classifier.feature_scores;
		feature_scores_sources{num_classifiers} = classifier_path;
		
		if (~exist('avg_feature_scores', 'var'))
			avg_feature_scores = classifier.feature_scores;
		else
			avg_feature_scores = avg_feature_scores + classifier.feature_scores;
		end
	end
end

avg_feature_scores = avg_feature_scores / num_classifiers;

fprintf( 'Wrote Feature Score Summary To `%s` \n', output_sig_file);
save (output_sig_file, 'avg_feature_scores', 'feature_scores', 'feature_scores_sources');
