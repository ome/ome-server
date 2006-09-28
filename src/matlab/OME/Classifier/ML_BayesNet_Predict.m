% SYNOPSIS
%	[marginal_probs, aggregate_probs] = ...
%		ML_BayesNet_Predict(bnet, contData, sigs_used, discWalls);
%
% INPUT GIVEN
%   'bnet'          - Bayesian Belief Network object
%   'contData'      - undiscretized signature MATRIX with entries in `sigs_used` order
%                     The last row of this matrix should represent any class grouping of 
%                     the input data. e.g. individual images that are tiles of a 
%                     larger original image should have the same class id.
%   'sigs_used'     - integers representing which signatures
%                     were found to be the best (collectively)
%                     in classifying the training set.
%   'discWalls'     - cell array with bin wall locations for discretization
%
% OUTPUT GIVEN
%   'marginal_probs' - a matrix with a row per image, and a column per predicted 
%                      outcome. It gives the probability distribution per image.
%   'aggregate_probs' - a matrix summarizing the marginal_probs. Each row 
%                       corresponds to a class, and contains the normalized,
%                       non-thresholded mariginal probabilities for images 
%                       in that class. If a class contains some unclassified 
%                       images, that row will not sum to 1.
%
% Written by: Josiah Johnston <siah@nih.gov>
%	(adapted from ML_BayesNet_Tester.m, written by Tom Macura)
function [marginal_probs, aggregate_probs, unclassified_counts] = ML_BayesNet_Predict (bnet, contData, sigs_used, discWalls);

% read the total number of classes this classifier can classify as from the bnet
% structure
num_training_classes = bnet.node_sizes(end);

% extract information about the experimental data.
[num_sigs num_images] = size(contData);
num_experimental_classes = length( unique( contData( end, : ) ) );
for class_index = 1:num_experimental_classes
	class_counts( class_index ) = length( find( contData(end, :) == class_index ) );
end;

% Actually generate predictions
percentages = zeros(num_experimental_classes, num_training_classes);
unclassified_counts = zeros(num_experimental_classes, 1);
for image_index = 1:num_images % for each instance
	actual_class = contData(end,image_index);
	marginal_probs(image_index,:) = ML_BayesNet_Classifier(bnet, contData([sigs_used],image_index), sigs_used, discWalls);
	
	% given a marginal probability distriburion, find which classes are predicted
	predicted_class = find (marginal_probs(image_index,:) == max(marginal_probs(image_index,:)));
	predicted_class = predicted_class(randperm(length(predicted_class))); % randomize the predicted class in case of a tie
	predicted_class = predicted_class(1);                % select the first class

	if (sum(marginal_probs(image_index,:)) == 0)
		%fprintf (1, 'All O marginal_probs happened for image id: %d.\n', image_index);
		unclassified_counts( actual_class ) = unclassified_counts( actual_class ) + 1;
	else 
		percentages(actual_class,:) = ... 
				percentages(actual_class,:) + marginal_probs(image_index,:);
	end
end

% some warning info about unclassified images.
if( sum( unclassified_counts ) > 0 )
	fprintf( '%d images were unclassified. The distribution across classes was:\n\t', ...
		sum( unclassified_counts ) );
	for class_index = 1:num_experimental_classes
		fprintf( '%d / %d,\t', unclassified_counts( class_index ), class_counts( class_index ) );
	end;
	fprintf( '\n' );
end;

% Calculate aggregate probability distribution
aggregate_probs = percentages;
for class_index = 1:num_experimental_classes     % N classes are identified by id's 1-N
	aggregate_probs( class_index, : )  = aggregate_probs( class_index, : ) / class_counts( class_index );
end;
