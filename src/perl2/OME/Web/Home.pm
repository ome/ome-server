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

    my $factory = $self->Factory();
    my $project = $factory->loadObject("OME::Project",1);
    $body .= $cgi->p($project->Field("id"));
    $body .= $cgi->p($project->Field("name"));
    $body .= $cgi->p($project->Field("description"));
    $body .= $cgi->p($project->Field("owner")->Field("firstName"));
    my $dataset1 = $factory->loadObject("OME::Dataset",1);
    my $dataset2 = $factory->loadObject("OME::Dataset",2);
    my $dataset3 = $factory->loadObject("OME::Dataset",3);
    $project->Field("datasets",[$dataset1,$dataset3]);
    $project->writeObject();
    
    return ('HTML',$body);
}

1;
