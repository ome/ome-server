# OME/Image.pm

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


package OME::Image;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

use OME::Repository;
use IO::File;

use OME::Image::Pix;
use OME::Feature;

use fields qw(_fileOpen _fileHandle Pix _dimensions);

__PACKAGE__->AccessorNames({
#    instrument_id   => 'instrument',
#    experimenter_id => 'experimenter',
#    repository_id   => 'repository',
#    group_id        => 'group'
});

__PACKAGE__->table('images');
__PACKAGE__->sequence('image_seq');
__PACKAGE__->columns(Primary => qw(image_id));
__PACKAGE__->columns(Essential => qw(image_guid name));
__PACKAGE__->columns(Others => qw(created inserted description
                                  experimenter_id group_id pixels_id));
# pixels_id is part of a hack added by josiah on 6/9/03
# it references the "primary" set of pixels. 

#__PACKAGE__->hasa('OME::Instrument' => qw(instrument_id));
#__PACKAGE__->hasa('OME::Experimenter' => qw(experimenter_id));
#__PACKAGE__->hasa('OME::Repository' => qw(repository_id));
#__PACKAGE__->hasa('OME::Group' => qw(group_id));
__PACKAGE__->has_many('dataset_links','OME::Image::DatasetMap' => qw(image_id));
__PACKAGE__->has_many('wavelengths','OME::Image::Wavelengths' => qw(image_id));
__PACKAGE__->has_many('XYZ_info','OME::Image::XYZInfo' => qw(image_id));
__PACKAGE__->has_many('all_features','OME::Feature' => qw(image_id));

sub experimenter {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->semantic_type()->name() eq "Experimenter";
        $self->experimenter_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->experimenter_id());
    }
}

sub group {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Group must be a Group"
          unless $attribute->semantic_type()->name() eq "Group";
        $self->group_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Group",
                                                          $self->group_id());
    }
}


sub features {
    my ($self) = @_;
    return OME::Feature->__image_roots(image_id => $self->id());
}

sub datasets {
	my $self = shift;
	return map $_->dataset(), $self->dataset_links();
}

sub _init {
    my $class = shift;
    my $self = $class->SUPER::_init();

    $self->{_fileOpen} = 0;
    $self->{_fileHandle} = undef;
    $self->{thePix} = undef;
    $self->{_dimensions} = undef;
    return $self;
}

# Old prototype:
# my $pix = $image->GetPix();
# New prototype:
# my $pix = OME::Image->GetPix($pixelAttribute);
#
# (Both work) The new prototype allows you to create a Pix object from
# any pixel attribute.  The old prototype uses the default Pixels associated 
# with $image, and creates a Pix object from that.

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
        return ($self->{thePix}) if defined $self->{thePix};
        my $pixels = $self->DefaultPixels();
        $self->{thePix} = new OME::Image::Pix (
            $self->getFullPath(),
            $pixels->SizeX(),$pixels->SizeY(),$pixels->SizeZ(),
            $pixels->SizeC(),$pixels->SizeT(),$pixels->BitsPerPixel()/8
        ) || die ref($self)."->GetPix:  Could not instantiate OME::Image::Pix object\n";
        return ($self->{thePix});
    }
}

# This is an accessor/mutator for the default pixels attribute associated with this image.
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


sub getFullPath {
    my $self = shift;
    my $pixels = shift or
    	die ref( $self )."->getFullPath() needs a Pixels attribute as a parameter. Received an undef instead.\n";
    
    my $repository = $pixels->Repository();
    my $path = $pixels->Path();

    return $repository->Path() . $path;
}

sub openFile {
    my $self = shift;

    return if ($self->{fileOpen});
    my $fullpath = $self->getFullPath();

    my $handle = new IO::File;
    open $handle, $fullpath or die "Cannot open image file!";

    $self->{_fileOpen} = 1;
    $self->{_fileHandle} = $handle;
}

sub closeFile {
    my $self = shift;

    return unless ($self->{_fileOpen});
    close $self->{_fileHandle};
    $self->{_fileOpen} = 0;
    $self->{_fileHandle} = undef;
}


# for now, a very simple implementation

sub GetPixels {
    my ($self,$xx1,$xx2,$yy1,$yy2,$zz1,$zz2,$ww1,$ww2,$tt1,$tt2) = @_;
 
    return $self->GetPix->GetROI ($xx1,$yy1,$zz1,$ww1,$tt1,$xx2,$yy2,$zz2,$ww2,$tt2)
        || die ref($self)."->GetPixels:  Could not read pixels\n";
}

# gets the pixels as an multi-dimensional array of ints

sub GetPixelArray {
    my ($self,$x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2) = @_;
    my $pixels = $self->GetPixels($x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2);

    my @result = unpack("S*",$pixels);

    return \@result;
}


# DEPRECATED!
# Please use the LogicalChannel and ChannelComponents attributes
# instead.

package OME::Image::Wavelengths;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    attribute_id => 'attribute',
    image_id     => 'image'
});

__PACKAGE__->table('channel_components');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id 
				     number logical_channel));
__PACKAGE__->hasa('OME::Image::LogicalChannel' => qw(logical_channel));

sub wavenumber { shift->number(); }
sub ex_wavelength { shift->logical_channel()->ex_wave(@_); }
sub em_wavelength { shift->logical_channel()->em_wave(@_); }
sub nd_filter { shift->logical_channel()->nd_filter(@_); }
sub fluor { shift->logical_channel()->fluor(@_); }

package OME::Image::LogicalChannel;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    attribute_id => 'attribute',
    image_id     => 'image'
});

__PACKAGE__->table('logical_channels');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id 
				     ex_wave em_wave 
				     nd_filter fluor));




# DEPRECATED!
# Please use the StackMean, StackGeomean, StackMinimum, StackMaximum,
# StackSigma, and StackCentroid attributes instead.

package OME::Image::XYZInfo;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    attribute_id => 'attribute',
    image_id     => 'image',
    the_c        => 'theW',
    the_t        => 'theT'
    });

__PACKAGE__->table('stack_statistics');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id the_c the_t 
				     minimum maximum mean geomean sigma 
				     centroid_x centroid_y centroid_z));

sub min { shift->minimum(@_); }
sub max { shift->maximum(@_); }


package OME::Image::ImageFilesXYZWT;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    file_sha1 => 'sha1',
    });

__PACKAGE__->table('image_files_xyzwt');
__PACKAGE__->columns(Essential => qw(image_id file_sha1 bigendian
				     path host url x_start x_stop
				     y_start y_stop z_start z_stop
				     w_start w_stop t_start t_stop));


package OME::Image::DatasetMap;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    image_id   => 'image',
    dataset_id => 'dataset'
    });

__PACKAGE__->table('image_dataset_map');
__PACKAGE__->columns(Essential => qw(image_id dataset_id));
__PACKAGE__->hasa('OME::Image' => qw(image_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));



1;

