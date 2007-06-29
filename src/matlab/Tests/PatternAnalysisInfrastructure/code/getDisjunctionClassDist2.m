function [pairwiseDist] = getDisjunctionClassDist( results, problem_index, sig_set_index, ai_index, trainOrTest )
% SYNOPSIS
%	[pairwiseDist] = getDisjunctionClassDist( results, problem_index, sig_set_index, ai_index, trainOrTest )

% Only draw samples from the target pair of classes

if( ~exist( 'trainOrTest', 'var' ) )
	trainOrTest = 1;
end;

num_splits  = length( results( problem_index ).Splits );
num_classes = size( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs, 2 );

% for each split, estimate disjuction
disjuction_by_split = [];
num_imgs_per_class  = [];
for split_index = 1:num_splits
	if( trainOrTest )
		classSimilarities = ...
			results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.class_similarities;
		class_vector = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.class_vector;
	else
		classSimilarities = ...
			results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.class_similarities;
		class_vector = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.class_vector;
	end;
	
	% Find the disjuction of each pair of classes
	for a = 1:num_classes - 1
		for b = a+1:num_classes
			% Only use samples from these classes
			class_instances = find( ismember( class_vector, [a b] ) );
			% Estimate the class volumes
			class_volume = mean( sum( classSimilarities(class_instances, [a b] ), 1 ) );
			% Find the disjuction
			disjuction_by_split( split_index, a, b ) = ...
				1 - sum( min( classSimilarities(class_instances, [a b]), [], 2 ) ) / class_volume;
			disjuction_by_split( split_index, b, a ) = disjuction_by_split( split_index, a, b );
		end;	
	end;	
end;

% Average disjuction estimates across splits
for c = 1:num_classes
	pairwiseDist(c,:) = mean( disjuction_by_split( :, c, : ) );
end;