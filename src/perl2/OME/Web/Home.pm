package OME::Web::Home;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
use OME::DBObject;
@ISA = ("OME::Web");

sub getPageTitle {
    return "Open Microscopy Environment";
}

sub getPageBody {
    my $self = shift;
    my $cgi = $self->CGI();
    my $body = "";

    $body .= $cgi->h3("Open Microscopy Environment");
    $body .= $cgi->p("Welcome to OME.  Soon you will be able to do something.");
    
    return ('HTML',$body);
}

1;
