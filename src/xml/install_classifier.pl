#!/usr/bin/perl

use strict;
use warnings;
use OME::Factory;
use OME::SessionManager;
use OME::Tasks::OMEImport;

use Term::ANSIColor qw(:constants);

my @classifierFiles = (
# Pre Feature Granularity Modules
#"OME/Analysis/Core/PixelIndicies.ome",  
#"OME/Analysis/Core/PixelSlices.ome",
#"OME/Analysis/Core/PixelSliceModules.ome",
#"OME/Analysis/Filters/HighPassFilter.ome",
#"OME/Analysis/Filters/BandPassFilter.ome",

# Tiling Trunk
"OME/Analysis/ROI/DerivedPixels.ome",
"OME/Analysis/ROI/ImageROIConstructors.ome",

# Modules for computing Edge Statistics
"OME/Analysis/Maths/Gradient.ome",

# Modules for computing Feature Statistics
"OME/Analysis/Segmentation/OtsuGlobalThreshold.ome",

# Transform Modules
"OME/Analysis/Transforms/FourierTransform.ome",
"OME/Analysis/Transforms/WaveletTransform.ome",
"OME/Analysis/Transforms/ChebyshevTransform.ome",

# Signature Modules
"OME/Analysis/Statistics/EdgeStatistics.ome",
"OME/Analysis/Statistics/ObjectStatistics.ome",
"OME/Analysis/Statistics/CombFirst4Moments.ome",            # new Nikita
"OME/Analysis/Statistics/ZernikePolynomials.ome",
"OME/Analysis/Statistics/ChebyshevFourierStatistics.ome",
"OME/Analysis/Statistics/ChebyshevStatistics.ome",
"OME/Analysis/Statistics/HaralickTextures.ome",
"OME/Analysis/Statistics/RadonTransformStatistics.ome",     # new Nikita
"OME/Analysis/Statistics/MultiScaleHistograms.ome",         # new Nikita
"OME/Analysis/Statistics/TamuraTextures.ome",               # new Nikita
"OME/Analysis/Statistics/GaborTextures.ome",        		# new Nikita

# Useful Chains
"OME/Analysis/Classifier/FeatureExtractionChain.ome",
"OME/Analysis/Classifier/WND-CHARM-SemanticTypes.ome",
);

my $session = OME::SessionManager->TTYlogin();
my $factory = $session->Factory();
my $omeImport = OME::Tasks::OMEImport->new(
	session => $session,
	# XXX: Debugging off.
	#debug => 1
);

foreach my $filename (@classifierFiles) {
	print "  \\__ $filename ";
	
	eval {
		$omeImport->importFile($filename, NoDuplicates => 1);
	};

	print BOLD, "[FAILURE]", RESET, ".\n"
		and print "ERROR LOADING XML FILE \"$filename\" -- OUTPUT: \"$@\"\n"
		and die
	if $@;

	print BOLD, "[SUCCESS]", RESET, ".\n";
	
}

$session->commitTransaction();
