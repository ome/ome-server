function [isub] = mb_imgbgsub(image, method)
%  MB_MLPTHRESH - Subtract the background from an image
%  [ISUB] = MB_IMGBGSUB(IMAGE, METHOD)
%
%    Outputs:
%     ISUB - IMAGE with the background subtracted
%     METHOD - method to use for identifying background
%              'common' - use the most common pixel value
%
%    Inputs:
%     IMAGE - image from which background should be subtracted
%     METHOD - method to use for identifying background
%              'common' - use the most common pixel value
%     %
%    M. Boland - 01 Mar 1999
%

% $Id$

if (isempty(image)),
  error('IMAGE is empty') ;
end

methods = {'common'} ;
if sum(strcmp(method, methods)) == 0
  error('Undefined method for determining the most common pixel');
end


if (strcmp(methods,'common')),
%
% Find the most common pixel value
common = mb_imgcommonpixel(image) ;

%
% Check for a common pixel value of 0
if (common == 0),
  isub = image ;
  return
end

%
% Subtract the most common pixel value from each pixel in the image
isub = image - common ;

%
% Set any pixel values < 0 to 0
isub = (isub>0).*isub ;

%
% endif
end
