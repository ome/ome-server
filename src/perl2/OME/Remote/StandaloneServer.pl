#!/usr/bin/perl -w 

use OME::SOAP::Exports;

use SOAP::Lite;
#SOAP::Trace->import('all');

use OME::Remote::Dispatcher;
my @dispatchObjects =
  qw(OME::Remote::Dispatcher);

use SOAP::Transport::HTTP;
$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;

$SIG{PIPE} = 'IGNORE';

if ($ARGV[0]) {
    print "Using dispatch objects\n  ",join("\n  ",@dispatchObjects),"\n";
} else {
    print "Using standard objects\n  ",join("\n  ",@OME::SOAP::Exports::SOAPobjects),"\n";
}

my $daemon = SOAP::Transport::HTTP::Daemon
  ->new(LocalPort => 8002)
  ->dispatch_to($ARGV[0]?
                @dispatchObjects:
                @OME::SOAP::Exports::SOAPobjects);

print "Connect to SOAP server at ", $daemon->url(), ".\n";
$daemon->handle();
