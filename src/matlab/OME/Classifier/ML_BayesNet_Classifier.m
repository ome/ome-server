% Tom Macura 3-15-05 Glue code
% Temporary. Hopefully
%
% INPUT GIVEN
%   'bnet'          - Bayesian Belief Network object
%   'contData'      - undiscretized vector with entries in `sigs_used` order
%   'sigs_used'     - integers representing which signatures
%                     were found to be the best (collectively)
%                     in classifying the training set.
%   'discWalls'     - cell array with bin wall locations for discretization
%
% OUTPUT GIVEN
%   'marginal_probs' - vector of doubles storing with what predicted 
%                      probabilities the instance belongs to those classes

function [marginal_probs] = ML_BayesNetClassifier (bnet, contData, sigs_used, discWalls);
% sanity checks
if (length(contData) ~= length(sigs_used)) 
	error ("contData and sigs_used must be the same size\n");
end

% use learned wall placements in discretization                 %
discData = ones(size(contData)); 
for i = 1:length(sigs_used)
	for j = 1:length(discWalls{sigs_used(i)})
		discData(i) = discData(i) + (contData(i) > discWalls{sigs_used(i)}(j));
	end
end

% use discretized vector in classification
marginal_probs = BayesNetClassifier (bnet, discData);