#!perl -w 
use SOAP::Transport::HTTP;
$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;
my @SOAPobjects = qw(
	OME::SessionManager
	OME::Session
	OME::Experimenter
	OME::Dataset
	OME::Project
	OME::Factory
	OME::Image
);
my $dispatch = SOAP::Transport::HTTP::CGI
    -> dispatch_to(@SOAPobjects);
$dispatch-> handle ();
