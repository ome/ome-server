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

use OME::ImportEngine::TIFFUtils;
use Log::Agent;

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


    my $importer = OME::ImportEngine::STKreader->new()

Creates a new instance of this class. The other public methods of this
class are accessed through this instance.  The caller would
normally be OME::ImportEngine::ImportEngine.

=cut


sub new {
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};

    bless $self, $class;
    return $self;
}




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


sub getGroups
{
    my $self = shift;
    my $fref = shift;
    my @outlist;
    my $xref;
	my ($filename,$file);
	my %STKs;
	my $uic2 = UIC2;

	# ignore any non-stk files.
	while ( ($filename,$file) = each %$fref ) {
		# STK images are TIFF images with a defined UIC tag
		if (defined(verifyTiff($file))) {
			my $tag0 = readTiffIFD( $file,0 );
			$STKs{$filename} = $file if exists ($tag0->{$uic2}) and defined $tag0->{$uic2};
		}
	}

    # Group files with recognized patterns together
    # Sort them by channels, z's, then timepoints
    my ($groups, $infoHash) = $self->getRegexGroups(\%STKs);

	my ($name,$group);
	
    while ( ($name,$group) = each %$groups ) {
    	next unless defined($name);
    	my $nZfiles = $infoHash->{ $name }->{ nZfiles };
		my $nCfiles = $infoHash->{ $name }->{ nCfiles };
		my $nTfiles = $infoHash->{ $name }->{ nTfiles };
		my @groupList;
	
		for (my $z = 0; $z < $nZfiles; $z++) {
    		for (my $c = 0; $c < $nCfiles; $c++) {
    			for (my $t = 0; $t < $nTfiles; $t++) {
    				$file = $group->[$z][$c][$t]->{File};
    				die "Uh, file is not defined at (z,c,t)=($z,$c,$t)!\n"
    					unless ( defined($file) );
    				
					# The other keys of this hash give access to the actual
					# sub-patterns matched by the RE:
    				# $zString = $group->[$z][$c][$t]->{Z};
    				# $cString = $group->[$z][$c][$t]->{C};
    				# $tString = $group->[$z][$c][$t]->{T};
					# Note that undef strings are converted to ''.
    				
    				push (@groupList, $file);
    				
    				# delete the file from the hash, so it's not processed by other importers
    				$filename = $file->getFilename();
					logdbg "debug",  "deleting $filename in group $name";
					delete $fref->{ $filename };
					delete $STKs{ $filename };
    			}
    		}
    	}
    	push (@outlist, {
    		Files => \@groupList,
    		BaseName => $name,
    		GroupInfo => $group,
    		nZfiles  => $nZfiles,
    		nCfiles  => $nCfiles,
    		nTfiles  => $nTfiles,
    	})
    		if ( scalar(@groupList) > 0 );
    }
    
    # Now look at the rest of the files in the list to see if we
    # have any single-file STKs.
    foreach $file ( values %STKs ) {    	
    	
    	$filename = $file->getFilename();
    	my $basename = $self->nameOnly($filename);
    	my $group;
    	$group->[0][0][0]={
    		File => $file,
    		Z    => undef,
    		C    => undef,
    		T    => undef,
    	};
    	push (@outlist, {
    		Files => [$file],
    		BaseName => $basename,
    		GroupInfo => $group,
    		nZfiles  => 1,
    		nCfiles  => 1,
    		nTfiles  => 1,
    	});
		logdbg "debug",  "deleting $filename in singleton group $basename";
		delete $fref->{ $filename };
		delete $STKs{ $filename };
    }
	
    return \@outlist;
}



=head2 importGroup

    my $image = $importer->importGroup($group, \%localSliceCallback)

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

sub importGroup {
    my ($self, $group, $callback) = @_;
    my $status;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my $groupList = $group->{Files};

    my $file = $groupList->[0];
	$file->open('r');
	my $tag0 = readTiffIFD( $file,0 );
    
	my $filename = $file->getFilename();
	my $basename = $group->{BaseName};
    

	# This is the number of Z,C,T in the first file.
	# The rest of the files in the group are assumed to contain the same number
	my ($fSizeZ,$fSizeC,$fSizeT,$theCs) = getUICinfo ($file, $tag0);
	
	# The total number of Z,C,T in the OME Image is the number in the 1st file
	# times the number of Z,C,and T files.
	my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT) = (
		$tag0->{TAGS->{ImageWidth}}->[0],
		$tag0->{TAGS->{ImageLength}}->[0],
		$fSizeZ,$fSizeC,$fSizeT
	);
	logdbg "debug",  "X: $sizeX, Y: $sizeY";
	$sizeZ *= $group->{nZfiles};
	$sizeC *= $group->{nCfiles};
	$sizeT *= $group->{nTfiles};

	my $bpp = $tag0->{TAGS->{BitsPerSample}}->[0];
    
    
    my $xref = {};
    $xref->{'Image.ImageType'} = "";

						 
    my $image = $self->newImage($basename);
	my ($pixels, $pix) = $self->createRepositoryFile($image, 
						 $sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp);

    my ($t, $c, $z);
    
    my $nZ = $group->{nZfiles};
    my $nC = $group->{nCfiles};
    my $nT = $group->{nTfiles};
	my $plane_size;
    my @channelInfo;
    my %channels;

	# Here we process the files - each of which may have multiple planes.	
	for ($z = 0; $z < $nZ; $z++) {
		for ($c = 0; $c < $nC; $c++) {
			for ($t = 0; $t < $nT; $t++) {
				my ($z0,$c0,$t0) = ( $z * $fSizeZ, $c * $fSizeC, $t * $fSizeT);
				$file = $group->{GroupInfo}->[$z][$c][$t]->{File};
				$tag0 = readTiffIFD( $file,0 );
				my ($thisSizeZ,$thisSizeC,$thisSizeT,$theseCs) = getUICinfo ($file, $tag0);
				my ($offsets_arr, $bytesize_arr) = getStrips($tag0);
				my $lastStrip = scalar (@$offsets_arr) - 1;
				$plane_size = ($offsets_arr->[$lastStrip] + $bytesize_arr->[$lastStrip]) - $offsets_arr->[0];
				my $offset;
				for (my $theZ = 0; $theZ < $fSizeZ; $theZ++) {
					$offset = $offsets_arr->[0] + ($theZ * $plane_size);
					$pix->convertPlane($file,$offset,$z0+$theZ,$c0,$t0,$tag0->{__Endian} == BIG_ENDIAN);
					$self->doSliceCallback($callback);
				}
				$self->storeOneFileInfo($file, $image,
					0, $sizeX-1,
					0, $sizeY-1,
					$z0, $z0+$fSizeZ-1,
					$c0, $c0+$fSizeC-1,
					$t0, $t0+$fSizeT-1,
					"Metamorph STK");
				my $cString = $group->{GroupInfo}->[$z][$c][$t]->{C};
				# Get rid of leading digits
				$cString = $1 if $cString =~ /^\d*(.*)$/;
				logdbg "debug",  "cString: $cString";
				unless ($channelInfo[$c0]) {
					$channelInfo[$c0] = {
						chnlNumber => $c0,
						ExWave     => undef,
						EmWave     => $theseCs->[0]->{EmWave} ? $theseCs->[0]->{EmWave} : undef,
						Fluor      => $cString ? $cString : undef,
						NDfilter   => undef
					}
				}
			}
		}
	}
    OME::Tasks::PixelsManager -> finishPixels( $pix, $pixels );
    
    
    # Now, write the metadata
    $self->storeChannelInfo ($image,@channelInfo);
    
	$self->storeDisplayOptions($image);

	return $image;
}


sub getUICinfo {
	my ($file, $tags) = @_;
	my $endian = $tags->{__Endian};
	my $buffer;
	my @data;
	my $uic2_tag_num = UIC2;
	
	my $num_planes = $tags->{$uic2_tag_num}->[0]->{value_count};
	logdbg "debug",  "number of planes: $num_planes, $tags->{$uic2_tag_num}->[0]";
	die "Apparently there are no planes in ".$file->getFilename()
		unless $num_planes;

	my $uic2 = do_uic2($file, $tags); # per plane z-position info
    # sizeZ is the number of different Z positions the planes were taken in
    my $sizeZ = scalar @$uic2;


	my $uic3 = do_uic3($file, $tags); # per plane wavelength info
    # sizeC is the number of different Wavelengths the planes were taken in
	my %indexC;
	my @theCs;
	my $wavelength;
    my $sizeC = 0;
    foreach (@$uic3) {
    	$wavelength = sprintf("%.0f",$_);
    	if (not exists $indexC{$wavelength}) {
			$indexC{$wavelength} = $sizeC;
			push (@theCs,{
				EmWave => $wavelength,
				Label  => undef,
			});
			$sizeC++;
    	}
    }

	my $sizeT = $num_planes / ($sizeZ * $sizeC);

	return ($sizeZ, $sizeC, $sizeT, \@theCs);

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

sub do_uic1_4 {
    my ($TAG_num, $file, $tags) = @_;
	my $endian = $tags->{__Endian};
	my $uic2_4_tag = $tags->{$TAG_num}->[0];
	my $caller = $TAG_num == UIC1 ? 'UIC1' : 'UIC4';

   	$file->setCurrentPosition($uic2_4_tag->{current_offset}, 0);
    
    my %uic1 = OME::ImportEngine::TIFFUtils::getTagValue (
		$file,
		$uic2_4_tag->{tag_type},
		$uic2_4_tag->{value_count},
		$uic2_4_tag->{value_offset},
		$endian,
	);

    return %uic1;
}


# By definition, the presence of a UIC2 tag marks this file as a MetaMorph stack.
# Its count field contains the number of planes in the stack. 

# This tag points to a contiguous set of 6 values for each of the N Z planes in the stack.
# Put each set of 6 values, as an array, into the %uic2 hash, keyed by its plane number (0 to N-1)

sub do_uic2 {
    my ($file, $tags) = @_;
	my $endian = $tags->{__Endian};
	my $uic2_tag_num = UIC2;
	my $uic2_tag = $tags->{$uic2_tag_num}->[0];
	my $num_planes = $uic2_tag->{value_count};
    
    my @uic2;
	
	$file->setCurrentPosition($uic2_tag->{value_offset}, 0);
		
    # read in a 6-tuple set of values for each of the $num_planes planes in the stack
    for (my $i = 0; $i < $num_planes; $i++) {
    
    	# read 6-tuple set
    	my $fmt = ($endian == LITTLE_ENDIAN) ? "V6" : "N6";
		my ($Z_num, $Z_denom, $cdate, $ctime, $mdate, $mtime) = unpack($fmt, $file->readData(6*4));
		
		# Tom: WTF is cdt used for? Is this an artefact of the stupid sorting?
		my $cdt = ($cdate * 86400000) + $ctime;   # date & time into 1 number for easy sorting
		
		# include plane # in hash since it won't necessarily equal the key after sorting
		# Z_dist is the distance between contingious Z-planes
		push (@uic2,{
			PlaneNum => $i,
			Zdist    => $Z_num/$Z_denom,
			DateTime => $cdt,
			Date     => $cdate,
			Time     => $ctime,
			Mdate    => $mdate,
			Mtime    => $mtime,
		});		
    }
    
    return \@uic2;
}


# The  UIC3  tag points to a pair of integers for each of the Z planes
# in the stack. The ratio of each pair is the wavelength used in imaging
# the pair's associated Z plane.

sub do_uic3 {
    my ($file, $tags) = @_;
	my $endian = $tags->{__Endian};
	my $fmt = ($endian == LITTLE_ENDIAN) ? "V2" : "N2";
	my $uic2_tag_num = UIC2;
	my $uic2_tag = $tags->{$uic2_tag_num}->[0];
	my $num_planes = $uic2_tag->{value_count};

	my $uic3_tag_num = UIC3;
	my $uic3_tag = $tags->{$uic3_tag_num}->[0];
    
    my @uic3;
	
	$file->setCurrentPosition($uic3_tag->{value_offset}, 0);


    for (my $i = 0; $i < $num_planes; $i++) {        
		my ($numer, $denom) = unpack($fmt, $file->readData(2*4));
		push (@uic3,$numer/$denom);
    }
    
    return \@uic3;
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
