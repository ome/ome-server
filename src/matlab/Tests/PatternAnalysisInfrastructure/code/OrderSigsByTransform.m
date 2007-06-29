function [sigs_ordered_by_transform] = OrderSigsByTransform( sig_labels )
% SYNOPSIS
%	[sigs_ordered_by_transform] = sigReorder( sig_labels );
% DESCRIPTION
%	Order signatures primarilty the transform they were computed on.
% This currently has a hard-coded answer. 

if( length( sig_labels ) ~= 1025 )
	sigs_ordered_by_transform = [1:length( sig_labels )];
	return;
end;

sigs_ordered_by_transform = [ ...
... % Group A
417:444, ...  %   EdgeStatistics(ImageGradient((im)))
445:478, ...  %   FeatureStatistics(OtsuGlobalThreshold(im)))
479:485, ...  %   GaborTextureFilters((im))
... % Group B: Image
1:32,    ...  %   ChebyshevFourierTransform((im))
65:96,   ...  %   ChebyshevStatistics((im))
882:953, ...  %   mb_zernike((im))
... % Group B: FFT
33:64,   ...  %   ChebyshevFourierTransform(FourierTransform((im)))
97:128,  ...  %   ChebyshevStatistics(FourierTransform((im)))
954:1025, ... %   mb_zernike(FourierTransform((im)))
... % Group C: Image
486:513, ...  %   HaralickTexturesRI((im))
129:176, ...  %   CombFirst4Moments((im))
654:677, ...  %   MultiScaleHistograms((im))
846:851, ...  %   TamuraTextures((im))
798:809, ...  %   RadonTransform((im))
... % Group C: Wavelet
598:625, ...  %   HaralickTexturesRI(WaveletSignatures((im)))
321:368, ...  %   CombFirst4Moments(WaveletSignatures((im)))
750:773, ...  %   MultiScaleHistograms(WaveletSignatures((im)))
870:875, ...  %   TamuraTextures(WaveletSignatures((im)))
... % Group C: FFT
570:597, ...  %   HaralickTexturesRI(FourierTransform((im)))
273:320, ...  %   CombFirst4Moments(FourierTransform((im)))
726:749, ...  %   MultiScaleHistograms(FourierTransform((im)))
864:869, ...  %   TamuraTextures(FourierTransform((im)))
834:845, ...  %   RadonTransform(FourierTransform((im)))
... % Group C: Chebeshev
514:541, ...  %   HaralickTexturesRI(ChebyshevTransform((im)))
177:224, ...  %   CombFirst4Moments(ChebyshevTransform((im)))
678:701, ...  %   MultiScaleHistograms(ChebyshevTransform((im)))
852:857, ...  %   TamuraTextures(ChebyshevTransform((im)))
810:821, ...  %   RadonTransform(ChebyshevTransform((im)))
... % Group C: Wavelet( FFT )
626:653, ...  %   HaralickTexturesRI(WaveletSignatures(FourierTransform((im))))
369:416, ...  %   CombFirst4Moments(WaveletSignatures(FourierTransform((im))))
774:797, ...  %   MultiScaleHistograms(WaveletSignatures(FourierTransform((im))))
876:881  ...  %   TamuraTextures(WaveletSignatures(FourierTransform((im))))
... % Group C: Chebeshev( FFT )
542:569, ...  %   HaralickTexturesRI(ChebyshevTransform(FourierTransform((im))))
225:272, ...  %   CombFirst4Moments(ChebyshevTransform(FourierTransform((im))))
702:725, ...  %   MultiScaleHistograms(ChebyshevTransform(FourierTransform((im))))
858:863, ...  %   TamuraTextures(ChebyshevTransform(FourierTransform((im))))
822:833, ...  %   RadonTransform(ChebyshevTransform(FourierTransform((im))))
];
