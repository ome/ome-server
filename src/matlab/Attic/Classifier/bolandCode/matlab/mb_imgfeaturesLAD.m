function [values] = mb_imgfeaturesLAD(imageproc)
% MB_IMGFEATURES(IMAGEPROC, DNAPROC) calculates features for IMAGEPROC
% MB_IMGFEATURES(IMAGEPROC, DNAPROC), 
%    where IMAGEPROC contains the pre-processed fluorescence image, 
%    and DNAPROC the pre-processed DNA fluorescence image.
%    Pre-processed means that the image has been cropped and had 
%    pixels of interest selected (via a threshold, for instance).
%    Use DNAPROC=[] to exclude features based on the DNA image.  
%
%    Features calculated include:
%      - Number of objects
%      - Euler number of the image (# of objects - # of holes)
%      - Average of the object sizes
%      - Variance of the object sizes
%      - Ratio of the largest object to the smallest
%      - Average of the object distances from the COF
%      - Variance of the object distances from the COF
%      - Ratio of the largest object distance to the smallest
%      - DNA: average of the object distances to the DNA COF
%      - DNA: variance of the object distances to the DNA COF
%      - DNA: ratio of the largest object distance to the smallest
%      - DNA/Image: distance of the DNA COF to the image COF
%      - DNA/Image: ratio of the DNA image area to the image area
%      - DNA/Image: fraction of image that overlaps with DNA 
%
% 10 Aug 98 - M.V. Boland
% 15 Jul 03 - L.A. David - I've ripped out all of the DNA stuff so that this is actually useful for
% all types of images
% $Id$

%
% Initialize the variables that will contain the names and
%   values of the features.
%
names = {} ;
values = [] ;

%
% Features from imfeature()
%
features = imfeature(double(im2bw(imageproc)), 'EulerNumber') ;

%
% Calculate the number of objects in IMAGE
%
imagelabeled = bwlabel(im2bw(imageproc)) ;
obj_number = max(imagelabeled(:)) ;

names = [names cellstr('object:number') cellstr('object:EulerNumber')] ;
values = [values obj_number features.EulerNumber] ;

%
% Calculate the center of fluorescence of IMAGE
%
imageproc_m00 = mb_imgmoments(imageproc,0,0) ;
imageproc_m01 = mb_imgmoments(imageproc,0,1) ;
imageproc_m10 = mb_imgmoments(imageproc,1,0) ;
imageproc_center = [imageproc_m10/imageproc_m00 ...
                    imageproc_m01/imageproc_m00] ;

% Find the maximum and minimum object sizes, and the distance 
%    of each object to the center of fluorescence
%
obj_minsize = realmax ;
obj_maxsize = 0 ;
obj_sizes = [] ;
obj_mindist = realmax ;
obj_maxdist = 0 ;
obj_distances = [] ;
t = 1:obj_number;
u = rand(1,obj_number);
v = ([t ; u])';
v = sortrows(v,2);
max_num = 100;
if obj_number < max_num;
    w = obj_number;
else
    w = max_num;
end
for (i=1:w)                                        % this number here may need amending
	obj_size = size(find(imagelabeled==v(i,1)),1) ;
	if obj_size < obj_minsize
		obj_minsize = obj_size ;
	end
	if obj_size > obj_maxsize
		obj_maxsize = obj_size ;
	end

	obj_sizes = [obj_sizes obj_size] ;

	obj_m00 = mb_imgmoments(roifilt2(0,imageproc,~(imagelabeled==v(i,1))),0,0) ;
	obj_m10 = mb_imgmoments(roifilt2(0,imageproc,~(imagelabeled==v(i,1))),1,0) ;
	obj_m01 = mb_imgmoments(roifilt2(0,imageproc,~(imagelabeled==v(i,1))),0,1) ;

	obj_center = [obj_m10/obj_m00 obj_m01/obj_m00] ;
	obj_distance = sqrt((obj_center - imageproc_center)...
                             *eye(2)*(obj_center - imageproc_center)') ;
	
	if obj_distance < obj_mindist
		obj_mindist = obj_distance ;
	end
	if obj_distance > obj_maxdist
		obj_maxdist = obj_distance ;
	end

	obj_distances = [obj_distances obj_distance] ;

end

obj_size_avg = mean(obj_sizes) ;
obj_size_var = var(obj_sizes) ;
obj_size_ratio = obj_maxsize/obj_minsize ;

names = [names cellstr('object_size:average') ...
		cellstr('object_size:variance') ...
		cellstr('object_size:ratio')] ;
values = [values obj_size_avg obj_size_var obj_size_ratio] ;

obj_dist_avg = mean(obj_distances) ;
obj_dist_var = var(obj_distances) ;
if obj_mindist ~= 0 
	obj_dist_ratio = obj_maxdist/obj_mindist ;
else
	obj_dist_ratio = 0 ;
end
names = [names cellstr('object_distance:average') ... 
		cellstr('object_distance:variance') ...
		cellstr('object_distance:ratio')] ;
values = [values obj_dist_avg obj_dist_var obj_dist_ratio] ;
