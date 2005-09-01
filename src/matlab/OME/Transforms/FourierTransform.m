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

%  This module computes the image's Fourier Transform. 
%  The frequency space (i.e. the Fourier Transform of Real space) is, in general,
%  complex. We represent it by its magnitude and phase rather than its real and 
%  imaginary parts. Magnitude(F) = sqrt (real(F)^2 + imag(F)^2). Also 
%  Phase(F) = atan(imag(F)/real(F)). The magnitude is encoded as channel 0 and the 
%  phase is channel 1 of the output pixels set.
%
function [outPixels] = FourierTransform(inPixels)

% its only a plane
inPixels = inPixels(:,:);

% fftshift shifts the zero-frequency component of the Fourier transform to center
% of spectrum.
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% September 1, 2005. Josiah Johnston <siah@nih.gov>
% Subsequent to conversations with Tom and Nikita, I am commenting out the 
% fftshift for the moment. The non-ome version of the classifier code base has
% been using a fourier space without the shift. It is unclear what the effects
% of using the shift will be on classifier performance, so for expediency, we
% will stick with the established protocal. Later, we plan to compare the two
% methods and keep the one with superior performance.
%inPixels = fftshift(fft2(inPixels));
inPixels = fft2(inPixels);

outPixels(:,:,1) = abs(inPixels);
outPixels(:,:,2) = angle(inPixels);

% Use the following Matlab code to visualize the Fourier Space frequency
% imshow( mat2gray(log(1+angle(inPixels))) )