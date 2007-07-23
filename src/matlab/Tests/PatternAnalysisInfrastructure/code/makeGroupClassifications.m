function [results] = makeGroupClassifications( varargin )
% SYNOPSIS
% 	results = makeGroupClassifications (results, 16, 32)
% INPUTS
%	results is the 'results file' followed by a variable number
% of inputs where each input specifies the number of tiles to combine
% into a group classification.
% DESCRIPTION
%	add this function to run.m to report group classifications:
% e.g:
%	results = loadResults( results_path );
%	results = makeGroupClassifications(results, 16, 32);
%	report( results, report_root );
%
% Written by Tom Macura <tmacura@nih.gov>

results = varargin{1};
	for problem_number = 1:length( results )
		for split_index = 1:length( results( problem_number ).Splits )
			for sig_set_index = 1:length( results( problem_number ).Splits( split_index ).SigSet )
				num_ais = length( results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI );
				for ai_index = 1:num_ais
					for i=2:length(varargin) 
						tiles_per_group = varargin{i};
						new_ai = results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index);
						new_ai.name = sprintf( 'Group Classifications (per %d tiles)', tiles_per_group);
						new_ai.results = makeGroupClassification_Internal (new_ai.results, tiles_per_group);
						new_ai.train_predictions = makeGroupClassification_Internal (new_ai.train_predictions, tiles_per_group);
		
						% make new_results and new_train_predictions 
						results( problem_number ).Splits( split_index ).SigSet( sig_set_index ).AI(i) = new_ai;
					end
				end
			end
		end
	end
end

function [ai_results] = makeGroupClassification_Internal (ai_results, tiles_per_group)
	% Iterate through images
	num_classes = length(unique(ai_results.class_vector));
	confusion_matrix = zeros(num_classes, num_classes);
	num_images = length(ai_results.image_ids) / tiles_per_group;
	for i=1:num_images
		image_paths{i} = sprintf('Group: %d', image);
		
		tile_indicies = (i-1)*tiles_per_group+1:i*tiles_per_group;
		
		% Convert per tile to per Image statistics
		marginal_probs(i,:) = sum(ai_results.marginal_probs([tile_indicies],:)) ./ length(tile_indicies);
		class_similarities(i,:) = sum(ai_results.class_similarities([tile_indicies],:)) ./length (tile_indicies);					
		
		[ junk most_probable_class ] = max( marginal_probs(end,:) );
		actual_class = ai_results.class_vector(tile_indicies(1));
	
		class_predictions(i) = most_probable_class;
		class_vector(i) = actual_class;
		% update confusion matrix
		confusion_matrix( actual_class, most_probable_class ) = ...
			confusion_matrix( actual_class, most_probable_class) + 1;
	end
	
	% compute summary  statistics
	for c = 1:num_classes
		norm_confusion_matrix(c,:) = confusion_matrix(c, :) / sum( confusion_matrix( c, : ) );
	end
	
	% Calculate statistics
	correctness = sum( diag( confusion_matrix ) ) / num_images; 
	mean_per_class_accuracy = mean( diag( norm_confusion_matrix ) );
	num_unclassified = num_images - sum( confusion_matrix(:) );	
	
	ai_results.confusion_matrix = confusion_matrix;
	ai_results.marginal_probs = marginal_probs;
	ai_results.image_paths = image_paths;
	ai_results.correctness = correctness;
	ai_results.net_accuracy = correctness;
	ai_results.better_accuracy = correctness;
	ai_results.norm_confusion_matix = norm_confusion_matrix;
	ai_results.class_predictions = class_predictions;
	ai_results.class_similarities = class_similarities;
	ai_results.class_vector = class_vector;
end