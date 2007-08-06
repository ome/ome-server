% SYNOPSIS
%	reportClassBasedDendrograms(results, report_root, ...
%	classDendrograms_rel_paths, classDistanceFunctionNames, classDistanceFunctions);
%
% DESCTIPTION:
%    draws dendrograms using class-to-class distance functions
%
% Written by Josiah Johnston
% 	reorganized by Tom Macura

function [] = reportClassBasedDendrograms( results, report_root, ...
	classDendrograms_rel_paths,  classDistanceFunctionNames, classDistanceFunctions);
	
for problem_index = 1:length( results )
	num_splits = length( results( problem_index ).Splits );
	for sig_set_index = 1:length( results( 1 ).Splits( 1 ).SigSet )
		for ai_index = 1:length( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI )

			classDendrograms_path = fullfile( report_root, classDendrograms_rel_paths{ problem_index, sig_set_index, ai_index } );
			classDendrograms_paths { problem_index, sig_set_index, ai_index } = classDendrograms_path;
			
			[REPORT_HTML] = fopen( classDendrograms_path,'w');
			if (REPORT_HTML == -1)
				error(sprintf ('Failed to open %s for writing', report_path));
			end;
			
			fprintf( REPORT_HTML, '<html><head><script type="text/javascript">function toggleVisibility( element_id ) { el = document.getElementById(element_id); if (el.style.display=="none"){ el.style.display="inline"; } else { el.style.display="none"; } } </script></head><body>\n' );
			fprintf( REPORT_HTML, '<h1>%s, SigSet %s, AI %s.</h1>last updated %s<br>\n', ...
				results( problem_index ).name, results( 1 ).Splits( 1 ).SigSet(sig_set_index).name, ...
				results( 1 ).Splits( 1 ).SigSet(1).AI( ai_index ).name, datestr( now ) );

			
			fprintf( REPORT_HTML, '<table border="1"><tr>\n\t<td></td>\n');
			for d = 1:length( classDistanceFunctions )
				fprintf( REPORT_HTML, '\t<td>%s</td>\n', classDistanceFunctionNames{d});
			end;
			fprintf( REPORT_HTML, '</tr>\n');
			if( isfield( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results, 'class_numeric_values' ) )
				class_numeric_values  = results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.class_numeric_values;
				true_class_distances  = pdist( class_numeric_values' );
			end;
			fprintf( REPORT_HTML, '<tr>\n\t<td>Mean of all Testing/Training Splits</td>\n');
			
			for d = 1:length( classDistanceFunctions )
				distanceFunction = classDistanceFunctions{ d };
				[classDistanceMatrix] = distanceFunction( results, problem_index, sig_set_index, ai_index );
				rel_dendrogram_path = sprintf( '%s.DistFunc%.0f', classDendrograms_rel_paths{ problem_index, sig_set_index, ai_index }, d );
				dendrogram_path     = fullfile( report_root, rel_dendrogram_path);

				if( ~exist( dendrogram_path, 'dir' ) )
					mkdir( report_root, rel_dendrogram_path );
				end;
				if( isfield( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results, 'class_numeric_values' ) )
					for c = 1:length( class_numeric_values )
						labels{c} = sprintf( '%.2f', class_numeric_values(c) );
					end;

					[svgPath pngPath] = drawDendrogram( classDistanceMatrix, dendrogram_path, fullfile( pwd, 'code/dendrograms' ), ...
						labels, labels, class_numeric_values);
					% Calculate correlation between the distance measure and difference in class
					[rho pValue] = corr( true_class_distances', squareform(classDistanceMatrix)', 'type', 'Pearson' );
					distanceFunctionCorrelationsByProblemAndFunction(d ) = rho;
					fprintf( REPORT_HTML, '\t<td><a href="../%s"><img src="../%s"/></a><br/>Correlation of distance measure and known class distances: %.2f</td>\n', svgPath, pngPath, rho );
				else
					cat_names = results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.category_names;
					[svgPath pngPath] = drawDendrogram( classDistanceMatrix, dendrogram_path, fullfile( pwd, 'code/dendrograms' ), ...
						cat_names,cat_names, []);
					fprintf( REPORT_HTML, '\t<td><a href="../%s"><img src="../%s"/></a></td>\n', svgPath, pngPath );
				end;
			end;
			fprintf( REPORT_HTML, '</tr></table>\n');

% TODO: think about adding class-based dendrograms for experimental classes.
%
%			if( isfield( results( problem_index ).Splits(1).SigSet( sig_set_index ).AI( ai_index ), 'experimental_datasets' ) )
%				fprintf( REPORT_HTML, '<div style="background-color: #FFC; margin: 10pt; padding: 5pt;">\n' );
%				fprintf( REPORT_HTML, '<h2> Experimental Datasets</h2>' );
%				fprintf( REPORT_HTML, '<table border="1"><tr>\n\t<td></td>\n');
%				for d = 1:length( classDistanceFunctions )
%					fprintf( REPORT_HTML, '\t<td>%s</td>\n', classDistanceFunctionNames{d});
%				end;
%				fprintf( REPORT_HTML, '</tr>\n');
%				% If experimental datasets are present, look up their class sizes
%				for exp_index = 1:length( results( problem_index ).Splits(1).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets )
%					fprintf( REPORT_HTML, '<tr><td>%s</td>', results( problem_index ).Splits(1).SigSet( sig_set_index ).AI( ai_index ).experimental_datasets(exp_index).name);
%					
%					% category_names ![]!
%					% avg_class_similarities
%					
%					for d = 1:length( classDistanceFunctions )
%						distanceFunction = classDistanceFunctions{ d };
%						[classDistanceMatrix] = distanceFunction( results, problem_index, sig_set_index, ai_index );
%						
%						rel_dendrogram_path = sprintf( '%s.Exp%.0f.DistFunc%.0f', classDendrograms_rel_paths{ problem_index, sig_set_index, ai_index }, exp_index, d );
%						dendrogram_path     = fullfile( report_root, rel_dendrogram_path);
%		
%						if( ~exist( dendrogram_path, 'dir' ) )
%							mkdir( report_root, rel_dendrogram_path );
%						end;
%						
%						cat_names = results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results.category_names;
%					
%						[svgPath pngPath] = drawDendrogram( classDistanceMatrix, dendrogram_path, fullfile( pwd, 'code/dendrograms' ), ...
%							cat_names,cat_names, []);
%						fprintf( REPORT_HTML, '\t<td><a href="../%s"><img src="../%s"/></a></td>\n', svgPath, pngPath );
%					
%					end;
%				end;
%				fprintf( REPORT_HTML, '</div>\n' );
%			end;


			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% Cross-compare each different distance function if there is more than one to evaluate
			if( length( classDistanceFunctions ) > 1 & isfield( results( problem_index ).Splits( 1 ).SigSet(sig_set_index).AI( ai_index ).results, 'class_numeric_values') )
				fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="5"><caption>Mean & std of correlations</caption><tr>\n' );
				fprintf( REPORT_HTML, '<td>%s</td>\n', classDistanceFunctionNames{:} );
				fprintf( REPORT_HTML, '</tr><tr>\n' );
				mean_distanceFunctionCorrelationsByProblemAndFunction = mean( distanceFunctionCorrelationsByProblemAndFunction, 1 )
				std_distanceFunctionCorrelationsByProblemAndFunction = std( distanceFunctionCorrelationsByProblemAndFunction, 0, 1 )
				for df_index = 1:length( classDistanceFunctionNames )
					fprintf( REPORT_HTML, '<td>%.2f +- %.2f</td>\n', mean_distanceFunctionCorrelationsByProblemAndFunction( df_index ), std_distanceFunctionCorrelationsByProblemAndFunction( df_index ) );
				end;
				fprintf( REPORT_HTML, '</tr></table>\n' );
				fprintf( REPORT_HTML, '<table border="1" cellspacing="0" cellpadding="5"><caption>Cell entries are the probability that the distance function in the column outperformed the distance function in the row. Results are based on a paired ttest. Significant entries are given in bold.</caption>\n' );
				fprintf( REPORT_HTML, '<tr>\n\t<td> </td>\n' );
				for df_index = 1:length( classDistanceFunctionNames )
					fprintf( REPORT_HTML, '\t<td>%s</td>\n', classDistanceFunctionNames{ df_index } );	
				end;
				fprintf( REPORT_HTML, '</tr>\n' );
				for df_indexA = 1:length( classDistanceFunctionNames )
					fprintf( REPORT_HTML, '<tr>\n\t<td>%s</td>\n', classDistanceFunctionNames{ df_indexA } );	
					for df_indexB = 1:length( classDistanceFunctionNames )
						[h p] = ttest( ...
							distanceFunctionCorrelationsByProblemAndFunction( continuousClassProblems, df_indexA ), ...
							distanceFunctionCorrelationsByProblemAndFunction( continuousClassProblems, df_indexB ), ...
							0.05, 'left' ...
						);
						style = '';
						if( h ==1 )
							style = 'font-weight: bold;';
						end;
						fprintf( REPORT_HTML, '\t<td style="%s">%.2f</td>\n', style, p );
					end;
					fprintf( REPORT_HTML, '</tr>\n' );
				end;
				fprintf( REPORT_HTML, '</table>\n' );
			end;
			fprintf( REPORT_HTML, '</html>\n' );
		end;
	end;
end;