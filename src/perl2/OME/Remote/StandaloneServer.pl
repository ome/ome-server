#!/usr/bin/perl -w 

use SOAP::Lite;
#SOAP::Trace->import('all');
use XMLRPC::Lite;


use OME::Remote::Dispatcher;
my @dispatchObjects =
  qw(OME::Remote::Dispatcher);

use SOAP::Transport::HTTP;
use XMLRPC::Transport::HTTP;
$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;
$XMLRPC::Constants::DO_NOT_USE_XML_PARSER = 1;

$SIG{PIPE} = 'IGNORE';

print "Using dispatch objects\n  ",join("\n  ",@dispatchObjects),"\n";

my $port = $ARGV[0] || 8002;

my ($transportClass, $style, $daemon);

if ((defined $ARGV[1]) && (uc($ARGV[1]) eq "XMLRPC")) {
    $transportClass = "XMLRPC::Transport::HTTP::Daemon";
    $daemon = $transportClass
      ->new(LocalPort => $port)
      ->dispatch_to('OME::Remote::Dispatcher')
      ->dispatch_with({undef,'OME::Remote::Dispatcher'});
    $style = "XML-RPC";
} else {
    $transportClass = "SOAP::Transport::HTTP::Daemon";
    $daemon = $transportClass
      ->new(LocalPort => $port)
      ->dispatch_to(@dispatchObjects);
    $style = "SOAP";
}

#$daemon->on_action(sub { print "A***(",join(',',@_),")\n"; });
#$daemon->on_dispatch(sub { print "D***(",join(',',@_),")\n"; });


print "Connect to $style server at ", $daemon->url(), ".\n";
$daemon->handle();
