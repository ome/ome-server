#!perl -w 

use OME::SOAP::Exports;

use SOAP::Transport::HTTP;
$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;

my $dispatch = SOAP::Transport::HTTP::CGI
    -> dispatch_to(@OME::SOAP::Exports::SOAPobjects);
$dispatch-> handle ();
