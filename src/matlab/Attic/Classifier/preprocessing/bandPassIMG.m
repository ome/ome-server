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

function w = hamming(varargin)
error(nargchk(1,2,nargin));
[w,msg] = gencoswin('hamming',varargin{:});
error(msg);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [w,msg] = gencoswin(varargin)
%GENCOSWIN   Returns one of the generalized cosine windows.
%   GENCOSWIN returns the generalized cosine window specified by the 
%   first string argument. Its inputs can be
%     Window name    - a string, any of 'hamming', 'hann', 'blackman'.
%     N              - length of the window desired.
%     Sampling flag  - optional string, one of 'symmetric', 'periodic'. 

%   Copyright 1988-2002 The MathWorks, Inc.
%   $Revision$  $Date$ 

% Parse the inputs
window = varargin{1};
n = varargin{2};
msg = '';

% Check for trivial orders
[n,w,trivialwin] = check_order(n);
if trivialwin, return, end;

% Select the sampling option
if nargin == 2, % no sampling flag specified, use default. 
    sflag = 'symmetric';
else
    sflag = lower(varargin{3});
end

% Allow partial strings for sampling options
allsflags = {'symmetric','periodic'};
sflagindex = strmatch(sflag, allsflags);
if length(sflagindex)~=1         % catch 0 or 2 matches
    msg = 'Sampling flag must be either ''symmetric'' or ''periodic''.';
    return;
else
    sflag = allsflags{sflagindex};
end

% Evaluate the window
switch sflag
case 'periodic'
    w = sym_window(n+1,window);
    w(end) = [];
case 'symmetric'
    w = sym_window(n,window);
end

%---------------------------------------------------------------------
function w = sym_window(n,window)
%SYM_WINDOW   Symmetric generalized cosine window.
%   SYM_WINDOW Returns an exactly symmetric N point generalized cosine 
%   window by evaluating the first half and then flipping the same samples
%   over the other half.

if ~rem(n,2)
    % Even length window
    half = n/2;
    w = calc_window(half,n,window);
    w = [w; w(end:-1:1)];
else
    % Odd length window
    half = (n+1)/2;
    w = calc_window(half,n,window);
    w = [w; w(end-1:-1:1)];
end

%---------------------------------------------------------------------
function w = calc_window(m,n,window)
%CALC_WINDOW   Calculate the generalized cosine window samples.
%   CALC_WINDOW Calculates and returns the first M points of an N point
%   generalized cosine window determined by the 'window' string.

% For the hamming and blackman windows we force rounding in order to achieve
% better numerical properties.  For example, the end points of the hamming 
% window should be exactly 0.08.

switch window
case 'hann'
    % Hann window
    %    w = 0.5 * (1 - cos(2*pi*(0:m-1)'/(n-1))); 
    a0 = 0.5;
    a1 = 0.5;
    a2 = 0;
    a3 = 0;
    a4 = 0;
case 'hamming'
    % Hamming window
    %    w = (54 - 46*cos(2*pi*(0:m-1)'/(n-1)))/100;
    a0 = 0.54;
    a1 = 0.46;
    a2 = 0;
    a3 = 0;
    a4 = 0;
case 'blackman'
    % Blackman window
    %    w = (42 - 50*cos(2*pi*(0:m-1)/(n-1)) + 8*cos(4*pi*(0:m-1)/(n-1)))'/100;
    a0 = 0.42;
    a1 = 0.5;
    a2 = 0.08;
    a3 = 0;
    a4 = 0;
case 'flattopwin'
    % Flattop window
    % Original coefficients as defined in the reference (see flattopwin.m);
    % a0 = 1;
    % a1 = 1.93;
    % a2 = 1.29;
    % a3 = 0.388;
    % a4 = 0.032;
    %
    % Scaled by (a0+a1+a2+a3+a4)
    a0 = 0.2156;
    a1 = 0.4160;
    a2 = 0.2781;
    a3 = 0.0836;
    a4 = 0.0069;
end

x = (0:m-1)'/(n-1);
w = a0 - a1*cos(2*pi*x) + a2*cos(4*pi*x) - a3*cos(6*pi*x) + a4*cos(8*pi*x);
return;
