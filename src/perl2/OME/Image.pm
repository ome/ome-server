package OME::Image;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::DBObject;
use OME::Repository;
use IO::File;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id           => ['IMAGES','IMAGE_ID',
			 {sequence => 'IMAGE_SEQ'}],
	guid         => ['IMAGES','IMAGE_GUID'],
	name         => ['IMAGES','NAME'],
	description  => ['IMAGES','DESCRIPTION'],
	instrument   => ['IMAGES','INSTRUMENT_ID',
			 {reference => 'OME::Instrument'}],
	experimenter => ['IMAGES','EXPERIMENTER_ID',
			 {reference => 'OME::Experimenter'}],
	created      => ['IMAGES','CREATED'],
	inserted     => ['IMAGES','INSERTED'],
	repository   => ['IMAGES','REPOSITORY_ID',
			 {reference => 'OME::Repository'}],
	path         => ['IMAGES','PATH'],
	sizeX        => ['ATTRIBUTES_IMAGE_XYZWT','SIZE_X'],
	sizeY        => ['ATTRIBUTES_IMAGE_XYZWT','SIZE_Y'],
	sizeZ        => ['ATTRIBUTES_IMAGE_XYZWT','SIZE_Z'],
	sizeW        => ['ATTRIBUTES_IMAGE_XYZWT','NUM_WAVES'],
	sizeT        => ['ATTRIBUTES_IMAGE_XYZWT','NUM_TIMES']
    };

    return $self;
}


# for now, a very simple implementation

sub GetPixels {
    my ($self,$xx1,$xx2,$yy1,$yy2,$zz1,$zz2,$ww1,$ww2,$tt1,$tt2) = @_;
    my $repository = $self->Field("repository");
    my $rpath = $repository->Field("path");
    my $path = $self->Field("path");

    my $sX = $self->Field("sizeX");
    my $sY = $self->Field("sizeY");
    my $sZ = $self->Field("sizeZ");
    my $sW = $self->Field("sizeW");
    my $sT = $self->Field("sizeT");

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
	    

    my $oX = 2;
    my $oY = $oX*$sX;
    my $oZ = $oY*$sY;
    my $oW = $oZ*$sZ;
    my $oT = $oW*$sW;

    my $offset = $x1*$oX + $y1*$oY + $z1*$oZ + $w1*$oW + $t1*$oT;
    my $dX = $x2-$x1+1;

    my $result = "";
    my $scanline;

    my $fullpath = $rpath . $path;
    my $handle = new IO::File;
    open $handle, $fullpath or return undef;

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

    close $handle;

    return $result;
}

# gets the pixels as an multi-dimensional array of ints

sub GetPixelArray {
    my ($self,$x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2) = @_;
    my $pixels = $self->GetPixels($x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2);

    my @result = unpack("S*",$pixels);

    return \@result;
}

1;

