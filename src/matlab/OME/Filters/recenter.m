function output_img = recenter(output_img, cutout_size);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% re-centering                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[hei len]    = size(output_img);
smaller_dim  = cutout_size; %min([hei len]);
output_img = [zeros(smaller_dim,len) ; output_img; zeros(smaller_dim,len)];   % heavily padding the edges %
output_img = [zeros(hei+2*smaller_dim,smaller_dim) output_img zeros(hei+2*smaller_dim,smaller_dim)];

y1 = mb_imgmoments(output_img,0,1)/mb_imgmoments(output_img,0,0);               % finding the center of mass
x1 = mb_imgmoments(output_img,1,0)/mb_imgmoments(output_img,0,0);

% removing everything outside a square defined to be the size of the smallest 
% side of the input image.
output_img = imcrop(output_img,[x1-smaller_dim/2  y1-smaller_dim/2 smaller_dim smaller_dim]);

return;
