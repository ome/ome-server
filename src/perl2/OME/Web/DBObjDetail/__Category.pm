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
	my $message = '';
	
	my @other_categories_in_this_group = 
		$obj->CategoryGroup->CategoryList( id => [ '!=', $obj->id ] );
	
	my $image_ids = $q->param( 'images_to_categorize' );
	if( $image_ids ) {
 		foreach my $image_id ( split( m',', $image_ids ) ) {
 			# Don't add this image if it belongs to another image in this Category Group.
 			# Don't bother searching if there are no other categories in this group;
 			# DBObject can't handle empty lists with the 'in' operator.
 			my @other_classifications = ( scalar ( @other_categories_in_this_group ) > 0 ?
				$factory->findObjects( '@Classification', {
					image                           => $image_id,
					'module_execution.experimenter' => $session->User(),
# for some unknown reason, this next parameter consistently fails with
# "DBD::Pg::st execute failed: ERROR:  parser: parse error at or near "'" at /Users/josiah/OME/cvs/OME/src/perl2//OME/Factory.pm line 1069."
# so i'll ignore it and grep it out at the next step
#					Valid                           => [ "is not", 0 ],
					Category => [ 'in', [ @other_categories_in_this_group] ]
				} ) :
				()
			);
			@other_classifications = grep( (not defined $_->Valid || $_->Valid != 0 ), @other_classifications );
			if( @other_classifications ) {
	 			$message .= "<font color='red'>Cannot add image ".
	 				$self->Renderer()->render( $other_classifications[0]->image(), 'ref' ).
 					" to this category because it belongs to another category. ".
 					$self->Renderer()->render( $other_classifications[0]->Category(), 'ref' ).
 					".</font><br>";
 				next;
 			}
 			
			my $image = $factory->loadObject( 'OME::Image', $image_id )
				or die "Couldn't load image id=$image_id";
 			# skip if the image has already been classified with this classification
 			if( $factory->findObject( '@Classification', {
				Category => $obj,
				image    => $image_id,
				'module_execution.experimenter' => $session->User()
			} ) ) {
	 			$message .= "<font color='red'>Cannot add image ".
	 				$self->Renderer()->render( $image, 'ref' ).
 					" to this category because it already belongs to this category.</font><br>";
 				next;
			}
			my ( $mex, $attrs ) = OME::Tasks::AnnotationManager->
				annotateImage( $image, 'Classification', { Category => $obj } );
		}
 		$session->commitTransaction();
	}
	return $message;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
