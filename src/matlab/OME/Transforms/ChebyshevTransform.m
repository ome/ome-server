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


%% Function computes coefficients for 2D Chebyshev transform 
%%
%% Nikita Orlov 
%% Computational Biology Unit, LG, NIA/NIH
%% :: revision :: 07-01-2004 ::
%%
%% output: cc2 (2D coeff matrix and reconstructed image)
%% input:  Im, N   (image and coeff order)
%%
%% Examples:
%% [cc2] = ChebyshevTransform(Im,170);
%% [cc2] = ChebyshevTransform(Im,20); 
%%
function [cc2] = ChebyshevTransform(Im,N)
packYes=0; recYes=0;
[m,n]=size(Im);x=1:n;y=1:m;
x=2.*x./max(x)-1;  y=2.*y./max(y)-1;
cc2 = getChCoeff(getChCoeff(Im,x,N)',y,N);
    % if want to reconstruct image:
if ~recYes,im2=[];else,im2=(recImg(x,N,recImg(y,N,cc2')'))';end
    % pack up coeff in 'Chebyshev space'
if packYes, [cc2_packed] = hist(cc2(:),30); cc2=cc2_packed'; end
return;

%% ChebyshevTransform for 2D: coefficients
function c = getChCoeff(Im,x,N)
for iy=1:size(Im,1), c(iy,:) = getChCoeff1D(Im(iy,:),x,N);end
return;

%% ChebyshevTransform for 1D: coefficients
function c = getChCoeff1D(f,x,N), Tj = TNx(x,N);
for jj=1:N, jx=jj-1; tj = Tj(:,jj);
 if ~jx, tj = tj./length(x); else, tj = tj.*2/length(x); end
 c(jj) = f*(tj./2);
end
return;

%% Chebyshev polynomials
function T=TNx(x,N), if max(abs(x(:)))>1, error(':: Cheb. Polynomials Tn :: abs(arg)>1'); end
T = cos((ones(size(x,2),1)*(0:(N-1))).*acos(x'*ones(1,N)));T(:,1)=ones(size(x'));
return;

%% reconstruct original image from coefficients of ChebyshevTransform
function im = recImg(x,N,cc), Tj = TNx(x,N); 
for iy=1:size(cc,1),
 for jx=1:length(x), im(iy,jx)=cc(iy,:)*Tj(jx,:)'; end
end
return;

%% filter out some of coeff in 'Chebyshev space' (like in frequency space for FFT)
function [fc_packed,fc] = filterCoeff(c),N = size(c,1);
mc=mean2(c); sc=std2(c); [cx,cy]=meshgrid(1:N);
cr=sqrt(cx.^2+cy.^2);fmax=max(cr(:));
fc=c; origLen = length(find(fc));
cutL = 0:.01:1;
cutH = cutL+.005; cutH=cutH(cutH<=1);cutL=cutL(1:length(cutH));
cutL=cutL.*fmax; cutH=cutH.*fmax;
cutL=cutL([1:3 4:3:end]);cutH=cutH([1:3 4:3:end]);
str = [];
for ind=1:length(cutL)-1,
 L = cutL(ind); H = cutH(ind); str = [str '(' num2str(L) '<cr&cr<' num2str(H) ')|'];
end
str = [str '(' num2str(cutL(length(cutL))) '<cr)'];
kk=eval(str); fc(~kk)=0;
nk=length(find(fc)); fc=fc.*N./sqrt(nk);
mkill2 = (abs(fc)<.5*sc) | (abs(fc)>3*sc); fc(mkill2)=0;
fc_packed = fc(fc>0);
return;
