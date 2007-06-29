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
%             Lior Shamir <shamirl@mail.nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% SYNOPSIS
%	[marginal_probabilities, class_predictions, class_similarities] = ...
%	WND_Predict( unknown_samples, norm_train_matrix, features_used, ...
%		feature_scores, feature_min, feature_max) ;
%
% INPUTS
%	unknown_samples - a set of samples to classify. Rows correspond to features,
%		and are synchronized with features calculated on training images. Columns
%		correspond to samples. 
%	norm_train_matrix - A set of samples for which the class is known. Rows 
%		correspond to features, and the last row stores the known class. Columns
%		correspond to samples. The range of each feature in this matrix is 
%		assumed to have been normalized to the range of 0-100 through linear scaling.
%	features_used - a list of feature indexes to use in distance calculations
%	feature_scores - a weight for each feature used in weighted distance calculations
%	feature_min, feature_max - the min and max observed value of each feature from
%		the non-noramlized training samples. Used to normalize the unknown samples.
%
% OUTPUTS
%	class_predictions - The class prediction for each sample.
%	marginal_probs - The probability of each sample belonging to each
%		class. It is more informative than class_predictions because it indicates
%		confidence of predictions. Rows correspond to samples, columns to classes.
%	class_similarities - How similar each sample is to each class. High values
%		indicate high degrees of similarities. Values have no units, so a 
%		comparison must be made to control data to draw meaningful conclusions.
%
% DESCRIPTION
%	Generate class predictions of unknown samples by computing similarities to 
% training samples of known classes. Similarity to a given training sample is 
% calculated from a weighted distance using an inverse exponential decay 
% reminiscent of equations for gravitational force. Total similarity to a known
% class is calculated by summing the similarities of all class instances. Class
% predictions are made by identifying the class with the highest similarity.

function [marginal_probs, class_predictions, class_similarities] = ...
	WND_Predict( unknown_samples, norm_train_matrix, features_used, ...
		feature_scores, feature_min, feature_max) 

exponent           = 5;
num_queries        = size(unknown_samples, 2);
num_train_records  = size(norm_train_matrix, 2);
tr_class_vector    = norm_train_matrix(end, :);
num_tr_classes     = length( unique( tr_class_vector ) );
class_similarities = [];
class_predictions  = [];
marginal_probs     = [];

% to prevent NaN values in the prediction data from buggering everything, 
% exclude those from the features examined.
collapsed_vals = sum( unknown_samples, 2 );
features_used  = setdiff( features_used, find( isnan( collapsed_vals ) ) );

for query_index = 1:num_queries

	% prepare a query by normalizing its vector
	query_vector = unknown_samples(features_used, query_index).';
	query_vector = 100 * ( ( query_vector - feature_min(features_used) ) ./ ...
		(feature_max(features_used) - feature_min(features_used)) );
	
	% Calculate the weighted distance to each training record
	use_records = [1:num_train_records];
	for train_record_index = 1:num_train_records
		dist(train_record_index) = sum( ...
			feature_scores(features_used) .^2 .* ...
			(query_vector - norm_train_matrix(features_used, train_record_index)').^2 ...
		);
		if( dist(train_record_index) < eps )
			use_records = setdiff( [1:num_train_records], train_record_index );
		end;
	end
	
	% Calculate the 'similarity' to each training record 
	% as an inverse exponential decay of the distances
	similarity = dist(use_records) .^ (-1 * exponent);
	
	% Calculate 'class similarity' by summing the similarities of each member of 
	% the class. This implicitly assumes each class has equal representation in 
	% the training set.
	for tr_class_index = 1:num_tr_classes
		class_instances = find( tr_class_vector(use_records) == tr_class_index );
		class_similarities( query_index, tr_class_index ) = ...
			 sum( similarity( class_instances ) );
	end;
	
	% Convert class similarities to marginal probabilities by making them sum
	% to one
	marginal_probs( query_index, : ) = ...
		class_similarities( query_index, : ) ./ sum( class_similarities( query_index, : ) );
	
	% Identify the most probable class
	[ junk most_probable_class ]     = max( marginal_probs( query_index, : ) );
	class_predictions(query_index)   = most_probable_class;

end
