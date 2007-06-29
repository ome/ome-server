function [confusion_matrixes avg_marg_probs avg_class_similarities unclassified std_confusion std_MPsimilarity ] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index, trainOrTest )
% SYNOPSIS
%	[confusion_matrixes avg_marg_probs avg_class_similarities unclassified std_confusion std_MPsimilarity ] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index, trainOrTest )
% INPUTS
%	trainOrTest is optional. it defaults to 1 for test. Set to 0 to summarize training results

if( ~exist( 'trainOrTest', 'var' ) )
	trainOrTest = 1;
end;

num_splits  = length( results( problem_index ).Splits );
num_classes = size( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs, 2 );

confusion_matrixes_by_split     = [];
avg_marg_probs_by_split         = [];
avg_class_similarities_by_split = [];
unclassified_by_split           = zeros( num_splits, num_classes );
num_imgs_per_class              = [];
for split_index = 1:num_splits
	if( trainOrTest )
		confusion_matrixes_by_split( split_index, :, : ) = ...
			results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.confusion_matrix;
		class_vector = load( results(problem_index).Splits(split_index).SigSet(sig_set_index).test_path, 'signature_matrix' );
	else
		confusion_matrixes_by_split( split_index, :, : ) = ...
			results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.confusion_matrix;
		class_vector = load( results(problem_index).Splits(split_index).SigSet(sig_set_index).train_path, 'signature_matrix' );
	end;
	class_vector = class_vector.signature_matrix(end,:);
	num_images   = length( class_vector );
	% Determine which images have predictions available
	predictions_available = [];
	for i = 1:num_images
		if( trainOrTest )
			if( sum( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs( i, : ) ) > 0 )
				predictions_available(end+1) = i;
			else
				unclassified_by_split( split_index, class_vector( i ) ) = ...
					unclassified_by_split( split_index, class_vector( i ) ) + 1;
			end;
		else
			if( sum( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.marginal_probs( i, : ) ) > 0 )
				predictions_available(end+1) = i;
			else
				unclassified_by_split( split_index, class_vector( i ) ) = ...
					unclassified_by_split( split_index, class_vector( i ) ) + 1;
			end;
		end;
	end;
	% Calculate class average marg probs
	for c = 1:num_classes
		ci = find( class_vector == c );
		ci = intersect( ci, predictions_available );
		if( length( ci ) == 0 )
			warning( sprintf( 'Could not find any instances of class %s (%.0f) for problem %s (%.0f), Split %.0f, AI %s (%.0f) that have predictions available.', ...
				results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.category_names{c}, ...
				c, results( problem_index ).name, problem_index, split_index, ...
				results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).name, ...
				ai_index ...
			) );
		end;
		if( trainOrTest )
			avg_marg_probs_by_split( split_index, c, : ) = ...
				mean( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs( ci, : ) );
			avg_class_similarities_by_split( split_index, c, : ) = ...
				mean( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.class_similarities( ci, : ) );
		else
			avg_marg_probs_by_split( split_index, c, : ) = ...
				mean( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.marginal_probs( ci, : ) );
			avg_class_similarities_by_split( split_index, c, : ) = ...
				mean( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).train_predictions.class_similarities( ci, : ) );
		end;
	end;
end;
% Average across splits
confusion_matrixes     = [];
avg_marg_probs         = [];
avg_class_similarities = [];
for c = 1:num_classes
	num_imgs_per_class(c)          = length( find( class_vector == c ) ); % Is same for every splt
	confusion_matrixes( c, : )     = mean( confusion_matrixes_by_split( :, c, : ) );
	std_confusion( c, : )          = std( confusion_matrixes_by_split( :, c, : ) );
	confusion_matrixes( c, : )     = confusion_matrixes( c, : ) ./ num_imgs_per_class(c);
	std_confusion( c, : )          = std_confusion( c, : ) ./ num_imgs_per_class(c);
	unclassified( c )              = mean( unclassified_by_split(:, c ) ) / num_imgs_per_class(c);
	avg_marg_probs( c, : )         = mean( avg_marg_probs_by_split( :, c, : ) );
	avg_class_similarities( c, : ) = mean( avg_class_similarities_by_split( :, c, : ) );
	std_MPsimilarity( c, : )       = std( avg_marg_probs_by_split( :, c, : ) );
end;

