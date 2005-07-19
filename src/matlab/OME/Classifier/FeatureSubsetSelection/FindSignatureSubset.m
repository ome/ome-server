%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2005 Open Microscopy Environment
%       Massachusetts Institue of Technology,
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

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Written By: Lawrence David <lad2002@columbia.edu> and
%             Tom Macura <tmacura@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function [sigs_used, sigs_used_ind, sigs_used_col, conf_mat] = ...
			FindSignatureSubset (contData, sigs_excluded, fmetric, testing_perc, iterations)

% INPUT NEEDED      
%   'contData'      - your continuous data
%   'sigs_excluded' - sigs that could not be discretized and 
%                     therefore were excluded.
%   'fmetric'       - function handle to metric that estimates classifier
%                     performance based on confusion matrix
%   'testing_perc'  - portion of training images to use as test-images
%                     (real number between 0 and 1) [optional]
%   'iterations'    - how many runs with random test images [optional]
%
% OUTPUT GIVEN
%   'sigs_used'     - integers representing which signatures
%                     were found to be the best (collectively)
%                     in classifying the training set.
%   'sigs_used_ind' - doubles recording the signatures'
%                     (corresponding to sigs_used vector) estimated
%                     individual predictive abilities.
%   'sigs_used_col' - doubles recording the signatures'
%                     (corresponding to sigs_used vector) estimated
%                     collective predictive abilities.
%   'conf_mat'      - Confusion Matrix summarizing results classifier
%                     achieved during training
% INTRODUCTION
%   Instead of trying to figure out how to classify the test set, N-fold-verification
%   looks to see how to classify a portion of the training set.  Assuming that 
%   there is a stable distribution of points in the test and training sets, 
%   whatever classifies the training set well should effectively classify the test
%   set.
%
%   To control for over-fitting, the training set is randomly split into another
%   training set and a smaller test set.  Since scores are always determined by 
%   classifying the smaller test set, one that was not involved in the training,
%   overfitting to individual images is not possible.
%
%   We start by discovering which feature can, individually, best classify the 
%   random test sets. Then we add another feature to the set to see which
%   features subset of length two best classifies the sets. We iteratively
%   continue to expand the feature set until all feature subsets of say
%   length N are worse classifiers than the best subset of length N - 1. 
% 
% Lawrence David - 2003.  lad2002@columbia.edu
% Tom Macura - 2005. tm289@cam.ac.uk               Modified for inclusion in OME

if (nargin < 4) 
	testing_perc = 0.35;
end

if (nargin < 5)
	iterations = 35;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find initial best signature to classify with                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[hei len] = size(contData);
sigs_left = setdiff([1: hei-1], sigs_excluded);

[ind_score] = n_fold_validate(contData, [], sigs_left, testing_perc, iterations, fmetric);
[big_score, score_place] = max(ind_score);                                              

sigs_used_ind           = big_score;
sigs_used_col           = big_score;
sigs_used               = sigs_left(score_place);
sigs_left               = [sigs_left(1:score_place-1) sigs_left(score_place+1:end)];
ind_score               = [ind_score(1:score_place-1) ind_score(score_place+1:end)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% greedy hill-climbing                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
conf_mat = cell(1,length(sigs_left));
done = 0;
while ~done

	% find signature with largest impact on cumulative score
    [score_avg score_std conf_mat] = n_fold_validate(contData, sigs_used, sigs_left, testing_perc, iterations, fmetric);
    [temp_score, temp_place] = max(score_avg);
    
    % add signature if it improves cumulative score
    if temp_score > big_score                                      
        big_score = temp_score;
        sigs_used = [sigs_used sigs_left(temp_place)];
        sigs_used_ind  = [sigs_used_ind ind_score(temp_place)];
        sigs_used_col  = [sigs_used_col temp_score];
        
		sigs_left = [sigs_left(1:temp_place-1) sigs_left(temp_place+1:end)];
		ind_score = [ind_score(1:temp_place-1) ind_score(temp_place+1:end)];
		
		% optimal performanced reached, additional signatures are superflous
        if ( abs(temp_score-1) < 0.01)                                      
            done = 1;
        end
	else
    	% additional signature did not improve score
        done = 1;
    end
end
conf_mat = conf_mat{temp_place};

function [scr_mean scr_std conf_mat] = n_fold_validate (contData, initial_sigs, additional_sigs, testing_perc, iterations, fmetric)
% INPUTS NEEDED:
%   N.B: 'contData' is already trimmed according to sigs_to_use.
%   'contData'      - data, in the form where rows are signatures and
%                     columns are instances (images). By convention,
%                     the bottom row contains the instance's class.
%
%   'initial_sigs'  - always use these sigs
%
%   'addtional_sigs'- try adding one of these sigs at a time. Look for the best
%                     additional sig
%
%   'testing_perc'  - portion of training images to use as test-images
%                     (real number between 0 and 1)
%
%   'iterations'    - how many times to perform n_fold_validation
%
% OUTPUTS GIVEN:
%   'scr_mean'      - mean score vector summarizing how various signature set fared at
%                     n_fold_verification
%   'scr_std'       - standard deviation score vector summarizing how various signature
%                     set fared at n_fold_verification
%   'conf_mat'      - cumulative (combines performance through all iterations)
%                     confusion matricies for all signatures 
% NOTES:
%   This group of code is a rough driver to quickly pull in discretized data,
%   learn a classifier, and then output how the classifer fared on multiple 
%   random testing/training subsets of the data.  Predictions are scored by 
%   how many instances were correctly classified using the 'all or nothing manner'
%   that assigns class to the class that had the highest probability.
%
% Lawrence David - 2003.  lad2002@columbia.edu
% Tom Macura - 2005. tm289@cam.ac.uk              Modified for inclusion in OME

class_number = length(unique(contData(end,:)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% being n_fold_verification                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
abso = 0; % variable to hold sums of 'all or nothing' decisions

len_add_sigs = length(additional_sigs);
conf_mat = cell(1,len_add_sigs);
scr_mean = zeros(1,len_add_sigs);
scr_std  = zeros(1,len_add_sigs);

for i=1:len_add_sigs
	abso = zeros(class_number, class_number+1);
	score_vec = zeros(1,iterations);
	
	for j = 1:iterations
		% remember about contData(end,:). That is the row of classes 
		[percentages absolutes]  = TrainAndTest(contData([initial_sigs additional_sigs(i) end],:), testing_perc); 

		abso = abso + absolutes;
		score_vec(j) = ConfusionMatrixScore(absolutes);
    end
    
	conf_mat{i} = abso;
	scr_mean(i) = mean(score_vec);
	scr_std(i)  = std(score_vec);
    
    abso
    score_vec
	fprintf(1, 'Signature: %03d -- Score [avg][var]: %f %f \n', additional_sigs(i), scr_mean(i), scr_std(i));
end
return

function [percentages, absolutes] = TrainAndTest(contData, testing_perc)
% INPUTS NEEDED:  
%   'contData'     - continious data, in the form where rows are signatures 
%                    and columns are instances (images). By convention, the  
%                    bottom row contains the instance's class.
%   'discWalls'    - cell array with bin wall locations
%   'testing_perc' - portion of training images to use as test-images
%                    (real number between 0 and 1)
% OUTPUTS GIVEN:
%   'percentages'  - the sum of the probability distributions for every
%                    image.  These sums are arranged in confusion matrices by 
%                    class. For instance, (1,1) is the sum of probabilities that
%                    images from class 1 were assigned class 1.  (4,2) is the 
%                    sum of probabilities that images from class 4 were assigned
%                    class 2.
%   'absolutes'    - like 'percentages' but done where probabilities are reduced
%                    to simply max instances.  E.g. if a probability 
%                    distribution for a node was [0.54 0.26 .20] absolutes would
%                    simply add that to its confusion matrix as [1 0 0].
%
% INTRODUCTION:
% We randomly select training and test sets. The test set's size is specified 
% as a function parameter. The provisional training set per class has all 
% the images in the class except the images in the test set. Constrained to 
% the size of the smallest training set, training sets are truncated so
% there is a constant number of images each type of class in the test set. 
%
% This is NOT GOOD when the sample's classes are not uniformly distributed. 
% However for classes that are equally distributed this ensures the classifier
% is balanced.
%
% The classifier is learned using a selective Naive-Bayesian approach.
% We use the K2 structure learning algorithm implemented by Kevin Murphy in 
% his Bayes Net Toolbox (http://www.cs.ubc.ca/~murphyk/Software/BNT/bnt.html)
% to try to greedily learn an optimal network for the class node.  
%
% Tom Macura - 2005. tm289@cam.ac.uk

rand('state',sum(100*clock));           % keeping the rand real

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert percentage into numbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classcounter = unique(contData(end,:));
class_number = length(classcounter);

ind_class_size = zeros(1,class_number);
matching_class = cell(1,class_number);

% find cardinality of smallest dataset
for u = 1:class_number                            
	[junk matching_class_vec] = find(contData(end,:)==classcounter(u));
	ind_class_size(u) = length(matching_class_vec);
    matching_class{u} = matching_class_vec(randperm(ind_class_size(u)));
end

% Figure out how many train_samples and test_samples you need
test_samples = ceil(testing_perc*min(ind_class_size));
train_samples = min(ind_class_size) - test_samples;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% divide the contData into training and testing datasets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contTrain_cols = [];  % column indicies
contTest_cols  = [];   % column indicies

for u = 1:class_number
	matching_class_vec = matching_class{u};
	contTrain_cols = [contTrain_cols matching_class_vec(1:train_samples)];
	contTest_cols  = [contTest_cols  matching_class_vec(train_samples+1:train_samples+test_samples)];
end

contTrainData = contData(:,contTrain_cols);
contTestData  = contData(:,contTest_cols);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% learn descretization walls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[hei len] = size(contTrainData);
discWalls = [];

for i = 1:hei-1              % don't involve the class row, (-1)
	discWalls{end+1} = FindDiscretizationWallsFayyadIrani (contTrainData(i,:),contTrainData(end,:),25);

	if length(discWalls{end}) == 0
		fprintf(1, 'Holly shit sigs_excluded\n');
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% descretization data based on walls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
discTrainData = ones(size(contTrainData)); 
discTestData  = ones(size(contTestData));
for i = 1:hei-1
    for j = 1:length(discWalls{i})
        discTrainData(i,:) = discTrainData(i,:) + (contTrainData(i,:) > discWalls{i}(j));
        discTestData(i,:)  = discTestData(i,:)  + (contTestData(i,:)  > discWalls{i}(j));
    end
end
discTrainData(end,:) = contTrainData(end,:);
discTestData(end,:)  = contTestData(end,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
node_sizes = zeros(1,length(discWalls) + 1);        % +1 since there is always one
													% more bin than walls.
for i = 1:length(discWalls)
    node_sizes(i) = (length(discWalls{i}) + 1);
end                                                 
node_sizes(end) = class_number;                    

% filling the adjacency matrix to make the DAG for a naive bayesian network
dag = zeros(hei, hei);
dag([1:end-1],end) = 1;

bnet = mk_bnet(dag, node_sizes); % generate bayes net, some datatype issues

for i = 1:hei                               
    bnet.CPD{i} = tabular_CPD(bnet,i);          % make each node 'tabular' so that it knows 
end                                             % its dealing with discrete data

bnet = learn_params(bnet, discTrainData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Testing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[hei len] = size(discTestData);
absolutes   = zeros(class_number, class_number+1);
percentages = zeros(class_number, class_number);

engin = jtree_inf_engine(bnet);
evidence = cell(1, hei);
for u = 1:len % for each instance
	actual_class = discTestData(end,u);
	
	% Quick Test. Very similar to BayesNetClassifier but reusing BNET engine
	% for efficency reasons (500% speedup)
	for t = 1:hei-1
		evidence{t} = discTestData(t,u);
	end
	[engin, loglik] = enter_evidence(engin,evidence);
	marginal_probs  = marginal_nodes(engin,hei);
	marginal_probs  = marginal_probs.T';
	
	% find which classes are predicted
	predicted_class = find (marginal_probs == max(marginal_probs));
	predicted_class = predicted_class(randperm(length(predicted_class))); % randomize the predicted class
	predicted_class = predicted_class(1);                % select the first class
	
	%predicted_class = predicted_class( floor( (length(predicted_class)+1)/2 ) );
	
	if (sum(marginal_probs) == 0)
		absolutes(actual_class, class_number+1) =  ...
				absolutes(actual_class, class_number+1) + 1;
	else 
		absolutes(actual_class, predicted_class) =  ...
				absolutes(actual_class, predicted_class) + 1;
		percentages(actual_class,:) = ... 
				percentages(actual_class,:) + marginal_probs;
	end
end