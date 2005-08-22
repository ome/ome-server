% Tom Macura 4-15-05 Glue code
% Temporary. Hopefully
% SYNOPSIS
%	
%
% INPUT GIVEN
%   'bnet'          - Bayesian Belief Network object
%   'contData'      - undiscretized signature MATRIX with entries in `sigs_used` order
%   'sigs_used'     - integers representing which signatures
%                     were found to be the best (collectively)
%                     in classifying the training set.
%   'discWalls'     - cell array with bin wall locations for discretization
%
% OUTPUT GIVEN
%   'conf_mat'      - Confusion Matrix summarizing results classifier
%                     achieved on testing images. Rows indicate actual classes,
%                     columns indicate predicted classes. A number in row j, 
%                     column i indicates how many images of class j were 
%                     predicted to be class i.
%   'marginal_probs' - a matrix with a row per image, and a column per predicted 
%                      outcome. It gives the probability distribution per image.
%   'aggregate_probs' - a matrix summarizing the marginal_probs. Each row 
%                       corresponds to a class, and contains the normalized,
%                       non-thresholded mariginal probabilities for images 
%                       in that class. If a class contains some unclassified 
%                       images, that row will not sum to 1.

function [conf_mat, marginal_probs, aggregate_probs] = ML_BayesNet_Tester (bnet, contData, sigs_used, discWalls);

% read the total number of classes this classifier can classify as from the bnet
% structure
class_number = bnet.node_sizes(end);

[hei len] = size(contData);
absolutes   = zeros(class_number, class_number);
percentages = zeros(class_number, class_number);
for u = 1:len % for each instance
	actual_class = contData(end,u);
	marginal_probs(u,:) = ML_BayesNet_Classifier(bnet, contData([sigs_used],u), sigs_used, discWalls);
	
	% find which classes are predicted
	predicted_class = find (marginal_probs(u,:) == max(marginal_probs(u,:)));
	predicted_class = predicted_class(randperm(length(predicted_class))); % randomize the predicted class
	predicted_class = predicted_class(1);                % select the first class
	
	if (sum(marginal_probs(u,:)) == 0)
		fprintf (1, 'All O marginal_probs happened. SHIT\n');
	else 
		absolutes(actual_class, predicted_class) =  ...
				absolutes(actual_class, predicted_class) + 1;
		percentages(actual_class,:) = ... 
				percentages(actual_class,:) + marginal_probs(u,:);
	end
end

conf_mat = absolutes;

% Calculate aggregate probability distribution
aggregate_probs = percentages;
for class_index = 1:class_number     % N classes are identified by id's 1-N
	num_images_in_class = length( find( contData(end,:) == class_index ) );
	aggregate_probs( class_index, : )  = aggregate_probs( class_index, : ) / num_images_in_class;
end;