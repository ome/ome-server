# OME/Web/Viewer.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
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
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::Viewer;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;

use base qw{ OME::Web };
sub getPageTitle {
	return "Open Microscopy Environment - Dataset Viewer";
}

sub getPageBody {
	my $self = shift;
	my $body = "";
	my $session = $self->Session();

   	# MUST BE CHANGED
      my @list=$session->project()->datasets();
      if (scalar(@list)==0){
		$body.="<h3>No current dataset. Please define a dataset</h3>";
		 return ('HTML',$body);


	}
	#

	my $datasetID=$session->dataset()->dataset_id();
      my $redirect="OME::Web::GetGraphics&DatasetID=$datasetID";
      return ('REDIRECT',$self->pageURL($redirect));
}

1;

