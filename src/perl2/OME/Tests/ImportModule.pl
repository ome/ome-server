use strict;
use OME::Tasks::ProgramImport;
use OME::SessionManager;

if (scalar(@ARGV) != 1) {
    print "Usage:  ImportModule <path to XML spec>\n\n";
    exit -1;
}

my $session = OME::SessionManager->TTYlogin();


my $newPrograms = OME::Tasks::ProgramImport->importXMLFile( $session, $ARGV[0] );

print "Imported ".scalar(@$newPrograms)." of 2 progams sucessfully.\n";

print "\n";
