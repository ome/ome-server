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
	
	# Load an OME::Image::Pix object
	# acquire a Pixels attribute
	my $pix = $image->GetPix( $pixels );
	
	
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
__PACKAGE__->addColumn(experimenter_id => 'experimenter_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'experimenters',
                       });
__PACKAGE__->addColumn(group_id => 'group_id',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'groups',
                       });
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
# pixels_id is part of a hack added by josiah <siah@nih.gov> on 6/9/03
# it references the "primary" set of pixels. 
__PACKAGE__->addColumn(pixels_id => 'pixels_id',{SQLType => 'integer'});

__PACKAGE__->hasMany('dataset_links','OME::Image::DatasetMap' => 'image');
__PACKAGE__->hasMany('all_features','OME::Feature' => 'image');

=head2 experimenter

accessor/mutator for Experimenter attribute

=cut

sub experimenter {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        $attribute->verifyType('Experimenter');
        $self->experimenter_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->experimenter_id());
    }
}

=head2 group

accessor/mutator for Group attribute

=cut

sub group {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        $attribute->verifyType('group');
        $self->group_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Group",
                                                          $self->group_id());
    }
}

=head2 features

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

sub datasets {
	my $self = shift;
	return map $_->dataset(), $self->dataset_links();
}

=head2 GetPix

$image->GetPix($pixelAttribute);

loads and returns the OME::Image::Pix object associated with this pixels

=cut

# Old prototype (DEPRICATED):
# my $pix = $image->GetPix();
# New prototype:
# my $pix = OME::Image->GetPix($pixelAttribute);
#
# (Both work) The new prototype allows you to create a Pix object from
# any pixel attribute.  The old prototype uses the default Pixels associated 
# with $image, and creates a Pix object from that. The old prototype is
# depricated. Calls to it should be replaced (minimally) with 
# my $pix = $image->GetPix( $image->DefaultPixels() );
# Any code that relies on the image having only one pixels element should get
# a careful inspection of its logic.

sub GetPix {
    my $self = shift;

    if (@_) {
        my ($pixelAttr) = @_;
        $pixelAttr->verifyType("Pixels");
        my $repositoryAttr = $pixelAttr->Repository();
        my $pix = OME::Image::Pix->
          new($repositoryAttr->Path().$pixelAttr->Path(),
              $pixelAttr->SizeX(),
              $pixelAttr->SizeY(),
              $pixelAttr->SizeZ(),
              $pixelAttr->SizeC(),
              $pixelAttr->SizeT(),
              $pixelAttr->BitsPerPixel()/8)
            || die ref($self)."->GetPix  Could not instantiate OME::Image::Pix object";
        return $pix;
    } else {
        my $pixels = $self->DefaultPixels();
        my $pix = new OME::Image::Pix (
            $self->getFullPath(),
            $pixels->SizeX(),$pixels->SizeY(),$pixels->SizeZ(),
            $pixels->SizeC(),$pixels->SizeT(),$pixels->BitsPerPixel()/8
        ) || die ref($self)."->GetPix:  Could not instantiate OME::Image::Pix object\n";
        return ($pix);
    }
}

=head2 DefaultPixels

# accessor
$image->DefaultPixels();

# mutator
$image->DefaultPixels( $pixels_ID );

This is an accessor/mutator for the default pixels attribute associated with this image.
Default pixels should NEVER be used for any computational purpose because they are mutable.
They are used by image viewers and other non computational purposes.

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


=head2 getFullPath

$image->getFullPath( $pixels );

Returns the full path to the repository file of the Pixels attribute passed as a parameter

=cut

sub getFullPath {
    my $self = shift;
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

# for now, a very simple implementation
# WARNING: USES DEPRICATED LOGIC!
sub GetPixels {
    my ($self,$xx1,$xx2,$yy1,$yy2,$zz1,$zz2,$ww1,$ww2,$tt1,$tt2) = @_;
 
    return $self->GetPix( $self->DefaultPixels() )->GetROI ($xx1,$yy1,$zz1,$ww1,$tt1,$xx2,$yy2,$zz2,$ww2,$tt2)
        || die ref($self)."->GetPixels:  Could not read pixels\n";
}

# gets the pixels as an multi-dimensional array of ints
# WARNING: USES DEPRICATED LOGIC!
sub GetPixelArray {
    my ($self,$x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2) = @_;
    my $pixels = $self->GetPixels($x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2);

    my @result = unpack("S*",$pixels);

    return \@result;
}


=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>, Open Microscopy Environment, MIT

=cut

package OME::Image::ImageFilesXYZWT;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('image_files_xyzwt');
__PACKAGE__->addColumn(image_id => 'image_id',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'images',
                       });
__PACKAGE__->addColumn(['file_sha1','sha1'] => 'file_sha1',{SQLType => 'char(40)'});
__PACKAGE__->addColumn(bigendian => 'bigendian',{SQLType => 'boolean'});
__PACKAGE__->addColumn(path => 'path',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(host => 'host',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(url => 'url',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(x_start => 'x_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(x_stop  => 'x_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn('y_start' => 'y_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn('y_stop'  => 'y_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn(z_start => 'z_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(z_stop  => 'z_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn(w_start => 'w_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(w_stop  => 'w_stop', {SQLType => 'smallint'});
__PACKAGE__->addColumn(t_start => 't_start',{SQLType => 'smallint'});
__PACKAGE__->addColumn(t_stop  => 't_stop', {SQLType => 'smallint'});


package OME::Image::DatasetMap;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('image_dataset_map');
__PACKAGE__->addColumn(image_id => 'image_id');
__PACKAGE__->addColumn(image => 'image_id','OME::Image',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'images',
                       });
__PACKAGE__->addColumn(dataset_id => 'dataset_id');
__PACKAGE__->addColumn(dataset => 'dataset_id','OME::Dataset',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'datasets',
                       });

# Our current caching implements breaks when there is not a single
# primary key column for the table.  As this is the case for this
# table, turn off caching (just for this class).

__PACKAGE__->Caching(0);



1;

