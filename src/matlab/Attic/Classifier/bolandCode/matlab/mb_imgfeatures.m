function [names, values] = mb_imgfeatures(imageproc, dnaproc)
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

% 
% Calculate DNA COF, if necessary
%
if ~isempty(dnaproc)
	dnaproc_m00 = mb_imgmoments(dnaproc,0,0) ;
	dnaproc_m01 = mb_imgmoments(dnaproc,0,1) ;
	dnaproc_m10 = mb_imgmoments(dnaproc,1,0) ;
	dnaproc_center = [dnaproc_m10/dnaproc_m00 ...
                          dnaproc_m01/dnaproc_m00] ;
end

%
% Find the maximum and minimum object sizes, and the distance 
%    of each object to the center of fluorescence
%
obj_minsize = realmax ;
obj_maxsize = 0 ;
obj_sizes = [] ;
obj_mindist = realmax ;
obj_maxdist = 0 ;
obj_distances = [] ;

obj_dnamindist = realmax ;
obj_dnamaxdist = 0 ;
obj_dnadistances = [] ;

for (i=1:obj_number)
	obj_size = size(find(imagelabeled==i),1) ;
	if obj_size < obj_minsize
		obj_minsize = obj_size ;
	end
	if obj_size > obj_maxsize
		obj_maxsize = obj_size ;
	end

	obj_sizes = [obj_sizes obj_size] ;

	obj_m00 = mb_imgmoments(roifilt2(0,imageproc,~(imagelabeled==i)),0,0) ;
	obj_m10 = mb_imgmoments(roifilt2(0,imageproc,~(imagelabeled==i)),1,0) ;
	obj_m01 = mb_imgmoments(roifilt2(0,imageproc,~(imagelabeled==i)),0,1) ;

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

	if ~isempty(dnaproc)
		obj_dnadistance = sqrt((obj_center - dnaproc_center) ...
                                      *eye(2)*(obj_center ...
                                      - dnaproc_center)') ;
		if obj_dnadistance < obj_dnamindist
			obj_dnamindist = obj_dnadistance ;
		end
		if obj_dnadistance > obj_dnamaxdist
			obj_dnamaxdist = obj_dnadistance ;
		end

		obj_dnadistances = [obj_dnadistances obj_dnadistance] ;
	end
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

if ~isempty(dnaproc)
	obj_dnadist_avg = mean(obj_dnadistances) ;
	obj_dnadist_var = var(obj_dnadistances) ;
	if obj_dnamindist ~= 0 
		obj_dnadist_ratio = obj_dnamaxdist/obj_dnamindist ;
	else
		obj_dnadist_ratio = 0 ;
	end
	names = [names cellstr('DNA_object_distance:average') ...
                       cellstr('DNA_object_distance:variance') ...
                       cellstr('DNA_object_distance:ratio')] ;
	values = [values obj_dnadist_avg obj_dnadist_var obj_dnadist_ratio] ;

	dna_image_distance = sqrt((imageproc_center-dnaproc_center)... 
                               *eye(2)*(imageproc_center-dnaproc_center)') ;

	dna_area = size(find(im2bw(dnaproc)),1) ;
	image_area = size(find(im2bw(imageproc)),1) ;
	%
	% what fraction of the image fluorescence area overlaps the dna image?
	%
	image_overlap = size(find(roifilt2(0,imageproc,~im2bw(dnaproc))),1) ;

	if image_area == 0
		dna_image_area_ratio = 0 ;
		image_dna_overlap = 0 ;
	else
		dna_image_area_ratio = dna_area/image_area ;
		image_dna_overlap = image_overlap/image_area ;
	end
	
	names = [names cellstr('DNA/image:distance') ...
			cellstr('DNA/image:area_ratio') ...
			cellstr('DNA/image:overlap')] ;
	values = [values dna_image_distance dna_image_area_ratio ...
                  image_dna_overlap] ;
end
