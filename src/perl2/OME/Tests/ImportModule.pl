use strict;
use OME::Tasks::ProgramImport;
use OME::SessionManager;

if (scalar(@ARGV) < 1 ) {
    print STDERR "Usage:  ImportModule [path to XML spec, path2, path3, ...]\n\n";
    exit -1;
}

my $session = OME::SessionManager->TTYlogin();
my $programImport = OME::Tasks::ProgramImport->new( 
	session => $session,
	debug   => 2
);

my $totalPrograms=0;
foreach (@ARGV) {
	print STDERR "Importing $_...\n";
	my $newPrograms;
	eval {
		$newPrograms = $programImport->importXMLFile( $_ );
	};
	print STDERR "Import failed on $_\nError message:\n$@\n"
		if $@;
	print STDERR "Imported ".scalar(@$newPrograms)." progams sucessfully.\n"
		unless $@;
	$totalPrograms += scalar(@$newPrograms)
		unless not defined $newPrograms;
}
print STDERR "\nImported $totalPrograms modules from ".scalar(@ARGV)." files.";

print STDERR "\n";
