# OME/Web/Home.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Web::Home;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
use OME::DBObject;
use OME::Image;
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
    $body .= $cgi->p($project->id());
    $body .= $cgi->p($project->name());
    $body .= $cgi->p($project->description());
    $body .= $cgi->p($project->owner()->firstname());
    my $dataset = $factory->loadObject("OME::Dataset",1);
    my $image = $factory->loadObject("OME::Image",1);

    my $pix = $image->GetPixelArray(10,20,10,20,0,0,0,0,0,0);

    $body .= "<table align=center valign=middle border=1>";

    my $i = 0;
    my ($x,$y);
    for ($y = 10; $y <= 20; $y++) {
	$body .= "<tr align=center valign=middle>";
	for ($x = 10; $x <= 20; $x++) {
	    $body .= "<td>$pix->[$i]</td>";
	    $i++;
	}
	$body .= "</tr>";
    }
    $body .= "</table>";

    my $table = $factory->loadObject("OME::LookupTable",1);
    $body .= $cgi->p($table->name());
    my $entries = $table->entries();
    while (my $entry = $entries->next()) {
	$body .= $cgi->p("..." . $entry->label());
    }
    
    return ('HTML',$body);
}

1;
