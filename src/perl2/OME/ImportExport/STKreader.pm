#!/usr/bin/perl -w
#
# STKreader.pm
# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Brian S. Hughes
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

# This class contains the methods to handle the STK variant of a TIFF
# format file.

# ---- Public routines -------
# new()
# readTag()
# formatImage()

# ---- Private routines ------
# partition_and_sort()
# slice_sorter()
# do_uic1()
# do_uic2()
# do_uic3()
# get_value()
# get_long()
# go_there()
# get_string()
# get_rational
# JulianToYTD()
# TimeOfDay()

package OME::ImportExport::STKreader;
our @ISA = ("OME::ImportExport::Import_reader", "OME::ImportExport::TIFFreader");
use strict;
use Carp;
use OME::ImportExport::FileUtils;
use OME::ImportExport::Params;
use OME::ImportExport::PixWrapper;
use vars qw($VERSION);
$VERSION = '1.0';

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



sub new {

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};
    $self->{params} = shift;

    return bless $self, $class;
}


# This method reads a STK specific tag and loads its contents into $self
sub readTag {
    my ($self, $tagname, $type, $cnt, $offset) = @_;
    my $params = $self->{params};
    my $endian = $params->endian;
    my $fih    = $params->fref;
    my $cur_offset;
    my $status;


    $status = OME::ImportExport::FileUtils::seek_it($fih, $offset);
    return $status
	unless $status eq "";

    if ($tagname eq "UIC1" ) {
	$status = do_uic1("UIC1", $endian, $fih, $type, $cnt);
    }
    elsif ($tagname eq "UIC2" ) {
	$status = do_uic2($self, $endian, $fih, $type, $cnt);
    }
    elsif ($tagname eq "UIC3" ) {
	$status = do_uic3($self, $endian, $fih, $type, $cnt);
    }
    elsif ($tagname eq "UIC4" ) {
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

sub formatImage {
    my $self = shift;;
    my $pixWrap = shift;
    my $params = $self->{params};
    my $xml_hash       = $params->xml_hash;
    my $row_size       = $params->row_size;
    my $offsets_arr    = $params->image_offsets;
    my $bytecounts_arr = $params->image_bytecounts;
    my $xyzwt          = $params->obuffer;
    my ($offs_arr, $bytes_arr);
    my (@xy_arr, @xyz, @xyzw);
    my $start_offset;
    my $end_offset;
    my $plane_size;
    my $num_rows;
    my $status = "";
    my $plane_num;
    my $ky;
    my $time;
    my $u2;
    my $dtm = $uic2_ndxs{Cr_dt};
    my %planes;
    my @args;

    $offs_arr = @$offsets_arr[0];
    $start_offset = $$offs_arr[0];  # begining of image data
    $end_offset = $$offs_arr[$#$offs_arr];         # start of last strip
    $bytes_arr = @$bytecounts_arr[0];
    $end_offset += $$bytes_arr[$#$bytes_arr];  # end of last strip
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
	#print "  sorted $time\n";
	$planes{$plane_num++} = $time;
    }
    $plane_num--; # this is the last plane in the clump


    # partition into clumps, and subsort the clumps
    # Will put image data, in XYZWT order, into 5D array for return to caller
    my @indeces = qw(Z_val W_ave Cr_dt);
    $status = partition_and_sort($params, \@xy_arr, $start_offset, 0, $plane_num, $plane_size, $num_rows, $u2, \%planes, @indeces);

    # now have list of all the XY planes. Arrange them in their 5D order
    #reverse @xy_arr;
    my ($t, $w, $z);
    my $maxY = $xml_hash->{'Image.SizeY'};
    my $maxZ = $xml_hash->{'Image.SizeZ'};
    my $maxW = $xml_hash->{'Image.NumWaves'};
    my $maxT = $xml_hash->{'Image.NumTimes'};
    for ($t = 0; $t < $maxT; $t++) {
	for ($w = 0; $w < $maxW; $w++) {
	    for ($z = 0; $z < $maxZ; $z++) {
		my $num_rows = 0;
		my $plane = pop(@xy_arr);
		my $rows = "";
		my $row;
		# flatten plane into string of rows
		for (my $y = 0; $y < $maxY; $y++) {
		    $row = $$plane[$y];
		    substr($rows, length($rows), 0, $row);
		    $num_rows++;
		}
		my $nPixOut = $pixWrap->SetRows ($rows, $num_rows);
		if ($plane_size/$params->byte_size != $nPixOut) {
		    $status = "Failed to write repository file - $plane_size/$params->byte_size != $nPixOut";
		    last;
		}
		
	    }
	}
    }



    #     Store the per plane metadata for return to caller
    # For each plane, in order, create XYinfo element & Wavelength element.
    # The individual elements will be hashes, and each hash will be
    # pushed onto an array, which will be hashed onto the XYinfo and 
    # Wavelength hash keys.
    my $w_aref = [];
    my $xy_aref = [];
    my $key;
    my $val;
    my $xref    =  $xml_hash->{'XYinfoPlane.'};   # ref to array built by TIFFreader
    my $wref    =  $xml_hash->{'WavelengthInfoPlane.'}; # another array from TIFFreader
    my ($znum, $wnum, $tnum) = (1, 1, 1);

    # Extract out & store the per plane data (XYinfo & WaveLength)
    foreach $ky (sort keys %planes) {
	#print "  sorted $ky -> $planes{$ky}\n";
	my $plane_num = $planes{$ky};

	# first make the XYinfo elements
	my $xyhref = {};
	# N.B. If TIFFReader leaves more than 1 pair of key/value,
	# the following must be expanded.
	$key = $xref->[0]->[$plane_num]->[0];  # copy, in proper order, XYinfo
	$val = $xref->[0]->[$plane_num]->[1];  #    left by TIFFreader
	$xyhref->{'XYinfo.'.$key} = $val;  # copy
	$xyhref->{'XYinfo.Stagepos.Z'} = $self->{uic2}->{$plane_num}[1];
	# IGG 10/06/02:  OME dimensions begin at 0.
	$xyhref->{'XYinfo.Zsection'} = ($znum++) - 1;
	$xyhref->{'XYinfo.WaveNumber'} = $wnum - 1;
	$xyhref->{'XYinfo.TimePoint'} = $tnum - 1;
	push @$xy_aref, $xyhref;

	# and now make the WavelengthInfo elements
	my $whref = {};
	# N.B. If TIFFReader leaves more than 1 pair of key/value,
	# the following must be expanded.
	$key = $wref->[0]->[$plane_num]->[0];  # copy Wave data, in order
	$val = $wref->[0]->[$plane_num]->[1];  #    left by TIFFreader
	$whref->{'WavelengthInfo.'.$key} = $val;  # copy
	$whref->{'WavelengthInfo.EmWave'} = $self->{uic3}->{$plane_num};
	# IGG 10/06/02:  OME dimensions begin at 0.
	$whref->{'WavelengthInfo.WaveNumber'} = $wnum - 1;
	push @$w_aref, $whref;

	if ($znum > $maxZ) {
	    $znum = 1;
	    $wnum++;
	    if ($wnum > $maxW) {
		$wnum = 1;
		$tnum++;
	    }
	}

    }
    
    # overwrite info at key 'XYinfo.'
    $xml_hash->{'XYinfo.'} = $xy_aref;
    $xml_hash->{'WavelengthInfo.'} = $w_aref;
    delete $xml_hash->{'XYinfoPlane.'};
    delete $xml_hash->{'WavelengthInfoPlane.'};

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
    #print "  ++ $depth: 1st plane: $st_plane  last plane: $end_plane\n";

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
	    #print "  ++ $depth: got back an array with ", scalar @subarray, " entries\n";
	}
	else {   # we have descended from XYZWT to XY hierarchy, or have only 1 plane
	         # so it's time to actually read bits
	    $depth = 3 - scalar @ndx_keys;
	    for ($i = $st_slice; $i <= $end_slice; $i++) {
		my @xy;
		for ($row = 0; $row < $num_rows; $row++) {
		    $offset = $st_offset + ($planes->{$i}) * $plane_size;
		    $status = OME::ImportExport::FileUtils::seek_and_read($fih, \$ibuf, $offset, $row_size);
		    last
			unless $status eq "";
		    my $cnt = Repacker::repack($ibuf, $row_size, 
				     $bps,
				     $endian eq "little",
				     $params->{host_endian} eq "little");
		    push @xy, $ibuf;
		    $offset += $row_size;
		}
		push @$oarray, \@xy;
	    }
	    $pl += ($end_slice - $st_slice);  # account for extra planes written here
	}
    }

    return $status;
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
	#print "\t keys to swap: @sorted\n";
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
# is parseds in case a use is ever found for it (or the UIC4 data gets reliable)

sub do_uic1 {
    my ($caller, $endian, $fih, $type, $tag_cnt) = @_;
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
	$fmt = ($endian eq "little") ? "V" : "N";
	$readit_loc = 2;
    }
    else {
	$fmt = ($endian eq "little") ? "v" : "n";
	$readit_loc = 3;
    }

    for ($i = 0; $i < $tag_cnt; $i++) {
	$status = OME::ImportExport::FileUtils::read_it($fih, \$buf, $id_len);   # Get ID of next field
	last
	    unless $status eq "";
	$id = unpack($fmt, $buf);
	if (($caller =~ /UIC4/) && ($id == 0)) {
	    last;   # in UIC4, an ID of 0 is the signal to stop processing the tag
	}
	$name = $codes{$id}[1];
	return ($status = "Unknown key value $id in $caller tag data")
	    unless (defined $name);
	$MMtype = $codes{$id}[0];
	    #print "*** $name: ";

	if ($caller =~ /UIC4/) {
	  OME::ImportExport::FileUtils::skip($fih, 2);
	}

	$read_it = $codes{$id}[$readit_loc];    # Each ID is only valid in one of UIC1 or UIC4
	if ($read_it == 0) {
	    OME::ImportExport::FileUtils::skip($fih, 4);    # ignore this field, so skip over it
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
	    #print " format: $type4 ";
	    $status = get_value($type4, $fih, $endian, $tag_cnt);
	}
	else {
	    $status = get_value($type1, $fih, $endian, $tag_cnt);
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
    my ($self, $endian, $fih, $type, $num_planes) = @_;
    my $params = $self->{params};
    my $xml_hash = $params->xml_hash;
    my $status = "";
    my $i;
    my $k;
    my @arr;
    my $buf;
    my $fmt = ($endian eq "little") ? "V6" : "N6";
    my ($Z_num, $Z_denom, $cdt, $cdate, $ctime, $mdate, $mtime);
    my $Z_val;
    my $last_Z = 0;
    my ($numZs, $numTs);
    my %uic2;

    $xml_hash->{'Image.ImageType'} = "STK";  # UIC2 tag marks this as STK format
    $self->{NumStacks} = $num_planes;     # Number of planes in this stack

    # read in a 6-tuple set of values for each of the $num_planes planes in the stack
    for ($i = 0; $i < $num_planes; $i++) {
	$status = OME::ImportExport::FileUtils::read_it($fih, \$buf, 6*4);
	last
	    unless ($status eq "");
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
    my ($self, $endian, $fih, $type, $num_planes) = @_;
    my $fmt = ($endian eq "little") ? "V2" : "N2";
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
	$status = OME::ImportExport::FileUtils::read_it($fih, \$buf, 2*4);
	last
	    unless ($status eq "");
	($numer, $denom) = unpack($fmt, $buf);
	$W_val = $numer/$denom;
	# keep track of # different wave values
	if ($W_val != $last_W) {
	    $last_W = $W_val;
	    $numWs++;
	}
	
	$uic3{$i} = $W_val;
	$u2 = $self->{uic2};
	$aref = $u2->{$i};
	push @$aref, $uic3{$i};   # Push the plane's w onto rest of per plane info

    }

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
    my ($MMtype, $fih, $endian, $cnt) = @_;
    my $status;
    my $buf;
    my $cur_offset;
    my $value;
    my ($val1, $val2, $val3, $val4, $rat);
    my $i;

    {    # Double block to allow use of the 'last' operator
    $cur_offset = tell $fih;
    # all except types L have an offset to where their values are
    if ($MMtype !~ /^L$/) {  
	# remember current file pntr position & go to the value(s)
	($cur_offset, $status) = go_there($fih, $endian); 
	last unless $status eq "";
    }

    # long type
    if ($MMtype eq 'L') {
	$status = get_long($fih, $endian, \$value);
	if ($status eq "") {
	    #print "   $value\n";
	    $cur_offset += 4;
	}
    }
    # string type
    elsif ($MMtype eq 'S') {
	$status = get_string($fih, $endian, \$buf);
	if ($status eq "") {
	    #print "   $buf\n";
	}
    }
    # "rational" type - read 2 longs, value is the 1st divided by the 2nd
    elsif ($MMtype eq 'R') {
	$status = get_rational($fih, $endian, \$val1, \$val2);
	last unless (($status eq "") && ($val2 != 0));
	$rat = $val1/$val2;
	#print "$val1/$val2 = $rat\n";
    }
    # "N4' type - N sets of 4 longs = N sets of 2 rationals
    elsif ($MMtype eq 'N4') {
	for ($i = 0; $i < $cnt; $i++) {
	    my ($rat1, $rat2);
	    $status = get_long($fih, $endian, \$val1);   # get 1st Long
	    last unless $status eq "";
	    $status = get_long($fih, $endian, \$val2);   # get 2nd Long
	    last unless $status eq "";
	    $status = get_long($fih, $endian, \$val3);   # get 3rd Long
	    last unless $status eq "";
	    $status = get_long($fih, $endian, \$val4);   # get 4th Long
	    last unless $status eq "";
	    last unless (($val2 > 0) && ($val4 > 0)); 
	    $rat1 = $val1/$val2;
	    $rat2 = $val3/$val4;
	    #print "ratios: $rat1, $rat2\n";
	}
    }
    # 'NS' type - N strings
    elsif ($MMtype eq 'NS') {
	#print "  getting $cnt string\n";
	for ($i = 0; $i < $cnt; $i++) {
	    $status = get_string($fih, $endian, \$buf);
	    last
		unless $status eq "";
	    #print "$buf\n";
	}
    }
    # 'N2' type - N rationals
    elsif ($MMtype eq 'N2') {
	for ($i = 0; $i < $cnt; $i++) {
	    $status = get_rational($fih, $endian, \$val1, \$val2);
	    last unless (($status eq "") && ($val2 != 0));
	    $rat = $val1/$val2;
	    #print "$val1/$val2 = $rat\n";
	}
    }
    # Date/Time type
    elsif ($MMtype eq 'T') {
	$status = get_long ($fih, $endian, \$value);
	if ($status eq "") {
	    #print "Date: $value  = ";
	    if ($value > 0) {
		#print JulianToYMD($value), "  ";
	    }
	    $status = get_long ($fih, $endian, \$value);
	    #print "Time: $value  ";
	    TimeOfDay($value);
	    #print "\n";
	}
    }
    elsif ($MMtype eq 'NL') {
	for ($i = 0; $i < $cnt; $i++) {
	    $status = get_long($fih, $endian, \$value);
	    last unless $status eq "";
		#print "   $value\n";
	}
    }
    # 'LO' type - offset to a single Long. Why not put the long in the tag itself?
    elsif ($MMtype eq 'LO') {
	$status = get_long($fih, $endian, \$value);
	last unless $status eq "";
		#print "   $value\n";
    }
			 
    else {
	$status = "Unknown UIC tag ID: $MMtype";
    }

    if ($status eq "") {
	# restore file pntr to end of tag
	$status = OME::ImportExport::FileUtils::seek_it($fih, $cur_offset);
    }

}

    if ($status eq "Skip") {
	$status = OME::ImportExport::FileUtils::seek_it($fih, $cur_offset);
    }
    return $status;
}


sub get_long {
    my ($fih, $endian, $value) = @_;
    my $status = "";
    my $buf;
    my $fmt;

    if (ref($value) eq "") {
	confess "Need to be passed a reference to a variable";
    }
    $status = OME::ImportExport::FileUtils::read_it($fih, \$buf, 4);
    return $status
	unless $status eq "";
    $fmt = ($endian eq "little") ? "V" : "N";
    $$value = unpack($fmt, $buf);

    return $status;
}


sub go_there {
    my ($fih, $endian) = @_;
    my $cur_offset;
    my $status;
    my $offset;

    $status = get_long($fih, $endian, \$offset); # value is offset to where data stored
    $cur_offset = tell $fih;
    if ($offset == 0) {     # Apparently, they use an offset of 0 to mean 'ignore field'
	$status = "Skip";
    }
    if ($status eq "") {
	#print " offset= $offset ";
	$status = OME::ImportExport::FileUtils::seek_it($fih, $offset);
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
    #print "   string is $len long\n";
    if ($status eq "") {
	$status = OME::ImportExport::FileUtils::read_it($fih, \$buf2, $len);  # read 'length' characters
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
    #print "$day $month $year ";
}


sub TimeOfDay {
    my $ticks = shift;
    my $secs = int($ticks/1000);
    my $mins = int($secs/60);
    my $hours = int($mins/60);

    $mins -= $hours * 60;
    $secs -= (($hours * 3600) + ($mins * 60));
    #print "$hours:$mins:$secs ";
}


1;
