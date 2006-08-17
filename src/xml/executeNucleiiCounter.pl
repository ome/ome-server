#! /usr/bin/perl
use strict;
use OME::SessionManager;
use OME::Analysis::Engine;
use OME::Tasks::AnnotationManager;

my $session = OME::SessionManager->TTYlogin();
my $factory = $session->Factory();

my $chain = $factory->findObject( 'OME::AnalysisChain',
                                   name => "HandE Stained Nucleii Counter" )
    or die "Got no FindSpots Chain";

my $dataset = $factory->findObject( 'OME::Dataset',
                                   name => "imgs" )
    or die "Got no Dataset";
    
my $parametersFI = $factory->findObject( 'OME::Module::FormalInput',
	'module.name' => "Find spots",
	'name'        => 'Parameters'
);

my $data_hash={};
$data_hash->{"TimeStart"}=0;
$data_hash->{"TimeStop"}=0;
$data_hash->{"Channel"}=0;
$data_hash->{"MinimumSpotVolume"}=500;
$data_hash->{"ThresholdType"}="Otsu";
$data_hash->{"ThresholdValue"}=0;
$data_hash->{"FadeSpotsTheT"}=0;
$data_hash->{"DarkSpots"}=1;

my $mex = OME::Tasks::AnnotationManager->annotateGlobal("FindSpotsInputs", $data_hash);

my %user_inputs;
$user_inputs{$parametersFI->id()} = $mex;

my %flags;
$flags{ReuseResults} = 0;
my $task = undef;

my $chain_execution = OME::Analysis::Engine->
	executeChain($chain,$dataset,\%user_inputs,$task,%flags)
	or die "Got no chex.";
print "Chex ID is ".$chain_execution->id."\n";