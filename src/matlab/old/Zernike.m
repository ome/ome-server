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
% Written by:  Nikita Orlov <orlovni@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


%function zernike = Zernike(Im,nzr,nzf,showWBar)
function zernikeStruct = Zernike(varargin)
Im=varargin{1};
nzr=varargin{2};
nzf=varargin{3};
if nargin>3,showWBar=varargin{4};else, showWBar=false; end

[m,n]=size(Im);x=1:n;y=1:m;
    % Move Origin to 'Im center'
x=2.*x./max(x);x=x-1;
y=2.*y./max(y);y=y-1;
    % Build matrices for Cartesian & Polar coordinates...
X=ones(m,1)*x;Y=y'*ones(1,n);[F,R]=cart2pol(X,Y);
R1d=reshape(R,1,m*n);F1d=reshape(F,1,m*n);
Im1d=reshape(Im,1,m*n);%X1d=reshape(X,1,m*n);Y1d=reshape(Y,1,m*n);
IJz=getMcnvIndeces(nzf,nzr);
if showWBar,hWB=waitbar(0,'form Zernike matrix...');end
    % form a matrix for Zernike polynomials
for beta=1:m*n,
 if showWBar,waitbar(beta/(m*n),hWB);end
 rr=R1d(beta);ff=F(beta);
 for alpha=1:nzr*nzf,[iFa,jRa]=dcnvIndeces(IJz,alpha);
  Znm(beta,alpha)=rr.^jRa .* exp(i.*(iFa-1).*ff);
 end
end
if showWBar,close(hWB);end
coef = pinv(Znm) * Im1d';
coef2=reshape(coef,nzf,nzr); % 2D-reshaped coefficients...

    % Recover rows/columns from multindex
[Mrow,Ncol]=dcnvIndecesMTX(IJz);
    % abs, Real, Imag [Zernike momentums]...
zernike.abs=abs(coef'); zernike.Re=real(coef'); zernike.Im=imag(coef');
zernike.mFI=Mrow; zernike.nRO=Ncol;
% Zernike approximant...
%recon=abs(Znm*coef); recon=reshape(recon,m,n);
%zernike.reconstruction=recon;

zernikeStruct = formatZernikeData(zernike);
return;

% Get a matrix-indeces for given range of rows (m) and columns (n)...
function IJ=getMcnvIndeces(m,n),
IJ1=m*ones(1,m)'*((1:n)-1);IJ2=(1:m)'*ones(1,n);IJ=IJ1+IJ2;
return;

% Reshape a 1D index (for a given index-matrix) into pair row-column
function [iy,jx]=dcnvIndeces(IJ,ij),[iy,jx,v]=find(IJ==ij);
return;
% Convolve a pair row-column into one [1D] index
function ij=cnvIndeces(ii,jj,IJ),[m,n]=size(IJ);ij=m*(jj-1)+ii;
return;

% Reshape a 1D index (for a given index-matrix) into pair row-column
function [Mrow,Ncol]=dcnvIndecesMTX(IJmtrx),
[nzf,nzr]=size(IJmtrx);
%for ind=1:(nzf*nzr), [Mrow(ind),Ncol(ind),val]=find(IJmtrx==ind);end
Mrow=repmat((1:nzf),1,nzr);
Ncol=reshape(((1:nzr)'*ones(1,nzf))',1,nzf*nzr);
return;

% format zernike data to a structure with the fields:
% index1x1_abs, index1x1_Re, index1x1_Im, index1x2_abs, etc.
function zernStruct=formatZernikeData(Zstruct)
n=length(Zstruct.abs);
for ix=1:n,
 st1=sprintf('Index%dx%d_Abs',Zstruct.mFI(ix),Zstruct.nRO(ix));
 st2=sprintf('Index%dx%d_Real',Zstruct.mFI(ix),Zstruct.nRO(ix));
 st3=sprintf('Index%dx%d_Img',Zstruct.mFI(ix),Zstruct.nRO(ix));
 zernStruct.(st1)=Zstruct.abs(ix);
 zernStruct.(st2)=Zstruct.Re(ix);
 zernStruct.(st3)=Zstruct.Im(ix);
end
return;
