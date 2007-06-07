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
		 DistMin, DistMax, DistMean, DistMedian, DistVar, DistHist] ...
		                                          = ObjectStatistics(BinaryMask)

% Input check
if( ~strcmpi( class( BinaryMask ), 'logical' ) )
	error( 'BinaryMask input must be cast into the Logical datatype. It is currently %s.', class( BinaryMask ) );
end;

% How many bins the histograms have
NUM_BINS = 10;

% Calculate number of contiguous regions in the image
[ features, Count ] = bwlabel( BinaryMask );
if (Count == 0)
	Euler = nan;
	Centroid = [nan nan];
	
	AreaMin    = 0;
	AreaMax    = 0;
	AreaMean   = 0;
	AreaMedian = 0;
	AreaVar    = nan;
	AreaHist = ones(1,NUM_BINS)*nan;
	
	DistMin    = 0;
	DistMax    = 0;
	DistMean   = 0;
	DistMedian = 0;
	DistVar    = nan;
	DistHist = ones(1,NUM_BINS)*nan;
	
	% Correctly set output type
	Count    = uint16(Count);
	Euler    = int32(Euler);
	AreaHist = uint16(AreaHist);
	DistHist = uint16(DistHist);
	return;
end

% Calculate region properties. Use regionprops() if available. 
% regionprops() came out in v 4.1 of the image processing toolbox
% If it isn't available, use imfeature. Both functions have identical
% interfaces.
% Determine which function to use:
returnCode = exist( 'regionprops', 'file' );
if( ismember( returnCode, [2:6] ) )
	useThisFunction = @regionprops;
else
	useThisFunction = @imfeature;
end;
% Actually perform calculation:
global_stats  = useThisFunction(double(BinaryMask), 'EulerNumber', 'Centroid');
featuresStats = useThisFunction(features, 'Area', 'Centroid' );

% Calculate Euler number & Centroid of the entire image.
Euler    = global_stats.EulerNumber;
Centroid = global_stats.Centroid;

% Calculate the statistics about each feature's areas 
featuresAreas = [featuresStats.Area];

AreaMin    = min(featuresAreas);
AreaMax    = max(featuresAreas);
AreaMean   = mean(featuresAreas);
AreaMedian = median(featuresAreas); 
AreaVar    = var(featuresAreas);
AreaHist   = hist(featuresAreas, NUM_BINS);

% Calculate the statistics about the distances between the feature centroids
% and image's centroid.
featuresCentroid = [featuresStats.Centroid];
featuresCentroidX = featuresCentroid(1:2:end) - double(Centroid(1));
featuresCentroidY = featuresCentroid(2:2:end) - double(Centroid(2));
featuresCentroidDist = sqrt(featuresCentroidX.*featuresCentroidX + ...
							featuresCentroidY.*featuresCentroidY);

DistMin    = min(featuresCentroidDist);
DistMax    = max(featuresCentroidDist);
DistMean   = mean(featuresCentroidDist);
DistMedian = median(featuresCentroidDist);
DistVar    = var(featuresCentroidDist);
DistHist   = hist(featuresCentroidDist, NUM_BINS);

% Correctly set output type
Count    = uint16(Count);
Euler    = int32(Euler);
AreaHist = uint16(AreaHist);
DistHist = uint16(DistHist);