function [names, values] = mb_imgedgefeatures(imageproc)
% MB_IMGFEATURES - calculates features for IMAGEPROC
% MB_IMGFEATURES(IMAGEPROC), 
%    where IMAGEPROC contains the pre-processed fluorescence image. 
%    Pre-processed means that the image has been cropped and had 
%    pixels of interest selected (via a threshold, for instance).
%
%    Features calculated include:
%
% 07 Mar 99 - M.V. Boland

% $Id$

%
% Initialize the variables that will contain the names and
%   values of the features.
%
names = {} ;
values = [] ;

%
% Total area of the image that is edges
%
A = bwarea(edge(imageproc,'canny',[]))/bwarea(im2bw(imageproc)) ;

%
% Directional edge filters
%
N = [1 1 1 ; 0 0 0 ; -1 -1 -1] ;
W = [1 0 -1 ; 1 0 -1 ; 1 0 -1] ;

%
% Calculation of the gradient from two orthogonal directions
%
iprocN = filter2(N,imageproc) ;
iprocW = filter2(W,imageproc) ;

%
% Calculate the magnitude and direction of the gradient
%
iprocmag = sqrt(iprocN.^2 + iprocW.^2) ;
iproctheta = atan2(iprocN, iprocW) ;

%
% Identify pixels in iproctheta that are not 0
%  (i.e. iprocN and iprocW were both 0)
%
[r,c,v] = find(iproctheta) ;

%
% Histogram the gradient directions
%
h = hist(v,8) ;

%
% max/min ratio
%
[hmax maxidx] = max(h) ;
hmin = min(h) ;

if (hmin ~= 0),
  maxminratio = hmax/hmin ;
else
  maxminratio = 0 ;
end

htmp=h ;
htmp(maxidx) = 0 ;
hnextmax = max(htmp) ;
maxnextmaxratio=hmax/hnextmax ;

%
% Difference between bins of histogram at angle and angle+pi
%  In general, objects have an equal number of pixels at an angle
%  and that angle+pi. The differences are normalized to the sum of 
%  the two directions.
%
sumdiff=sum(abs(h(1:4)-h(5:8))./abs(h(1:4)+h(5:8))) ;

%
% Measure of edge homogeneity - what fraction of edge pixels are in
%  the first two bins of the histogram.
%
homogeneity = sum(h(1:2))/sum(h(:)) ;

names = [names cellstr('edges:area_fraction') ...
         cellstr('edges:homogeneity') ...
	 cellstr('edges:direction_maxmin_ratio') ...
         cellstr('edges:direction_maxnextmax_ratio') ...
         cellstr('edges:direction_difference')] ;
values = [A homogeneity maxminratio maxnextmaxratio sumdiff] ;
