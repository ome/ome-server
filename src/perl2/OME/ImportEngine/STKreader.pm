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
#                Tom Macura
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
#
# L  = contains a long, 
# R  = 2 longs (numerator and denomenator) producing a float,
# S  = Pascal string, w/ length as a long,
# T  = 2 longs - Date & Time, 
# NL = 1 long  for each of N planes,
# N2 = 2 longs for each of N planes,
# N4 = 4 longs for each of N planes, 
# NS = N Pascal strings

# N.B, type L is directly in the value half of the pair. For all other types, the value
# is actually the offset to the start of the referenced data.

# the last two fields are depreciated.
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
        next unless exists $tags->{$uic2};

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

    my $session = ($self->{super})->Session();
    my $factory = $session->Factory();
	my $params = $self->{params};

	my $filename = $file->getFilename();
    ($self->{super})->__nameOnly($filename);
    $params->fref($file);
    $params->oname($filename);
    
	# open file and read TIFF tags or return undef
	$file->open('r');
	my $tags = readTiffIFD($file);
    if (!defined($tags)) {
		$file->close();
		return undef;
    }
    
    # use TIFF tags to fill-out info about the img
    my ($offsets_arr, $bytesize_arr) = getStrips($tags);
    $params->image_offsets($offsets_arr);
    $params->image_bytecounts($bytesize_arr);
    $params->endian($tags->{__Endian});
    
    # read STK tags 
    my @ui_tags = (UIC1, UIC2, UIC3, UIC4);
    my @tag_type;
    my @tag_count;
    my @tag_offset;
    
    foreach my $u (@ui_tags) {
        my $t_arr = $tags->{$u};
		my $t_hash = $$t_arr[0];
		
		push @tag_type, $t_hash->{tag_type};
		push @tag_count, $t_hash->{value_count};
		push @tag_offset, $t_hash->{value_offset};	
	}
	
	# number of UIC2 tags corresponds to the number of planes. N.B: because of the idicoity of the STK
	# standard, this must be set before the do_uic* calls are made.
    $self->{NumStacks} = $tag_count[1];
    
    
	my %uic2 = do_uic2($self, $tag_type[1], $tag_count[1], $tag_offset[1]); # per plane z-position info
	my %uic3 = do_uic3($self, $tag_type[2], $tag_count[2], $tag_offset[2]); # per plane wavelength info
	#my %uic1 = do_uic1($self, "UIC1", $tag_type[0], $tag_count[0], $tag_offset[0]); # per stack info
	#my %uic4 = do_uic1($self, "UIC4", $tag_type[3], $tag_count[3], $tag_offset[3]); # per plane info
    
    my $xref = $params->{xml_hash};
    $xref->{'Image.ImageType'} = "STK";
    $xref->{'Image.SizeX'} = $tags->{TAGS->{ImageWidth}}->[0];
    $xref->{'Image.SizeY'} = $tags->{TAGS->{ImageLength}}->[0];
    
    # sizeZ is the number of different Z positions the planes were taken in
    my $sizeZ;
    foreach (keys(%uic2)) {
    	my $ptr = $uic2{$_};
    	my ($i, $Z_dist, $cdt, $cdate, $ctime, $mdate, $mtime) = @$ptr;
    	if ($Z_dist != 0) {
    		$sizeZ++;
    	}
    }
	$xref->{'Image.SizeZ'} = $sizeZ;

    # sizeC is the number of different Wavelengths the planes were taken in
	my %different_wavelengths;
    foreach (keys(%uic3)) {
 		my $wavelength = $uic3{$_};
   		$different_wavelengths{$wavelength} = 0;  
    }
    $xref->{'Image.NumWaves'} = scalar keys %different_wavelengths ;

        
    # number of time-points is derived from the number of planes and sizeZ and sizeC
    $xref->{'Image.NumTimes'} = $self->{NumStacks} / ($xref->{'Image.SizeZ'}  * $xref->{'Image.NumWaves'});
     
    $xref->{'Data.BitsPerPixel'} = $tags->{TAGS->{BitsPerSample}}->[0];
   	$params->byte_size($xref->{'Data.BitsPerPixel'}/8);
    $params->row_size($xref->{'Image.SizeX'} * ($params->byte_size));
						 
    my $image = ($self->{super})->__newImage($filename);
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
   
    # The planes are in the OME canonical order (hopefully, fingers crossed) - write them out
    my  $start_offset = $$offsets_arr[0];
    
    my ($t, $c, $z);
    my $maxY = $xref->{'Image.SizeY'};
    my $maxZ = $xref->{'Image.SizeZ'};
    my $maxC = $xref->{'Image.NumWaves'};
    my $maxT = $xref->{'Image.NumTimes'};
    my $plane_size = $xref->{'Image.SizeX'} * $xref->{'Image.SizeY'}*$params->byte_size;
    for (my $i = 0, $t = 0; $t < $maxT; $i++, $t++) {
		for ($c = 0; $c < $maxC; $c++) {
			for ($z = 0; $z < $maxZ; $z++) {
				my $offset = $start_offset + ($z+$c*$maxZ+$t*$maxZ*$maxC) * $plane_size;
				$pix->convertPlane($file,$offset,$z,$c,$t,$params->endian == BIG_ENDIAN);
				doSliceCallback($callback);
			}
		}
    }

	OME::Tasks::PixelsManager->finishPixels ($pix,$self->{pixels});
	

    $file->close();

	$self->__storeInputFileInfo($session, \@finfo);
	# Store info about each input channel (wavelength).
	storeChannelInfo($self, $session);
	return $image;

   	# TODO: How do we know nothing bad happened?
	#	($self->{super})->__destroyRepositoryFile($pixels, $pix);
	#	die $status;
}

# The UIC1 tag refers to $cnt ID/value pairs. These will be stored in this instance's 
# %uic1 hash. In all cases, the ID part of the pair will be the hash key. In some 
# cases. the value is simply a straight value. In this case, store the pair as a 
# key/value in our private UIC1 hash. In the other cases, the value serves as an 
# offset to 1, 2, N, or 2N longs. For these, store the referenced long as a flat 
# list in the value part of the UIC1 hash. The ID is a long.
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
    my ($self, $caller, $type, $tag_cnt, $offset) = @_;
    
    my $params   = $self->{params};
    my $endian   = $params->endian;
    my $file     = $params->fref;
    
   	$file->setCurrentPosition($offset, 0);
    
    my $status = "";
    my $i;
    my $id;
    my $id_len; # = ($caller eq "UIC1" ? 4 : 2);
    
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
		$id_len = 4;
    } else {
		$fmt = ($endian == LITTLE_ENDIAN) ? "v" : "n";
		$readit_loc = 3;
		$id_len = 2;
    }

    for ($i = 0; $i < $tag_cnt; $i++) {
		# Get ID of next field
		$id = unpack($fmt, $file->readData($id_len));
		
		if (($caller =~ /UIC4/) && ($id == 0)) {
			last;   # in UIC4, an ID of 0 is the signal to stop processing the tag
		}
		
		# tags 28,29,37,40 and 41 don't apply to UID1
		if ( ($caller =~ /UIC1/) and (($id == 28) or ($id == 29) or ($id == 37) or ($id==40) or ($id==41)) ){
			$file->setCurrentPosition(4,1); # move to the next ID
			redo;
		}
		
		$name   = $codes{$id}[1];
		croak "Unknown key value $id in $caller tag data" unless (defined $name);
		$MMtype = $codes{$id}[0];
		
		my $tag_value;
		$tag_value = get_value($self, $MMtype);
		print STDERR "Value of $caller tag $name($id) $MMtype is $tag_value\n";		
		$file->setCurrentPosition(4,1); # move to the next ID
    }
    return %uic1;
}


# By definition, the presence of a UIC2 tag marks this file as a MetaMorph stack.
# Its count field contains the number of planes in the stack. 

# This tag points to a contiguous set of 6 values for each of the N Z planes in the stack.
# Put each set of 6 values, as an array, into the %uic2 hash, keyed by its plane number (0 to N-1)

sub do_uic2 {
    my ($self, $type, $num_planes, $offset) = @_;
    my $params   = $self->{params};
    my $endian   = $params->endian;
    my $file     = $params->fref;
    my $xml_hash = $params->xml_hash;
    my $i;
    
    my %uic2;
	
	$file->setCurrentPosition($offset, 0);
		
    # read in a 6-tuple set of values for each of the $num_planes planes in the stack
    my $last_Z_pos = 0;
    for ($i = 0; $i < $num_planes; $i++) {
    
    	# read 6-tuple set
    	my $fmt = ($endian == LITTLE_ENDIAN) ? "V6" : "N6";
		my ($Z_num, $Z_denom, $cdate, $ctime, $mdate, $mtime) = unpack($fmt, $file->readData(6*4));
		
		# Tom: WTF is cdt used for? Is this an artefact of the stupid sorting?
		my $cdt = ($cdate * 86400000) + $ctime;   # date & time into 1 number for easy sorting
		
		# include plane # in hash since it won't necessarily equal the key after sorting
		# Z_dist is the distance between contingious Z-planes
		$uic2{$i} = [$i, $Z_num/$Z_denom, $cdt, $cdate, $ctime, $mdate, $mtime];		
    }
    
    $self->{uic2} = \%uic2;  # remember to access this hash after doing a `sort keys`

    return %uic2;
}


# The  UIC3  tag points to a pair of integers for each of the Z planes
# in the stack. The ratio of each pair is the wavelength used in imaging
# the pair's associated Z plane. Put these ratios, keyed by the plane
# number (0 thru N-1) into the %iuc3 hash. Store these ratios along with
# the other per plane data in the %uic2 hash.

sub do_uic3 {
    my ($self, $type, $num_planes, $offset) = @_;
    my $params = $self->{params};
    my $endian = $params->endian;
    my $file   = $params->fref;
    
    my $i;
    
    my %uic3;

    $file->setCurrentPosition($offset, 0);


    for ($i = 0; $i < $num_planes; $i++) {        
        my $fmt = ($endian == LITTLE_ENDIAN) ? "V2" : "N2";
		my ($numer, $denom) = unpack($fmt, $file->readData(2*4));
		
		$uic3{$i} = $numer/$denom;
    }
    $self->{uic3} = \%uic3;
    
    return %uic3;
}

# get_value returns the value(s) associated with a tag. 
# It returns the file pointer where it started

sub get_value {
    my ($self, $MMtype) = @_;
    my $status;
    my $cur_offset;
    my $i;
    
    my $params = $self->{params};
    my $endian = $params->endian;
    my $file   = $params->fref;
	my $cnt = $self->{NumStacks};

	$cur_offset = $file->getCurrentPosition();

	# all except types L have an offset to where their values are
	if ($MMtype !~ /^L$/) {  
		my $offset;
		# remember current file pntr position & go to the value(s)
		$offset = go_there($file, $endian); 
		
		# They use an offset of 0 to mean 'Ignore Field'
		#if ($offset == 0) {
		#	$file->setCurrentPosition($cur_offset,0);
		#	return "Ignored";
		#}
	}

	# long type
	if ($MMtype eq 'L') {
		my $value;
		get_long($file, $endian, \$value);
		$file->setCurrentPosition($cur_offset,0);  
		return $value;
	}
	
	# string type
	elsif ($MMtype eq 'S') {
		my $buf;
		get_string($file, $endian, \$buf);
		$file->setCurrentPosition($cur_offset,0);  
		return $buf;
	}
	
	# "rational" type - read 2 longs, value is the 1st divided by the 2nd
	elsif ($MMtype eq 'R') {
		my $rat;
		get_rational($file, $endian, \$rat);
		$file->setCurrentPosition($cur_offset,0);  
		return $rat;
	}
	
	# "N4' type - N sets of 4 longs = N sets of 2 rationals
	elsif ($MMtype eq 'N4') {
		my ($rat1, $rat2);
		my @rat_list;
		
		for ($i = 0; $i < $cnt; $i++) {	
			get_rational($file, $endian, \$rat1);   # get 1st rational
			get_rational($file, $endian, \$rat2);   # get 2nd rational
			
			push @rat_list, $rat1;
			push @rat_list, $rat2;
		}
		$file->setCurrentPosition($cur_offset,0);  
		return @rat_list;
	}
	
	# 'NS' type - N strings
	elsif ($MMtype eq 'NS') {
		my $buf;
		my @buf_list;
		
		for ($i = 0; $i < $cnt; $i++) {
			get_string($file, $endian, \$buf);
			
			push @buf_list, $buf;
		}
		$file->setCurrentPosition($cur_offset,0);  
		return @buf_list;
	}
	
	# 'N2' type - N rationals
	elsif ($MMtype eq 'N2') {
		my $rat;
		my @rat_list;
		
		for ($i = 0; $i < $cnt; $i++){
			get_rational($file, $endian, \$rat);
			
			push @rat_list, $rat;
		}
		$file->setCurrentPosition($cur_offset,0);  			
		return @rat_list;
	}
	
	# Date/Time type
	elsif ($MMtype eq 'T') {
		my $value;
		get_long ($file, $endian, \$value);
		$file->setCurrentPosition($cur_offset,0);  
		return $value;
	}
	
	elsif ($MMtype eq 'NL') {
		my $value;
		my @value_list;
		
		for ($i = 0; $i < $cnt; $i++) {
			get_long($file, $endian, \$value);
			
			push @value_list, $value;
		}
		
		$file->setCurrentPosition($cur_offset,0);  
		return @value_list;
	}
	
	# 'LO' type - offset to a single Long. Why not put the long in the tag itself?
	elsif ($MMtype eq 'LO') {
		my $value;
		$status = get_long($file, $endian, \$value);
		$file->setCurrentPosition($cur_offset,0);  
		return $value;
	} else {
		die "Unknown UIC tag ID: $MMtype";
	}
	
}

sub get_long {
    my ($fih, $endian, $value) = @_;
    my $fmt;
    
	$fmt = ($endian == LITTLE_ENDIAN) ? "V" : "N";
	$$value = unpack($fmt, $fih->readData(4));
}


sub go_there {
    my ($fih, $endian) = @_;
    my $offset;
	
	get_long($fih, $endian, \$offset); # value is offset to where data stored
    
    # Apparently, they use an offset of 0 to mean 'ignore field'
    if ($offset != 0) {
        $fih->setCurrentPosition($offset, 0);
    }
    
    return $offset;
}


sub get_string {
    my ($fih, $endian, $buf) = @_;
    my $len;
    
    get_long($fih, $endian, \$len);    # string length precedes characters

	# TODO Convert between little endian big endian orders
	$$buf = $fih->readData($len);
}


# get a rational
sub get_rational {
    my ($fih, $endian, $rat) = @_;
    my ($val1, $val2);

    get_long($fih, $endian, \$val1); # read the 2 longs
	get_long($fih, $endian, \$val2);
	
	if ($val2 == 0) {
		$$rat = -1;
	} else {
		$$rat = $val1/$val2;
	}
}

# Store channel (wavelength) info
sub storeChannelInfo {
    my $self = shift;
    my $session = shift;
    my $params = $self->{params};
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
    my $self = shift;
    my $file = shift;
    return $file->getSHA1();
}
=head1 Author

Brian S. Hughes
Tom Macura

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>
L<OME::ImportEngine::TIFFreader.pm>

=cut

1;
