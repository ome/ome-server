use strict;
use XML::LibXML;
use Log::Agent;
use OME::SessionManager;
use OME::ImportEngine::ImportEngine;
use OME::Image::Server::File;

if( ! $ARGV[0] ) {
	print "Usage is:\n\t perl UberImport.pl [file1] [file2] ...\n";
	exit -1;
}
#
# Set OME_DEBUG environment variable to turn on debugging.
#
if ($ENV{OME_DEBUG} > 0) {
	logconfig(
		-prefix      => "$0",
		-level    => 'debug'
	);
}
my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $repository = $session->findRepository(); # make sure there is one, and its activated.
my $importer = OME::ImportEngine::ImportEngine->new (session => $session);
my @files;
foreach my $path (@ARGV) {
	print "Uploading to OMEIS: $path.\n";
	push @files, OME::Image::Server::File->upload($path);
}
print "Uploading to OME:".join(" ","",@files). "\n";
$importer->startImport();
$importer->importFiles(\@files);
$importer->finishImport();
