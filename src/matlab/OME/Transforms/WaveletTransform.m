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

%% Function computes wavelet transform for image and its fft counterpart
%% sym5 wavelet family was used, with 2 levels being computed
%% Signatures are wavelet coefficients -- horizontal, vertical, and diagonal combined alltogether.
%%
%% output: 
%%  det1      WL signatures for level 1 (image);
%%  det2      WL signatures for level 2 
%%
%% input:
%%  img             image; 
%% 
%% :: Nikita Orlov :: LG, NIA/NIH
%%      5-11-2004
%% 

function [det1,det2] = WaveletSignatures(img),
L = 2; 
% Perform decomposition at level 2 of 'img' using sym5. 
[c,s]   = wavedec2(img,L,'sym5');
[chd1,cvd1,cdd1] = detcoef2('all',c,s,1); [chd2,cvd2,cdd2] = detcoef2('all',c,s,2); 
det1 = chd1+cvd1+cdd1; det2 = chd2+cvd2+cdd2;
return;
