function commonpixel = mb_imgcommonpixel(image)
% MB_IMGCOMMONPIXEL finds the most common pixel value in the input image. 
% [COMMONPIXEL] = MB_IMGSCALE(IMAGE) 
%
% 23 Feb 99

% $Id$

if ~image
	error('Invalid input image') ;
end

%
% Generate a histogram where the number of bins is equal to the 
%  maximum pixel value + 1 (0..maxpixel).
%
imagemax = max(max(image)) ;
if (imagemax ~= 0)
  [hmax,ihmax] = max(imhist(image/imagemax, imagemax+1)) ;
else
  [hmax,ihmax] = max(imhist(image, imagemax+1)) ;
end

commonpixel = ihmax-1 ; 

