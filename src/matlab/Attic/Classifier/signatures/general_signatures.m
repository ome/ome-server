% Comment: In the past, images that are essentially blank were assigned a zero vector for
% a signature vector. This is no longer the case.

function [sig, sig_id] = general_signatures(pixels)

img_feat = mb_imgfeaturesLAD1(pixels);

level = graythresh(pixels);
bw = im2bw(pixels,level);
[lab num] = bwlabel(bw,4);                  % num = how many 'blobs' are there
idata = regionprops(lab,'basic');
histo = hist([idata.Area],10);              % histogram of the binary image, based on 'blob' size
meany = mean([idata.Area]);                 % average blob size
myf = [num histo meany];    

sig = [img_feat'; myf'];
sig_id = signature_id ("general_signatures.m");