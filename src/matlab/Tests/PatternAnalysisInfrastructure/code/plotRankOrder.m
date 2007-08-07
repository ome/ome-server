function [normalized_x, order] = plotRankOrder( continuous_predictions, class_vector, fig_title, class_ages, baseline_class_ages )
% SYNOPSIS:
%	[normalized_x, order] = plotRankOrder( continuous_predictions, class_vector );
%	scatter( normalized_x, continuous_predictions(order), 5 );
% ALTERNATELY, have the function open the figure & plot
%	plotRankOrder( continuous_predictions, class_vector, fig_title );

classes      = unique( class_vector );
order        = [];
normalized_x = [];
if( ~exist( 'baseline_class_ages', 'var' ) )
	baseline_class_ages = class_ages;
end;

for i = 1:length(classes)
	class_instances = find( class_vector == classes(i) );
	class_size      = length( class_instances );
	[junk instance_order]  = sort( continuous_predictions( class_instances ) );
	insert = [ length(order) + 1 : length(order) + class_size ];
	order( insert )      = class_instances( instance_order );
	
	normalizing_x = find( baseline_class_ages == class_ages(i) );
	normalized_x(insert) = normalizing_x + [0 : 1/class_size : (1 - 1/class_size )];
end;

if( exist( 'fig_title', 'var' ) )
	figure;
	scatter( normalized_x, continuous_predictions(order), 5 );
	title( fig_title );
end;
