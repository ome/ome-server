#!/usr/bin/perl -w
#
# OME::ImportEngine::STKreader.pm
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

OME::ImportEngine::STKreader.pm  -  STK format image importer


=head1 SYNOPSIS

    use OME::ImportEngine::STKreader
    my $stkFormat = new STKreader($session, $module_execution)
    my $groups = $stkFormat->getGroups(\@filenames)
    my $image  = $stkFormat->importGroup(\@filenames)


=head1 DESCRIPTION

This importer class handles the TIFF variant Universal Imaging Corp. 
STK format. The getGroups() method discovers which files in a set
of input files have the STK format, and the importGroup() method 
imports these STK files into OME 5D image files and metadata.

STK files each contains a 5D image, meaning that each STK file is its 
own group. The importGroup() method will import each single STK file 
into a separate OME 5D image.


=cut


package OME::ImportEngine::STKreader;
use strict;
use Carp;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::Params;
use OME::ImportEngine::TIFFUtils;
use base qw(OME::ImportEngine::AbstractFormat);

use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use constant 'UIC1' => 33628;
use constant 'UIC2' => 33629;
use constant 'UIC3' => 33630;
use constant 'UIC4' => 33631;


# Indeces to per plane info array
my %uic2_ndxs = (
		Plane_ndx  => 0,
		Z_val      => 1,
		Cr_dt      => 2,
		Cr_date    => 3,
		Cr_time    => 4,
		M_date     => 5,
		M_time     => 6,
		W_ave      => 7
	    );

# layout of the UIC tag id codes
# Array entry 1 - value type, entry 2 - name, entry 3 - 1 if read for UIC1, 4 - 1 if read for UIC4
# Data types are:
# L = contains a long, R = 2 longs producing a float, S = Pascal string, w/ length as a long,
# T = 2 longs - Date & Time, N4 = 4 longs for each of N planes, NS = N Pascal strings, N2= N R values
# N2 = 2 Longs for each of N planes, NL = 1 Long for each of N planes
# N.B, type L is directly in the value half of the pair. For all other types, the value
# is actually the offset to the start of the referenced data.
my %codes = (0 => ['L', 'AutoScale', 1, 0],
	    1 => ['L', 'MinScale', 1, 0],
	    2 => ['L', 'MaxScale', 1, 0],
	    3 => ['L', 'SpatialCalibration', 0, 0],
	    4 => ['R', 'XCalibration', 1, 0],
	    5 => ['R', 'YCalibration', 1, 0],
	    6 => ['S', 'CalibrationUnits', 1, 0],
	    7 => ['S', 'Name', 1, 0],
	    8 => ['L', 'ThreshState', 1, 0],
	    9 => ['L', 'ThreshStateRed', 1, 0],

	    10 => ['L', 'unknown_sub_tag', 1, 0],

	    11 => ['L', 'ThreshStateGreen', 1, 0],
	    12 => ['L', 'ThreshStateBlue', 1, 0],
	    13 => ['L', 'ThreshStateLo', 1, 0],
	    14 => ['L', 'ThreshStateHi', 1, 0],
	    15 => ['L', 'Zoom', 1, 0],
	    16 => ['T', 'CreateTime', 1, 0],
	    17 => ['T', 'LastSavedTime', 1, 0],
	    18 => ['L', 'currentBuffer', 1, 0],
	    19 => ['L', 'grayFit', 1, 0],
	    20 => ['L', 'grayPointCount', 1, 0],
	    21 => ['R', 'grayX', 1, 0],
	    22 => ['R', 'grayY', 1, 0],
	    23 => ['R', 'grayMin', 1, 0],
	    24 => ['R', 'grayMax', 1, 0],
	    25 => ['S', 'grayUnitName', 1, 0],
	    26 => ['L', 'StandardLUT', 1, 0],
	    27 => ['L', 'wavelength', 1, 0],
	    28 => ['N4', 'StagePosition', 0, 0],
	    29 => ['N4', 'CameraChipOffset', 0, 1],
	    30 => ['L', 'OverlayMask', 1, 0],
	    31 => ['L', 'OverlayCompress', 1, 0],
	    32 => ['L', 'Overlay', 1, 0],
	    33 => ['L', 'SpecialOverlayMask', 1, 0],
	    34 => ['L', 'SpecialOverlayCompress', 1, 0],
	    35 => ['L', 'SpecialOverlay', 1, 0],
	    36 => ['L', 'ImageProperty', 1, 0],
	    37 => ['NS', 'StageLabel', 0, 1],
	    38 => ['R', 'AutoScaleLoInfo', 1, 0],
	    39 => ['R', 'AutoScaleHIInfo', 1, 0],
	    40 => ['N2', 'AbsoluteZ', 0, 1],
	    41 => ['NL', 'AbsoluteZValid', 0, 1],
	    42 => ['LO', 'Gamma', 1, 0],
	    43 => ['LO', 'GammaRed', 1, 0],
	    44 => ['LO', 'GammaGreen', 1, 0],
	    45 => ['LO', 'GammaBlue', 1, 0],
	    46 => ['L', 'Undocumented', 0, 0],
	    );



=head1 METHODS

The following public methods are available:


=head2 B<new>


    my $importer = OME::ImportEngine::STKreader->new($session, $module_execution)

Creates a new instance of this class. The other public methods of this
class are accessed through this instance.  The caller, which would
normally be OME::ImportEngine::ImportEngine, should already
have created the session and the module_execution.

=cut


sub new {

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};
    my $session = shift;
    my $module_execution = shift;


    bless $self, $class;
    $self->{super} = $self->SUPER::new();

    my %paramHash;
    $self->{params} = new OME::ImportEngine::Params(\%paramHash);
    return $self;

    };




=head2 B<getGroups> S< > S< > S< >

    my $group_output_list = $importer->getGroups(\@files)

This method examines the list of filenames that is passed in by
reference. Any files on the list that are STK files are removed
from the input list and added to the output list. 

This method examines each file's contents, first looking for the 
presence of TIFF identity bytes at the beginning of the file. 
If these identity bytes are present, it then looks for the custom 
TIFF tag designated UIC2. If it finds this tag, it decides the file
has the STK format.

=cut


sub getGroups {
    my $self = shift;
    my $fref = shift;
    my $nmlen = scalar(keys %$fref);
    my @outlist;

    foreach my $key (keys %$fref) {
        my $file = $fref->{$key};

        $file->open('r');

        my $tags = readTiffIFD($file);
        $file->close();

        my $uic2 = UIC2;
        next if (!defined($tags->{$uic2}));

        my $t_arr = $tags->{$uic2};
        my $t_hash = $$t_arr[0];

        # it's STK format, so remove from input list, put on output list
        delete $fref->{$key};
        push @outlist, $file;
    }

    $self->{groups} = \@outlist;

    return \@outlist;
}



=head2 importGroup

    my $image = $importer->importGroup(\@files)

This method imports individual STK format files into OME
5D images. The caller passes a set of input files by
reference. This method opens each file in turn, extracts
its metadata and pixels, and creates a coresponding OME image.

Besides the metadata it extracts from standard TIFF tag values, this
method also extracts metadata from the custom STK tags called UIC1,
UIC2, UIC3, and UIC4.

The arrangement of the planes in the STK file may not be in the canonical
OME order (XYZCT). Before writing the image out to the OME repository,
this method executes a routine (parition_and_sort) that recursively 
sorts the planes of the STK file on each dimension, ordering the output in
 XYZCT order.

If all goes well, this method returns a pointer to a freshly created 
OME::Image. In that case, the caller should commit any outstanding
image creation database transactions. If the module detects an error,
it will return I<undef>, signalling the caller to rollback any associated
database transactions.

=cut


# Import a single group. For STK format files, a group always contains
# just one file.

sub importGroup {
    my ($self, $file, $callback) = @_;
    my $status;

    my $sha1 = $file->getSHA1();

    my $session = ($self->{super})->Session();
    my $factory = $session->Factory();

    $file->open('r');


    my $tags = readTiffIFD($file);
    if (!defined($tags)) {
	$file->close();
	return undef;
    }
    my $filename = $file->getFilename();
    my $base = ($self->{super})->__nameOnly($filename);

    my ($offsets_arr, $bytesize_arr) = getStrips($tags);

    my $params = $self->getParams();
    $params->image_offsets($offsets_arr);
    $params->image_bytecounts($bytesize_arr);
    
    $params->fref($file);
    $params->oname($filename);
    $params->endian($tags->{__Endian});
    my $xref = $params->{xml_hash};
    $xref->{'Image.SizeX'} = $tags->{TAGS->{ImageWidth}}->[0];
    $xref->{'Image.SizeY'} = $tags->{TAGS->{ImageLength}}->[0];
    $xref->{'Data.BitsPerPixel'} = $tags->{TAGS->{BitsPerSample}}->[0];
    $params->byte_size($xref->{'Data.BitsPerPixel'}/8);
    $params->row_size($xref->{'Image.SizeX'} * ($params->byte_size));

    my @ui_tags = (UIC1, UIC2, UIC3, UIC4);
    foreach my $u (@ui_tags) {
        my $t_arr = $tags->{$u};
	my $t_hash = $$t_arr[0];
	my $status = readTag ($self, $t_hash->{tag_id}, $t_hash->{tag_type},
			    $t_hash->{value_count}, $t_hash->{value_offset});
	die $status
	    unless ($status eq "");
    }

    my $image = ($self->{super})->__newImage($base);
    $self->{image} = $image;


    # pack together & store info on input file
    my @finfo;
    $self->__storeOneFileInfo(\@finfo, $file, $params, $image,
			      0, $xref->{'Image.SizeX'}-1,
			      0, $xref->{'Image.SizeY'}-1,
			      0, $xref->{'Image.SizeZ'}-1,
			      0, $xref->{'Image.NumWaves'}-1,
			      0, $xref->{'Image.NumTimes'}-1,
                  "Metamorph STK");

    my ($pixels, $pix) = 
	($self->{super})->__createRepositoryFile($image, 
						 $xref->{'Image.SizeX'},
						 $xref->{'Image.SizeY'},
						 $xref->{'Image.SizeZ'},
						 $xref->{'Image.NumWaves'},
						 $xref->{'Image.NumTimes'},
						 $xref->{'Data.BitsPerPixel'});
    $self->{pixels} = $pixels;
    $status = readWritePixels($self, $params, $pix, $callback);

    $file->close();

    if ($status eq "") {
	$self->__storeInputFileInfo($session, \@finfo);
	# Store info about each input channel (wavelength).
	storeChannelInfo($self, $session);
	return $image;
    } else {
	($self->{super})->__destroyRepositoryFile($pixels, $pix);
	die $status;
    }

}


# This method reads a STK specific tag and loads its contents into $self
sub readTag {
    my ($self, $tagname, $type, $cnt, $offset) = @_;
    my $params = $self->{params};
    my $endian = $params->endian;
    my $fih    = $params->fref;
    my $cur_offset;
    my $status;


    $offset = $fih->setCurrentPosition($offset,0);

    if ($tagname == UIC1 ) {
	$status = do_uic1("UIC1", $endian, $fih, $type, $cnt);
    }
    elsif ($tagname == UIC2 ) {
	$status = do_uic2($self, $endian, $fih, $type, $cnt);
    }
    elsif ($tagname == UIC3 ) {
	$status = do_uic3($self, $endian, $fih, $type, $cnt);
    }
    elsif ($tagname == UIC4 ) {
	$status = do_uic1("UIC4", $endian, $fih, $type, $cnt);
    }
    else {
	$status = "Unknown TIFF tag $tagname for STK file";
    }


    return($status);
}


# This method reads in the image data & puts it into a multidimensional
# array in XYZWT order. In STK format, all the image planes, and hence
# their component TIFF strips,  are stored in consequetive locations,
# making location easy. Also, the metadata is retrieved  from its
# holding hashes, and put into the output hash in the proper order.
#   Plane n's starting addr is: Offset to 1st plane + n*(plane size)

sub readWritePixels {
    my $self = shift;
    my $params =shift;
    my $pix = shift;
    my $callback = shift;

    my $fih            = $params->fref;
    my $endian         = $params->endian;
    my $xml_hash       = $params->xml_hash;
    my $row_size       = $params->row_size;
    my $offsets_arr    = $params->image_offsets;
    my $bytecounts_arr = $params->image_bytecounts;
    my $xyzwt          = $params->obuffer;
    my (@xy_arr, @xyz, @xyzw);
    my $start_offset;
    my $end_offset;
    my $plane_size;
    my $num_rows;
    my $ibuf;
    my $status = "";
    my $plane_num;
    my $ky;
    my $time;
    my $u2;
    my $dtm = $uic2_ndxs{Cr_dt};
    my %planes;
    my @args;


    $start_offset = $$offsets_arr[0];
    $end_offset = $$offsets_arr[$#$offsets_arr];         # start of last strip\
    my @foo = @$bytecounts_arr;
    $end_offset += $$bytecounts_arr[$#$bytecounts_arr];  # end of last strip
    $plane_size = $end_offset - $start_offset;
    $num_rows = $plane_size/$row_size;

    # sort planes 1st by creation time, then by wavelength, and then by Z value
    # this will leave them in XYZWT order

    $u2 = $self->{uic2};
    #$u2->{3}[2] = 1; # HARDWIRED VALUE - for testing only
    #$u2->{3}[7] = 444; # HARDWIRED VALUE - for testing only
    #$u2->{2}[2] = 1; # HARDWIRED VALUE - for testing only
    #$u2->{0}[2] = 1; # HARDWIRED VALUE - for testing only

    # sort planes in time order
    # hold the order in the hash %planes. The key is the ordinal (0 = 1st,
    # 1 = 2nd, ...), and the value is the number of the plane.
    $plane_num = 0;
    for $time  (sort {$u2->{$a}[$dtm] <=> $u2->{$b}[$dtm]} keys %$u2) {
	$planes{$plane_num++} = $time;
    }
    $plane_num--; # this is the last plane in the clump


    # partition into clumps, and subsort the clumps
    # Will arrange the image planes into the proper XYZWT order.

    my @indeces = qw(Z_val W_ave Cr_dt);
    partition_and_sort($params, \@xy_arr, $start_offset, 0, $plane_num,
			$plane_size, $num_rows, $u2, \%planes, @indeces);

    # The planes are in the OME canonical order - write them out
    #reverse @xy_arr;
    my ($t, $c, $z);
    my $maxY = $xml_hash->{'Image.SizeY'};
    my $maxZ = $xml_hash->{'Image.SizeZ'};
    my $maxC = $xml_hash->{'Image.NumWaves'};
    my $maxT = $xml_hash->{'Image.NumTimes'};
    for (my $i = 0, $t = 0; $t < $maxT; $i++, $t++) {
	for ($c = 0; $c < $maxC; $c++) {
	    for ($z = 0; $z < $maxZ; $z++) {
		my $offset = $start_offset + ($planes{$i}) * $plane_size;
		$pix->convertPlane($fih,$offset,$z,$c,$t,$endian == BIG_ENDIAN);
		doSliceCallback($callback);
	    }
	}
    }

	OME::Tasks::PixelsManager->finishPixels ($pix,$self->{pixels});

    return $status;
}


# Input - a multidimensional set of entities that are already sorted on
# the first dimension. A list, in reverse hierarchical order, of the 
# dimensions to sort on. The values for each dimensions are in the uic2 hash.
#
# Action - partition entities into clumps, where each clump has the same
# value of its first dimension. Then recursively sort each clump on the
# next lower dimension. 
#


sub partition_and_sort {
    my ($params, $oarray, $st_offset, $st_plane, $end_plane, $plane_size, $num_rows, $u2, $planes, @ndx_keys) = @_;
    my $fih      = $params->fref;
    my $endian   = $params->endian;
    my $bps      = $params->byte_size;
    my $row_size = $params->row_size;
    my $row;
    my @obuf;
    my ($ibuf, $rowbuf);
    my ($pl, $i);
    my $status = "";
    my $offset;
    my $depth;
    my $num_slices;
    my ($st_slice, $end_slice);
    my $ndx_key = pop @ndx_keys;
    my $ndx = $uic2_ndxs{$ndx_key}; # partition on 1st index in list

    $depth = 3 - scalar @ndx_keys;

    for ($pl = $st_plane; $pl <= $end_plane; $pl++) {
	my @subarray;
	# partition into sets of planes with equal values at the index of interest
	$st_slice = $end_slice = $pl;
	if (scalar @ndx_keys > 0) {
	    while ($pl< $end_plane) {
		if ($u2->{$planes->{$pl}}[$ndx] != $u2->{$planes->{$pl+1}}[$ndx]) {
		    last;
		}
		$end_slice = ++$pl;
	    }
	}
	else {
	    $end_slice = $end_plane;   # no more things to test - lump remainder together
	}


	if ((scalar @ndx_keys > 0) && ($st_slice != $end_slice)) {
	    slice_sorter($u2, $planes, $st_slice, $end_slice, @ndx_keys);
	    # now partition & sort this clump on next sort attribute in list
	    partition_and_sort($params, \@subarray, $st_offset, $st_slice, $end_slice, $plane_size, $num_rows, $u2, $planes, @ndx_keys);
	    push @$oarray, \@subarray;
	}
	else {   # we have descended from XYZWT to XY hierarchy, or have only 1 plane
		# reading row-at-a-time used to be here
		
		# reading row-at-a-time ended here
	}
	$pl += ($end_slice - $st_slice);  # account for extra planes written here
    }
}



# Sort passed slice. Value to sort on is at array index $ndx_key

sub slice_sorter {
    my ($u2, $planes, $st_slice, $end_slice, @ndx_keys) = @_;
    my @sorted;
    my $ndx_key = pop @ndx_keys;
    my $ndx = $uic2_ndxs{$ndx_key};
    my $hr;
    my $ky;

    # if have a slice > 1 entry long, then sort it by value at $ndx
    if ($st_slice != $end_slice) {
	@sorted = sort {$u2->{$planes->{$a}}[$ndx] <=> $u2->{$planes->{$b}}[$ndx]} ($st_slice .. $end_slice);
	my $href = {};
	$hr = 0;
	foreach $ky (@sorted) {     # store values that are being swapped
	    $href->{$hr++} = $planes->{$ky};
	    }
	my $hr = 0;
	while ($st_slice <= $end_slice) { # now do the swap
	    $planes->{$st_slice++} = $href->{$hr++};
	}
    }
}



# The UIC1 tag refers to $cnt ID/value pairs. These
# will be stored in this instance's %uic1 hash. In all
# cases, the ID part of the pair will be the hash key.
# In some cases. the value is simply a straight value.
# In this case, store the pair as a key/value in our
# private UIC1 hash. In the other cases, the value serves
# as an offset to 1, 2, N, or 2N longs. For these, store
# the referenced long as a flat list in the value part
# of the UIC1 hash. The ID is a long.
#

# The format and meaning of the ID/value or value sets when this is called
# to handle UIC4 data is identical to the definitions for the UIC1 tag, except the
# ID is a short. However, this tag will contain ID/value pair sets for each of the 
# N planes in the stack. Each set is terminated by an ID = 0. This set of N sets of
# ID/pairs will be put into the %uic4 hash.
#
# Nothing is actually done yet with any data from the UIC1 or UIC4 tags. It
# is parsed in case a use is ever found for it (or the UIC4 data gets reliable)

sub do_uic1 {
    my ($caller, $endian, $file, $type, $tag_cnt) = @_;
    my $status = "";
    my $i;
    my $id;
    my $id_len = ($caller eq "UIC1" ? 4 : 2);
    my $name;
    my ($read_it, $readit_loc);
    my ($type1, $type4);
    my $MMtype;
    my $len;
    my $buf;
    my $fmt;
    my %uic1;

    if ($caller =~ m/UIC1/) {
	$fmt = ($endian == LITTLE_ENDIAN) ? "V" : "N";
	$readit_loc = 2;
    }
    else {
	$fmt = ($endian == LITTLE_ENDIAN) ? "v" : "n";
	$readit_loc = 3;
    }

    for ($i = 0; $i < $tag_cnt; $i++) {
	# Get ID of next field
        $buf = $file->readData($id_len);
	$id = unpack($fmt, $buf);
	if (($caller =~ /UIC4/) && ($id == 0)) {
	    last;   # in UIC4, an ID of 0 is the signal to stop processing the tag
	}
	$name = $codes{$id}[1];
	return ($status = "Unknown key value $id in $caller tag data")
	    unless (defined $name);
	$MMtype = $codes{$id}[0];

	if ($caller =~ /UIC4/) {
	    $file->setCurrentPosition(2,1);
	}

	$read_it = $codes{$id}[$readit_loc];    # Each ID is only valid in one of UIC1 or UIC4
	if ($read_it == 0) {
        $file->setCurrentPosition(4,1);
	    next;
	}


	# switch on $MMtype to determine how to read value
	if ($caller =~ m/UIC1/) {
	    $type1 = $MMtype;
	    $type4 = $MMtype;
	}
	else {
	    $type1 = 'L';
	    $type4 = $MMtype;
	}
	if ($name =~ m/(StagePosition)|(CameraChipOffset)|(StageLabel)|(AbsoluteZ)|(AbsoluteZValid)/) {
	    $status = get_value($type4, $file, $endian, $tag_cnt);
	}
	else {
	    $status = get_value($type1, $file, $endian, $tag_cnt);
	}
	last
	    unless $status eq "";

    }

    return $status;
}


# By definition, the presence of a UIC2 tag marks this file as a MetaMorph stack.
# Its count field contains the number of planes in the stack. By examining
# the actual Z and time values, one can determine the number of Z planes
# and the number of different time points.
# This tag points to a contiguous set of 6 values for each of the N Z planes in the stack.
# Put each set of 6 values, as an array, into the %uic2 hash, keyed by its plane number (0 to N-1)

sub do_uic2 {
    my ($self, $endian, $file, $type, $num_planes) = @_;
    my $params = $self->{params};
    my $xml_hash = $params->xml_hash;
    my $status = "";
    my $i;
    my $k;
    my @arr;
    my $buf;
    my $fmt = ($endian == LITTLE_ENDIAN) ? "V6" : "N6";
    my ($Z_num, $Z_denom, $cdt, $cdate, $ctime, $mdate, $mtime);
    my $Z_val;
    my $last_Z = 0;
    my ($numZs, $numTs);
    my %uic2;

    $xml_hash->{'Image.ImageType'} = "STK";  # UIC2 tag marks this as STK format
    $self->{NumStacks} = $num_planes;     # Number of planes in this stack

    # read in a 6-tuple set of values for each of the $num_planes planes in the stack
    for ($i = 0; $i < $num_planes; $i++) {
        $buf = $file->readData(6*4);
	($Z_num, $Z_denom, $cdate, $ctime, $mdate, $mtime) = unpack($fmt, $buf);
	$Z_val = $Z_num/$Z_denom;
	# keep track of # different Z values
	if ($Z_val != $last_Z) {
	    $last_Z = $Z_val;
	    $numZs++;
	}
	$cdt = ($cdate * 86400000) + $ctime;   # date & time into 1 number for easy sorting
	# include plane # in hash since it won't necessarily equal the key after sorting
	$uic2{$i} = [$i, $Z_val, $cdt, $cdate, $ctime, $mdate, $mtime];

	JulianToYMD($cdate);
	TimeOfDay($ctime);
	if ($mdate != 0) {
	    JulianToYMD($mdate);
	    TimeOfDay($mtime);
	}
    }

    # These values may be modified after processing UIC3 (the wavelength tag)
    $numZs = $numZs ? $numZs : 1;
    $xml_hash->{'Image.SizeZ'} = $numZs;
    $numTs = $num_planes/$numZs;
    $xml_hash->{'Image.NumTimes'} = $numTs;


    $self->{uic2} = \%uic2;  # remember to access this hash after doing a `sort keys`

    return $status;
}


# The  UIC3  tag points to a pair of integers for each of the Z planes
# in the stack. The ratio of each pair is the wavelength used in imaging
# the pair's associated Z plane. Put these ratios, keyed by the plane
# number (0 thru N-1) into the %iuc3 hash. Store these ratios along with
# the other per plane data in the %uic2 hash.

sub do_uic3 {
    my ($self, $endian, $file, $type, $num_planes) = @_;
    my $fmt = ($endian == LITTLE_ENDIAN) ? "V2" : "N2";
    my $params = $self->{params};
    my $xml_hash = $params->xml_hash;
    my $status = "";
    my ($denom, $numer);
    my $W_val;
    my $last_W = 0;
    my $numWs;
    my $buf;
    my $i;
    my $u2;
    my $aref;
    my %uic3;

    for ($i = 0; $i < $num_planes; $i++) {
        $buf = $file->readData(2*4);
	($numer, $denom) = unpack($fmt, $buf);
	$W_val = $numer/$denom;
	# keep track of # different wave values
	if ($W_val != $last_W) {
	    $last_W = $W_val;
	    $numWs++;
	}
	
	$uic3{$i} = $W_val;
    }
    $self->{uic3} = \%uic3;

    $xml_hash->{'Image.NumWaves'} = (($numWs == 0) ? 1 : $numWs);
    # if number of waves > 1, have to re-adjust NumT
    if ($numWs > 1) {
	my $numZT = $num_planes/$numWs;
	$xml_hash->{'Image.NumTimes'} = $numZT/$xml_hash->{'Image.SizeZ'};
    }

    $self->{uic3} = \%uic3;  # remember to access this hash after doing a `sort keys`

    return $status;
}



# get_value returns the value(s) associated with a tag. As a side effect, it will
# leave the file pntr positioned at the start of the next tag.

sub get_value {
    my ($MMtype, $file, $endian, $cnt) = @_;
    my $status;
    my $buf;
    my $cur_offset;
    my $value;
    my ($val1, $val2, $val3, $val4, $rat);
    my $i;

    {    # Double block to allow use of the 'last' operator
    $cur_offset = $file->getCurrentPosition();
    # all except types L have an offset to where their values are
    if ($MMtype !~ /^L$/) {  
	# remember current file pntr position & go to the value(s)
	($cur_offset, $status) = go_there($file, $endian); 
	last unless $status eq "";
    }

    # long type
    if ($MMtype eq 'L') {
	$status = get_long($file, $endian, \$value);
	if ($status eq "") {
	    $cur_offset += 4;
	}
    }
    # string type
    elsif ($MMtype eq 'S') {
	$status = get_string($file, $endian, \$buf);
	if ($status eq "") {
	}
    }
    # "rational" type - read 2 longs, value is the 1st divided by the 2nd
    elsif ($MMtype eq 'R') {
	$status = get_rational($file, $endian, \$val1, \$val2);
	last unless (($status eq "") && ($val2 != 0));
	$rat = $val1/$val2;
    }
    # "N4' type - N sets of 4 longs = N sets of 2 rationals
    elsif ($MMtype eq 'N4') {
	for ($i = 0; $i < $cnt; $i++) {
	    my ($rat1, $rat2);
	    $status = get_long($file, $endian, \$val1);   # get 1st Long
	    last unless $status eq "";
	    $status = get_long($file, $endian, \$val2);   # get 2nd Long
	    last unless $status eq "";
	    $status = get_long($file, $endian, \$val3);   # get 3rd Long
	    last unless $status eq "";
	    $status = get_long($file, $endian, \$val4);   # get 4th Long
	    last unless $status eq "";
	    last unless (($val2 > 0) && ($val4 > 0)); 
	    $rat1 = $val1/$val2;
	    $rat2 = $val3/$val4;
	}
    }
    # 'NS' type - N strings
    elsif ($MMtype eq 'NS') {
	for ($i = 0; $i < $cnt; $i++) {
	    $status = get_string($file, $endian, \$buf);
	    last
		unless $status eq "";
	}
    }
    # 'N2' type - N rationals
    elsif ($MMtype eq 'N2') {
	for ($i = 0; $i < $cnt; $i++) {
	    $status = get_rational($file, $endian, \$val1, \$val2);
	    last unless (($status eq "") && ($val2 != 0));
	    $rat = $val1/$val2;
	}
    }
    # Date/Time type
    elsif ($MMtype eq 'T') {
	$status = get_long ($file, $endian, \$value);
	if ($status eq "") {
	    $status = get_long ($file, $endian, \$value);
	    TimeOfDay($value);
	}
    }
    elsif ($MMtype eq 'NL') {
	for ($i = 0; $i < $cnt; $i++) {
	    $status = get_long($file, $endian, \$value);
	    last unless $status eq "";
	}
    }
    # 'LO' type - offset to a single Long. Why not put the long in the tag itself?
    elsif ($MMtype eq 'LO') {
	$status = get_long($file, $endian, \$value);
	last unless $status eq "";
    }
			 
    else {
	$status = "Unknown UIC tag ID: $MMtype";
    }

    if ($status eq "") {
	# restore file pntr to end of tag
        $file->setCurrentPosition($cur_offset,0);
    }

}

    if ($status eq "Skip") {
        $file->setCurrentPosition($cur_offset,0);
        $status = "";
    }
    return $status;
}


sub get_long {
    my ($fih, $endian, $value) = @_;
    my $status = "";
    my $buf;
    my $fmt;

    if (ref($value) eq "") {
	$status =  "Need to be passed a reference to a variable";
    } else {
	$buf = $fih->readData(4);
	return $status
	    unless $status eq "";
	$fmt = ($endian == LITTLE_ENDIAN) ? "V" : "N";
	$$value = unpack($fmt, $buf);
    }

    return $status;
}


sub go_there {
    my ($fih, $endian) = @_;
    my $cur_offset;
    my $status;
    my $offset;

    $status = get_long($fih, $endian, \$offset); # value is offset to where data stored
    $cur_offset = $fih->getCurrentPosition();
    if ($offset == 0) {     # Apparently, they use an offset of 0 to mean 'ignore field'
	$status = "Skip";
    }
    if ($status eq "") {
        $fih->setCurrentPosition($offset,0);
        $status = "";
    }
    return ($cur_offset, $status);
}


sub get_string {
    my ($fih, $endian, $buf) = @_;
    my $status;
    my $len;
    my $buf2;
    my ($cur_offset, $delta);
    $status = get_long($fih, $endian, \$len);     # string length precedes characters
    if ($status eq "") {
	# read 'length' characters
        $buf2 = $fih->readData($len);
	$$buf = $buf2;
    }
    if ($len == 0) {
	$status = "Skip";
    }
    return $status;
}


# get a rational
sub get_rational {
    my ($fih, $endian, $val1, $val2) = @_;
    my $status;
    my ($v1, $v2);
    my $rat = 0;

    {
    $status = get_long($fih, $endian, $val1); # read the 2 longs
    last unless $status eq "";
    $status = get_long($fih, $endian, $val2);
    last unless $status eq "";
    }

    return $status;
}

# taken from UIC's STK documentation
sub JulianToYMD {
    my $julian =  shift;
    my ($a, $b, $c, $d, $e, $alpha, $z);
    my ($day, $month, $year);
    
    $z = $julian +1;
    if ($z < 2299161) {
	$a = $z;
    }
    else {
	$alpha = ($z - 1867216.25)/36524.25;
	$a = $z + 1 + $alpha - $alpha/4;
    }
    $b = ($a > 1721423 ? $a + 1524 : $a + 1158);
    $c = ($b - 122.1)/365.25;
    $d = 365.25 * $c;
    $e = ($b - $d)/30.6001;
    $day = $b - $d - (30.6001 * $e);
    $month = ($e < 13.5) ? $e - 1 : $e - 13;
    $year = ($month > 2.5) ? ($c - 4716) : ($c - 4715);
    $day = sprintf("%.0f",$day);
    $month = int($month);
    $year = int($year);
}


sub TimeOfDay {
    my $ticks = shift;
    my $secs = int($ticks/1000);
    my $mins = int($secs/60);
    my $hours = int($mins/60);

    $mins -= $hours * 60;
    $secs -= (($hours * 3600) + ($mins * 60));
}



# Get %params hash reference
sub getParams {
    my $self = shift;
    return $self->{params};
}


# Store channel (wavelength) info
sub storeChannelInfo {
    my $self = shift;
    my $session = shift;
    my $params = $self->getParams();
    my $xref = $params->{xml_hash};
    my $numWaves = $xref->{'Image.NumWaves'};
    my $u3 = $self->{uic3};
    my @channelInfo;

    for (my $i = 0; $i < $numWaves; $i++) {
	push @channelInfo, {chnlNumber => $i,
			    ExWave     => undef,
			    EmWave     => $u3->{$i},
			    Fluor      => undef,
			    NDfilter   => undef};
    }

    $self->__storeChannelInfo($session, $numWaves, @channelInfo);
}

sub getSHA1 {
    getCommonSHA1(@_);
}


=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>
L<OME::ImportEngine::TIFFreader.pm>

=cut

1;
