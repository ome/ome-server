use strict;
use OME::Tasks::ProgramImport;
use OME::SessionManager;

my $session = OME::SessionManager->TTYlogin();
if (scalar(@ARGV) != 1) {
    print "Usage:  ImportModule <path to XML spec>\n\n";
    exit -1;
}

OME::Tasks::ProgramImport->importXMLFile( $session, $ARGV[0] );

print "\n";
