use strict;
use warnings;
use OME::Factory;
use OME::SessionManager;
use OME::Tasks::OMEImport;

use Term::ANSIColor qw(:constants);

my @classifierFiles = ("OME/Analysis/Core/PixelIndicies.ome",
"OME/Analysis/Core/PixelSlices.ome",
"OME/Analysis/Core/PixelSliceModules.ome",
"OME/Analysis/Filters/HighPassFilter.ome",
"OME/Analysis/Filters/BandPassFilter.ome",
"OME/Analysis/Maths/Gradient.ome",
"OME/Analysis/Segmentation/GlobalThreshold.ome",
"OME/Analysis/Segmentation/OtsuGlobalThreshold.ome",
"OME/Analysis/Transforms/ChebyshevTransform.ome",
"OME/Analysis/Transforms/FourierTransform.ome",
"OME/Analysis/Transforms/WaveletSignatures.ome",
"OME/Analysis/Statistics/EdgeStatistics.ome",
"OME/Analysis/Statistics/FeatureStatistics.ome",
"OME/Analysis/Statistics/HaralickFeatures.ome",
"OME/Analysis/Statistics/ZernikeMoments.ome",
"OME/Analysis/Statistics/ChebyshevStatistics.ome",
"OME/Analysis/Statistics/ChebyshevFourierStatistics.ome",
"OME/Analysis/Classifier/SignatureStitcher.ome",
"OME/Analysis/Classifier/ClassificationStatistics.ome",
"OME/Analysis/Classifier/BayesNetTrainer.ome",
"OME/Analysis/Classifier/BayesNetClassifier.ome",
#"OME/Analysis/Classifier/TrainerChain.ome",
"OME/Analysis/Classifier/SignatureChain.ome");

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
