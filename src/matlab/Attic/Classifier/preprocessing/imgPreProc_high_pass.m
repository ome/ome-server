function [final_image] = imgPreProc_high_pass(si2)

% INPUTS NEEDED  'si2'  - input image as an XY array 
%                 
%                'res'   - the scale that you want the image to be reduced by before 
%				  processing. Enter a value between [0.0 1.0].  The motivation behind
%                 scaling down is that doing so saves significant image
%                 processing time.
%
% OUTPUT GIVEN                  'final_image'    - your image matrix
% INTRODUCTION                  
%
% Tom Macura - 2004. tm289@cam.ac.uk
res=0.5;
[width,height] = size(si2);
min_dimen = min(width,height);

% scale down images as appropriate
if (res ~= 1)
    smaller_img = imresize(si2,1.5*res,'bicubic'); % scaling down image but under do it by 50% to be able to rotate
else
    smaller_img = si2;
end

% find orienation angle
angle = findOrientationAngle(smaller_img);

% special Tomasz sauce to pre-process images
smaller_img = short_treat(smaller_img);

% orient image horizontally (uniform orientation critical to eigenface analysis)
final_image = imrotate(smaller_img,angle,'bicubic');
final_image = recenter(final_image, min_dimen*res); % cut out center 600 by 600

return

%
% Here is where the pre-processing happens 
%
function imfile = short_treat(imfile);

imfile = double(imfile);
imfile = uint8(imfile ./ max(max(imfile)) .* 255);

imfile = anisodiff(imfile,3,40,.15,1);

lap = fspecial('laplacian',0.5);
imfile = conv2(imfile,lap);

imfile = anisodiff(imfile,3,40,.15,1);
imfile = imfile ./ max(max(imfile)) ; % image has range 0-1
imfile = uint8(imfile .* 255);  % image has range 0-255
imfile = histeq(imfile);
imfile = anisodiff(imfile,3,40,.15,2);

% skip 5 pixels around the image. These pixels were compromised during the
% image convolution process
skip = 3;
[hei,len] = size(imfile);
imfile = imfile(skip:(hei-skip), skip:(len-skip));


% convert to from 12 bits to 8
imfile = double(imfile);
imfile = imfile - min(min(imfile));
imfile = imfile ./ max(max(imfile)) ; % image has range 0-1
imfile = uint8(imfile .* 255);  % image has range 0-255

lambda = 4;
sigma = 1;
rho = 2;
m = 10;
stepsize = 0.15;
nosteps = 3;
return;