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
function [EdgeArea, MagMean, MagMeadian, MagVar, MagHist, ...
		  DirecMean, DirecMedian, DirecVar, DirecHist, ...
		  DirecHomogeneity, DiffDirecHist] = EdgeStatistics(GradientMag,GradientDirec)

% How many bins the histograms have
NUM_BINS = 8;
NUM_BINS_HALF = 4;

% Calculate number of image pixels that are edge pixels
EdgeArea = sum(sum(im2bw(GradientMag)));

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
DirecHomogeneity = sum(DirecVec(1:2))/sum(DirecVec);