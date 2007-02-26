% [ZVALUES] = ZernikePolynomials(I,D,R) Zernike moments through degree D 
% ZernikePolynomials(I,D,R),
%     Returns a vector of Zernike moments through degree D for the
%     image I, and the names of those moments in cell array znames. 
%     R is used as the maximum radius for the Zernike polynomials.
%
%     degree and radius are optional and default to 
%     The magnitude of the Zernike moments is returned.
%
%     Reference: Teague, MR. (1980). Image Analysis vi athe General
%       Theory of Moments.  J. Opt. Soc. Am. 70(8):920-930.
%
% 19 Dec 98 - M.V. Boland
% 20 Sep 04 - T.J. Macura Modified for inclusion with OME. Returns only 
%             magnitude component of complex value. Degree and Radius are
%             now optional function parameters.
%             

function [zvalues] = ZernikePolynomials(I,D,R)
zvalues = [] ;

if nargin < 2 D = 15; end
if nargin < 3 [rows cols] = size(I); R = rows/2; end

%
% Find all non-zero pixel coordinates and values
%
[Y,X,P] = find(I) ;
P = double(P);

%
% Normalize the coordinates to the center of mass and normalize
%  pixel distances using the maximum radius argument (R)
%

Xn = (X-IMGMOMENTS(I,1,0)/IMGMOMENTS(I,0,0))/R; 
Yn = (Y-IMGMOMENTS(I,0,1)/IMGMOMENTS(I,0,0))/R;


%
% Find all pixels of distance <= 1.0 to center
%
k = find(sqrt(Xn.^2 + Yn.^2) <= 1.0) ;
psum = sum(P);       % trying to speed things up here.

for n=0:D,
  for l=0:n,
    if (mod(n-l,2)==0)
		zvalues = [zvalues Znl(n, l, Xn(k), Yn(k), P(k)/psum)] ;
    end
  end
end

zvalues = abs(zvalues);

function moment = IMGMOMENTS(image, x, y)
% IMGMOMENTS(IMAGE, X, Y) calculates the moment MXY for IMAGE
% IMGMOMENTS(IMAGE, X, Y), 
%    where IMAGE is the image to be processed and X and Y define
%    the order of the moment to be calculated. For example, 
%    IMGMOMENTS(IMAGE,0,1) calculates the first order moment 
%    in the y-direction, and 
%    IMGMOMENTS(IMAGE,0,1)/IMGMOMENTS(IMAGE,0,0) is the 
%    'center of mass (fluorescence)' in the y-direction
%
% 10 Aug 98 - M.V. Boland

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