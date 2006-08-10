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
%
% INPUT NEEDED      
%   'sigMatrix'     - Continuous data. Rows are signatures, columns are images.
%                     The last row is the class vector
%   'sigs_excluded' - Signatures to be excluded from consideration. 
%                     e.g. Signatures that cannot be discretized.
%   'sigLabels'     - Names of the signatures. Format is: 
%                         sig_method( transform( im ) ).sig_ST.SE_name
%
% OUTPUT GIVEN
%   'sigs_used'     - integers representing which signatures
%                     were found to be the best (collectively)
%                     in classifying the training set.
%   'fd_sigs_used' -  doubles recording the selected signatures'
%                     Fisher Discriminate scores
% INTRODUCTION
%    This function is based on a file "select_sigs_FisherDiscrim" which Nikita wrote
% and is not on cvs. The code in select_sigs_FisherDiscrim is very difficult to read,
% so I rewrote the algorithm into this function. I have not had opporutinity to
% validate numeric equivalency between the two functions. This note serves as a reminder
% to check into that.
%	The method is to calculate fisher discriminate scores for the signatures 
% (see fisherScores.m), and choose the top scoring signatures from different
% signature families. The number of signatures chosen is one more than the 
% number of classes.
function [selected_sigs, fd_selected_sigs] = ...
			FindSignatureSubsetFD (sigMatrix, sigs_excluded, sigLabels )

% Get the Fisher Discriminate scores
sig_fd_scores = fisherScores( sigMatrix );

numClasses = length( unique( sigMatrix( end,: ) ) );

% Get the list of signature families
sig_family_vector = getSigFamilies( sigLabels );
num_sig_families = length( unique( sig_family_vector ) );
target_num_sigs = numClasses + 1;

% Find the top numClasses+1 signatures from distinct families
[sortedScores rankings] = sort( sig_fd_scores, 2, 'descend' );
selected_sigs = [];
families_used = [];
for ranking_index = 1:length( rankings )
	sig_index = rankings( ranking_index );

	% Skip this signature if the caller asked for it to be excluded
	% or if another signature from its family has already been included
	% or if it has a NaN as a fisher score
	if( ( length( find( sigs_excluded == sig_index ) ) > 0 ) | ...
	    ( length( find( families_used == sig_family_vector( sig_index ) ) ) > 0 ) | ...
	    isnan( sig_fd_scores( sig_index ) ) )
		continue;
	end;
	
	% Add this signature to the set, and its family to the list of those used
	selected_sigs( end + 1 ) = sig_index;
	families_used( end + 1 ) = sig_family_vector( sig_index );
	
	% Leave this loop when we reach the desired number of signatures
	if( length( selected_sigs ) == target_num_sigs )
		break;
	end;
end;

% Record the fd scores for the calling function
fd_selected_sigs = sig_fd_scores( selected_sigs );

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function to parse signature families from the larger list of sig labels
% The signature labels are assumed to be in the form:
%	sig_method( transform( im ) ).sig_ST.SE_name
function [sig_family_vector] = getSigFamilies( sigLabels )

sig_family_names = {};
sig_family_vector = [];
for sig_index = 1:length( sigLabels )
	% Everything up to the next-to-the-last dot is the signature family name
	dots = strfind( sigLabels{ sig_index }, '.' );
	if( length( dots ) < 2 )
		error( [ 'Could not parse signature label: ' sigLabels{ sig_index } ] );
	end;
	sig_family_name = sigLabels{ sig_index }(1:dots( end-1 )-1 );
	
	% Mark this signature as not belonging to a family yet.
	sig_family_vector( sig_index ) = 0;
	% Look for a family this signature may belong to.
	for sig_family_index = 1:length( sig_family_names )
		if( strcmp( sig_family_name, sig_family_names{ sig_family_index } ) )
			sig_family_vector( sig_index ) = sig_family_index;
			break;
		end;
	end;
	
	% If no catalogued signature family matches, then create a new catologue entry
	if( sig_family_vector( sig_index ) == 0 )
		sig_family_index = length( sig_family_names ) + 1;
		sig_family_names{ sig_family_index } = sig_family_name;
		sig_family_vector( sig_index ) = sig_family_index;
	end;
end;

return;
