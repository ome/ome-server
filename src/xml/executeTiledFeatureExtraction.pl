#! /usr/bin/perl
use strict;
use OME::SessionManager;
use OME::Analysis::Engine;
use OME::Tasks::AnnotationManager;

my $session = OME::SessionManager->TTYlogin();
my $factory = $session->Factory();

my $chain = $factory->findObject( 'OME::AnalysisChain',
                                   id => 9 )
    or die "Got no Feature Extraction Chain";

my $dataset = $factory->findObject( 'OME::Dataset',
                                   id => 1 )
    or die "Got no Dataset";
    
my $parametersFI = $factory->findObject( 'OME::Module::FormalInput',
	'module.name' => "Image 2D Tiled ROIs",
	'name'        => 'Number of Tiles'
);

my $data_hash={};
$data_hash->{"NumOfHorizontalTiles"}=1;
$data_hash->{"NumOfVerticalTiles"}=1;

my $mex = OME::Tasks::AnnotationManager->annotateGlobal("ROINumberOfTiles", $data_hash);

my %user_inputs;
$user_inputs{$parametersFI->id()} = $mex;

my %flags;
$flags{ReuseResults} = 1;
my $task = undef;

my $chain_execution = OME::Analysis::Engine->
	executeChain($chain,$dataset,\%user_inputs,$task,%flags)
	or die "Got no chex.";
print "Chex ID is ".$chain_execution->id."\n";