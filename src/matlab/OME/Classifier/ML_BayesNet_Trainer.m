% Tom Macura 2-13-05 Glue code
% Temporary. Hopefully
%
% SYNOPSIS:
%	% Train a network using default parameters
%	[sigs_used, sigs_used_ind, sigs_used_col, sigs_excluded, discWalls, bnet, conf_mat] = ...
%		ML_BayesNet_Trainer(contData, sigLabels );
%	% Train a network using FD univariate analysis selecting 10% of sigs, followed by GHC
%	[sigs_used, sigs_used_ind, sigs_used_col, sigs_excluded, discWalls, bnet, conf_mat] = ...
%		ML_BayesNet_Trainer(contData, sigLabels, 'sigReductionMethod', 'FD-GHC', 'FDsubselect', 0.1 );
%
% INPUTS
%	Everything aver sigLabels is optional and is a comma separated list of 
%	name/value pairs. 
%	'sigReductionMethod' can have the values: 'FD-GHC', 'FD', or 'GHC'
%	'FD-GHC' has an optional parameter called 'FDsubselect' that specifies 
%	the percentage of signatures to retain with the initial FD selection.
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
	ML_BayesNet_Trainer(contData, sigLabels, varargin)

% Default parameters:
sigReductionMethod = 'FD-GHC';
FDsubselect        = 0.2;

% Look for inputs that will override the defaults.
for i=1:2:length( varargin )
	name  = varargin{ i };
	value = varargin{ i + 1 };
	if    ( strcmp( name, 'sigReductionMethod' ) )
		sigReductionMethod = value;
	elseif( strcmp( name, 'FDsubselect' ) )
		FDsubselect        = value;
	end;
end;


[rows cols] = size(contData);      

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% individually learn wall placements                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sigs_excluded = [];
discWalls = [];

for i = 1:rows-1              % don't involve the class row, (-1)
	discWalls{end+1} = FindDiscretizationWallsFayyadIrani (contData(i,:),contData(end,:));
	
	if length(discWalls{end}) == 0
    	sigs_excluded = [sigs_excluded i];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use learned wall placements in discretization                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
discData = ones(size(contData)); 
for i = 1:rows-1
    for j = 1:length(discWalls{i})
        discData(i,:) = discData(i,:) + (contData(i,:) > discWalls{i}(j));
    end
end
discData(end,:) = contData(end,:);

% Uncomment the line below to visualize the feature's discriminating power
% plot_discData(discData([555 end],:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% find optimal subset of signatures                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if( strcmp( sigReductionMethod, 'FD' ) )
	[sigs_used, sigs_used_ind] = FindSignatureSubsetFD (contData, sigs_excluded, sigLabels );
	num_sigs_used = length( sigs_used );
	% We sometimes get out of memory errors if we use more than 10 signatures 
	% for training the BayesNet.
	if( num_sigs_used > 10 )
		sigs_used     = sigs_used( 1:10 );
		sigs_used_ind = sigs_used_ind( 1:10 );
	end;
elseif( strcmp( sigReductionMethod, 'FD-GHC' ) )
	target_num_sigs = round( length( sigLabels ) * FDsubselect );
	[top_fd_sigs, fd_scores] = FindSignatureSubsetFD (contData, sigs_excluded, sigLabels, target_num_sigs );
	sigs_to_avoid = setdiff( [1:length( sigLabels )], top_fd_sigs );
	sigs_to_avoid = union( sigs_to_avoid, sigs_excluded );
	[sigs_used, sigs_used_ind, sigs_used_col, conf_mat] = FindSignatureSubset(contData, sigs_to_avoid, @ConfusionMatrixScore);
elseif( strcmp( sigReductionMethod, 'GHC' ) )
	[sigs_used, sigs_used_ind, sigs_used_col, conf_mat] = FindSignatureSubset(contData, sigs_excluded, @ConfusionMatrixScore);
end;
fprintf( '%.0d Signatures were selected.\n', length( sigs_used ) );
sigs_used_col = [];
conf_mat = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build the Bayes Net (BNET)                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
discData = discData([sigs_used end],:);
[rows cols] = size(discData);
for i=1:length(sigs_used)
	node_sizes(i) = length(discWalls{sigs_used(i)}) + 1;
end
node_sizes(end+1) = length(unique(contData(end,:))); % how many different classes
                                                     % there are
       
% filling the adjacency matrix to make the DAG for a naive bayesian network
dag = false(rows, rows);
dag([1:end-1],end) = true;
                                                   
bnet = mk_bnet(double(dag), double(node_sizes)); % generate bayes net, some datatype issues

for i = 1:rows
    bnet.CPD{i} = tabular_CPD(bnet,i);          % make each node 'tabular' so that it knows 
end                                             % its dealing with discrete data

bnet = learn_params(bnet,double(discData));     % learn the parameters
