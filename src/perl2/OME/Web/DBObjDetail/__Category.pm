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
use OME::Tasks::CategoryManager;

use Log::Agent;
use base qw(OME::Web::DBObjDetail);

sub _takeAction {
	my $self = shift;
	my $obj = $self->_loadObject();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $q = $self->CGI();
	my $message = '';
	
	my @other_categories_in_this_group = 
		$obj->CategoryGroup->CategoryList( id => [ '!=', $obj->id ] );
	
	my $image_ids = $q->param( 'images_to_categorize' );
	if( $image_ids ) {
		my @these_images_are_already_classified;
		foreach my $image_id ( split( m',', $image_ids ) ) {
			my $image = $factory->loadObject( 'OME::Image', $image_id )
				or die "Couldn't load image id=$image_id";
 			my $rc = OME::Tasks::CategoryManager->classifyImage( $image, $obj );
 			next if $rc->semantic_type()->name() eq 'Classification';
 			if( $rc->id ne $obj->id ) {
	 			$message .= "<font color='red'>Cannot add image ".
	 				$self->Renderer()->render( $image, 'ref' ).
 					" to this category because it belongs to another category in this group.".
 					$self->Renderer()->render( $rc, 'ref' )."</font><br>";
 			} else {
 				push( @these_images_are_already_classified, $image );
			}
		}
		$message .= "<font color='red'>Cannot add image".
			( ( @these_images_are_already_classified > 1 ) ? 's ' : ' ' ).
	 		$self->Renderer()->renderArray( \@these_images_are_already_classified, 'bare_ref_mass', { type => 'OME::Image' } ).
 			" because ".
			( ( @these_images_are_already_classified > 1 ) ? 'they already belong' : 'it already belongs' ).
 			" to this category.</font><br>"
 			if( @these_images_are_already_classified );
		$session->commitTransaction();
	}
	
	my $image_id_to_declassify = $q->param( 'declassifyImage' );
	if( $image_id_to_declassify ) {
		my $image = $factory->loadObject( 'OME::Image', $image_id_to_declassify )
			or die "Couldn't load image (id=$image_id_to_declassify)";
		my $classification = $factory->findObject( 
			'@Classification', 
			Category => $obj,
			image    => $image
		) or die "Couldn't find a classification for this category & image";
		$classification->Valid( 0 );
		$classification->storeObject();
		$session->commitTransaction();
		$message .= "Declassified image ".$self->Renderer()->render( $image, 'ref' )."<br>";
	}
	
	return $message;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
