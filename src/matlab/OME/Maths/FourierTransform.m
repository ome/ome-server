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
function [outPixels] = FourierTransform(inPixels, theC)

% select the Channel from the XYZCT pixels
inPixels = inPixels(:,:,:,theC,:);

% fftshift shifts the zero-frequency component of the Fourier transform to center
% of spectrum
inPixels = fftshift(fft2(inPixels));

outPixels(:,:,:,1,:) = abs(inPixels);
outPixels(:,:,:,2,:) = angle(inPixels);

outPixels = double(outPixels);

% Use the following Matlab code to visualize the Fourier Space frequency
% imshow( mat2gray(log(1+angle(inPixels))) )