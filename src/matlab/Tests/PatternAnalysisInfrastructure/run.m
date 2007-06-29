% This is a script to kick off a scan through image and signature directories.
% It results in compiled Training and Test sets

% add paths
addpath('code');
data_root = 'data/classifiers';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update the problems on disk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters to setting up Training & Test sets.
sig_dirs   = { ...
	'data/OrigSigData/computedInOME_AE/' ...
...	% Add more signature directories here.
};
training_perc  = .8;
min_test_class_size = 20;
crossValidateRepeats = 10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create/update the directories of training and test divisions
updateSplitDirs( sig_dirs, data_root, training_perc, crossValidateRepeats, min_test_class_size);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initiate Training & Testing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set function parameters
classifier_dir   = 'code/Classifiers/';
sig_sets          = { ...
	'computedInOME_AE' ...
...	% Add more signature directories here.
};
results_path = fullfile( data_root, 'results.mat' );
% Train classifiers, generate predictions for both the test set and the 
% training set, and compile the results into a .mat file when done.
scanAndTrainAndTest(data_root, classifier_dir, sig_sets, results_path);
% This second form of calling performs a scan only
%scanAndTrainAndTest(data_root, classifier_dir, sig_sets, results_path, [], 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build a report
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
report_root  = 'reports';
results = loadResults( results_path );
report( results, report_root );
%exit;
