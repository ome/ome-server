#!/usr/bin/perl -w

use OME::SessionManager;
use OME::Session;
use OME::Factory;
use OME::ImportEngine::ImportEngine;
use OME::Analysis::Engine;

use OME::LocalFile;
use OME::Image::Server::File;
use OME::Tasks::PixelsManager;

use Getopt::Long;
Getopt::Long::Configure("bundling");

my $reuse = '';
my $verbose = 0;
my $skip_chain = 0;

GetOptions('reimport|r!' => \$reuse,
           'verbose|v+' => \$verbose,
           'skip-chain|s!' => \$skip_chain);

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

if( scalar @ARGV eq 0 ) {
	print STDERR "Incorrect usage. Usage is\n\t ImporEngine.pl file1 file2 file3 ...\n";
	exit -1;
}

my $repository = $factory->findAttribute('Repository');

my %opts = (session => $session);
$opts{AllowDuplicates} = 1 if $reuse;

my @files;

my $chain;

if ($repository->IsLocal()) {
    @files = map { OME::LocalFile->new($_) } @ARGV;
    $chain = $session->Configuration()->import_chain();
} else {
    $chain = $factory->
      findObject('OME::AnalysisChain',
                 name => 'Image server stats');
    $OME::Image::Server::SHOW_CALLS = 1 if $verbose > 0;
    $OME::Image::Server::SHOW_READS = 1 if $verbose > 1;
    OME::Tasks::PixelsManager->activateRepository($repository);
    print "Uploading original files to image server\n";
    foreach my $filename (@ARGV) {
        my $file;
        if ($filename =~ /^\:([0-9]+)$/) {
            $file = OME::Image::Server::File->new($1);
        } else {
            $file = OME::Image::Server::File->upload($filename);
        }
        push @files, $file;
        print "  $filename\n    ",$file->getFileID(),", size ",$file->getLength(),"\n";
    }
}

print "Importing files\n";
my $importer = OME::ImportEngine::ImportEngine->new(%opts);
my ($dataset,$global_mex) = $importer->startImport();
my $image_list = $importer->importFiles(\@files);
$importer->finishImport();


if (!$skip_chain && (scalar(@$image_list) > 0)) {
    if (defined $chain) {
        OME::Analysis::Engine->executeChain($chain,$dataset,{});
    } else {
        print "I cannot figure out which chain to run on import.\n";
    }
}
