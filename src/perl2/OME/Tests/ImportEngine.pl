#!/usr/bin/perl -w

use OME::SessionManager;
use OME::Session;
use OME::Factory;
use OME::ImportEngine::ImportEngine;

use Getopt::Long;
Getopt::Long::Configure("bundling");

my $reuse = '';

GetOptions('reimport|r!' => \$reuse);

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

if( scalar @ARGV eq 0 ) {
	print STDERR "Incorrect usage. Usage is\n\t ImporEngine.pl file1 file2 file3 ...\n";
	exit -1;
}

my %opts = (session => $session);
$opts{AllowDuplicates} = 1 if $reuse;

print "Importing @ARGV\n";
OME::ImportEngine::ImportEngine->
  importFiles(%opts,
              \@ARGV);
