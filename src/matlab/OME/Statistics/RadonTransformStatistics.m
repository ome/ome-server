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
% Written by:  Nikita Orlov <norlov@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% Signatures based on the Radon transform (matlab built-in function).
% Radon transform is the projection of the image intensity along a radial line 
% (at a specified orientation angle).
%
% Total 4 orientations are taken. Transformation n/2 vectors (for each rotation) 
% go through 3-bin histogram and convolve into 1x12 vector
%
% Nikita Orlov
% Computational Biology Unit, LG, NIA/NIH
% :: revision :: 03-10-2005
%
% Input:  Im (input image; or a matrix)
% Output: hr (3-bin histograms from all 4 orientations form 1x12 vector)
%
% Example: hr = RadonTransform(im2double(imread(filename)));
%

function hr = RadonTransformStatistics(Im),

hr = []; nbins = 3; th1=0:45:135;

R1 = radon(Im,th1);

for ii = 1:length(th1), hr = [hr hist(R1(:,ii),nbins)]; end
hr = uint16(hr);

return;

