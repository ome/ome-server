use strict;
use OME::Tasks::OMEImport;
use OME::SessionManager;
use XML::LibXML;

if( ! $ARGV[0] ) {
	print "Usage is:\n\t perl UberImport.pl [file1] [file2] ...\n";
	exit -1;
}

my $session = OME::SessionManager->TTYlogin();
my $OMEImporter = OME::Tasks::OMEImport->new( session => $session, debug => 1 );

map( $OMEImporter->importFile( $_ ), @ARGV );

