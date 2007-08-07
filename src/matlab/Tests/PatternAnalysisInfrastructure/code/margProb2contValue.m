function [continuous_predictions] = margProb2contValue( marginal_probs, class_numeric_values )
% SYNOPSIS
%	[continuous_predictions] = margProb2contValue( marginal_probs, class_numeric_values )
% Description
%	Convert marginal probabilities of classes with associated numeric values
% into a continuous prediction by using the marginal probabilities to calculate
% a weighted sum of the class numeric values.

num_images = size( marginal_probs, 1 );
for i = 1:num_images
	continuous_predictions(i) = sum( ...
		marginal_probs( i, : ) .* ...
		class_numeric_values ...
	);
end;

