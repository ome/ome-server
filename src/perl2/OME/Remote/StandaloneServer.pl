#!/usr/bin/perl -w 

use OME::SOAP::Exports;

use SOAP::Transport::HTTP;
$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;

$SIG{PIPE} = 'IGNORE';

my $daemon = SOAP::Transport::HTTP::Daemon
  ->new(LocalPort => 8002)
  ->dispatch_to(@OME::SOAP::Exports::SOAPobjects);

print "Connect to SOAP server at ", $daemon->url(), ".\n";
$daemon->handle();
