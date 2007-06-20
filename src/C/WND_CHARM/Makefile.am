lib_LIBRARIES = libimfit.a
include_HEADERS = cmatrix.h signatures.h


libimfit_a_SOURCES = TrainingSet.cpp cmatrix.cpp signatures.cpp colors/FuzzyCalc.cpp  \
	transforms/chevishev.cpp transforms/ChebishevFourier.cpp  \
	transforms/wavelet/Symlet5.cpp transforms/wavelet/convolution.cpp \
	transforms/ChebishevFourier.cpp statistics/CombFirst4Moments.cpp \
	transforms/radon.cpp statistics/FeatureStatistics.cpp textures/gabor.cpp \
	textures/haarlick/haarlick.cpp textures/tamura.cpp textures/zernike/zernike.cpp \
	transforms/wavelet/DataGrid2D.cpp transforms/wavelet/Wavelet.cpp \
	transforms/wavelet/FilterSet.cpp transforms/wavelet/Filter.cpp transforms/wavelet/wt.cpp \
	transforms/wavelet/WaveletHigh.cpp transforms/wavelet/WaveletMedium.cpp transforms/wavelet/WaveletLow.cpp \
	transforms/wavelet/Symlet5.cpp textures/haarlick/CVIPtexture.cpp textures/zernike/complex.cpp 

AM_CPPFLAGS = -fPIC

bin_PROGRAMS=wndchrm

wndchrm_SOURCES = wndchrm.cpp

wndchrm_LDADD = -lm -ltiff -L. -limfit -lfftw3



