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

% This module computes the image's gradient. It encodes the gradient vector at 
% each pixel as a magnitude and angle. The magnitude is the channel 0 of the 
% resulting pixels set. The angle is channel 1.
%
function [outPixels] = Gradient(inPixels, theC)

% select the Channel from the XYZCT pixels
inPixels = double(inPixels(:,:,:,theC,:));

% Calculation of the gradient from two orthogonal directions
N = [1 1 1 ; 0 0 0 ; -1 -1 -1];
W = [1 0 -1; 1 0 -1; 1 0 -1];
iprocN = filter2(N, inPixels);
iprocW = filter2(W, inPixels);

% Calculate the magnitude and direction of the gradient
outPixels(:,:,:,1,:) = sqrt(iprocN.^2 + iprocW.^2);
outPixels(:,:,:,2,:) = atan2(iprocN, iprocW);

outPixels = double(outPixels);
