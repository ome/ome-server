# OME/Web/DBObjDetail/__Category.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjDetail::__Category;

=pod

=head1 NAME

OME::Web::DBObjDetail::__Category

=head1 DESCRIPTION

implements _takeAction to allow Categorization of Images

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::AnnotationManager;

use Log::Agent;
use base qw(OME::Web::DBObjDetail);

sub _takeAction {
	my $self = shift;
	my $obj = $self->_loadObject();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $q = $self->CGI();
	
	my $image_ids = $q->param( 'images_to_categorize' );
	if( $image_ids ) {
 		foreach my $image_id ( split( m',', $image_ids ) ) {
 			next if $factory->findObject( '@Classification', {
				Category => $obj,
				image    => $image_id,
				'module_execution.experimenter' => $session->User()
			} );
			my $image = $factory->loadObject( 'OME::Image', $image_id )
				or die "Couldn't load image id=$image_id";
			OME::Tasks::AnnotationManager->
				annotateImage( $image, 'Classification', { Category => $obj } );
		}
 		$session->commitTransaction();
	}
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
