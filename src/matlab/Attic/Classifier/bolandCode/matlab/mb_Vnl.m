function Vnl = mb_Vnl(n, l, x, y)
% MB_Vnl(N, L, X, Y) Zernike Polynomial for n, l, x, y.
% MB_Vnl(N, L, X, Y),
%     Calculates the Zernike polynomial for the given input parameters.
%     
% 30 Nov 98 - M.V. Boland
%

% $Id$

Vnl = 0 ;

for m=0:(n-l)/2,
  Vnl = Vnl + (-1)^m * (mb_factorial(n-m)/...
                   (mb_factorial(m) * mb_factorial((n-2*m+l)/2) * ...
                    mb_factorial(n-2*m-l)/2) * ...
                   (x^2 + y^2)^(n/2 - m) * exp(i*l*atan2(y,x))) ;

end
