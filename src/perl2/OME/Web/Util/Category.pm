# OME/Web/Util/Category.pm

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


package OME::Web::Util::Category;

=pod

=head1 NAME

OME::Web::Util::Category - a front end for OME::Tasks::CategoryManager

=head1 DESCRIPTION

This package makes calls to CategoryManager and generates return
messages formatted in html

=head1 METHODS

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;
use OME::Web;

use Log::Agent;
use base qw(OME::Web);

=head2 classify

	my $message = $self->CategoryUtil()->classify( $image_ids, $category );

$image_ids is comma separated list of image ids
$category should be a loaded Category attribute or a category ID

=cut

sub classify {
	my ($self, $image_ids, $category ) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $message;
	my (@these_images_are_already_classified, @succesfully_classified_images );
	
	# Load category if we were given an ID
	$category = $factory->loadObject( '@Category', $category )
		or die "Couldn't load Category (id=$category)"
		unless( ref( $category ) );
	
	foreach my $image_id ( split( m',', $image_ids ) ) {
		my $image = $factory->loadObject( 'OME::Image', $image_id )
			or die "Couldn't load image id=$image_id";
		my $rc = OME::Tasks::CategoryManager->classifyImage( $image, $category );
		# classifyImage will return a Classification if it was successful.
		if( $rc->semantic_type()->name() eq 'Classification' ) {
			push( @succesfully_classified_images, $image );
			next;
		# did classifyImage return a different category?
		} elsif( $rc->id ne $category->id ) {
			$message .= "<font color='red'>Cannot add image ".
				$self->Renderer()->render( $image, 'ref' ).
				" to this category because it belongs to another category in this group,".
				$self->Renderer()->render( $rc, 'ref' ).". To re-classify the image, you must first ".
				"remove it from the other category.</font><br>";
		# classifyImage returned this category, which means the image is already classified
		} else {
			push( @these_images_are_already_classified, $image );
		}
	}
	$message .= "Successfully classified ".
		$self->Renderer()->renderArray( \@succesfully_classified_images, 'bare_ref_mass', { type => 'OME::Image' } ).".<br>"
		if( @succesfully_classified_images );
	$message .= "<font color='red'>Cannot classify image".
		( ( @these_images_are_already_classified > 1 ) ? 's ' : ' ' ).
		$self->Renderer()->renderArray( \@these_images_are_already_classified, 'bare_ref_mass', { type => 'OME::Image' } ).
		" because ".
		( ( @these_images_are_already_classified > 1 ) ? 'they already belong' : 'it already belongs' ).
		" to this category.</font><br>"
		if( @these_images_are_already_classified );
	$session->commitTransaction();
	
	return $message;
}

=head2 declassify

	my $message = $self->CategoryUtil()->declassify( $image_id, $category );

$image_ids is comma separated list of image ids
$category should be a loaded Category attribute

=cut

sub declassify {
	my ($self, $image_ids, $category ) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $message;
}
=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
