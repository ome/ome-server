%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2005 Open Microscopy Environment
%       Massachusetts Institue of Technology,
%       National Institutes of Health,
%       University of Dundee
%
%
%
%    This library is free software; you can redistribute it and/or
%    modify it under the terms of the GNU Lesser General Public
%    License as published by the Free Software Foundation; either
%    version 2.1 of the License, or (at your option) any later version.
%
%    This library is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%    Lesser General Public License for more details.
%
%    You should have received a copy of the GNU Lesser General Public
%    License along with this library; if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Written By: Josiah Johnston <siah@nih.gov>
%             based on concepts developed by Nikita Orlov
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% SYNOPSIS
%	[selected_sigs, fd_selected_sigs] = ...
%		FindSignatureSubsetFD (sigMatrix, sigs_excluded, sigLabels );
%
% INPUT NEEDED
%   'sigMatrix'       - Continuous data. Rows are signatures, columns are images.
%                       The last row is the class vector
%   'sigs_excluded'   - Signatures to be excluded from consideration. 
%                       e.g. Signatures that cannot be discretized.
%   'sigLabels'       - Names of the signatures. Format is: 
%                         sig_method( transform( im ) ).sig_ST.SE_name
%   'target_num_sigs' - The number of signatures to return. Optional. 
%                       defaults to number of classes + 1
%
% OUTPUT GIVEN
%   'sigs_used'     - integers representing which signatures
%                     were found to be the best 
%                     in classifying the training set.
%   'fd_sigs_used' -  doubles recording the selected signatures'
%                     Fisher Discriminate scores
%
% INTRODUCTION
%	This function performs univariate analysis on the rows of sigMatrix and 
% selects the top signatures from different signature families. In the example
% sigLabel given above, sig_method( transform( im ) ) is the signature family 
% name. If more signatures are requested than there are unique families, then 
% multiple selected signatures per family will be allowed after all families 
% have been selected from one.
%    This function is based on a file "select_sigs_FisherDiscrim" which Nikita wrote.
% The code in select_sigs_FisherDiscrim is very difficult to read,
% so I rewrote the algorithm into this function. The algorithms are not numerically
% equivalent, but this one performs significantly better on all problem sets
% so far. I'll drop the select_sigs_FisherDiscrim from cvs if this one 
% outperforms it on all problem sets.
%
function [selected_sigs, fd_selected_sigs] = ...
			FindSignatureSubsetFD (sigMatrix, sigs_excluded, sigLabels, target_num_sigs )

% Convert the list of signature indexes to exclude into a binary list
% This makes later code easier.
numClasses         = length( unique( sigMatrix( end,: ) ) );
num_sigs           = length( sigLabels );
sigs_excluded_mask = zeros( 1, num_sigs );
sigs_excluded_mask( sigs_excluded ) = 1;
if( ~exist( 'target_num_sigs', 'var' ) ) 
	target_num_sigs = numClasses + 1;
end;

% Get the list of signature families
[ sig_is_member_of_family sig_family_names ] = getSigFamilies( sigLabels );
num_sig_families = length( unique( sig_is_member_of_family ) )

% Get the Fisher Discriminate scores
sig_fd_scores = fisherScores( sigMatrix );

% Find the top numClasses+1 signatures from distinct families. Allow repeats
% from within families when 
selected_sigs      = [];
selected_sigs_mask = zeros( 1, num_sigs );
families_used      = zeros( 1, num_sig_families );
families_used_mask = zeros( 1, num_sigs );
nan_scores         = find( isnan( sig_fd_scores ) );
nan_excluded_mask  = zeros( 1, num_sigs );
nan_excluded_mask( nan_scores ) = 1;
while( length( selected_sigs ) < target_num_sigs )
	% Find signatures whos families haven't been used, are not in the 
	% excluded list, and have not been selected.
	candidates = find( ...
		( families_used_mask(:) == 0 ) & ...
		( sigs_excluded_mask(:) == 0 ) & ...
		( selected_sigs_mask(:) == 0 ) & ...
		( nan_excluded_mask(:) == 0 ) ...
	);
	% Exit if athere are no available candidates.
	if( length( candidates ) == 0 )
		break;
	end;
	% Find the highest ranking signature from the candidate pool
	[ junk current_best_sig ] = max( sig_fd_scores( candidates ) );
	% Convert the candidates index to a signature index and add it to the list
	current_best_sig = candidates( current_best_sig );
	selected_sigs_mask( current_best_sig ) = 1;
	selected_sigs( end + 1 ) = current_best_sig;
	% Mark this family as being used
	families_used( sig_is_member_of_family( current_best_sig ) ) = 1;
	other_sigs_in_this_family = find( ...
		sig_is_member_of_family == sig_is_member_of_family( current_best_sig ) );
	families_used_mask( other_sigs_in_this_family ) = 1;
	% Find signatures whos families haven't been used, are not in the 
	% excluded list, and have not been selected.
	candidates = find( ...
		( families_used_mask(:) == 0 ) & ...
		( sigs_excluded_mask(:) == 0 ) & ...
		( selected_sigs_mask(:) == 0 ) & ...
		( nan_excluded_mask(:) == 0 ) ...
	);
	% Reset the families used if we are out of candidates
	if( length( candidates ) == 0 )
		families_used      = zeros( 1, num_sig_families );
		families_used_mask = zeros( 1, num_sigs );
	end;
end;

% Record the fd scores for the calling function
fd_selected_sigs = sig_fd_scores( selected_sigs );

return;


