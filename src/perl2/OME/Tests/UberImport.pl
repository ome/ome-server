use strict;
use OME::Tasks::OMEImport;
use OME::SessionManager;
use XML::LibXML;
use Log::Agent;
if( ! $ARGV[0] ) {
	print "Usage is:\n\t perl UberImport.pl [file1] [file2] ...\n";
	exit -1;
}
#
# Set OME_DEBUG environment variable to turn on debugging.
#
if ($ENV{OME_DEBUG} > 0) {
#	print 'Debugging output enabled';
#	logconfig(
#		-driver    => Log::Agent::Driver::File->make(
#			-prefix      => '$0',
#			-showpid     => 1,
#			-channels    => {
#	#			 'error'  => '/OME/Logs/OME.err',
#	#			 'output' => '/OME/Logs/OME.out',
#				 'debug'  => "$0.dbg",
#			}
#		),
#	# for now, debug output is on.
#		-level    => 'debug'
#	);
	
	logconfig(
		-prefix      => "$0",
		-level    => 'debug'
	);
}

my $session = OME::SessionManager->TTYlogin();
#$session->DBH()->trace(3);
my $OMEImporter = OME::Tasks::OMEImport->new( session => $session, debug => 1 );

foreach my $path (@ARGV) {
	print "\n\nImporting $path.\n";
	$OMEImporter->importFile( $path );
}

