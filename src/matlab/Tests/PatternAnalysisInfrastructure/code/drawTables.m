function [] = drawTables( results, report_root )

if( strcmp( class( results ), 'char' ) )
	[results] = loadResults( results );
end;

num_ais = length( results( 1 ).Splits( 1 ).SigSet(1).AI );

table1_path = fullfile( report_root, 'table1.tsv' );
table2_path = fullfile( report_root, 'table2.tsv' );

% Table 1
targetAI_index = 1;
targetSigIndex = 1;
[TABLE1] = fopen( table1_path,'w');
fprintf( TABLE1, 'Dataset Name\tNum Classes\tNum Imgs Per Training Class\tRange & Mean of num images per Test class\tCorrelation Coefficients (Mean +- std)\n' );
for problem_index = 1:length( results )
	% Gather data
	num_splits = length( results( problem_index ).Splits );
	individual_correlations = [];
	for split_index = 1:num_splits
		% Attempt to load numeric values from the test file
		dat = load( results(problem_index).Splits(split_index).SigSet(targetSigIndex).test_path, 'continuous_values', 'class_numeric_values' );
		predicted_values = [];
		if( isfield( dat, 'continuous_values' ) )
			known_values         = dat.continuous_values;
			class_numeric_values = dat.class_numeric_values;
		else
			continue;
		end;
		predicted_values = ...
			results( problem_index ).Splits( split_index ).SigSet(targetSigIndex).AI( targetAI_index ).results.marginal_probs * ...
			class_numeric_values';
		individual_correlations(end+1) = corr( known_values', predicted_values );
	end;
	
	% Print data
	min_test_class_size  = min( results.Splits(1).divisions.test_class_counts );
	max_test_class_size  = max( results.Splits(1).divisions.test_class_counts );
	fprintf( TABLE1, '%s\t%.0f\t%.0f\t%.0f:%.0f, %.1f\t%.2f +- %.2f\n', ...
		results( problem_index ).name, ...
		length( results.Splits(1).divisions.train_class_counts ), ...
		results.Splits(1).divisions.train_class_counts(1),  ...
		min_test_class_size, max_test_class_size, ...
		mean( results.Splits(1).divisions.test_class_counts ), ...
		mean( individual_correlations ), ...
		std( individual_correlations )  ...
	);
end;
fclose(TABLE1);
