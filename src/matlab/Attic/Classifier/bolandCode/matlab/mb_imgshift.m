function Is = mb_imgshift(I, x, y)
% MB_IMGSHIFT - shifts an input image
% MB_IMGSHIFT(I, X, Y), 
%         Shifts image I by X (cols) and Y (rows).  The output image
%         is the same size as the input image.
%
% 07 Jan 99 - M.V. Boland

% $Id$

if (nargin ~=3)
	error('mb_imgshift requires three arguments.') ;
end

if (isempty(I))
	error('You must specify an image for cropping') ;
end

%
% Return the original image if there is no shift
if (x==0 & y==0)
	Is = I ;
end

%
% Generate a blank Is
Is = zeros(size(I)) ;

%
% Various cases for the sign of x and y
if (x >= 0 & y <= 0)
	Is(1:end-abs(y), x+1:end) = I(abs(y)+1:end, 1:end-x) ;
elseif (x > 0 & y > 0)
	Is(y+1:end, x+1:end) = I(1:end-y, 1:end-x) ;
elseif (x < 0 & y < 0)
	Is(1:end-abs(y), 1:end-abs(x)) = I(abs(y)+1:end, abs(x)+1:end) ;
elseif (x <= 0 & y >= 0)
	Is(y+1:end, 1:end-abs(x)) = I(1:end-y, abs(x)+1:end) ;
end


