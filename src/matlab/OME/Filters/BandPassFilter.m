function [final_image] = BandPassFilter(si2)

% INPUTS NEEDED                 'si2'   - This is an input image as an XY array
%                                
%                               'res'   - the scale that you want the image to be reduced by before processing.
%                                       Enter a value between [0.0 1.0].  The motivation behind
%                                       scaling down is that doing so saves significant image
%                                       processing time.
%
% OUTPUT GIVEN                  'final_image'    - your image matrix
% INTRODUCTION                  
% Uses Nikita's preprocessing filters to enchance muscles 
% Tom Macura - 2004. tm289@cam.ac.uk
res =0.5;

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

% special Nikita sauce to pre-process images
smaller_img = uint8(bandPassIMG(smaller_img));

% orient image horizontally (uniform orientation critical to eigenface analysis)
final_image = imrotate(smaller_img,angle,'bicubic');
final_image = recenter(final_image, min_dimen*res);  % cut out center