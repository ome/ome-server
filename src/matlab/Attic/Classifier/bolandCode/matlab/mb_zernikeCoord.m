function [xc,yc] = mb_zernike(I)
% [ZNAMES, ZVALUES] = MB_ZERNIKE(I,D,R) Zernike moments through degree D 
% MB_ZERNIKE(I,D,R),
%     Returns a vector of Zernike moments through degree D for the
%     image I, and the names of those moments in cell array znames. 
%     R is used as the maximum radius for the Zernike polynomials.
%
%     For use as features, it is desirable to take the 
%     magnitude of the Zernike moments (i.e. abs(zvalues))
%
%     Reference: Teague, MR. (1980). Image Analysis vi athe General
%       Theory of Moments.  J. Opt. Soc. Am. 70(8):920-930.
%
% 19 Dec 98 - M.V. Boland
%

% $Id$

znames = {} ;
zvalues = [] ;

%
% Find all non-zero pixel coordinates and values
%
[Y,X,P] = find(I) ;

%
% Normalize the coordinates to the center of mass and normalize
%  pixel distances using the maximum radius argument (R)
%
xc = mb_imgmoments(I,1,0)/mb_imgmoments(I,0,0);
yc = mb_imgmoments(I,0,1)/mb_imgmoments(I,0,0);



