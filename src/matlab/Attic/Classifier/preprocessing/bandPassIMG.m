% By Nikita Orlov 
% changed by T.Macura to fit with the classifier
% image im

function img = bandPassIMG(im)

% Step 1: reading from file
aa=normalizeImg(im2double(im));

%preprocessing, whatever...
%--------------------------------------------------------------------
bL = 10;

BP = makeBP(21);
cnvted=conv2(aa,BP,'same');
    % while working with sub-images we don't need mask
bpassed = cnvted;

bpassed = normalizeImg(bpassed);

bpassed = padd0(bpassed,bL);
bpassed(bpassed < 1.15*mean2(bpassed) ) = 0;
bpassed(bpassed > 0 ) = 1;
bpassed(bpassed < 1 ) = 0;
%--------------------------------------------------------------------

% output
img = bpassed.*255;
return;

function a0 = padd0(a,n)
a0=zeros(size(a)); a0(1+n:end-n,1+n:end-n)=a(1+n:end-n,1+n:end-n);
return;

function hLP = makeLP(varargin)
if nargin<1 | (nargin==1 & (varargin{1}>65 | varargin{1}<21)), 
 nn=31;
else,nn=varargin{1};
end
Hd2=ones(nn);[f1,f2]=freqspace(nn,'meshgrid'); r = sqrt(f1.^2 + f2.^2);
Hd2(r>0.01)=0;hLP=fwind1(Hd2,hamming(nn));
return;

function [mask,bL] = makemask(varargin)
aa=varargin{1};
if nargin>1,nn=varargin{2};
 LP = makeLP(nn);
else,
 LP = makeLP;
end
bL=round(min(size(LP))/2); if bL>10,bL=10;end
LP=conv2(aa,LP,'same'); LP = normalizeImg(LP);
[yy,xx]=find(LP>mean2(LP(bL:end-bL,bL:end-bL))*0.95);kk=convhull(xx,yy);xk=xx(kk);yk=yy(kk);
for ii=1:length(kk),mask(yk(ii),xk(ii))=1;end
    % retreave binary mask of area inside convex hull
[junk,mask]=roifill(aa,xk,yk); 
return;

function BP = makeBP(varargin)
if nargin<1 | (nargin==1 & (varargin{1}>35 | varargin{1}<11)), nn = 21;
else,nn=varargin{1};
end
Hd=ones(nn);[f1,f2]=freqspace(nn,'meshgrid'); r = sqrt(f1.^2 + f2.^2);
Hd((r<0.2)|(r>0.4)) = 0;BP = fwind1(Hd,hamming(21));
return;

function Nimg = normalizeImg(img)
img=img-min(img(:)); img=img./max(img(:)); Nimg = img;
return;
