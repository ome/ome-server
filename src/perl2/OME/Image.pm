package OME::Image;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

use OME::Repository;
use IO::File;

use fields qw(_fileOpen _fileHandle);

__PACKAGE__->AccessorNames({
    instrument_id   => 'instrument',
    experimenter_id => 'experimenter',
    repository_id   => 'repository',
    group_id        => 'group'
});

__PACKAGE__->table('images');
__PACKAGE__->sequence('image_seq');
__PACKAGE__->columns(Primary => qw(image_id));
__PACKAGE__->columns(Essential => qw(image_guid name path image_type));
__PACKAGE__->columns(Others => qw(created inserted description));
__PACKAGE__->hasa(OME::Instrument => qw(instrument_id));
__PACKAGE__->hasa(OME::Experimenter => qw(experimenter_id));
__PACKAGE__->hasa(OME::Repository => qw(repository_id));
__PACKAGE__->hasa(OME::Group => qw(group_id));
#__PACKAGE__->has_many('datasets',OME::Image::DatasetMap => qw(image_id));


sub _init {
    my $class = shift;
    my $self = $class->SUPER::_init();
   
    $self->{_fileOpen} = 0;
    $self->{_fileHandle} = undef;
    return $self;
}


sub ImageAttributes {
    my $self = shift;
    my @attributes = $self->Factory()->findObjects("OME::Image::Attributes",
                                                   "image_id",
                                                   $self->id());
    
    die "Image has multiple attribute entries" if (scalar(@attributes) > 1);
    return $attributes[0];
}

sub getFullPath {
    my $self = shift;
    my $repository = $self->repository();
    my $rpath = $repository->path();
    my $path = $self->path();

    return ($rpath . $path);
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

    my $attributes = $self->ImageAttributes();

    my $sX = $attributes->size_x();
    my $sY = $attributes->size_y();
    my $sZ = $attributes->size_z();
    my $sW = $attributes->num_waves();
    my $sT = $attributes->num_times();

    # make sure x1 < x2, etc
    my $x1 = ($xx1 < $xx2)? $xx1: $xx2;
    my $x2 = ($xx1 < $xx2)? $xx2: $xx1;
    my $y1 = ($yy1 < $yy2)? $yy1: $yy2;
    my $y2 = ($yy1 < $yy2)? $yy2: $yy1;
    my $z1 = ($zz1 < $zz2)? $zz1: $zz2;
    my $z2 = ($zz1 < $zz2)? $zz2: $zz1;
    my $w1 = ($ww1 < $ww2)? $ww1: $ww2;
    my $w2 = ($ww1 < $ww2)? $ww2: $ww1;
    my $t1 = ($tt1 < $tt2)? $tt1: $tt2;
    my $t2 = ($tt1 < $tt2)? $tt2: $tt1;

    # make sure coordinates are within their appropriate bounds
    return undef
	if (($x1 < 0) ||
	    ($x2 >= $sX) ||
	    ($y1 < 0) ||
	    ($y2 >= $sY) ||
	    ($z1 < 0) ||
	    ($z2 >= $sZ) ||
	    ($w1 < 0) ||
	    ($w2 >= $sW) ||
	    ($t1 < 0) ||
	    ($t2 >= $sT));

    my $closeFileLater = 0;

    if (!$self->{_fileOpen}) {
        $self->openFile();
        $closeFileLater = 1;
    }

    my $handle = $self->{_fileHandle};

    my $oX = 2;
    my $oY = $oX*$sX;
    my $oZ = $oY*$sY;
    my $oW = $oZ*$sZ;
    my $oT = $oW*$sW;

    my $offset = $x1*$oX + $y1*$oY + $z1*$oZ + $w1*$oW + $t1*$oT;
    my $dX = $x2-$x1+1;

    my $result = "";
    my $scanline;

    for (my $t = $t1; $t <= $t2; $t++) {
	for (my $w = $w1; $w <= $w2; $w++) {
	    for (my $z = $z1; $z <= $z2; $z++) {
		for (my $y = $y1; $y <= $y2; $y++) {
 		    seek($handle,$offset,0);
		    read($handle,$scanline,$dX*$oX) or return undef;
		    $result .= $scanline;

		    $offset += $oY;
		}
		$offset += $oZ;
	    }
	    $offset += $oW;
	}
	$offset += $oT;
    }

    if ($closeFileLater) {
        $self->closeFile();
    }

    return $result;
}

# gets the pixels as an multi-dimensional array of ints

sub GetPixelArray {
    my ($self,$x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2) = @_;
    my $pixels = $self->GetPixels($x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2);

    my @result = unpack("S*",$pixels);

    return \@result;
}


package OME::Image::Attributes;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    image_id     => 'image'
});

__PACKAGE__->table('attributes_image_xyzwt');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(size_x size_y size_z num_waves num_times bits_per_pixel));
__PACKAGE__->hasa(OME::Image => qw(image_id));


#package OME::Image::DatasetMap;
#
#use strict;
#our $VERSION = '1.0';
#
#use OME::DBObject;
#use base qw(


1;

