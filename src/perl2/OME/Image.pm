# OME/Image.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


=head1 NAME

OME::Image - an OME image

=head1 SYNOPSIS

	use OME::Image;

	# Acquire a factory from your session. See OME::Session for more details

	# Load an image
	my $image = $factory->loadObject( OME::Image, $imageID );
	
=head1 DESCRIPTION

To come.

=head1 METHODS

=head2 name

accessor/mutator for name

=head2 created

accessor/mutator for creation timestamp

=head2 inserted

accessor/mutator for timestamp of image import

=head2 description

accessor/mutator for description

=cut

package OME::Image;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

use IO::File;

use OME::Image::Pix;
use OME::Feature;
use OME::Image::Server;

use fields qw(_fileOpen _fileHandle Pix _dimensions);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('images');
__PACKAGE__->setSequence('image_seq');
__PACKAGE__->addPrimaryKey('image_id');
__PACKAGE__->addColumn(image_guid => 'image_guid',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(256)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->addColumn(['experimenter_id','owner_id'] => 'experimenter_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'experimenters',
                       });
__PACKAGE__->addColumn(['experimenter','owner'] => 'experimenter_id',
                       '@Experimenter');
__PACKAGE__->addColumn(group_id => 'group_id',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'groups',
                       });
__PACKAGE__->addColumn(group => 'group_id','@Group');
__PACKAGE__->addColumn(created => 'created',
                       {
                        SQLType => 'timestamp',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(inserted => 'inserted',
                       {
                        SQLType => 'timestamp',
                        NotNull => 1,
                       });
# pixels_id references the default set of pixels. 
__PACKAGE__->addColumn(pixels_id => 'pixels_id',{SQLType => 'integer'});
__PACKAGE__->addColumn(default_pixels => 'pixels_id','@Pixels');

__PACKAGE__->hasMany('pixels','@Pixels' => 'image');

__PACKAGE__->hasMany('dataset_links','OME::Image::DatasetMap' => 'image');
__PACKAGE__->manyToMany('datasets',
                        'OME::Image::DatasetMap','image','dataset');

__PACKAGE__->hasMany('all_features','OME::Feature' => 'image');
__PACKAGE__->hasMany('module_executions','OME::ModuleExecution' => 'image');

=head2 experimenter

accessor/mutator for Experimenter attribute

=cut

# Now defined by addColumn, above

=head2 group

accessor/mutator for Group attribute

=cut

# Now defined by addColumn, above

=head2 features

Returns the root features of this image (i.e., those which do not have
a parent feature).

=cut


sub features {
    my ($self) = @_;
    return $self->Session()->Factory()->
      findObjects(
                  "OME::Feature",
                  image          => $self,
                  parent_feature => undef
                 );
}

=head2 datasets

$image->datasets();

returns all datasets that the image belongs to

=cut

# This should be depricated completely
sub GetPix {
    my $self = shift;
    die ref($self) . "->GetPix() has been depricated. Change your code to use OME::Image::Server::Pixels->open()";
}

=head2 DefaultPixels

# accessor
$image->DefaultPixels();

# mutator
$image->DefaultPixels( $pixels_ID );

This is an accessor/mutator for the default pixels attribute
associated with this image.  Default pixels should NEVER be used for
any computational purpose because they are mutable.  They are used by
image viewers and other non computational purposes.

The older version of this method (C<DefaultPixels>) still exists for
legacy code.  New code should use the C<default_pixels> version, which
takes advantage of underlying DBObject code for reading/writing
attributes.

=cut

sub DefaultPixels {
	my $self = shift;
	my $pixels_id = shift;
	
	if( not defined $pixels_id ) {
		my $pixels = $self->Session()->Factory()->
			loadAttribute("Pixels",$self->pixels_id());
		return $pixels;
	} else {
		$self->pixels_id( $pixels_id );
		return $self->DefaultPixels();
	}
}

# Depricate this!
sub getFullPath {
    my $self = shift;
    die ref($self)."->getFullPath() has been heavily depricated. Pixels live on the image server now. ";
    my $pixels = shift or
    	die ref( $self )."->getFullPath() needs a Pixels attribute as a parameter. Received an undef instead.\n";
    
    my $repository = $pixels->Repository();
    my $path = $pixels->Path();

    return $repository->Path() . $path;

#	This assumes the Image server is mounted on a shared drive at '/OME/OMEIS'
#	It also awaits Pixel attributes to store image server id's
#OME::Image::Server->useLocalServer() ;
#return '/OME/OMEIS/' . OME::Image::Server->get_IS_PixelsPath( $pixels->imageServerID() );
}

# DEPRICATE this!
sub GetPixels {
    my ($self,$xx1,$xx2,$yy1,$yy2,$zz1,$zz2,$ww1,$ww2,$tt1,$tt2) = @_;
 
    return $self->GetPix( $self->DefaultPixels() )->GetROI ($xx1,$yy1,$zz1,$ww1,$tt1,$xx2,$yy2,$zz2,$ww2,$tt2)
        || die ref($self)."->GetPixels:  Could not read pixels\n";
}


=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>, Open Microscopy Environment, MIT

=cut

1;

