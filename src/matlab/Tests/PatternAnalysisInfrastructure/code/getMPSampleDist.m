function [pairwiseDist] = getMPSampleDist( predictions, use_samples, experimental_results, experimental_use_samples )
% SYNOPSIS
%	predictions = load( 'path/to/results/file' );
%	[pairwiseDist] = getMPSampleDist( predictions, use_samples, experimental_results, experimental_use_samples )
% FORMULA USED
%	squareform( pdist( predictions.marginal_probs ) );

if( exist( 'use_samples', 'var' ) )
	positions = predictions.marginal_probs( use_samples, : );
else
	positions = predictions.marginal_probs;
end;
if( exist( 'experimental_results', 'var' ) )
	for exp_index = 1:length( experimental_results )
		positions = [ positions; experimental_results{exp_index}.marginal_probs( experimental_use_samples{exp_index}, : ) ];
	end;
end;
pairwiseDist = squareform( pdist( positions ) );
