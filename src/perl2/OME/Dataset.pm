# OME/Dataset.pm

# Copyright (C) 2003 Open Microscopy Environment
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


package OME::Dataset;

=head1 NAME

OME::Dataset - a collection of images

=head1 DESCRIPTION

The C<Dataset> class represents OME datasets, which are a collection
of images.  Datasets and images form a many-to-many map, as do
datasets and projects.  A user's session usually has a single dataset
selected as the "active dataset".  Datasets also form the unit of
analysis for the OME analysis engine; analysis chains are
batch-execute against all of the images in a dataset.

=cut

use strict;
our $VERSION = 2.000_000;

use OME::Image;
use OME::Project;
use base qw(OME::DBObject);

__PACKAGE__->table('datasets');
__PACKAGE__->sequence('dataset_seq');
__PACKAGE__->columns(Primary => qw(dataset_id));
__PACKAGE__->columns(Essential => qw(name description locked owner_id group_id));
__PACKAGE__->has_many('image_links','OME::Image::DatasetMap' => qw(dataset_id));
__PACKAGE__->has_many('project_links','OME::Project::DatasetMap' => qw(dataset_id));

=head1 METHODS (C<Dataset>)

The following methods are available to C<Dataset> in addition to those
defined by L<OME::DBObject>.

=head2 name

	my $name = $dataset->name();
	$dataset->name($name);

Returns or sets the name of this dataset.

=head2 description

	my $description = $dataset->description();
	$dataset->description($description);

Returns or sets the description of this dataset.

=head2 locked

	my $locked = $dataset->locked();
	$dataset->locked($locked);

Returns or sets whether this dataset is locked.  A dataset must be
locked once it is analyzed; nothing is allowed to add or remove images
from a locked dataset.  (Its other properties, such and name and
description, however, can still be modified.)

=head2 owner

	my $owner = $dataset->owner();
	$dataset->owner($owner);

Returns or sets the owner of this dataset.

=head2 group

	my $group = $dataset->group();
	$dataset->group($group);

Returns or sets the group that this dataset belongs to.

=head2 project_links

	my @project_links = $dataset->project_links();
	my $project_link_iterator = $dataset->project_links();

Returns or iterates, depending on context, the project links for this
dataset.  (Being a many-to-many map, the link represents the mapping
table.)

=head2 image_links

	my @image_links = $dataset->image_links();
	my $image_link_iterator = $dataset->image_links();

Returns or iterates, depending on context, the image links for this
dataset.  (Being a many-to-many map, the link represents the mapping
table.)

=cut

sub owner {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->semantic_type()->name() eq "Experimenter";
        $self->owner_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->owner_id());
    }
}

sub group {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "group must be of Group semantic type"
          unless $attribute->semantic_type()->name() eq "Group";
        $self->group_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Group",
                                                          $self->group_id());
    }
}

sub projects {
	my $self = shift;
	return map $_->project(), $self->project_links();
}

sub images{
  	my $self = shift;
	return map $_->image(), $self->image_links();

}
# Added 18-03
sub addImage{
  my $self=shift;
  my $image=shift;
  return undef unless defined $image;
  my $factory=$self->Session()->Factory();
  my $pdMap = $factory->findObject("OME::Image::DatasetMap",{
		 dataset_id => $self->ID(),
		 image_id => $image->ID()
	});
  # my $pdMapIter = OME::Image::DatasetMap->search( image_id => $image->ID(), dataset_id => $self->ID() );

  #my $pdMap = $pdMapIter->next() if defined $pdMapIter;


	if (not defined $pdMap) {
		$pdMap=$factory->newObject("OME::Image::DatasetMap",{
			dataset_id => $self->ID(),
			image_id => $image->ID()

			} );



		#$pdMap = OME::Image::DatasetMap->create ( {
		#	dataset_id => $self->ID(),
		#	image_id => $image->ID()
		#} )
		#or die ref($self)."->addExisting:  Could not create a new Image::DatasetMap entry.\n";

	}

	return $image;


}
sub addImageID{
  my $self = shift;
  my $imageID = shift;
  my $factory=$self->Session()->Factory();
  my $image =$factory->loadObject("OME::Image",$imageID);
 # my $image = OME::Image->retrieve($imageID);	
  return $self->addImage($image);



}
1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

