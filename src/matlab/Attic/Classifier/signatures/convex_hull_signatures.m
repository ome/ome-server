%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convex hull signatures                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [sig, sig_id] = convex_hull_signatures(pixels);

level = graythresh(pixels);
bw = im2bw(pixels,level);
	
% this was an unholy mess to put together.  The problem is that you can't
% just use your original binary mask - think about making a convex hull of the star of david
% using only 6 points.  So you need to generate a hull and then fill it in to look like the
% mask.  SEE imgPreProc4 (I put code there)

[hei len] = size(bw);                           % the old binary mask from up top
[xc yc] = find(bw);                             % figure out where the mask lives on the image
k = convhull(xc,yc);                            % construct the convex hull
bw2 = poly2mask(yc(k),xc(k),hei,len);           % now convert it back into a binary image
[junk hullf] = mb_hullfeatures(subject_image,bw2);   % Boland has done it again

sig = [haraf(1:end-1, end); mean(haraf(1:end-1,1:end-1),2)];
sig_id = signature_id ('haralick_signatures.m');