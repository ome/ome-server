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
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% This module computes statistics about the contiguous regions of the image 
% (features). It is passed in a binary image such that non-zero pixel intensities 
% are of features.
%
function [Count, Euler, Centroid, ...
		 AreaMin, AreaMax, AreaMean, AreaMedian, AreaVar, AreaHist, ...
		 DistMin, DistMax, DistMean, DistMedian, DistVar, DistHist ] ...
		                                          = FeatureStatistics(BinaryMask)

% How many bins the histograms have
NUM_BINS = 10;

% Calculate number of contiguous regions in the image
features = bwlabel(im2bw(BinaryMask));
Count = max(features);

% Calculate Euler number
global_stats = imfeature(double(im2bw(BinaryMask)), 'EulerNumber', 'Centroid');
Euler = global_stats.EulerNumber;

% Calculate the image centroid
Centroid = global_stats.Centroid;

% Calculate the statistics about the feature's areas 
featuresAreas = imfeature(features, 'Area');
featuresAreas = [featuresAreas.Area];

AreaMin    = min(featuresAreas);
AreaMax    = max(featuresAreas);
AreaMean   = mean(featuresAreas);
AreaMedian = median(featuresAreas); 
AreaVar    = var(featuresAreas);
AreaHist   = hist(featuresAreas, NUM_BINS);

% Calculate the statistics about the distances between the feature centroids
% and image's centroid.
featuresCentroid = [imfeature(features,'Centroid')];
featuresCentroid = [featuresCentroid.Centroid];
featuresCentroidX = featuresCentroid(1:2:end) - Centroid(1);
featuresCentroidY = featuresCentroid(2:2:end) - Centroid(2);
featuresCentroidDist = sqrt(featuresCentroidX.*featuresCentroidX + ...
							featuresCentroidY.*featuresCentroidY);

DistMin    = min(featuresCentroidDist);
DistMax    = max(featuresCentroidDist);
DistMean   = mean(featuresCentroidDist);
DistMedian = median(featuresCentroidDist);
DistVar    = var(featuresCentroidDist);
DistHist   = hist(featuresCentroidDist, NUM_BINS);