use strict;
use OME::Tasks::ProgramImport;
use OME::SessionManager;

if (scalar(@ARGV) != 1) {
    print "Usage:  ImportModule <path to XML spec>\n\n";
    exit -1;
}

my $session = OME::SessionManager->TTYlogin();
my $programImport = OME::Tasks::ProgramImport->new( 
	session => $session,
	debug   => 2
);

my $newPrograms = $programImport->importXMLFile( $ARGV[0] );

print "Imported ".scalar(@$newPrograms)." progams sucessfully.\n";

print "\n";
