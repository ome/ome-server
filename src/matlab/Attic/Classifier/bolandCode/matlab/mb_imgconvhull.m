function hull = mb_imgconvhull(bwimage)
% MB_IMGCONVHULL returns the convex hull of BWIMAGE as an image
% MB_IMGCONVHULL(IMAGE), where BWIMAGE is the binary image 
%    to be processed.
%
% 07 Aug 98 - M.V. Boland

% $Id$

if (isempty(bwimage))
	error('Invalid input image') ;
end

%
% Find all non-zero points in bwimage, and then identify the points on 
%   the convex hull
%
[Ty, Tx] = find(bwimage) ;
k = convhull(Tx,Ty) ;

%
% Convert the convex hull polygon to an image
%
hull = roipoly(bwimage, Tx(k), Ty(k)) ;


