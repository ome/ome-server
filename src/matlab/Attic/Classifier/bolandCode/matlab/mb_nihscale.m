function scaledimage = nihscale(image)
% nihscale(image)
% scales the pixel values of an image to make it like an nih image
% with 256 grey levels
%
% W. Dirks, 1998
%

% $Id$

        s = image * 253/(max(max(image))-min(min(image)))+1;
        s = s/255;

scaledimage = s;

