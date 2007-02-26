%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2003 Open Microscopy Environment
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
% Written by:  Tom Macura <tmacura@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% SYNOPSIS
%	[haralick_avg_and_range] = HaralickTexturesRI(Im, dist);
% INPUTS
%	Im - an image matrix
%	dist - optional, defaults to 1.


function [haralick_avg_and_range] = HaralickTexturesRI(Im, dist);

if nargin < 2
	dist = 1;
end

haralick_features(:,1) = HaralickTextures (Im, dist, 0);
haralick_features(:,2) = HaralickTextures (Im, dist, 45);
haralick_features(:,3) = HaralickTextures (Im, dist, 90);
haralick_features(:,4) = HaralickTextures (Im, dist, 135);

haralick_avg = mean(haralick_features, 2);					
haralick_range = range(haralick_features, 2);

haralick_avg_and_range = [haralick_avg; haralick_range];