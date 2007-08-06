% SYNOPSIS
%	reportSampleBasedDendrograms(results, report_root, ...
%	sampleDendrograms_rel_paths, sampleDistanceFunctionNames, sampleDistanceFunctions...
%	max_samples_to_use_in_histogram, num_splits);
%
% INPUTS
% 	max_samples_to_use_in_histogram: optional variable that defaults to 50
% 	num_splits: optional variable that defaults to all splits. 
%
%
% DESCTIPTION:
%    draws dendrograms using sample-to-sample distance functions
%
% Written by Josiah Johnston
% 	reorganized by Tom Macura

function [] = reportSampleBasedDendrograms( results, report_root, ...
	sampleDendrograms_rel_paths, sampleDistanceFunctionNames, sampleDistanceFunctions, ...
	max_samples_to_use_in_histogram, num_splits);
	
if( ~exist( 'max_samples_to_use_in_histogram', 'var' ) )
	max_samples_to_use_in_histogram = 50;
end;

if( ~exist( 'num_splits', 'var' ) )
	num_splits = length( results( problem_index ).Splits );
end;

for problem_index = 1:length( results )
	for sig_set_index = 1:length( results( 1 ).Splits( 1 ).SigSet )
		for ai_index = 1:length( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI )

			sampleDendrograms_path = fullfile( report_root, sampleDendrograms_rel_paths{ problem_index, sig_set_index, ai_index } );
			sampleDendrograms_paths { problem_index, sig_set_index, ai_index } = sampleDendrograms_path;
			
			[REPORT_HTML] = fopen( sampleDendrograms_path,'w');
			if (REPORT_HTML == -1)
				error(sprintf ('Failed to open %s for writing', report_path));
			end;
			
			fprintf( REPORT_HTML, '<html><head><script type="text/javascript">function toggleVisibility( element_id ) { el = document.getElementById(element_id); if (el.style.display=="none"){ el.style.display="inline"; } else { el.style.display="none"; } } </script></head><body>\n' );
			fprintf( REPORT_HTML, '<h1>%s, SigSet %s, AI %s.</h1>last updated %s<br>\n', ...
				results( problem_index ).name, results( 1 ).Splits( 1 ).SigSet(sig_set_index).name, ...
				results( 1 ).Splits( 1 ).SigSet(1).AI( ai_index ).name, datestr( now ) );

			fprintf( REPORT_HTML, '<table border="1"><tr>\n\t<td></td>\n');
			for d = 1:length( sampleDistanceFunctionNames )
				fprintf( REPORT_HTML, '\t<td>%s</td>\n', sampleDistanceFunctionNames{d});
			end;
			fprintf( REPORT_HTML, '</tr>\n');

			for split_index = 1:num_splits
				fprintf( REPORT_HTML, '<tr>\n\t<td>Split %.0f</td>\n',split_index);

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Prepare Random split (useSamples.mat)
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				rel_dendrogram_path = sprintf( '%s.Split%.0f', sampleDendrograms_rel_paths{ problem_index, sig_set_index, ai_index }, split_index );
				dendrogram_path     = fullfile( report_root, rel_dendrogram_path);
				
				if( ~exist( dendrogram_path, 'dir' ) )
					mkdir( report_root, rel_dendrogram_path );
				end;

				% Select test samples to use for this dendrogram
				use_samples_path = fullfile( dendrogram_path, 'useSamples.mat' );
				% Try to load them from file
				if( exist( use_samples_path, 'file' ) )
					use_samples = load( use_samples_path );
				else
					% If the file doesn't exist, make it
					control_test_samples = [];
					class_vector   = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.class_vector;
					classes        = unique( class_vector );
					min_class_size = length( class_vector ); % Initialize, then look for min class size
					total_classes  = length( classes );
					for c = classes
						ci = find( class_vector == c );
						min_class_size = min( [ min_class_size length( ci ) ] );
					end;

					% If experimental datasets are present, look up their class sizes;
					if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
						for exp_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
							exp_class_vector   = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).experimental_datasets(exp_index).results.class_vector;
							exp_classes        = unique( exp_class_vector );
							total_classes      = total_classes + length( exp_classes );
							for c = exp_classes
								ci = find( exp_class_vector == c);
								min_class_size = min( [ min_class_size length( ci ) ] );
							end;
						end;
					end;
					samples_per_class = min_class_size;
					if( samples_per_class * total_classes > max_samples_to_use_in_histogram )
						samples_per_class = floor( max_samples_to_use_in_histogram / total_classes );
					end;

					for c = classes
						ci = find( class_vector == c );
						rand_order = randperm( length( ci ) );
						control_test_samples = [ control_test_samples ci( rand_order( 1:samples_per_class ) ) ];
					end;

					% If experimental datasets are present, choose samples from them
					if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
						exp_samples = {};
						for exp_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
							exp_class_vector   = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).experimental_datasets(exp_index).results.class_vector;
							exp_classes        = unique( exp_class_vector );
							total_classes      = total_classes + length( exp_classes );
							exp_samples{exp_index} = [];
							for c = exp_classes
								ci = find( exp_class_vector == c);
								rand_order = randperm( length( ci ) );
								exp_samples{exp_index} = [ exp_samples{exp_index} ci( rand_order( 1:samples_per_class ) ) ];
							end;
						end;
						save( use_samples_path, 'control_test_samples', 'exp_samples' );
					else
						save( use_samples_path, 'control_test_samples' );
					end;
					use_samples = load( use_samples_path );
				end; % End determine which samples to draw the dendrogram with

				% Derive true distance between samples if possible
				if( isfield( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results, 'known_values' ) )
					known_values          = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.known_values(use_samples.control_test_samples);
					true_sample_distances = pdist( known_values );
				end;

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% Generate Sample Labels
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				sample_labels = {}; % image_names, extracted from iamge_path
				sample_categories = {}; % category names;
				labels         = {};
				
				for i=use_samples.control_test_samples
					sample_label = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).results.image_paths{i};
					sample_label = regexprep(sample_label, '/.*/', ''); % shorten the image_path to just image_name
					sample_label = regexprep(sample_label, '\[.*\]',''); % remove the ROI references

					sample_labels{end+1} = sample_label;
					sample_cat_num = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).results.class_vector(i);
					sample_categories{end+1} = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).results.category_names{sample_cat_num};
				end;
				
				if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
					% put all experimental results in a convenient data structure
					for exp_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
						for i = use_samples.exp_samples{ exp_index }
						
							sample_label = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets.results.image_paths{i};
							sample_label = regexprep(sample_label, '/.*/', ''); % shorten the image_path to just image_name
							sample_label = regexprep(sample_label, '\[.*\]',''); % remove the ROI references
						
							sample_labels{end+1} = sample_label;
							sample_cat_num = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets.results.class_vector(i);
							sample_categories{end+1} = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets.results.category_names{sample_cat_num};
						end;
					end;
				end;
				
				% Generate dendrograms for each sample-based distance function
				for d = 1:length( sampleDistanceFunctions )
					distanceFunction = sampleDistanceFunctions{ d };
					
					if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
						% put all experimental results in a convenient data structure
						for exp_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
							exp_results{ exp_index } = results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).experimental_datasets(exp_index).results;
						end;
						distanceMatrix = distanceFunction( ...
							results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results, ...
							use_samples.control_test_samples, ...
							exp_results, use_samples.exp_samples );
						clear exp_results;
					else
						distanceMatrix = distanceFunction( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results, use_samples.control_test_samples );
					end;
					
					rel_dendrogram_path = sprintf( '%s.Split%.0f.DistFunc%.0f', sampleDendrograms_rel_paths{ problem_index, sig_set_index, ai_index }, split_index, d );
					dendrogram_path     = fullfile( report_root, rel_dendrogram_path);
					if( ~exist( dendrogram_path, 'dir' ) )
						mkdir( report_root, rel_dendrogram_path );
					end;
					% Make link show the dendrogram from a given split
					if( isfield( results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results, 'control_class_numeric_values' ) )
						[svgPath pngPath] = drawDendrogram( distanceMatrix, dendrogram_path, fullfile( pwd, 'code/dendrograms' ), sample_labels, sample_categories, ...
							results( problem_index ).Splits( split_index ).SigSet(sig_set_index).AI( ai_index ).results.control_class_numeric_values);
						
						% Calculate correlation between the distance measure and difference in class
						if( isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
							num_control_samples = length( use_samples.control_test_samples );
							distanceMatrix = distanceMatrix( [1:num_control_samples], [1:num_control_samples] );
						end;
						[rho pValue] = corr( true_sample_distances', squareform(distanceMatrix)', 'type', 'Pearson' );
						sampleDistanceFunctionCorrelationsByProblemAndFunction( problem_index, d ) = rho;
						fprintf( REPORT_HTML, '\t<td><a href="../%s"><img src="../%s"/></a><br/>Correlation of distance measure and known class distances for control images from the test set: %.2f</td>\n', svgPath, pngPath, rho );
					else
						[svgPath pngPath] = drawDendrogram( distanceMatrix, dendrogram_path, fullfile( pwd, 'code/dendrograms' ), sample_labels, sample_categories, []);
						fprintf( REPORT_HTML, '\t<td><a href="../%s"><img src="../%s"/></a></td>\n', svgPath, pngPath );
					end;		
				end;
				fprintf( REPORT_HTML, '</tr>\n');
			end;
			fprintf( REPORT_HTML, '</html>\n' );
		end;
	end;
end;