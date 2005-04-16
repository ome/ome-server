% Tom Macura 4-15-05 Glue code
% Temporary. Hopefully
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
%                     achieved on testing images

function [conf_mat] = ML_BayesNet_Tester (bnet, contData, sigs_used, discWalls);

% read the total number of classes this classifier can classify as from the bnet
% structure
class_number = bnet.node_sizes(end);

[hei len] = size(contData);
absolutes   = zeros(class_number, class_number);
percentages = zeros(class_number, class_number);
for u = 1:len % for each instance
	actual_class = contData(end,u);
	marginal_probs = ML_BayesNet_Classifier(bnet, contData([sigs_used],u), sigs_used, discWalls);
	
	% find which classes are predicted
	predicted_class = find (marginal_probs == max(marginal_probs));
	predicted_class = predicted_class(randperm(length(predicted_class))); % randomize the predicted class
	predicted_class = predicted_class(1);                % select the first class
	
	if (sum(marginal_probs) == 0)
		fprintf (1, 'All O marginal_probs happened. SHIT\n');
	else 
		absolutes(actual_class, predicted_class) =  ...
				absolutes(actual_class, predicted_class) + 1;
		percentages(actual_class,:) = ... 
				percentages(actual_class,:) + marginal_probs;
	end
end

conf_mat = absolutes;