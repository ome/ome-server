#!/usr/bin/perl -w

use OME::SessionManager;
use OME::Session;
use OME::Factory;
use OME::ImportEngine::ImportEngine;
#OME::DBObject->Caching(1);

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

$session->BenchmarkTimer->start ('Total');
if( scalar @ARGV eq 0 ) {
	print STDERR "Incorrect usage. Usage is\n\t ImporEngine.pl file1 file2 file3 ...\n";
	exit -1;
}

print "Importing @ARGV\n";
OME::ImportEngine::ImportEngine->
  importFiles(session => $session,
              \@ARGV);
$session->BenchmarkTimer->stop ('Total');

$session->BenchmarkTimer->report(); 

