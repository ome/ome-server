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
% written by: Lior Shamir <shamirl@mail.nih.gov>
%             Josiah Johnston <siah@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% SYNOPSIS
%	[features_used, feature_scores, norm_train_matrix, feature_min, feature_max] = ...
%		WND_Train(train_matrix, percentage_of_features_to_use)
%
% INPUTS
%	train_matrix - a matrix of training samples. Rows correspond to features, and
%		columns correspond to samples.
%	percentage_of_features_to_use - The hard-threshold parameter that specifies
%		what portion of the top-scoring features to use. Value needs to be between 0 & 1.
%		This parameter is optional, and defaults to 0.65.
%
% OUTPUTS
%	features_used - indexes of features that make it through the hard-threshold
%	feature_scores - the score, or weight, of Every feature, including ones that
%		are not used.
%	feature_min, feature_max - The minimum and maximum values observed for Every
%		feature in the training samples.
%	norm_train_matrix - The input training matrix, normalized to the range of 
%		0 to 100 with linear offset & scaling from feature_min and feature_max. 
%		The classification algorithm is a nearest-neighbor variant, so the 
%		training samples are the heart of the classifier.
%
% DESCRIPTION
%	Trains a "Weighted Neighbor Distances" (WND) classifier by calculating 
% normalizationg factors, normalizing the training set, calculating Fisher
% Discriminant weights for each feature, and choosing a subset of the features
% with the largest weights.
%

function [features_used, feature_scores, norm_train_matrix, feature_min, feature_max] = ...
	WND_Train(train_matrix, percentage_of_features_to_use)

if( ~exist( 'percentage_of_features_to_use', 'var' ) )
	percentage_of_features_to_use = 0.65;
end;

class_num     = size(unique(train_matrix(end,:)),2);
num_features  = size(train_matrix,1)-1;
class_row     = num_features + 1;

% for each signature - find the min and max value
feature_max = max(train_matrix.');
feature_min = min(train_matrix.');
% Pad feature_max as necessary to avoid division by zero during normalization.
feature_max = feature_max+0.00001*(feature_max==feature_min); 

% normalize the values, then add the class row
for index = 1:num_features 
	norm_train_matrix(index,:) = 100*( train_matrix(index,:) - feature_min(index) ) ./ ...
		( feature_max(index) - feature_min(index) );
end
norm_train_matrix(class_row,:) = train_matrix(class_row,:);


feature_scores             = fisherScores(norm_train_matrix);
feature_scores(class_row)  = 0;
% make sure there are no NaNs in the signatures weights
nan_scores                 = find( isnan(feature_scores) );
feature_scores(nan_scores) = 0; 
[temp sorted_signatures]   = sort(feature_scores, 2, 'descend' );

% Identify X% of top-scoring signatures
features_used = sorted_signatures( 1:round( num_features*percentage_of_features_to_use ) );

