function [names, values] = mb_hullfeatures(imageproc, imagehull)
% MB_HULLFEATURES - calculates features using the convex hull of IMAGE
% MB_HULLFEATURES(IMAGEPROC, IMAGEHULL) 
%     IMAGEPROC is the processed fluorescence image, IMAGEHULL is its binary 
%     convex hull.
%
% 12 Aug 98 - M.V. Boland

% $Id$


if ~isbw(imagehull)
	error('The convex hull image must be binary.') ;
end

%
% Initialize the return variables
%
names = {} ;
values = [] ;

%
% Fraction of the convex hull occupied by fluorescence
%    Ahull = area of the convex hull.
%
Ahull = bwarea(imagehull) ;
hullfract = length(find(imageproc))/Ahull ;
names = [names cellstr('convex_hull:fraction_of_overlap')] ;
values = [values hullfract] ;

%
% 'Shape factor' of the convex hull.
%    Phull = approximation to the hull perimeter.
%
Phull = bwarea(bwperim(imagehull)) ;
hullshape = (Phull^2)/(4*pi*Ahull) ;
names = [names cellstr('convex_hull:shape_factor')] ;
values = [values hullshape] ;

%
% Central moments of the convex hull
%
hull_mu00 = mb_imgcentmoments(imagehull,0,0) ;
hull_mu11 = mb_imgcentmoments(imagehull,1,1) ;
hull_mu02 = mb_imgcentmoments(imagehull,0,2) ;
hull_mu20 = mb_imgcentmoments(imagehull,2,0) ;

%
% Parameters of the 'image ellipse'
%   (the constant intensity ellipse with the same mass and
%   second order moments as the original image.)
%   From Prokop, RJ, and Reeves, AP.  1992. CVGIP: Graphical
%   Models and Image Processing 54(5):438-460
%

hull_semimajor = sqrt((2 * (hull_mu20 + hull_mu02 + ...
                      sqrt((hull_mu20 - hull_mu02)^2 + ...
                           4 * hull_mu11^2)))/hull_mu00) ;

hull_semiminor = sqrt((2 * (hull_mu20 + hull_mu02 - ...
                      sqrt((hull_mu20 - hull_mu02)^2 + ...
                           4 * hull_mu11^2)))/hull_mu00) ;

hull_eccentricity = sqrt(hull_semimajor^2 - hull_semiminor^2) / ...
                     hull_semimajor ;

names = [names cellstr('convex_hull:eccentricity')] ;

values = [values hull_eccentricity] ;

