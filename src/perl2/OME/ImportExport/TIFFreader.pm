#!/usr/bin/perl -w
#
# TIFFreader.pm
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

# This class contains the methods to handle a TIFF format file. If it detects
# that its target file is a TIFF variant, it will call the apropriate subclass.

# ---- Public routines -------
# new()
# readTag()
# formatImage()

# ---- Private routines ------
# parseImageDescription()
# readTiffIFD()
# readTiffTag()

package OME::ImportExport::TIFFreader;
our @ISA = ("OME::ImportExport::Import_reader");
use Class::Struct;
use strict;
use Carp;
use OME::ImportExport::FileUtils;
use OME::ImportExport::Import_reader;
use OME::ImportExport::STKreader;
use OME::ImportExport::PixWrapper;
use vars qw($VERSION);
$VERSION = '1.0';



# This hash relates base TIFF Tag IDs to the tag names
# It's included here for human convenience in interpreting field meanings
# See http://partners.adobe.com/asn/developer/PDFS/TIFF6.pdf for the complete
# TIFF specification.
#
#   Hash tables entry: Tag ID -> Tag name
 #


my %Variants =  ( 33628 => ['STK', 'UIC1', 0],    # STK format keys
		  33629 => ['STK', 'UIC2', 1],
		  33630 => ['STK', 'UIC3', 1],
		  33631 => ['STK', 'UIC4', 1]
		  );


my %Tagnames =  ( 254   => 'SubFile',     #Start of image marker
		  255   => 'SubfileType', #1 = full res., 2=reduced res., 3=single page of multi-page image - see PageNumberField
		  256   => 'ImageWidth',
		  257   => 'ImageLength',
		  258   => 'BitsPerSample',
		  259   => 'Compression', # 1=none, 2=CCITT ID 3=Grp3 Fax 4=Grp4 Fax, 5=LZW, 6=JPEG, 32773=PackBits
		  262   => 'PhotometricInterpretation',
		  263   => 'Threshholding', #1=no dithering/halftone, 2=ordered dither/halftone, 3=randomize process)
		  264   => 'CellWidth',
		  265   => 'CellLength',
		  266   => 'FillOrder',
		  269   => 'DocumentName',
		  270   => 'ImageDescription',
		  271   => 'Make',
		  272   => 'Model',
                  # ONLY WAY TO FIND IMAGE DATA
		  273   => 'StripOffsets',    # offset to image data strip - one value per strip 
		  274   => 'Orientation',     # 1=starts at top row, left column
		  277   => 'SamplesPerPixel', # Usually 3 for RGB, else usually 1
		  278   => 'RowsPerStrip',
		  279   => 'StripByteCounts', # How many bytes/strip after compression
		  280   => 'MinSampleValue',
		  281   => 'MaxSampleValue',
		  282   => 'XResolution',
		  283   => 'YResolution',
		  284   => 'PlanarConfig',    # 1=chunky format (recommended)
		  285   => 'PageName',
		  286   => 'XPos',
		  287   => 'YPos',
		  287   => 'FreeOffsets',
		  287   => 'FreeByteCnt',
		  290   => 'GrayResponseUnit',
		  291   => 'GrayResponseCurve',
		  292   => 'T4Options',
		  293   => 'T6Options',
		  
		  296   => 'ResolutionUnit', # 1=No absolute, 2=Inch, 3=cm.
		  297   => 'PageNumber',
		  301   => 'TransferFunction', 
                        
# StripsPerImage = floor((ImageLen + RowsPerStrip-1)/RowsPerStrip),
		  305   => 'Software',       #Name/version of s/w pkg to make image
		  306   => 'DateTime',       # YYYY:MM:DD HH:MM:SS
		  315   => 'Artist',
		  316   => 'Host',
		  317   => 'Predictor',
		  318   => 'WhitePoint',
		  319   => 'PrimaryChroma',
		  320   => 'ColorMap',
		  321   => 'Halftine Hints',
		  322   => 'TileWidth',
		  323   => 'TileLength',
		  324   => 'TileOffsets',
		  325   => 'TileByteCounts',
		  332   => 'InkSet',
		  333   => 'InkNames',
		  334   => 'NumberOfInks',
		  336   => 'DotRange',
		  337   => 'TargetPrinter',
		  338   => 'ExtraSamples',
		  339   => 'SampleFormat',
		  340   => 'SMinSampleValue',
		  341   => 'SMaxSampleValue',
		  342   => 'TransferRange',
		  512   => 'JPEGProc',
		  513   => 'JPEGInterchangeFormat',
		  514   => 'JPEGInterchangeFormat',
		  515   => 'JPEGRestartInterval',
		  517   => 'JPEGLosslessPredictors',
		  518   => 'JPEGPointTransforms',
		  519   => 'JPEGQTables',
		  520   => 'JPEGDCTables',
		  521   => 'JPEGACTables',
		  529   => 'YCbCrCoefficients',
		  530   => 'YCbCrSubSampling',
		  531   => 'YCbCrPositioning',
		  33432 => 'Copyright',
		  33628 => 'UIC1',
		  33629 => 'UIC2',
		  33630 => 'UIC3',
		  33631 => 'UIC4'

		  );


my %xml_image_entries = (ImageWidth => 'SizeX',
			  ImageLength => 'SizeY',
			  DateTime    => 'CreationDate',
			  );

my %xml_data_entries  = (BitsPerSample => 'BitsPerPixel'
			 );

my @useful_desc_fields = ("Exposure:", "Illumination:");
my %desc_fields_to_top_level_element = ('Exposure:' => 'XYinfo.',
					'Illumination:' => 'WavelengthInfo.'
					);

my %xml_image_from_desc = ('Exposure:' => 'ExpTime',
			   'Illumination:' => 'Flour'
                           );

my %tag_accumulates = ('StripOffsets' => 1,
		       'StripByteCounts' => 1
		       );



sub new {

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};
    $self->{params} = shift;

    return bless $self, $class;
}


sub readImage {
    my $i = 1;
    my $image_file;
    my $self = shift;     # Ourselves

    croak "Image::TIFFreader must be called from Import-reader or other class"
	unless ref($self);
    my $params = $self->{params};   # Caller had to pass reference to
                                    # hash that holds image data
    my $image_group = $params->image_group();
    my $k;

    foreach $k (keys %tag_accumulates) {
	$self->{$k} = ();
    }

    $params->fref($params->fref);
    my $status = readTiffIFD($self, $i++);
    my $bps = $self->{'BitsPerSample'};
    $params->pixel_size($bps);
    $params->byte_size($bps/8);

    # if we were passed a set of files, import them all into the current image
    if (($status eq "") && (scalar(@$image_group > 1))) {
	while (defined ($image_file = $$image_group[$i-1])) {
	    close  $params->fref;
	    my $last_type = $params->image_type;
	    $params->image_file($image_file);
	    $self->check_type();  # opens file & gets offset to IFD & file type
	    if ($last_type ne $params->image_type) {
		$status = "File $image_file is not of type $last_type";
		last;
	    }
	    $params->fref($params->fref);
	    $status = readTiffIFD($self, $i++);
	    last
		unless $status eq "";
	}
	if ($status eq "") {
	    $params->xml_hash->{'Image.NumWaves'} = scalar(@$image_group);
	}
    }

    return($status);
}



sub formatImage {
    my $self = shift;     # Ourselves
    my $pixWrap = shift;
    my $params = $self->{params};
    my $xml_hash = $params->xml_hash;
    my $fih;      # File handle of input files
    my $buf_offset;
    my $start_offset;
    my $offsets_arr;
    my $bytecounts_arr;
    my $offsets;
    my $bytecounts;
    my $status;
    my ($strip_size, $row_size);
    my $buf;
    my $endian;
    my $theC = 0;
    my (@xy, @xyz, @xyzw, @xyzwt);
    my $obuf = $params->obuffer;
    my ($sz, $ndxi, $ndxo, $ch);
    my $irow;
    my $i;

    $fih = $params->fref;
    $endian = $params->endian;
    my $bps = $params->byte_size;  # bytes per sample (1 channel of a pixel)
    $row_size = $self->{ImageWidth} * $bps;               # bytes per row
    ($offsets_arr, $bytecounts_arr) = getStrips($self);

    # If this image is a TIFF variant, let the variant class handle it
    if (defined $self->{Variant}) {
	my $variant_ref = $self->{$self->{Variant}};
	#$self->{fih} = $fih;
	#$self->{endian} = $endian;
	#$self->{bps} = $bps;
	$params->row_size($row_size);

	# +++ Note - needs code mods to handle grouping multiple variant files together
	$params->image_offsets($offsets_arr);
	$params->image_bytecounts($bytecounts_arr);
	#$self->{obuffer} = $params->obuffer;
	$status = $variant_ref->formatImage($pixWrap)
    }
    else {
	# send pixels to repository file via a PixWrapper
	# TODO  -  fix so it will handle more than 1 strip per TIFF file
	for ($i = 0; scalar(@$offsets_arr) > $i; $i++) {
	    my $plane_size = 0;
	    $offsets = @$offsets_arr[$i];
	    $bytecounts = @$bytecounts_arr[$i];
	    @$offsets = reverse(@$offsets);
	    @$bytecounts = reverse(@$bytecounts);
	    my $num_rows = 0;
	    my $rows = "";
	    while (@$offsets) {
		$start_offset = pop(@$offsets);
		$strip_size = pop(@$bytecounts);
		$status = OME::ImportExport::FileUtils::seek_and_read($fih, \$buf, $start_offset, $strip_size);
		last
		    unless $status eq "";

		# extract rows out of the buffer
		for ($buf_offset = 0; $strip_size >= $row_size; $strip_size -= $row_size) {
		    $irow = substr($buf, $buf_offset, $row_size);
		    my $cnt = Repacker::repack($irow, $row_size, 
					       $bps,
					       $endian eq "little",
					       $params->{host_endian} eq "little");
		    substr($rows, length($rows), 0, $irow);
		    $num_rows++;
		    $buf_offset += $row_size;
		    $plane_size += $row_size;
		}
		
	    }
	    # For now, at least, we don't handle > 1 Z or T dimension
	    my $nPixOut = $pixWrap->SetRows ($rows, $num_rows);
	    if ($plane_size != $nPixOut*$bps) {
		$status = "Failed to write repository file - $plane_size != $nPixOut";
		last;
	    }

	}

	# Now store metadata from multiple planes, if any
	my ($key, $val);
	my $xy_aref = [];
	my $wv_aref = [];

	# ref to array built by TIFFreader
	my $xref    =  $xml_hash->{'XYinfoPlane.'};
	if (defined $xref->[0]->[0]->[0]) {       # don't proceed if no data
	    delete $xml_hash->{'XYinfoPlane.'};
	    # ref to array built by TIFFreader
	    my $wref    =  $xml_hash->{'WavelengthInfoPlane.'};
	    delete $xml_hash->{'WavelengthInfoPlane.'};

	    # This next op. done to make output array in same format
	    # as STKreader
	    # Now make the XYinfo elements from previously stored info
	    my $xyhref = {};
	    # N.B. If TIFFReader leaves more than 1 pair of key/value,
	    # the following must be expanded.
	    $key = $xref->[0]->[0]->[0];  # copy, in proper order, XYinfo
	    $val = $xref->[0]->[0]->[1];  #    left by TIFFreader
	    $xyhref->{'XYinfo.'.$key} = $val;  # copy
	    push @$xy_aref, $xyhref;

	    $xml_hash->{'XYinfo.'} = $xy_aref;

	    # Now make the WavelengthInfo elements from previously stored info
	    my $wvhref = {};
	    # N.B. If TIFFReader leaves more than 1 pair of key/value,
	    # the following must be expanded.
	    $key = $wref->[0]->[0]->[0];  # copy, in proper order, Waveleninfo
	    $val = $wref->[0]->[0]->[1];  #    left by TIFFreader
	    $wvhref->{'WavelengthInfo.'.$key} = $val;  # copy
	    push @$wv_aref, $wvhref;

	    $xml_hash->{'WavelengthInfo.'} = $wv_aref;
	}
    }

    return $status;
}


# Get image strip offsets and bytecounts into passed arrays
sub getStrips {
    my $self = shift;
    my ($offsets_aref, $bytecounts_aref);
    my (@offs_arr, @counts_arr);
    my (@lstoff, @lstcnt);

    @offs_arr = $self->{'StripOffsets'};        # offsets to start of each TIFF image strip
    @counts_arr = $self->{'StripByteCounts'};  # how long the strip is

    $offsets_aref = $offs_arr[0];
    $bytecounts_aref = $counts_arr[0];

    # images w/ just 1 offset don't have an array of offsets - make one
    if (ref($offsets_aref) ne 'ARRAY') {
	push @lstoff, \@offs_arr;
	push @lstcnt, \@counts_arr;
	$offsets_aref = \@lstoff;
	$bytecounts_aref = \@lstcnt;
    }

    return($offsets_aref, $bytecounts_aref);
} 


# Read a Tiff Image File Directory (IFD)

sub readTiffIFD {
    my $self = shift;
    my $params = $self->{params};
    my $image_plane = shift;
    my $fih    = $params->fref;
    my $endian = $params->endian;
    my $offset = $params->offset;
    my $xml_hash = $params->xml_hash;
    my $xel;
    my $buf;
    my $cnt;
    my $status;
    my $k;
    my $value;

    # For TIFF images, some fields are hardcoded. Variants may overwrite these
    $xml_hash->{'Image.SizeZ'} = 1;
    $xml_hash->{'Image.NumWaves'} = $image_plane;
    $xml_hash->{'Image.NumTimes'} = 1;

    while ($offset > 0) {    # read every Tiff IFD 
	$status = OME::ImportExport::FileUtils::seek_and_read($fih, \$buf, $offset, 2);
	last
	    unless $status eq "";

	# get # of tags in this IFD
	$cnt = unpack $endian eq "little" ? "v" : "n",  $buf;

	# Process every tag in this IFD
	while ($cnt) {       # read every tag in this IFD
	    $status = readTiffTag($self, $fih, $endian);
	    last unless $status eq "";
	    $cnt--;
	}
	last unless $status eq "";

	# read in the offset to next IFD. Offset to 0 mean end of IFDs.
	$status = OME::ImportExport::FileUtils::read_it($fih, \$buf, 4);
	last
	    unless $status eq "";
	$offset = unpack $endian eq "little" ? "V" : "N",  $buf;
    }

    # Put relevant pieces of metadata into xml_elements for later DB storage

    # Save certain image & data tag values
    # Only do this once per image
    if ($image_plane == 1) {
	# The Image top level element
	foreach $k (keys %xml_image_entries) {
	    $xel = $xml_image_entries{$k};
	    $value = $self->{$k};
	    if (!defined $value) {
		$value = "";
	    }
	    $xml_hash->{"Image.".$xel} = $value;
	}
	# The Data top level element
	foreach $k (keys %xml_data_entries) {
	    $xel = $xml_data_entries{$k};
	    $value = $self->{$k};
	    if (!defined $value) {
		$value = "";
	    }
	    $xml_hash->{"Data.".$xel} = $value;
	}
    }


    parseImageDescription($self, $xml_hash, $image_plane);


    return $status;
}


# The ImageDescription field contains subfields. Each subfield,
# except a text descriptor line, is composed as "subkey : subvalue".
# Parse out each subfield, and if it's of interest, save as metadata.
# Note - only XYInfo & Wavelenght info should be stored for each
# image plane. All info from other categories gets stored once/image.
sub parseImageDescription {
    my $self = shift;
    my $xml_hash = shift;
    my $image_plane = shift;
    my $buf;
    my @val;
    my ($k, $ky, $subfld, $elem);

    my $xyfullref = [];
    my $wfullref = [];
    my ($xyref, $wref);
    @$xyref = ();
    @$wref = ();
    foreach $k (keys %$self) {
	my @href;

	if ($k =~ /ImageDescription/) {
	    $buf = $self->{$k};
	    foreach $subfld (@useful_desc_fields) {
		while ($buf =~ m/$subfld (.*)/g) {
		    my @val = ($1);
		    $ky = $xml_image_from_desc{$subfld};
		    $elem = $desc_fields_to_top_level_element{$subfld};

		    # for those subflds going into an XYInfo or Wavelength
		    # element, push them into an array. These two elements
		    # can have many instances, so put all the instances into
		    # an anonymous array & put the array ref into the hash.
		    if ($elem =~ m/XYinfo|Wavelength/) {
			if ($elem =~ m/XYinfo/) {
			    push @$xyref, [$ky, $val[0]];
			} else {
			    push @$wref, [$ky, $val[0]];
			}
		    } elsif ($image_plane == 1) {    # Only record once/image
			$xml_hash->{$elem.$ky} = $val[0];
		    }
		}
	    }
	    push @$wref, ['WaveNumber', $image_plane];   

	    if ($image_plane == 1) {         # Only record once/image
		# now chop off any line that has an embeded ":"
		$buf =~ s/.*:.*//g;
		# if there's a non-empty line, take it as the Description fld
		@val = ($buf =~ m/^(.+)/gm);
		if (defined $val[0]) {
		    $xml_hash->{'Image.Description'} = $val[0];
		}
	    }

	    last;
	}
    }

    if (scalar(@$xyref) != 0) {
	push @{ $xml_hash->{'XYinfoPlane.'}}, $xyref;
    }
    if (scalar(@$wref) != 0) {
	push @{ $xml_hash->{'WavelengthInfoPlane.'}}, $wref;
    }
}


# Read each TIFF tag tuple
sub readTiffTag {
    my $self = shift;
    my $fih = shift;
    my $endian = shift;
    my $status;
    my $cur_loc;
    my $format;
    my @fmts;
    my @tagflds;
    my ($tag_id, $tag_type, $tag_cnt, $tag_offset);
    my $tag_name;
    my $buf;
    my $cnt;
    my $is_list = 0;
    my @vallist;
    my ($variant_ref, $variant_name);
    my ($value, $val1, $val2);
    my %Type = (1=>'Byte', 2=>'ASCII', 3=>'Short', 4=>'Long', 5=>'Rational');

    $status = OME::ImportExport::FileUtils::read_it($fih, \$buf, 12);
    return $status
	unless $status eq "";

    $format = $endian eq "little" ? "vvVV" : "nnNN";
    @tagflds = unpack ($format, $buf);
    $tag_id = $tagflds[0];
    $tag_type = $tagflds[1];
    $tag_cnt = $tagflds[2];
    $tag_offset = $tagflds[3];


    # This section handles TIFF variants. Detection of a variant depends upon
    # that variant using a unique tag ID. The hash %Variants, above, contains
    # a list of these unique IDs as keys, with the values being arrays that
    # hold the variant name as element 0.
    #   Upon detecting a variant, this routine accesses the subclass called
    # by the name $variant_name.reader . Eg., the STK variant of TIFF is handled
    # by the STKreader class.

    if (exists($Variants{$tag_id})) {
	my $variant_handler;
	my $variant_name = $Variants{$tag_id}[0];
        # handle case where only a part of a variant's code is in a file
        # e.g., when UI writes a TIF file they stick in the UIC1 tag (?why?)
	if ($Variants{$tag_id}[2] == 1) {
	    $self->{Variant} = $variant_name;
	}
	$tag_name = $Variants{$tag_id}[1];
	#print "Detected TIFF variant $variant_name: $tag_name\n";

	# create instance of the variant handler class if not yet created
	if (!defined $self->{$variant_name}) {
	    my $variant_ref = "OME::ImportExport::".$variant_name."reader";
	    $self->{$variant_name} = $variant_ref->new($self->{params});
	    if (!defined $self->{$variant_name}) {
		return ($status = "Couldn\'t create instance of the $variant_ref class");
	    }
	}

	my $cur_offset = tell $fih;
	$variant_handler = $self->{$variant_name};
	$status = $variant_handler->readTag($tag_name, $tag_type, $tag_cnt, $tag_offset);
        OME::ImportExport::FileUtils::seek_it($fih, $cur_offset);

	return $status;;
    }

    # simple TIFF tags have their value in the offset field
    $tag_name = $Tagnames{$tag_id};
    if ((($tag_type == 1) || ($tag_type == 3) || ($tag_type == 4)) && $tag_cnt == 1) {
	$value = $tag_offset;
    }
    else {   # the other tags have value lists located at 'offset'
	# remember where we are
	$cur_loc = tell($fih);
	# & go read the values
	$status = OME::ImportExport::FileUtils::seek_it($fih, $tag_offset);
	return $status
	    unless $status eq "";

	if ($tag_type == 2) {
	    $cnt = $tag_cnt;            # length of ASCII string
	    $tag_cnt = 1;               # read entire string at once
	}
	else {
	    @fmts = (0,1,0,2,4,8);
	    if ($tag_type > $#fmts) {
		$status = "\nBad tag type: $tag_type  " ;
		return $status;
	    }
	    $cnt = $fmts[$tag_type];    # How many bytes to read/value
	}
	if ($endian eq "little") {
	    @fmts = ("_","c","_","v","V","VV");
	}
	else {
	    @fmts = ("_","c","_","n","N","NN");
	}
	$format = $fmts[$tag_type];
	if ($tag_cnt > 1) {
	    $is_list = 1;
	    @vallist = ();
	}
	while($tag_cnt) {    # read each value in the value list
	    $status = OME::ImportExport::FileUtils::read_it($fih, \$buf, $cnt);
	    return $status
		unless $status eq "";

	    if ($tag_type == 2) {                 # the string type
		$value = $buf;
		if ($tag_name eq "DocumentName") {
		    $value =~ s\.*/\\g;           # strip path from document name
		}
	    }
	    elsif ($tag_type == 5) {
		($val1, $val2) = unpack($format, $buf);  # the "Rational' type
		$value = $val1/$val2;
	    }
	    else {
		$value = unpack($format, $buf);   # the other types
	    }
	    if ($is_list) {
		push @vallist, $value;
	    }
	    $tag_cnt--;
	}
	$status = OME::ImportExport::FileUtils::seek_it($fih, $cur_loc);
    }

    if (defined $tag_name) {
	if ($tag_name eq 'BitsPerSample') {
	    if ($value < 8) {
		$status = "Pixle size too small - cannot process file";
	    }
	    elsif ($is_list) {
		$status = "More than one color per file - cannot process";
	    }
	}
	if ($status eq "") {

	    if (!$is_list) {
		$self->{$tag_name} = $value;
		#print "$tag_name = $value\n";
	    }
	    # some tag contents accumulate across multi-file images
	    else {    # accumulate via array of array references
		if (defined($tag_accumulates{$tag_name})) {
		    push @{ $self->{$tag_name} }, \@vallist;
		}
		else {
		    $self->{$tag_name} = \@vallist;
		}
	    }
	}
    }
    
    return $status;
}

1;
