#!/usr/bin/perl -w

use OME::SessionManager;
use OME::Session;
use OME::Factory;
use OME::ImportEngine::ImportEngine;

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

print "Importing @ARGV\n";
OME::ImportEngine::ImportEngine->
  importFiles(session => $session,
              \@ARGV);
