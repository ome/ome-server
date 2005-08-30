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


%% Tamura texture signatures: coarseness, directionality, contrast 
%%
%% Reference: Tamura H., Mori S., Yamawaki T., 
%% 'Textural features corresponsing to visual perception'. 
%% IEEE Trans. on Systems, Man and Cybernetics, 8, 1978, 460-472
%% 
%% Nikita Orlov
%% Computational Biology Unit, LG,NIA/NIH
%% :: revision :: 07-20-2005
%% 
%% input:   Img (input image)
%% output1: Total coarseness,       a scalar
%% output2: Coarseness histogram,   a 1x3 vector
%% output3: Directionality,         a scalar
%% output4: Contrast,               a scalar
%% 
%% Examples:
%% allTFeatures = Tamura3Sigs(Im);
%% 
function allTFeatures = Tamura3Sigs(Im)
if ~isa(Im,'double'),Im = im2double(Im);end

[TM_Coarseness,TM_Coarseness_hist] = Tamura_Coarseness(Im);
TM_Directionality = Tamura_Directionality(Im);
TM_Contrast = Tamura_Contrast(Im);

allTFeatures = [TM_Coarseness TM_Coarseness_hist TM_Directionality TM_Contrast];

return;


function Fdir = Tamura_Directionality(Im),
[gx,gy] = gradient(Im); [t,r] = cart2pol(gx,gy);
nbins = 125;
r(r<.15.*max(r(:))) = 0; 
t0 = t; t0(abs(r)<1e-4) = 0;
r = r(:)'; t0 = t0(:)'; 
Hd = hist(t0,nbins); 
nrm = hist(r(:).^2+t0(:).^2,nbins); 
fmx = find(Hd==max(Hd));
ff  = 1:length(Hd); ff2 = (ff - fmx).^2; 
Fdir = sum(Hd.*ff2)./sum(nrm);
Fdir = abs(log(Fdir+eps));
return;


function Fc = Tamura_Contrast(Im), Im = Im(:)';
ss = std(Im); if abs(ss)<1e-10, Fc = 0;return; else, k = kurtosis(Im);end
alf = k ./ ss.^4;
Fc = ss./(alf.^(.25));
return;


function [total_coarseness,coarseness_hist] = Tamura_Coarseness(Im), 
kk = 0:6; %nh = []; nv = [];
for ii = 1:kk(end),
 A = moveav(Im,2.^(kk(ii)));
 shift = 200;
 shift = 2.^(kk(ii));
 implus = zeros(size(A)); implus(:,1:end-shift+1) = A(:,shift:end);
 iminus = zeros(size(A)); iminus(:,shift:end) = A(:,1:end-shift+1);
 Hdelta(:,:,ii) = abs(implus-iminus);
 implus = zeros(size(A)); implus(1:end-shift+1,:) = A(shift:end,:);
 iminus = zeros(size(A)); iminus(shift:end,:) = A(1:end-shift+1,:);
 Vdelta(:,:,ii) = abs(implus-iminus);
end
HdeltaMax = max(Hdelta,[],3); hs = sum(HdeltaMax(:));
VdeltaMax = max(Vdelta,[],3); vs = sum(VdeltaMax(:));
hij = reshape(Hdelta,size(Hdelta,1)*size(Hdelta,2),size(Hdelta,3)); %shij = sum(hij,1);
vij = reshape(Vdelta,size(Vdelta,1)*size(Vdelta,2),size(Vdelta,3)); %svij = sum(vij,1);
newh = zeros(size(hij,1),1); 
for ii = 1:size(hij,1),
 tmp1 = hij(ii,:); tmp2 = vij(ii,:); 
 mtmp1 = max(tmp1); mtmp2 = max(tmp2); mtmp1 = mtmp1(1); mtmp2 = mtmp2(1);
 mm = max(mtmp1,mtmp2);
 im1 = find(tmp1==mtmp1); im2 = find(tmp2==mtmp2); 
 if mm == mtmp1, imm = im1(1); else, imm = im2(1); end
 newh(ii) = kk(imm);
end
total_coarseness = mean(newh);
newh = reshape(2.^newh,size(Im,1),size(Im,2));
nbin = 3;
coarseness_hist = hist(newh(:),nbin);
%coarseness_hist = coarseness_hist./max(coarseness_hist);
coarseness_hist = uint16(coarseness_hist);
return;

function sm = moveav(Im,nk),
kern = ones(nk)./nk.^2; sm = conv2(Im,kern,'same');
return;

