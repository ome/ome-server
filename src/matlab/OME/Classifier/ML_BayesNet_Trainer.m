% Tom Macura 2-13-05 Glue code
% Temporary. Hopefully
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
%   'sigs_excluded' - sigs that could not be discretized and 
%                     therefore were excluded.
%   'discWalls'     - cell array with bin wall locations
%   'bnet'          - Bayesian Belief Network object
%   'conf_mat'      - Confusion Matrix summarizing results classifier
%                     achieved during training

function [sigs_used, sigs_used_ind, sigs_used_col, sigs_excluded, discWalls, bnet, conf_mat] = ...
	ML_BayesNet_Trainer(contData)
	
contData    = double(contData);
[rows cols] = size(contData);        
discData    = ones(size(contData)); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% individually learn wall placements                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:rows
	discWalls{i} = FindDiscretizationWallsFayyadIrani(contData(i,:),contData(end,:));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use learned wall placements in discretization                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:rows
    for j = 1:length(discWalls{i})
        discData(i,:) = discData(i,:) + (contData(i,:) > discWalls{i}(j));
    end
end
discData(end,:) = contData(end,:); % restoring the class signatures
discData = uint8(discData);

% Uncomment the line below to visualize the feature's discriminating power
% plot_discData(discData([555 end],:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% find optimal subset of signatures                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[sigs_used, sigs_used_ind, sigs_used_col, sigs_excluded, conf_mat] = FindSignatureSubset(discData, discWalls);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build the Bayes Net (BNET)                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
discData = discData(sigs_used,:);
size(discWalls)
sigs_used

[rows cols] = size(discData);
for i=1:length(sigs_used)
	node_sizes(i) = length(discWalls(sigs_used(i))) + 1;
end
node_sizes(end+1) = length(unique(contData(end,:))); % how many different classes
                                                     %there are
       
% filling the adjacency matrix to make the DAG for a naive bayesian network
dag = false(rows, rows);
dag([1:end-1],end) = true;
                                                   
bnet = mk_bnet(double(dag), double(node_sizes)); % generate bayes net, some datatype issues

for i = 1:rows
    bnet.CPD{i} = tabular_CPD(bnet,i);          % make each node 'tabular' so that it knows 
end                                             % its dealing with discrete data

bnet = learn_params(bnet,double(discData));     % learn the parameters
