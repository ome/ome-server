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
% Written By: Tom Macura <tmacura@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function mat = ConstructPenaltyMatrix (category_weights, damping_function);
%
% This function constructs a matrix A such that entry A_ij is the distance
% (based on category_weights) tempered with the damping_function
%
% INPUTS NEEDED:
%   'category_weights'   - e.g. [1 4 8] for C. elegans worm example
%   'damping_function'   - optional string ('linear','sqr', 'sqrt', 'exp', 'log')
%                          defaults to 'linear';
%
% OUTPUTS GIVEN:
%   'mat'                - penalty matrix ready to be applied (see ConfusionMatrixScore) 
%
% Tom Macura - 2005. tm289@cam.ac.uk

% set optional damping_function parameter to default
if (nargin < 2) 
	damping_function = 'linear';
end

% create preliminary penalty matrix
[r, c] = size(category_weights);
mat = zeros(c,c);
for i=1:c
	for j=1:c
		mat(i,j) = abs(category_weights(1,i) - category_weights(1,j));
	end
end

% apply damping function to preliminary penalty matrix
if (strcmp(damping_function, 'linear'))
	mat = mat;
elseif (strcmp(damping_function, 'sqr'))
	mat = mat.*mat;
elseif (strcmp(damping_function, 'sqrt'))
	mat = sqrt(mat);
elseif (strcmp(damping_function, 'exp'))
	mat = 2.718281828459045 .^ mat;
elseif (strcmp(damping_function, 'log'))
	mat = log (mat+1);
elseif (strcmp(damping_function, 'loglog'))
	mat = log (log (mat+1) + 1);
else
	error('Specified string `%s` refers to an unkown damping function.\n', damping_function);
end