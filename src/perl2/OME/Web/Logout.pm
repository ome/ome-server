package OME::Web::Logout;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
@ISA = ("OME::Web");

sub getPageTitle {
    return "Open Microscopy Environment";
}

sub getPageBody {
    my $self = shift;
    my $apacheSession = $self->ApacheSession();

    $apacheSession->{username} = undef;
    $apacheSession->{password} = undef;

    return ('REDIRECT',$self->pageURL('OME::Web::Login'));
}

1;
