%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2003 Open Microscopy Environment
%       Massachusetts Institue of Technology,
%       National Institutes of Health,
%       University of Dundee
%
%
%
%    This library is free software; you can redistribute it and/or
%    modify it under the terms of the GNU Lesser General Public
%    License as published by the Free Software Foundation; either
%    version 2.1 of the License, or (at your option) any later version.
%
%    This library is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%    Lesser General Public License for more details.
%
%    You should have received a copy of the GNU Lesser General Public
%    License along with this library; if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Written by:  Nikita Orlov <norlov@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%% Function computes coefficients for 2D Chebyshev-Fourier transform 
%%
%% Q.: what is Chebyshev-Fourier transform? 
%% A.: Image => sum [ c(n,m) * Chebyshev(2r-1,n)*exp(imf) ]
%% 
%% :: Nikita Orlov :: LG, NIA/NIH
%%      7-16-2004
%% 
%% output: 
%%  coeff_packed    packed coefficients, which become signatures;
%%
%% input:
%%  Im, N           image and coeff order; 
%%
%% Notes
%% Function is memory-consuming.
%% 256x320 with N = 20 is almost marginal (memory use is about 1Gb), for now it is hardcoded limit.
%% For future use on 32bit machines the threshold must rather be under 2Gb, so it'll need some refinement.

function [coeff_packed] = ChebyshevFourierTransform(Im,N)

recYes=0; packingOrder = 40;

[m,n] = size(Im); nLast = n*m;
if nLast > 256*320, warning(':: ChebyshevFourierTransform :: image size is critical');end
y = linspace(1,-1,m); x = linspace(-1,1,n);
[X,Y] = meshgrid(x,y); clear x,y;
xx = X(:); yy = Y(:); img = Im(:);  clear Im;
[f,r] = cart2pol(xx,yy); clear xx yy;
kk = find(r<=1); nk = length(kk); nLast = nk;
Nmax = fix((min(m,n)-1)/2); if N > Nmax, N = Nmax;end
if m*n*N > 256*320*20, error(':: ChebyshevFourierTransform :: memory use is critical [> 256*320*20], abort');end
NN = 2*N + 1;

%% Get Cheb-Fourier matrix 'C'...
C = zeros(nLast,NN*NN);
%tic0 = cputime;
for ind = 1:nk, ri = r(kk(ind)); fi = f(kk(ind));
 if ri>1, continue; end
 Tn = ChebPol(2*ri'-1,NN); c = [];
 for im = 1:NN, mf = im-1-N; if ~mf, Ftrm=.5; else, Ftrm=1;end
  cbuf = zeros(1,NN);
  tmp = Ftrm.*exp( -i*mf*fi ).* Tn;  cbuf(1:length(tmp)) = tmp;  c = [c cbuf];
 end %% im
 C(ind,:) = c(:)';
end %% for coord_ind
clear c;
coeff = C'*img(kk); 

    % filter out some of coeff in 'Chebyshev-Fourier space'
%coeff_packed = coeff;    
coeff_packed = hist(abs(coeff(:)),packingOrder)'; 

if ~recYes,X=[];Y=[];rec=[];tts=[];return;
else,
 rec = zeros(m*n,1);
 recTmp = real(conj(C)*coeff)./size(C,1); clear C;
 rec(kk) = recTmp; rec = reshape(rec,m,n);
%tmStamp = getEtime(cputime-tic0);
%tts = sprintf('%3i * %3i, 2N+1 = %2i',m,n,NN);
end
%figure,pcolor(X,Y,rec),colormap gray,colorbar,shading flat,title(tts);
return;


%======================================================================
function T = ChebPol(x,N), if max(abs(x(:)))>1, error(':: ChebPol :: abs(arg)>1'); end
n = 0:(N-1); T = cos(n.*acos(x)); T(1) = 1/2;
return;

function [st,hh,mm,ss]=getEtime(tm),
hh = floor(tm/3600); hrem = rem(tm,3600); mm = floor(hrem/60); ss = rem(hrem,60); 
st = sprintf('%02i:%02i:%02i.%02i',hh,mm,fix(ss),round(1e2*(ss-fix(ss))));
return;
