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
%
% SYNOPSIS
%	fisher_discriminate_scores = fisherScores( sigMatrix, class_vec );
%
% INPUTS
%	sigMatrix is a standard signature matrix, where rows are indexed by signatures, 
%	the last row stores the class, and columns are indexed by images.
%	class_vec is optional. If given, sigMatrix is assumed not to have the class in 
%	the last row. If absent, the last rox of sigMatrix is assumed to store the classes.
%
% OUTPUTS
%	fisher_discriminate_scores is a vector indexed by signatures. It stores the
%	fisher discriminate score for every image.
%
% DESCRIPTION
%	Calculate Fisher Discriminate scores for each signature using the formula:
%		mean( variance of class means from pooled mean ) /
%		( mean( variance within each class ) + eps )
%
% NOTES
%	This is a simplified version of Nikita's classic select_sigs_FisherDiscrim.m
% (roughly 1/10 the code). It differs in that it does not discretize the data 
% prior to calculating FD's. It also ignores signature families, and  does not 
% normalize the signature data before calculating the FD. It likely has other
% differences, but select_sigs_FisherDiscrim is extremely hard to read, and 
% I haven't puzzled out all the differences.
% When fisherScores is given discretized data, the ordering of signatures is 
% usually identical to select_sigs_FisherDiscrim. 
% Eps is added to the denominator for cases where the inner class variance is 0.

function [fisher_discriminate_scores] = fisherScores( sigMatrix, class_vec );


% Extract info from inputs
if( exist( 'class_vec', 'var' ) )
	num_sigs  = size(sigMatrix, 1);
else
	num_sigs  = size(sigMatrix, 1) - 1;
	class_vec = sigMatrix( end, : );
end;
num_classes = length( unique( class_vec ) );

% Calc a Fisher Discriminate score for one sig at a time.
% The formula is: 
%	mean( variance of class means from pooled mean ) /
%	mean( variance within each class )
for sig_index = 1:num_sigs
	% Calculate stats for each class
	for class_index = 1:num_classes
		class_instances = find( class_vec == class_index );
		class_means( class_index )     = mean( sigMatrix( sig_index, class_instances ) );
		inner_class_var( class_index ) = var(  sigMatrix( sig_index, class_instances ) );
	end;
	
	% Plug in numbers to the Fisher Formula
	sig_mean = mean( sigMatrix( sig_index, : ) );
	class_dev_from_mean = ...
		sum( ( class_means - sig_mean ).^2 ) / ( num_classes - 1 );
	fisher_discriminate_scores( sig_index ) = class_dev_from_mean / ( mean( inner_class_var ) + eps );
end;
