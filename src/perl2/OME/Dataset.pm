# OME/Dataset.pm

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


package OME::Dataset;

use strict;
our $VERSION = '1.0';

use OME::Image;
use OME::Project;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    project_id => 'project',
 #   owner_id   => 'owner',		
    group_id   => 'group',
    image_id => 'image',		
    });

__PACKAGE__->table('datasets');
__PACKAGE__->sequence('dataset_seq');
__PACKAGE__->columns(Primary => qw(dataset_id));
__PACKAGE__->columns(Essential => qw(name description locked owner_id group_id));
__PACKAGE__->has_many('image_links','OME::Image::DatasetMap' => qw(dataset_id));
__PACKAGE__->has_many('project_links','OME::Project::DatasetMap' => qw(dataset_id));
#__PACKAGE__->hasa('OME::Experimenter' => qw(owner_id));
#__PACKAGE__->hasa('OME::Group' => qw(group_id));

sub owner {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->attribute_type()->name() eq "Experimenter";
        return $self->owner_id($attribute->id());
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->owner_id());
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

