
function scaledimage = mb_imgscale(image)
% MB_IMGSCALE scales the range of values in the input image to 0-1
% MB_IMGSCALE(IMAGE) scales the values in IMAGE to be between 
%	0 and 1.
%
% 07 Aug 98

% $Id$

if ~image
	error('Invalid input image') ;
end

%
% Subtract the minimum value and divide by the resulting maximum
%
scaledimage = image - min(image(:)) ;
scaledimage = scaledimage/max(scaledimage(:)) ;


