# OME/Tasks/CategoryManager.pm

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


package OME::Tasks::CategoryManager;
use strict;
use OME;
use OME::Session;
use OME::Tasks::AnnotationManager;
our $VERSION = $OME::VERSION;

=head1 NAME

OME::Tasks::CategoryManager

=head1 SYNOPSIS

	use OME::Tasks::CategoryManager;

=head1 DESCRIPTION

The OME::Tasks::CategoryManager


=head1 METHODS

=head2 getImagesInCategory()

	my @images = OME::Tasks::CategoryManager->getImagesInCategory($category);

Finds all images in the given category

=cut

sub getImagesInCategory {
	my ($proto, $category) = @_;
	my @classifications = $category->ClassificationList( );
# for some unknown reason, using 
#	Valid    => [ "is not", 0 ]
# as a filtering parameter consistently fails with the message
# "DBD::Pg::st execute failed: ERROR:  parser: parse error at or near "'" at /Users/josiah/OME/cvs/OME/src/perl2//OME/Factory.pm line 1069."
# so i'll just filter the list with grep
	@classifications = grep( ( ( not defined $_->Valid ) || $_->Valid ne 0 ), @classifications );
	my @images = sort( { $a->name cmp $b->name } map( $_->image, @classifications ) );
	return @images;
}

=head2 classifyImage()

	OME::Tasks::CategoryManager->classifyImage($image, $category);

Returns:
	a Category if the image is classified under other categories in this category's group
	this Category if the image is already classified with this Category
	the classification attribute if successful

=cut

sub classifyImage {
	my ($proto, $image, $category) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();

	my @other_categories_in_this_group = 
		$category->CategoryGroup->CategoryList( id => [ '!=', $category->id ] );
	# Don't add this image if it belongs to another image in this Category Group.
	# Don't bother searching if there are no other categories in this group;
	# DBObject can't handle empty lists with the 'in' operator.
	my @other_classifications = ( scalar ( @other_categories_in_this_group ) > 0 ?
		$factory->findObjects( '@Classification', {
			image                           => $image,
			'module_execution.experimenter' => $session->User(),
# for some unknown reason, this next parameter consistently fails with
# "DBD::Pg::st execute failed: ERROR:  parser: parse error at or near "'" at /Users/josiah/OME/cvs/OME/src/perl2//OME/Factory.pm line 1069."
# so i'll ignore it and grep it out at the next step
#					Valid                           => [ "is not", 0 ],
			Category => [ 'in', [ @other_categories_in_this_group] ]
		} ) :
		()
	);
	@other_classifications = grep( (not defined $_->Valid || $_->Valid eq 1 ), @other_classifications );
	return $other_classifications[0]->Category() if( @other_classifications );
	
	# skip if the image has already been classified with this classification
	if( my $classification = $factory->findObject( '@Classification', {
		Category => $category,
		image    => $image,
		'module_execution.experimenter' => $session->User(),
	} ) ) {
		return $category if $classification->Valid();
		$classification->Valid( 1 );
		$classification->storeObject();
		$session->commitTransaction();
		return $classification;
	}

	my ( $mex, $attrs ) = OME::Tasks::AnnotationManager->
		annotateImage( $image, 'Classification', 
		{ 
			Category => $category,
			Valid   => 1
		}
		);
	return $attrs->[0];
}

=head2 classifyImage()

	OME::Tasks::CategoryManager->declassifyImage($image, $category);

declassifies an image.

=cut

sub declassifyImage {
	my ($proto, $image, $category ) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $classification = $factory->findObject( 
		'@Classification', 
		Category => $category,
		image    => $image
	) or die "Couldn't find a classification for this category & image";
	$classification->Valid( 0 );
	$classification->storeObject();
	$session->commitTransaction();
}

=head1 AUTHOR

Josiah Johnston <siah@nih.gov>

=cut

1;

