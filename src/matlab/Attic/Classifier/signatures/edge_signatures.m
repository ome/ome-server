function [sig, sig_id] = edge_signatures(pixels)

[junk edgef] = mb_imgedgefeatures(pixels);   % Michael Boland Baby

sig = [edgef'];
sig_id = signature_id('edge_signatures.m');
