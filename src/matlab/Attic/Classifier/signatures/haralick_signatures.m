%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% haralick signatures                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [sig, sig_id] = haralick_signatures(pixels)
	
haraf = mb_texture(uint8(pixels));

sig = [haraf(1:end-1, end); mean(haraf(1:end-1,1:end-1),2)];
sig_id = signature_id ('haralick_signatures.m');