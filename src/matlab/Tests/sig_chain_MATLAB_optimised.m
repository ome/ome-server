% [1-32]       EXACT  ChebyshevFourierTransform((im))
% [33-64]      EXACT  ChebyshevFourierTransform(FourierTransform((im)))
% [65-96]      EXACT  ChebyshevStatistics((im))
% [97-128]     EXACT  ChebyshevStatistics(FourierTransform((im)))
% [129-176]    EXACT  CombFirst4Moments((im))
% [177-224]    EXACT  CombFirst4Moments(ChebyshevTransform((im)))
% [225-272]    EXACT  CombFirst4Moments(ChebyshevTransform(FourierTransform((im))))
% [273-320]    EXACT  CombFirst4Moments(FourierTransform((im)))
% [321-368]    EXACT  CombFirst4Moments(WaveletSignatures((im)))
% [369-416]    EXACT  CombFirst4Moments(WaveletSignatures(FourierTransform((im))))
% [417-444]    10^-12 <15, 15.8> EdgeStatistics(ImageGradient((im)))
% [445-478]    10^-12 <15, 15.8> FeatureStatistics(GlobalThreshold(graythresh((im))))
% [479-485]    EXACT  GaborTextureFilters((im))
% [486-513]    10^-3  <5, 6.89> HaralickTexturesRI((im))
% [514-541]    10^-6  <5, 6.89> HaralickTexturesRI(ChebyshevTransform((im)))
% [542-569]    10^-3  <5, 6.89> HaralickTexturesRI(ChebyshevTransform(FourierTransform((im))))
% [570-597]    10^-3  <5, 6.89> HaralickTexturesRI(FourierTransform((im)))
% [598-625]    10^-3 <5, 6.89> HaralickTexturesRI(WaveletSignatures((im)))
% [626-653]    10^-3 <5, 6.89> HaralickTexturesRI(WaveletSignatures(FourierTransform((im))))
% [654-677]    10^-7 <6, 8.95> MultiScaleHistograms((im))
% [678-701]    10^-7 <6, 8.95> MultiScaleHistograms(ChebyshevTransform((im)))
% [702-725]    10^-7 <6, 8.95> MultiScaleHistograms(ChebyshevTransform(FourierTransform((im))))
% [726-749]    10^-9 <6, 8.95> MultiScaleHistograms(FourierTransform((im)))
% [750-773]    10^-7 <6, 8.95> MultiScaleHistograms(WaveletSignatures((im)))
% [774-797]    10^-7 <6, 8.95> MultiScaleHistograms(WaveletSignatures(FourierTransform((im))))
% [798-809]    EXACT RadonTransform((im))
% [810-821]    EXACT RadonTransform(ChebyshevTransform((im)))
% [822-833]    EXACT RadonTransform(ChebyshevTransform(FourierTransform((im))))
% [834-845]    EXACT RadonTransform(FourierTransform((im)))
% [846-851]    10^-6 <6, 9.69> TamuraTextures((im))
% [852-857]    10^-6 <6, 9.69> TamuraTextures(ChebyshevTransform((im)))
% [858-863]    10^-3 <6, 9.69> TamuraTextures(ChebyshevTransform(FourierTransform((im))))
% [864-869]    10^0  <6, 9.69> TamuraTextures(FourierTransform((im)))
% [870-875]    10^-4 <6, 9.69> TamuraTextures(WaveletSignatures((im)))
% [876-881]    10^-1 <6, 9.69> TamuraTextures(WaveletSignatures(FourierTransform((im))))
% [882-953]    10^-17 <16, 16> mb_zernike((im))
% [954-1025]   10^-17 <16, 16> mb_zernike(FourierTransform((im)))

function [signature_vector] = sig_chain_MATLAB_optimised (im); 

FrequencySpace2Pixels_FourierTransform_single_im = FrequencySpace2Pixels(FourierTransform(single(im)));
ChebyshevTransform_single_im = ChebyshevTransform(single(im));
ChebyshevTransform_FrequencySpace2Pixels_FourierTransform_single_im = ChebyshevTransform(FrequencySpace2Pixels_FourierTransform_single_im);
WaveletSelector_WaveletSignatures_single_im = WaveletSelector(WaveletSignatures(single(im)));
WaveletSelector_WaveletSignatures_FrequencySpace2Pixels_FourierTransform_single_im = WaveletSelector(WaveletSignatures(FrequencySpace2Pixels_FourierTransform_single_im));

% single conversion per XML execution instructions
vec_0 = concat_outputs (ChebyshevFourierTransform(im));
vec_1 = concat_outputs (ChebyshevFourierTransform(FrequencySpace2Pixels_FourierTransform_single_im));
vec_2 = concat_outputs (ChebyshevStatistics(single(im)));
vec_3 = concat_outputs (ChebyshevStatistics(FrequencySpace2Pixels_FourierTransform_single_im));

vec_4 = vd_Comb4Moments(concat_outputs (CombFirst4Moments(single(im))));
vec_5 = vd_Comb4Moments(concat_outputs (CombFirst4Moments(ChebyshevTransform_single_im)));
vec_6 = vd_Comb4Moments(concat_outputs (CombFirst4Moments(ChebyshevTransform_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_7 = vd_Comb4Moments(concat_outputs (CombFirst4Moments(FrequencySpace2Pixels_FourierTransform_single_im)));
vec_8 = vd_Comb4Moments(concat_outputs (CombFirst4Moments(WaveletSelector_WaveletSignatures_single_im)));
vec_9 = vd_Comb4Moments(concat_outputs (CombFirst4Moments(WaveletSelector_WaveletSignatures_FrequencySpace2Pixels_FourierTransform_single_im)));

[EdgeArea,MagMean,MagMedian,MagVar,MagHist, DirecMean, DirecMedian,DirecVar,DirecHist,DirecHomo,DiffDirecHist] = EdgeStatistics(double(single(ImageGradient(single(im)))));
vec_10 = ro_EdgeStatistics(EdgeArea,MagMean,MagMedian,MagVar,MagHist, DirecMean, DirecMedian,DirecVar,DirecHist,DirecHomo,DiffDirecHist);

[Count, Euler, Centroid, AreaMin, AreaMax, AreaMean, AreaMedian, AreaVar, AreaHist, DistMin, DistMax, DistMean, DistMedian, DistVar, DistHist] = FeatureStatistics(logical(GlobalThreshold(im, graythresh(im))));
vec_11 = ro_FeatureStatistics(Count, Euler, Centroid, AreaMin, AreaMax, AreaMean, AreaMedian, AreaVar, AreaHist, DistMin, DistMax, DistMean, DistMedian, DistVar, DistHist);

vec_12 = concat_outputs (GaborTextureFilters(single(im)));

vec_13 = vd_HaralickTexturesRI(concat_outputs (HaralickTexturesRI(im)));
vec_14 = vd_HaralickTexturesRI(concat_outputs (HaralickTexturesRI(ChebyshevTransform_single_im)));
vec_15 = vd_HaralickTexturesRI(concat_outputs (HaralickTexturesRI(ChebyshevTransform_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_16 = vd_HaralickTexturesRI(concat_outputs (HaralickTexturesRI(FrequencySpace2Pixels_FourierTransform_single_im)));
vec_17 = vd_HaralickTexturesRI(concat_outputs (HaralickTexturesRI(WaveletSelector_WaveletSignatures_single_im)));
vec_18 = vd_HaralickTexturesRI(concat_outputs (HaralickTexturesRI(WaveletSelector_WaveletSignatures_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_19 = concat_outputs (single(MultiScaleHistograms(single(im))));
vec_20 = concat_outputs (MultiScaleHistograms(single(ChebyshevTransform_single_im)));
vec_21 = concat_outputs (MultiScaleHistograms(single(ChebyshevTransform_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_22 = concat_outputs (MultiScaleHistograms(single(FrequencySpace2Pixels_FourierTransform_single_im)));
vec_23 = concat_outputs (MultiScaleHistograms(single(WaveletSelector_WaveletSignatures_single_im)));
vec_24 = concat_outputs (MultiScaleHistograms(single(WaveletSelector_WaveletSignatures_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_25 = vd_RadonTextures(concat_outputs (RadonTransform(im)));
vec_26 = vd_RadonTextures(concat_outputs (RadonTransform(ChebyshevTransform_single_im)));
vec_27 = vd_RadonTextures(concat_outputs (RadonTransform(ChebyshevTransform_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_28 = vd_RadonTextures(concat_outputs (RadonTransform(FrequencySpace2Pixels_FourierTransform_single_im)));
vec_29 = vd_TamuraTextures(concat_outputs (TamuraTextures(im)));
vec_30 = vd_TamuraTextures(concat_outputs (TamuraTextures(ChebyshevTransform_single_im)));
vec_31 = vd_TamuraTextures(concat_outputs (TamuraTextures(ChebyshevTransform_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_32 = vd_TamuraTextures(concat_outputs (TamuraTextures(FrequencySpace2Pixels_FourierTransform_single_im)));
vec_33 = vd_TamuraTextures(concat_outputs (TamuraTextures(WaveletSelector_WaveletSignatures_single_im)));
vec_34 = vd_TamuraTextures(concat_outputs (TamuraTextures(WaveletSelector_WaveletSignatures_FrequencySpace2Pixels_FourierTransform_single_im)));
vec_35 = concat_outputs (mb_zernike((im)));
vec_36 = concat_outputs (mb_zernike(FrequencySpace2Pixels_FourierTransform_single_im));

signature_vector = [double(vec_0) vec_1 vec_2 vec_3 vec_4 vec_5 vec_6 vec_7 vec_8 vec_9 vec_10 vec_11 vec_12 vec_13 vec_14 vec_15 vec_16 vec_17 vec_18 vec_19 vec_20 vec_21 vec_22 vec_23 vec_24 vec_25 vec_26 vec_27 vec_28 vec_29 vec_30 vec_31 vec_32 vec_33 vec_34 vec_35 vec_36 ];
%
% MATLAB implementation of required typecaster modules
%
function pix = FrequencySpace2Pixels(fs)
pix = single(fs(:,:,1)); % the single is cause OMEIS doesn't support doubles
 
function wav_result = WaveletSelector(wav1, wav2)
wav_result = wav1; % the single is cause OMEIS doesn't support doubles

%
% MATLAB implementation of certain module's vector decoder (from execution instructions)
%
function out = vd_Comb4Moments(in)
out = [in(46) in(47) in(48) in(37) in(38) in(39) in(43) in(44) in(45) in(40) in(41) in(42) ...
   in(34) in(35) in(36) in(25) in(26) in(27) in(31) in(32) in(33) in(28) in(29) in(30) ...
   in(10) in(11) in(12) in(1) in(2) in(3) in(7) in(8) in(9) in(4) in(5) in(6) ...
   in(22) in(23) in(24) in(13) in(14) in(15) in(19) in(20) in(21) in(16) in(17) in(18)];
   
function out = ro_EdgeStatistics(EdgeArea, MagMean, MagMedian, MagVar, MagHist, DirecMean, DirecMedian, DirecVar, DirecHist, DirecHomogeneity, DiffDirecHist)
out = [double(EdgeArea) double(DiffDirecHist) double(DirecHist) double(DirecHomogeneity)...
	   double(DirecMean) double(DirecMedian) double(DirecVar) double(MagHist) double(MagMean) double(MagMedian) double(MagVar)];

function out = ro_FeatureStatistics(Count, Euler, Centroid, AreaMin, AreaMax, AreaMean, AreaMedian, AreaVar, AreaHist, DistMin, DistMax, DistMean, DistMedian, DistVar, DistHist)
out = [double(AreaHist) double(AreaMax) double(AreaMean) double(AreaMedian) ...
	   double(AreaMin) double(AreaVar) double(Centroid) double(Count) double(DistHist) ...
	   double(DistMax) double(DistMean) double(DistMedian) double(DistMin) double(DistVar) double(Euler)];
	   
function out = vd_HaralickTexturesRI(in)
out = [in(1) in(15) in(2) in(16) in(3) in(17) in(10) in(24) in(11) in(25) in(9) in(23) ...
   in(12) in(26) in(5) in(19) in(14) in(28) in(13) in(27) in(6) in(20) in(8) in(22) ...
   in(7) in(21) in(4) in(18)];

function out = vd_RadonTextures(in)
out = [in(1) in(2) in(3) in(10) in(11) in(12) in(4) in(5) in(6) in(7) in(8) in(9)];

function out = vd_TamuraTextures(in)
out = [in(2) in(3) in(4) in(6) in(5) in(1)];

%
% helper function combines multiple function outputs into a single output vector
%
function concat = concat_outputs (varargin)
N = nargin;
concat = [];
for i=1:N
	vec = varargin{i};
	% some vectors are row-oriented others are column-oriented.
	% This fixes them all to be row oriented
	vec = vec(:)';
	concat = [concat vec];
end
concat = double(concat);