function [znames, zvalues] = mb_zernike(I,D,R)
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
Xn = (X-mb_imgmoments(I,1,0)/mb_imgmoments(I,0,0))/R ;
Yn = (Y-mb_imgmoments(I,0,1)/mb_imgmoments(I,0,0))/R ;

%
% Find all pixels of distance <= 1.0 to center
%
k = find(sqrt(Xn.^2 + Yn.^2) <= 1.0) ;
psum = sum(P);       % trying to speed things up here.

for n=0:D,
  for l=0:n,
    if (mod(n-l,2)==0)
	znames = [znames cellstr(sprintf('Z_%i,%i', n, l))] ;
	zvalues = [zvalues mb_Znl(n, l, Xn(k), Yn(k), ...
	             double(P(k))/psum)] ;
    end
  end
end





