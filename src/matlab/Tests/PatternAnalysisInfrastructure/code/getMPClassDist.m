function [pairwiseDist] = getMPClassDist( results, problem_index, sig_set_index, ai_index, trainOrTest )

if( exist( 'trainOrTest', 'var' ) )
	[confusion_matrixes avg_marg_probs] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index, trainOrTest );
else
	[confusion_matrixes avg_marg_probs] = getConfusionMatrixes( results, problem_index, sig_set_index, ai_index );
end;
num_classes = size( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.marginal_probs, 2 );
for a = 1:num_classes
	pairwiseDist(a,:) = avg_marg_probs(a,:) ./ avg_marg_probs(a,a);
end;
for a = 1:num_classes
	for b = 1:num_classes
		pairwiseDist(a,b) = mean( [pairwiseDist(a,b) pairwiseDist(b,a) ]);
		pairwiseDist(b,a) = pairwiseDist(a,b);
	end;
end;
pairwiseDist = 1 - pairwiseDist;