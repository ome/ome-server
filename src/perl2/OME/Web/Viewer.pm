# OME/Web/Viewer.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Jean-Marie Burel <j.burel@dundee.ac.uk>
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



package OME::Web::Viewer;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Dataset Viewer";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $session = $self->Session();

   	# MUST BE CHANGED
      my @list=$session->project()->datasets();
      if (scalar(@list)==0){
		$body.=$cgi->h3("No current dataset. Please define a dataset");
		 return ('HTML',$body);


	}
	#

	my $datasetID=$session->dataset()->dataset_id();
      my $redirect="OME::Web::GetGraphics&DatasetID=$datasetID";
      return ('REDIRECT',$self->pageURL($redirect));
}

1;

