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
% Written By: Tom Macura <tmacura@nih.gov>
%
% Concepts of Edge Homogenity and Difference Histogram from
%   Robert F. Murph et. al's "Searching Online Journals for Fluorescence Microscope
%                            Images Depicting Protein Subcellular Location Patterns"
%   2nd IEEE International Symposium on Bioinformatics and Bioengineering
%
% Implementation of aformentioned topics from
%   M.V. Boland's mb_imgfeatures:
%   http://greenhorn.stc.cmu.edu/software/2001_bioinformatics/matlab/mb_imgedgefeatures.m
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% This module computes statistics about the image's edge magnitudes and directions. 
%
%
% DUDU (TODO)
%     1) Since DirecHist, MagHist, DiffDirecHist are stored as uint16, if there are
%        more than 2^16 pixels per bin there is overflow. 
%	  2) This convolves image size with direction of pixels (which is bad)
%     Recommendation (1+2) is a normalized histogram as floats
%
%     3) Pixels with very small gradient magnitude shouldn't be binned in the DirecHist,
%     DiffDirecHist because they are noise sensitive, also they result in pile-up in
%     hist bin for direction 0. 0 can mean a direction or no direction.

function [EdgeArea, MagMean, MagMedian, MagVar, MagHist, ...
		  DirecMean, DirecMedian, DirecVar, DirecHist, ...
		  DirecHomogeneity, DiffDirecHist] = EdgeStatistics(ComputedImageGradient)

% How many bins the histograms have
NUM_BINS = 8;
NUM_BINS_HALF = 4;

GradientMag   = ComputedImageGradient(:,:,1);
GradientDirec = ComputedImageGradient(:,:,2);

% Calculate number of image pixels that are edge pixels
EdgeArea = sum(sum(im2bw( uint8(GradientMag) )));

% Calculate statistics about the edge strength
MagVec = GradientMag(1:1:end); % unravel the matrix into array
MagMean   = mean(MagVec);
MagMedian = median(MagVec); 
MagVar    = var(MagVec);
MagHist   = hist(MagVec, NUM_BINS);

% Calculate statistics about the edge direction
DirecVec = GradientDirec(1:1:end); % unravel the matrix into array
DirecMean   = mean(DirecVec);
DirecMedian = median(DirecVec);
DirecVar    = var(DirecVec);
DirecHist   = hist(DirecVec, NUM_BINS);

% Calculate statistics about edge difference direction
% Histogram created by computing differences amongst histogram bins at angle and angle+pi
DiffDirecHist = abs( DirecHist(1:NUM_BINS_HALF)-DirecHist(NUM_BINS_HALF+1:end) );
DiffDirecHist = DiffDirecHist ./ (DirecHist(1:NUM_BINS_HALF)+DirecHist(NUM_BINS_HALF+1:end));
 
% The fraction of edge pixels that are in the first two bins of the histogram measure
% edge homogeneity
DirecHomogeneity = sum(DirecHist(1:2))/sum(DirecHist);

% Correctly set output type
EdgeArea  = uint16(EdgeArea);
MagHist   = uint16(MagHist);
DirecHist = uint16(DirecHist);