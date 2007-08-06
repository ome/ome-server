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
%		WND_Train(train_matrix, percentage_of_features_to_use, artifact_correction_type, artifact_correction_data)
% DESCRIPTION
%	Trains and tests (using the training set)
% train_matrix - the train set data
% percentage_of_features_to_use - a value between 0 and 1: 0 - no signature, 1 - all signatures, 0.5 - half of the signatures ...
% slide_class_vector - Optional. If given, will be used to downplay systematic differences between sample of the same class collected from differet slides


function [features_used, feature_scores, norm_train_matrix, feature_min, feature_max] = ...
	WND_Train(train_matrix, percentage_of_features_to_use, artifact_correction_type, artifact_correction_data)


class_num     = size(unique(train_matrix(end,:)),2);
num_features  = size(train_matrix,1)-1;
class_row     = num_features + 1;
class_vector  = train_matrix( class_row, : );

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


raw_feature_scores = fisherScores(norm_train_matrix);
if( ~exist( 'artifact_correction_type', 'var' ) )
	artifact_correction_type = '';
end;
if( strcmp( artifact_correction_type, 'slide_class_vector' ) )
	slide_class_vector = artifact_correction_data;
	% Learn how to ignore systematic differences in data collection.
	slide_fds = [];
	for class_index = 1:class_num
		class_instances = find( class_vector == class_index);
		% Compute FD based on slides
		slide_fds( class_index, : ) = fisherScores( norm_train_matrix(1:num_features,class_instances), slide_class_vector(class_instances) );
	end;
	% Average the artifact FD's together
	artifactual_fds = mean( slide_fds );
	feature_scores(1:num_features) = raw_feature_scores(1:num_features) - artifactual_fds(1:num_features);
	if( length( find( feature_scores > 0 ) ) == 0 )
		warning( 'Artifact correction caused all features to have negative weights. Consequently, ARTIFACT CORRECTION IS NOT BEING APPLIED TO THIS PROBLEM.' );
		feature_scores(1:num_features) = raw_feature_scores(1:num_features);
	end;
elseif( strcmp( artifact_correction_type, 'artifact_correction_vector' ) )
	feature_scores(1:num_features) = raw_feature_scores(1:num_features) - artifact_correction_data(1:num_features);
	if( length( find( feature_scores > 0 ) ) == 0 )
		warning( 'Artifact correction caused all features to have negative weights. Consequently, ARTIFACT CORRECTION IS NOT BEING APPLIED TO THIS PROBLEM.' );
		feature_scores(1:num_features) = raw_feature_scores(1:num_features);
	end;
else
	feature_scores(1:num_features) = raw_feature_scores(1:num_features);
end;

feature_scores(class_row)  = 0;
% make sure there are no NaNs in the signatures weights
nan_scores                 = find( isnan(feature_scores) );
feature_scores(nan_scores) = 0; 
[temp sorted_signatures]   = sort(feature_scores, 2, 'descend' );

% Identify X% of top-scoring signatures
features_used = sorted_signatures( 1:round( num_features*percentage_of_features_to_use ) );
gt0 = find( feature_scores > 0 );
features_used = intersect( features_used, gt0 );
