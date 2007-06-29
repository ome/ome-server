function [pairwiseDist] = getMPClassCentroidDist( results, problem_index, sig_set_index, ai_index, trainOrTest )

if( exist( 'trainOrTest', 'var' ) )
	[confusion_matrixes avg_marg_probs] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index, trainOrTest );
else
	[confusion_matrixes avg_marg_probs] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index );
end;
pairwiseDist = squareform( pdist( avg_marg_probs ) );