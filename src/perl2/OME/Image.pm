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

use fields qw(_fileOpen _fileHandle Pix _dimensions);

__PACKAGE__->AccessorNames({
    instrument_id   => 'instrument',
    experimenter_id => 'experimenter',
    repository_id   => 'repository',
    group_id        => 'group'
});

__PACKAGE__->table('images');
__PACKAGE__->sequence('image_seq');
__PACKAGE__->columns(Primary => qw(image_id));
__PACKAGE__->columns(Essential => qw(image_guid file_sha1 name path image_type));
__PACKAGE__->columns(Others => qw(lens_id created inserted description));
__PACKAGE__->hasa('OME::Instrument' => qw(instrument_id));
__PACKAGE__->hasa('OME::Experimenter' => qw(experimenter_id));
__PACKAGE__->hasa('OME::Repository' => qw(repository_id));
__PACKAGE__->hasa('OME::Group' => qw(group_id));
__PACKAGE__->has_many('dataset_links','OME::Image::DatasetMap' => qw(image_id));
__PACKAGE__->has_many('wavelengths','OME::Image::Wavelengths' => qw(image_id));
__PACKAGE__->has_many('XYZ_info','OME::Image::XYZInfo' => qw(image_id));
__PACKAGE__->has_many('features','OME::Feature' => qw(image_id));
	

sub _init {
    my $class = shift;
    my $self = $class->SUPER::_init();
   
    $self->{_fileOpen} = 0;
    $self->{_fileHandle} = undef;
    $self->{Pix} = undef;
    $self->{_dimensions} = undef;
    return $self;
}

sub Pix {
    my $self = shift;
    return ($self->{Pix}) if defined $self->{Pix};
    my $dimensions = $self->Dimensions();
    $self->{Pix} = new OME::Image::Pix (
        $self->getFullPath(),
        $dimensions->size_x(),$dimensions->size_y(),$dimensions->size_z(),
        $dimensions->num_waves(),$dimensions->num_times(),
        $dimensions->bits_per_pixel()/8
    ) || die ref($self)."->Pix:  Could not instantiate OME::Image::Pix object\n";
    return ($self->{Pix});
}

sub Dimensions {
    my $self = shift;
    return ($self->{_dimensions}) if defined $self->{_dimensions};
    
    my @dimensions = OME::Image::Dimensions->search (image_id => $self->id());
    
    die "Image has multiple dimension entries" if (scalar(@dimensions) > 1);
    $self->{_dimensions} = $dimensions[0];
    return $self->{_dimensions};
}

sub getFullPath {
    my $self = shift;
    my $repository = $self->repository();
    my $path = $self->path();

    return $repository->path() . $path;
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
 
    return $self->Pix->GetROI ($xx1,$yy1,$zz1,$ww1,$tt1,$xx2,$yy2,$zz2,$ww2,$tt2)
        || die ref($self)."->GetPixels:  Could not read pixels\n";
}

# gets the pixels as an multi-dimensional array of ints

sub GetPixelArray {
    my ($self,$x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2) = @_;
    my $pixels = $self->GetPixels($x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2);

    my @result = unpack("S*",$pixels);

    return \@result;
}


package OME::Image::Dimensions;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    image_id     => 'image'
});

__PACKAGE__->table('image_dimensions');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id size_x size_y size_z 
				     num_waves num_times 
				     bits_per_pixel));
__PACKAGE__->columns(Others => qw(pixel_size_x pixel_size_y pixel_size_z
				  wave_increment time_increment)); 
__PACKAGE__->hasa('OME::Image' => qw(image_id));



package OME::Image::Wavelengths;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    attribute_id => 'attribute',
    image_id     => 'image'
});

__PACKAGE__->table('image_wavelengths');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id wavenumber 
				     ex_wavelength em_wavelength 
				     nd_filter fluor));


package OME::Image::XYZInfo;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    attribute_id => 'attribute',
    image_id     => 'image'
    });

__PACKAGE__->table('xyz_image_info');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id wavenumber timepoint deltatime
				     min max mean geomean sigma 
				     centroid_x centroid_y centroid_z));


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

