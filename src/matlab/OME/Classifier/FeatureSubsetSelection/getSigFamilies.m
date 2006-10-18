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
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% SYNOPSIS
%	[sig_family_vector sig_family_names] = getSigFamilies( sigLabels );
%
% INPUT NEEDED
%   sigLabels - Signature labels in the form:
%               sig_method( transform( im ) ).sig_ST.SE_name
%
% OUTPUT GIVEN
%   sig_family_vector - index is paired to sigLabels. Describes distinct 
%                       signature families. Provides indexes into sig_family_names
%	sig_family_names  - Names of distinct signature families.
%
% DESCRIPTION
% 	A helper function to parse signature families from a full list of sig labels
function [sig_family_vector sig_family_names] = getSigFamilies( sigLabels )

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
