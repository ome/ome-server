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

%% Function computes signatures based on Gabor texture filter.
%% The signature is an estimate of how much of the texture energy 
%% gets through the Gabor filter of a given frequency.
%% Signature vector of total 7 frequencies is computed.
%%
%% Nikita Orlov 
%% Computational Biology Unit, LG, NIA/NIH
%% :: revision :: 12-30-2004 ::
%%
%% output: ratios (1D vector)
%% input:  Img    (image)
%%
%% Example:
%% ratios = GaborTextureFilters(Img);
%%
%%
%% Reference:
%% C. Grigorescu, N. Petkov, M. Westenberg, J. of WSCG (ISSN 1213-6972), 11, No 1
%%

function ratios = GaborTextureFilters(Img),
GRAYthr = .60;  % Gray level; could be customized/automized
% parameters set up in complience with the paper
gamma = 0.5; sig2lam = 0.56;
n = 38;
f0 = 1:7;       % frequencies for several HP Gabor filters
f0LP = 0.1;     % frequencies for one LP Gabor filter
m1 = []; m2 = []; te = [];
cumE = zeros(size(Img));
[mm,nn] = size(Img);
GRAYthr = graythresh(Img);
fmask = forceBW(Img,GRAYthr);
originalScore = sum(fmask(fmask>0)); 
theta = pi/2;   % one orientation
e2LP = GaborEnergy(Img,f0LP,sig2lam,gamma,theta,n); 
fmaskLP=e2LP./max(e2LP(:)); fmaskLP = forceBW(fmaskLP,.4);
originalScore = sum(fmaskLP(fmaskLP>0));
for ii = 1:length(f0),
 e2 = GaborEnergy(Img,f0(ii),sig2lam,gamma,theta,n); 
 fmask = e2./max(e2(:)); 
 GRAYthr = graythresh(fmask); fmask = forceBW(fmask,GRAYthr);
 afterGabor = Img.*fmask; afterGabor = forceBW(afterGabor,GRAYthr);
 afterGaborScore = sum(afterGabor(afterGabor>0));
 ratios(ii) = afterGaborScore ./ originalScore;
end
return;


%% Computes Gabor energy
function [e2] = GaborEnergy(Im,f0,sig2lam,gamma,theta,n),
fi = 0; Gexp = Gabor(f0,sig2lam,gamma,theta,fi,n);
Gexp=Gexp./sum(sum(abs(Gexp))); %% normalization...
e2 = abs(conv2(Im,Gexp,'same'));
return;


%% Creates a non-normalized Gabor filter
function Gex = Gabor(f0,sig2lam,gamma,theta,fi,n),
sig2lam = 0.56; lambda = 2.*pi./f0; sig = sig2lam .* lambda;
if length(n)>1, nx=n(1);ny=n(2); else, nx=n; ny=n;end;
if mod(nx,2)>0,tx=-((nx-1)/2):(nx-1)/2;else,tx=-(nx/2):(nx/2-1);end;
if mod(ny,2)>0,ty=-((ny-1)/2):(ny-1)/2;else,ty=-(ny/2):(ny/2-1);end;
[X,Y]=meshgrid(tx,ty);
xte = X*cos(theta)+Y*sin(theta);
yte =-X*sin(theta)+Y*cos(theta);
rte = xte.^2 + (gamma.*yte).^2;
ge = exp(-rte./(2.*sig.^2));
argm = f0.*xte + fi;
Gex = ge .* exp(j.*argm);
return;


function outIMG = forceBW(inIMG,GRAYthr),outIMG = im2double(im2bw(inIMG,GRAYthr));return;
