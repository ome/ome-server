%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2003 Open Microscopy Environment
%       Massachusetts Institute of Technology,
%       National Institutes of Health,
%       University of Dundee
%
%
%
%    This library is free software; you can redistribute it and/or
%    modify it under the terms of the GNU Lesser General Public
%    License as published by the Free Software Foundation; either
%    version 2.1 of the License, or (at your option) any later version.
%
%    This library is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%    Lesser General Public License for more details.
%
%    You should have received a copy of the GNU Lesser General Public
%    License along with this library; if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% written by: Josiah Johnston <siah@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% SYNOPSIS
%	[accuracy, mean_per_class_accuracy, confusion_matrix, norm_confusion_matrix, ...
%		class_predictions, marginal_probabilities, class_similarities] = ...
%	WND_Test(test_samples, norm_train_matrix, features_used, feature_scores, feature_min, feature_max)
%
% INPUTS
%	test_samples - a set of samples to classify. Rows correspond to features,
%		and are synchronized with features calculated on training images. The 
%		last row indicates the known class. Columns correspond to samples. 
%	norm_train_matrix - A set of samples for which the class is known. Rows 
%		correspond to features, and the last row stores the known class. Columns
%		correspond to samples. The range of each feature in this matrix is 
%		assumed to have been normalized to the range of 0-100 through linear scaling.
%	features_used - a list of feature indexes to use in distance calculations
%	feature_scores - a weight for each feature used in weighted distance calculations
%	feature_min, feature_max - the min and max observed value of each feature from
%		the non-noramlized training samples. Used to normalize the unknown samples.
%
%
% OUTPUTS
%	accuracy - ratio of number of test samples correctly classified to number of test samples
%	mean_per_class_accuracy - average-per-class accuracy, or the mean of the 
%		trace of the normalized confusion matrix. More appropriate than accuracy
%		if classes are not equally represented in the test set.
%	confusion_matrix - number of samples classified correctly & incorrectly. 
%		Rows indicate known classes. Columns indicate predicted classes. Cell
%		values indicate how many samples from a known class were classified
%		as a given class.
%	norm_confusion_matrix - Similar to the confusion matrix, except cell values
%		indicate percentage of samples classified like so, not number of samples.
%	class_predictions - The class prediction for each test sample.
%	marginal_probabilities - The probability of each sample belonging to each
%		class. It is more informative than class_predictions because it indicates
%		confidence of predictions. Rows correspond to samples, columns to classes.
%	class_similarities - How similar each sample is to each class. High values
%		indicate high degrees of similarities. Values have no units, so a 
%		comparison must be made to control data to draw meaningful conclusions.
%
% DESCRIPTION
%	Evaluate the predictive power of a classifer using samples for which ground 
% truth is known.

function [accuracy, mean_per_class_accuracy, confusion_matrix, norm_confusion_matrix, ...
	class_predictions, marginal_probabilities, class_similarities] = ...
	WND_Test(test_samples, norm_train_matrix, features_used, feature_scores, feature_min, feature_max)

% Generate predictions on the 'Test' set
[marginal_probabilities, class_predictions, class_similarities] = ...
	WND_Predict( test_samples, norm_train_matrix, features_used, ...
		feature_scores, feature_min, feature_max);

% Generate a confusion matrix
num_images       = size( test_samples, 2 );
num_classes      = length( unique( norm_train_matrix(end,:) ) );
confusion_matrix = zeros(num_classes, num_classes);
for i=1:num_images 
	actual_class = test_samples( end, i );
	most_probable_class = class_predictions(i);
	confusion_matrix( actual_class, most_probable_class ) = ...
		confusion_matrix( actual_class, most_probable_class) + 1;
end;
% Generate a normalized confusion matrix
for c = 1:num_classes
	norm_confusion_matrix(c,:) = confusion_matrix(c, :) / sum( confusion_matrix( c, : ) );
end;

% Calculate statistics
accuracy = sum( diag( confusion_matrix ) ) / num_images; 
mean_per_class_accuracy = mean( diag( norm_confusion_matrix ) );
num_unclassified = num_images - sum( confusion_matrix(:) );	
