% SYNOPSIS
%	[sig_set_results, sig_names, AI_results, AI_names, indexes] = flattenResults( results );
% 

function [sig_set_results, sig_names, AI_results, AI_names, indexes] = flattenResults( results );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initiate variables
sig_set_results = struct('net_accuracy', {[]}, 'correctness', {[]}, 'num_unclassified', {[]});
% These next two lines make sig_set_results the right size
num_sig_sets = length( results( end ).Splits( end ).SigSet );
sig_set_results( num_sig_sets ).net_accuracy = [];

AI_results      = struct('net_accuracy', {[]}, 'correctness', {[]}, 'num_unclassified', {[]});
% These next two lines make AI_results the right size
num_AIs = length( results( end ).Splits( end ).SigSet(end).AI );
AI_results( num_AIs ).net_accuracy = [];

sig_names = {};
AI_names  = {};
indexes = struct( 'problem_index', {}, 'split_index', {} );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop through the structure and flatten the data
for problem_index = 1:length( results )
	for split_index = 1:length( results( problem_index ).Splits )

		% Skip problem splits that haven't been completed
		skip_problem_trial = 0;
		for sig_set_index = 1:length( results( problem_index ).Splits( split_index ).SigSet )
			for ai_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI )
				if( ~isfield( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI( ai_index ), 'results' ) )
					skip_problem_trial = 1;
				end;
			end;
		end;
		if( skip_problem_trial )
			continue;
		end;
		indexes( end+1 ).problem_index = problem_index;
		indexes( end ).split_index   = split_index;
		
		for sig_set_index = 1:length( results( problem_index ).Splits( split_index ).SigSet )
			sig_names{ sig_set_index } = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).name;
			
			for ai_index = 1:length( results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI )
				AI_names{ ai_index } = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI.name;
	
				individual_results = results( problem_index ).Splits( split_index ).SigSet( sig_set_index ).AI.results;
				sig_set_results( sig_set_index ).net_accuracy(end+1)     = individual_results.net_accuracy;
				sig_set_results( sig_set_index ).correctness(end+1)      = individual_results.correctness;
				sig_set_results( sig_set_index ).num_unclassified(end+1) = individual_results.num_unclassified;
	
				AI_results( ai_index ).net_accuracy(end+1)     = individual_results.net_accuracy;
				AI_results( ai_index ).correctness(end+1)      = individual_results.correctness;
				AI_results( ai_index ).num_unclassified(end+1) = individual_results.num_unclassified;
			end;
		end;
	end;
end;

return;