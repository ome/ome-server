function centralmoment = mb_imgcentmoments(image, x, y)
% MB_IMGCENTMOMENTS(IMAGE, X, Y) central moment MUxy for IMAGE
% MB_IMGCENTMOMENTS(IMAGE, X, Y), 
%    where IMAGE is the image to be processed and X and Y define
%    the order of the moment to be calculated. The coordinate system 
%    is centered using the center of fluorescence (m10/m00, m01/m00).
%
% 19 Aug 98 - M.V. Boland

% $Id$

if nargin ~= 3
	error('Please supply all three arguments (IMAGE, X, Y)') ;
end

if (isempty(image))
	error('IMAGE is empty.') 
end

% 
% Convert image to double precision if necessary
%
if (~isa(image,'double'))
	image = double(image) ;
end

m00 = mb_imgmoments(image, 0, 0) ;
m10 = mb_imgmoments(image, 1, 0) ;
m01 = mb_imgmoments(image, 0, 1) ;

cofx = m10/m00 ;
cofy = m01/m00 ;

%
% Generate a matrix with the x coordinates of each pixel.
%  If the order of the moment in x is 0, then generate
%  a matrix of ones.  Subtract the center of fluorescence
%  from the x coordinates.
%
if x==0
	xcoords = ones(size(image)) ;
else
	xcoords = (ones(size(image,1),1) * (([1:size(image,2)] - cofx) .^ x)) ;
end

%
% Generate a matrix with the y coordinates of each pixel.
%  If the order of the moment in y is 0, then generate
%  a matrix of ones Subtract the center of fluorescence 
%  from the y coordinates.
%
if y==0
	ycoords = ones(size(image)) ;
else
	ycoords = ((([1:size(image,1)]' - cofy) .^ y) * ones(1,size(image,2)));
end

%
% Multiply the x and y coordinate values together
%
xycoords = xcoords .* ycoords ;

%
% The central moment is the double sum of the xyf(x,y)
%
centralmoment = sum(sum(xycoords .* image)) ;
