#!/usr/bin/perl -w
#
# OME::ImportEngine::DVreader.pm
#
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
# Written by:    Brian S. Hughes
#
#-------------------------------------------------------------------------------


#

=head1 NAME

OME::ImportEngine::DVreader.pm  -  Softworx format image importer


=head1 SYNOPSIS

    use OME::ImportEngine::DVreader
    my $dvFormat = new DVreader($session, $module_execution)
    my $groups = $dvFormat->getGroups(\@filenames)
    my $image  = $dvFormat->importGroup(\@filenames)


=head1 DESCRIPTION

This importer class handles Advanced Imaging Corp. DeltaVision
Softworx format image files (DV format). The getGroups() method 
discovers which  files in a set of input files have the DV format, 
and the importGroup() method imports these files into OME 5D image 
files and metadata.

DV files each contain a 5D image, meaning that each DV file will import
directly into a separate OME 5D image.


=cut

# This class contains the methods for importing a Softworx file.
#


package OME::ImportEngine::DVreader;
use strict;
use Carp;
use OME::Image::Pix;
use OME::Tasks::PixelsManager;
use OME::ImportEngine::AbstractFormat;
use OME::ImportEngine::Params;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::FileUtils qw(/^.*/);
use OME::ImportExport::Repacker::Repacker;
use base qw(OME::ImportEngine::AbstractFormat);
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;


my %pix_size = (0=>1, 1=>2, 2=>4, 3=>2, 4=>4);
my @seq_types = (0, 1, 2);

use constant DVID               => -16224;
use constant DV_HEADER_LENGTH   => 1024;
use constant DV_BIG_TEMPLATE    => "NNNx84n";
use constant DV_LITTLE_TEMPLATE => "VVVx84v";

# This hash lists all the DeltaVision fields - their names, types, and lengths
# See IM_ref.html for the complete UI specification.
#
#   Hash tables entry: Tag name, length, type of value: {s, w, f, c}
#
our %tag_table =  (1     => ['NumCol', 4, 'w'],      # Image width
		  2     => ['NumRows', 4, 'w'],      # Image height
		  3     => ['NumSections', 4, 'w'],  # total sections = NumZSec * NumWaves * NumTimes
		  4     => ['PixelType', 4, 'w'],    # 0: 1 byte integer 
		                                     # 1: 2 byte integer
		                                     # 2: 4 byte float 
		                                     # 3: 2 byte complex
						     # 4: 4 byte complex
		  5     => ['mxst', 4, 'w'],         # starting pnt, in pixels,  along X axis of sub-image
		  6     => ['myst', 4, 'w'],         # starting pnt, in pixels,  along X axis of sub-image
		  7     => ['mzst', 4, 'w'],         # starting pnt, in pixels,  along X axis of sub-image
		  8     => ['mx', 4, 'w'],           # Pixel sampling size along X
		  9     => ['my', 4, 'w'],           # Pixel sampling size along Y
		  10    => ['mz', 4, 'w'],           # Pixel sampling size along Z
		  11    => ['dx', 4, 'f'],           # float - X element length in um.
		  12    => ['dy', 4, 'f'],           # float - Y element length in um.
		  13    => ['dz', 4, 'f'],           # float - Z element length in um.
		  14    => ['alpha', 4, 'f'],        # float - X axis angle in degrees
		  15    => ['beta', 4, 'f'],         # float - Y axis angle in degrees
		  16    => ['gamma', 4, 'f'],        # float - Z axis angle in degrees
		  17    => ['colseq', 4, 'w'],       # column axis seq. can be 1, 2, or 3 (default 1)
		  18    => ['rowseq', 4, 'w'],       # row axis seq. can be 1, 2, or 3 (default 2)
		  19    => ['secseq', 4, 'w'],       # section axis seq. can be 1, 2, or 3 (default 3)
		  20    => ['min', 4, 'f'],          # float - min intensity of 1st wavelength image
		  21    => ['max', 4, 'f'],          # float - max intensity of 1st wavelength image
		  22    => ['mean', 4, 'f'],         # float - mean intensity of 1st wavelength image
		  23    => ['nspg', 4, 'w'],         # space group numner - Xtallography
		  24    => ['next', 4, 'w'],         # size, in bytes, of extended header
		                                   # = (NumInts + NumFloats) * NumSections * 4
		  25    => ['dvid', 2, 's'],       # DeltaVision ID (== -16224)
		  26    => ['blank', 30, 'c'],     # blank section - 30 bytes
		  27    => ['NumInts', 2, 's'],      # number of 4 bytes ints in extended header
		  28    => ['NumFloats', 2, 's'],    # number of 4 bytes floats in extended header
		  29    => ['sub', 2, 's'],          # number of sub-resolution data sets. S.B 1
		  30    => ['zfac', 2, 's'],         # Z axis reduction quotient. S.B. 1
		  31    => ['min2', 4, 'f'],         # float - min intensity of 2nd wavelength image
		  32    => ['max2', 4, 'f'],         # float - max intensity of 2nd wavelength image
		  33    => ['min3', 4, 'f'],         # float - min intensity of 3rd wavelength image
		  34    => ['max3', 4, 'f'],         # float - max intensity of 3rd wavelength image
		  35    => ['min4', 4, 'f'],         # float - min intensity of 4th wavelength image
		  36    => ['max4', 4, 'f'],         # float - max intensity of 4th wavelength image
		  37    => ['type', 2, 's'],         # image type  0 - normal, 1 - tilt-series
		                                       # 2- stereo tilt series, 3 - averaged images
		                                       # 4 - average stereo pairs
		  38    => ['lensnum', 2, 's'],      # Lens ID number
		  39    => ['n1', 2, 's'],           # depends on image type
		  40    => ['n2', 2, 's'],           # depends on image type
		  41    => ['v1', 2, 's'],           # depends on image type
		  42    => ['v2', 2, 's'],           # depends on image type
		  43    => ['min5', 4, 'f'],         # float - min intensity of 5th wavelength image
		  44    => ['max5', 4, 'f'],         # float - max intensity of 5th wavelength image
		  45    => ['NumTimes',2, 's'],       # number of time points
		  46    => ['ImgSeq', 2, 's'],        # 0 = ZTW 1 = WZT, 2 = ZWT
		  47    => ['XTilt', 4, 'f'],        # float - X axis tilt (normally 0)
		  48    => ['YTilt', 4, 'f'],        # float - Y axis tilt (normally 0)
		  49    => ['ZTilt', 4, 'f'],        # float - Z axis tilt (normally 0)
		  50    => ['NumWaves', 2, 's'],     # number of wavelengths
		  51    => ['wave1', 2, 's'],        # Wavelength 1, in nm.
		  52    => ['wave2', 2, 's'],        # Wavelength 2, in nm.
		  53    => ['wave3', 2, 's'],        # Wavelength 3, in nm.
		  54    => ['wave4', 2, 's'],        # Wavelength 4, in nm.
		  55    => ['wave5', 2, 's'],        # Wavelength 5, in nm.
		  56    => ['Xorigin', 4, 'w'],      # X origin, in um.
		  57    => ['Yorigin', 4, 'w'],      # Y origin, in um.
		  58    => ['Zorigin', 4, 'w'],      # Z origin, in um.
		  59    => ['NumTitles', 4, 'w'],    # number of titles (0 - 10)
		  60    => ['Title1', 80, 'c'],      # Title 1
		  61    => ['Title2', 80, 'c'],      # Title 2
		  62    => ['Title3', 80, 'c'],      # Title 3
		  63    => ['Title4', 80, 'c'],      # Title 4
		  64    => ['Title5', 80, 'c'],      # Title 5
		  65    => ['Title6', 80, 'c'],      # Title 6
		  66    => ['Title7', 80, 'c'],      # Title 7
		  67    => ['Title8', 80, 'c'],      # Title 8
		  68    => ['Title9', 80, 'c'],      # Title 9
		  69    => ['Title10', 80, 'c'],     # Title 10
		  70    => ['end', 0, 0]           # flags end of hash
	      );

our %xml_image_entries = (NumCol => 'SizeX',
                          NumRows => 'SizeY',     # SizeZ calculated separately
                          NumWaves =>'NumWaves',
                          NumTimes => 'NumTimes',
			  lensnum  => 'LensID',
                          mx       => 'PixelSizeX',
                          my       => 'PixelSizeY',
                          mz       => 'PixelSizeZ'
			  );

my %xml_wavelength_entries = (wave1  => 'EmWave',
			       wave2  => 'EmWave',
			       wave3  => 'EmWave',
			       wave4  => 'EmWave',
			       wave5  => 'EmWave'
			       );


sub new {
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};


    bless $self, $class;
    $self->{super} = $self->SUPER::new();
    my %paramHash;
    $self->{params} = new OME::ImportEngine::Params(\%paramHash);
    return $self;

    };



=head2 B<getGroups> S< > S< > S< >

    my $group_output_list = $importer->getGroups(\@filepaths)

This method examines the list of filenames that is passed in by
reference. Any files on the list that are DV files are removed
from the input list and added to the output list. 

This method examines each file's contents, first looking for the 
presence of a special DV identity value at a fixed location in the
beginning of the file. If this identity value is present, this method
decides that the file has the DV format.

=cut


sub getGroups {
    my $self = shift;
    my $fhash = shift;
    my $file;
    my @files_found;

	foreach $file (values (%$fhash)) {
		$file->open('r');
		if ($file->getLength() > DV_HEADER_LENGTH) {
			push (@files_found, $file) if getEndian($file) ne "";
		}
		$file->close();
	}

    # Clean out the $filenames list.
    $self->__removeFiles($fhash,\@files_found);

    return \@files_found;
}




=head2 importGroup

    my $image = $importer->importGroup(\@filenames)

This method imports individual DV format files into OME
5D images. The caller passes a set of individual input files by
reference. This method opens each file in turn, extracts
its metadata and pixels, and creates a corresponding OME image.

DV format files carry their metadata in a header and a series of
extended headers. This method extracts the metadata values from
these structures, and records the values of the fields of interest
to OME into the OME database.

The arrangement of the planes in the DV file may not be in the canonical
OME order (XYZCT). This method makes sure to read each plane in its OME
order instead of reading sequential DV-order planes, jumping around the
input file if necessary. When the reads are done, the planes are arranged in memory in OME order. This method then just writes the planes out sequentially.


If all goes well, this method returns a pointer to a freshly created 
OME::Image. In that case, the caller should commit any outstanding
image creation database transactions. If the module detects an error,
it will return I<undef>, signalling the caller to rollback any associated
database transactions.

=cut


sub importGroup {
    my ($self,$file, $callback) = @_;

    my $sha1 = $file->getSHA1();

    my $session = ($self->{super})->Session();
    my $factory = $session->Factory();

    $file->open('r');
    my $filename = $file->getFilename();
    my $base = ($self->{super})->__nameOnly($filename);

    my $params = $self->getParams();
    $params->fref($file);
    $params->oname($base);
    $params->endian(getEndian($file));

    my $image = ($self->{super})->__newImage($filename);
    $self->{image} = $image;
    if (!defined($image)) {
	$file->close();
	die "Failed to open image" ;
    }

    # Softworx records many pieces of metadata in the file header and
    # extended headers. Read it and store it.
    $params->offset(0);
    my $status = readHeaders($self, $params);
    if ($status ne '') {
	$file->close();
	die $status ;
    }

    # Create repository file, and fill it in from the input file pixels.
    my $xref = $params->{xml_hash};
	my ($pixels, $pix) = ($self->{super})->
      __createRepositoryFile($image, 
                             $xref->{'Image.SizeX'},
                             $xref->{'Image.SizeY'},
                             $xref->{'Image.SizeZ'},
                             $xref->{'Image.NumWaves'},
                             $xref->{'Image.NumTimes'},
                             $xref->{'Data.BitsPerPixel'},
			     0, 0);
    $self->{pixels} = $pixels;
    $status = readPixels($self, $params, $pix, $callback);
    if ($status ne '') {
	$file->close();
	($self->{super})->__destroyRepositoryFile($pixels, $pix);
	die $status ;
    }

    # pack together info on input file
    my @finfo;
    $self->{in_files} = {file => $file,
                         path => $filename,
			  file_sha1 => ($file->getSHA1()),
			  bigendian => ($params->{endian} eq "big"),
			  image_id => $image->id(),
			  x_start => 0,
			  x_stop => $xref->{'Image.SizeX'}-1,
			  y_start => 0,
			  y_stop => $xref->{'Image.SizeY'}-1,
			  z_start => 0,
			  z_stop => $xref->{'Image.SizeZ'}-1,
			  w_start => 0,
			  w_stop => $xref->{'Image.NumWaves'}-1,
			  t_start => 0,
			  t_stop => $xref->{'Image.NumTimes'}-1,
              format => "DeltaVision R3D"};

    $file->close();

    storeMetadata($self, $session, $params);

    return $image;

}



# Read in the DeltaVision image metadata
sub readHeaders {
    my $self = shift;     # Ourselves
    my $params = shift;
    my $file    = $params->fref;
    my $sz;
    my $len;
    my $img_len;
    my $calc_len;
    my ($numsecs, $numflds);
    my $pix_OK = 0;
    my $seq;
    my $seq_OK = 0;

    $len = $file->getLength();

    # Read the DeltaVision fixed header
    my $status = "";

    $status = readUIHdr($self, $file,
			   $params->{endian},
			   $params->{offset});
    return($status) if defined $status && $status ne '';

    # check that PixelType has a valid value
    foreach my $ky (keys %pix_size) {
	if ($ky == $self->{"PixelType"}) {
	    my $xref = $params->{xml_hash};
	    $xref->{'Data.BitsPerPixel'} = $pix_size{$ky}*8;
	    $pix_OK = 1;
	    last;
	}
    }
    return ($status = "Bad pixel type: ".$self->{"PixelType"})
	unless $pix_OK == 1;

    # check that ImgSeq has a value this module supports
    foreach $seq (@seq_types) {
	if ($seq == $self->{"ImgSeq"}) {
	    $seq_OK = 1;
	    last;
	}
    }
    return ($status = "Unsupported bit plane order: $self->{'ImgSeq'}")
	unless $seq_OK == 1;

    # Calculate & verify image length & total file size;
    $img_len = $self->{NumCol} * $self->{NumRows} * $self->{NumSections};
    $img_len *= $pix_size{$self->{"PixelType"}};   # Calculate size of image
    $calc_len = DV_HEADER_LENGTH + $self->{next} + $img_len;   # + hdr + extended hdrs = file size
    return ($status = "File wrong size")
	unless $len == $calc_len;

    # Read in the extended header segments
    $numsecs = $self->{NumSections};                   # number of planes in image
    $numflds = $self->{NumInts} + $self->{NumFloats};  # number of fields per plane
    $status = readUIExtHdrs($self, $file, $params->{endian}, $numsecs, $numflds, DV_HEADER_LENGTH);
    return $status;

}



sub readPixels {
    my $self = shift;     # Ourselves
    my $params = shift;
    my $pix  = shift;
    my $callback = shift;

    my $file    = $params->fref;
    my $endian = $params->endian;
    my $xml_hash = $params->xml_hash;
    my $ibuf;
    my ($theT, $theC, $theZ, $row);
    my $status;
    my $start_offset;
    my $nPix;
    my ($row_size, $plane_size);
    my $bps = $pix_size{$self->{"PixelType"}};
    my ($t_jump, $w_jump, $z_jump);
    my ($offset, $t_offset, $w_offset, $z_offset);
    my $order = $self->{ImgSeq};                 # 0 = XYZTW 1 = XYWZT, 2 = XYZWT
    my $rows = $self->{NumRows};
    my $cols = $self->{NumCol};
    my $waves = $self->{NumWaves};
    my $times = $self->{NumTimes};
    my $sections = $self->{NumSections};
    my $zs = ($sections/$waves)/$times;         # number of Z steps in a stack

    $params->byte_size($bps);
    $params->pixel_size($bps * 8);
    $row_size   = $cols * $bps;               # size of an X vector (row)
    $plane_size = $rows * $row_size;            # size of 1 XY plane

    #print STDERR "Times: $times, waves:$waves, zs: $zs, rows: $rows, cols: $cols, sections: $sections\n";
    # Start at begining of image data
    $start_offset = DV_HEADER_LENGTH + $self->{next};

    # get offsets between consequtive time, wave, and Z sections in the file
    ($status, $t_jump, $w_jump, $z_jump) = get_jumps($times, $waves, $zs, $plane_size, $order);
    return $status
	unless $status eq "";
    
    # Read image out of the input file & arrange it in
    # our canonical XYZWT order.
    #print STDERR "   DVreader start read loop: ".localtime."\n";
    my $big_endian = $endian eq "big";

    for ($theT = 0; $theT < $times; $theT++) {
        $t_offset = $start_offset + $theT * $t_jump;
        my @xyzw;
        for ($theC = 0; $theC < $waves; $theC++) {
            $w_offset = $t_offset + $theC * $w_jump;
            my @xyz;
            for ($theZ = 0; $theZ < $zs; $theZ++) {
                #print STDERR "$theZ $theC $theT\n";
                my $plane_size = 0;
                $offset = $w_offset + $theZ * $z_jump;
                eval {
                    $pix->convertPlane($file,$offset,
                                       $theZ,$theC,$theT,
                                       $big_endian);
                };
                return $@ if $@;
		doSliceCallback($callback);
            }
        }
    }
    
	OME::Tasks::PixelsManager->finishPixels ($pix,$self->{pixels});
    #print STDERR "   DVreader end read loop: ".localtime."\n";

    if ($status eq "") {
	
    }

    return $status;
}



sub storeMetadata {
    my ($self, $session, $params) = @_;

    # store channel (wavelength) metadata
    storeChannelInfo($self, $session, $params);

    # run post-import analysis (statistics)
    #doImportAnalysis($self, $params);

    # store info about the input files
    storeInputFileInfo($self, $session);

    # store input file dimension info
    storeInputPixelDimension($self, $session, $params);

}


# Make array of per wavelength info.
# Feed it to helper routine to be put in DB
sub storeChannelInfo {
    my ($self, $session, $params) = @_;
    my $xml_hash = $params->xml_hash();
    my @channelInfo;
    my $numWaves = $self->{NumWaves};
    my $wv = $xml_hash->{'WavelengthInfo.'};
    for (my $i = 0; $i < $numWaves; $i++) {
	my $wvh = $wv->[$i];
	push @channelInfo, {chnlNumber => $i,
			    ExWave     => undef,
			    EmWave     => $wvh->{'WavelengthInfo.EmWave'},
			    Fluor      => undef,
			    NDfilter   => undef};
    }

    $self->__storeChannelInfo($session, $numWaves, @channelInfo);
}


# Make array of info on input files. Feed it to helper
# routine to be put in DB tbl for image files XYZWT.
sub storeInputFileInfo {
    my ($self, $session) = @_;

    push my @finfo, $self->{in_files};
    $self->__storeInputFileInfo($session, \@finfo);
}

# Make an array of input file's pizel size. Feed it to helper
# routine to be put in image file pixel dimension DB table.
sub storeInputPixelDimension {
    my ($self, $session, $params) = @_;
    my $xml_hash = $params->xml_hash();
    my $pixelInfo = [$xml_hash->{'Image.PixelSizeX'},
		       $xml_hash->{'Image.PixelSizeY'},
		       $xml_hash->{'Image.PixelSizeZ'}];
    $self->__storePixelDimensionInfo($session, $pixelInfo);
}


# Read in the main Softworx file header & store the many pieces of
# metadata contained therein.
sub readUIHdr {
    my $self = shift;
    my $file = shift;
    my $endian = shift;
    my $offset = shift;
    my $params = $self->getParams();
    my $xml_hash = $params->xml_hash();
    my $i;
    my $len;
    my $typ;
    my $k;
    my $xel;
    my $buf;
    my $fmt;
    my $val;
    my $status;
    my $w_aref = [];

    eval {
        $file->setCurrentPosition($offset);

        for ($i = 1; ($k = $tag_table{$i}[0]) ne 'end'; $i++) {
            $len = $tag_table{$i}[1];
            $typ = $tag_table{$i}[2];
            $buf = $file->readData($len);
	$fmt = get_fmt($typ, $endian);
	$fmt =~ s/^(.)$/$1$len/;
	$val = unpack($fmt, $buf);
	$self->{$k} = $val;
    }
    # Put relevant pieces of metadata into xml_elements for later DB storage
    foreach $k (keys %xml_image_entries) {
	$xel = $xml_image_entries{$k};
	$xml_hash->{"Image.".$xel} = $self->{$k};
    }

    # Make one WavelengthInfo element per wavelength in image
    $i = 0;
    foreach $k (sort keys %xml_wavelength_entries) {
	if ($i >= $self->{'NumWaves'}) {
	    last;
	}
	my $whref = {};
	$xel = $xml_wavelength_entries{$k};
	$whref->{'WavelengthInfo.'.$xel} = $self->{$k};
	$whref->{'WavelengthInfo.WaveNumber'} = $i;
	push @$w_aref, $whref;
	$i++;
    }
    $xml_hash->{'WavelengthInfo.'} = $w_aref;

    $i = $self->{NumSections}/$self->{NumWaves};
    $i /= $self->{NumTimes};
    $xml_hash->{'Image.SizeZ'} = $i;
    };
    return $@ if $@;

    return $status;
}



# Read in each of the extended headers - 1 per 'section'. A section is
# an instance of an XY plane. An imaages contains Z*W*T sections, where
# Z is the number of z slices, W is the number of wavelengths, and T
# is the number of time points.
sub readUIExtHdrs {
    my $self = shift;
    my $file = shift;
    my $endian = shift;
    my $numsecs = shift;
    my $numflds = shift;
    my $offset = shift;
    my $params = $self->getParams();
    my $numInts;
    my $numFlts;
    my $i;
    my $buf;
    my $val;
    my $len;
    my $curpos;
    my $status;

    eval {
        $file->setCurrentPosition($offset);
    $numInts = $self->{NumInts};
    $numFlts = $self->{NumFloats};
    $status = "File read error";
    $numsecs = $self->{NumSections};
    $len = 4;                 # Every field in the ext. hdr is 4 bytes long
    $curpos = $file->getCurrentPosition();
    while ($numsecs--) {
	#skip over the integers in the Ext hdr (they're always 0)
        $file->setCurrentPosition($numInts*$len,1);

	$status = "File read error";
	for ($i = 0; $i < $numFlts; $i++) {
            $buf = $file->readData($len);
	    $val = unpack("f", $buf);
	    if ($endian ne $params->host_endian) {
		#$val = $self->SUPER::flip_float($val);
	    }
	    #if ($i < 13) {  # only the 1st 13 floats are interesting
		#printf("flt: %g, ", $val);
	    #}
	}
	#print "\n";
    }
    $curpos = $file->getCurrentPosition();
    };
    return $@ if $@;
    return ($status = "");
}





# This routine returns the number of bytes between consequtive
# times, waves, and Z planes in an input imaqe file. These will
# allow the reader to position to the next segment to extract
# the image in XYZWT order.

sub get_jumps {
    my ($times, $waves, $zs, $plane_size, $order) = @_;
    my $status = "";
    my ($t_jump, $w_jump, $z_jump);

    # Get input file step offsets as we step thru extracting in XYZWT order
    if ($order == 0) {     # input is in XYZTW order
	$t_jump = $zs * $plane_size;
	$w_jump = $zs * $times * $plane_size;
	$z_jump = $plane_size;
    }
    elsif ($order == 1) {  # input is in XYWZT order
	$t_jump = $waves * $zs * $plane_size;
	$w_jump = $plane_size;
	$z_jump = $waves * $plane_size;
    }
    elsif ($order == 2) {  # input is in XYZWT order
	$t_jump = $waves * $zs * $plane_size;
	$w_jump = $zs * $plane_size;
	$z_jump = $plane_size;
    }
    else {
	$status = "Impossible image type value: $order";
    }

    return ($status, $t_jump, $w_jump, $z_jump);
}


# Helper routine to return the proper format character for unpacking header fields,
# depending upon the length of the field & the endian-ness of the source

sub get_fmt {
    my $type = shift;
    my $endian = shift;
    my $fmt = "";

    if ($type eq 'c') {       # character type
	$fmt = "A";
    }
    elsif (($type eq 'w') || ($type eq 'f')) {    # 'word'or 'float' type - 4 bytes
	$fmt =  $endian eq "little" ? "V" : "N";
    }
    elsif ($type eq 's') {    # 'short' type - 2 bytes
	$fmt = $endian eq "little" ? "v" : "n";
    }

    return $fmt;              # no error checking
}



# Get this file's endianness. Also serves to decide if file is
# a DV format file or not.
sub getEndian {
    my $file = shift;
    my $buf;
    my $endian = "";

    $file->setCurrentPosition(0);
    $buf = $file->readData(DV_HEADER_LENGTH);
    
    if (GetDVID(DV_LITTLE_TEMPLATE, $buf) == DVID) {
	$endian = "little";
    } elsif (GetDVID(DV_BIG_TEMPLATE, $buf) == DVID) {
	$endian = "big";
    }

    return $endian;
}


# Get what might be the DeltaVision ID & convert to signed
sub GetDVID {
    my $template = shift;
    my $buf = shift;
    my $dvid;
    my @hdr;

    @hdr = unpack($template, $buf); 
    $dvid = $hdr[3];
    # it unpacked as unsigned, so 1st convert to signed
    $dvid = $dvid >= 32768 ? $dvid-65536 : $dvid;

    return $dvid;
}


# Get %params hash reference
sub getParams {
    my $self = shift;
    return $self->{params};
}


sub getSHA1 {
    my $self = shift;
    my $file = shift;
    return $file->getSHA1();
}


=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut

1;
