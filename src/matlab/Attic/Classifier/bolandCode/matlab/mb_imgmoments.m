function moment = mb_imgmoments(image, x, y)
% MB_IMGMOMENTS(IMAGE, X, Y) calculates the moment MXY for IMAGE
% MB_IMGMOMENTS(IMAGE, X, Y), 
%    where IMAGE is the image to be processed and X and Y define
%    the order of the moment to be calculated. For example, 
%    MB_IMGMOMENTS(IMAGE,0,1) calculates the first order moment 
%    in the y-direction, and 
%    MB_IMGMOMENTS(IMAGE,0,1)/MB_IMGMOMENTS(IMAGE,0,0) is the 
%    'center of mass (fluorescence)' in the y-direction
%
% 10 Aug 98 - M.V. Boland

% $Id$

if nargin ~= 3
	error('Please supply all three arguments (IMAGE, X, Y)') ;
end

%
% Check for a valid image and convert to double precision
%   if necessary.
%
if (isempty(image))
	error('IMAGE is empty.') 
elseif (~isa(image,'double'))
	image = double(image) ;
end

%
% Generate a matrix with the x coordinates of each pixel.
%  If the order of the moment in x is 0, then generate
%  a matrix of ones
%
if x==0
	if y==0
		xcoords = ones(size(image)) ;
	end
else 
	xcoords = (ones(size(image,1),1) * ([1:size(image,2)] .^ x)) ;
end

%
% Generate a matrix with the y coordinates of each pixel.
%  If the order of the moment in y is 0, then generate
%  a matrix of ones
%
if y~=0
%	ycoords = ones(size(image)) ;
	ycoords = (([1:size(image,1)]' .^ y) * ones(1,size(image,2))) ;
end

%
% Multiply the x and y coordinate values together
%
if y==0
	xycoords = xcoords ;
elseif x==0
	xycoords = ycoords ;
else
	xycoords = xcoords .* ycoords ;
end

%
% The moment is the double sum of the xyf(x,y)
%
moment = sum(sum(xycoords .* image)) ;
