use strict;
use warnings;
use OME::Factory;
use OME::SessionManager;
use OME::Tasks::OMEImport;

use Term::ANSIColor qw(:constants);

my @nucleiiCounterFiles = (
"OME/Analysis/Filters/HaematoxylinEosinColourDeconvolution.ome",
"OME/Analysis/HaematoxylinEosinStainedNucleiiCounter.xml",

);

my $session = OME::SessionManager->TTYlogin();
my $factory = $session->Factory();
my $omeImport = OME::Tasks::OMEImport->new(
	session => $session,
	# XXX: Debugging off.
	#debug => 1
);

foreach my $filename (@nucleiiCounterFiles) {
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
