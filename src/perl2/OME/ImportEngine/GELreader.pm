#!/usr/bin/perl -w
#
# OME::ImportEngine::GELreader.pm
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

OME::ImportEngine::GELreader.pm  -  import Molecular Dynamics GEL format files


=head1 SYNOPSIS

    use OME::ImportEngine::GELreader
    my $gelFormat = new GELreader($session, $module_execution)
    my $groups = $gelFormat->getGroups(\@filenames)
    my $image = $gelFormat->importGroup(\@filenames)

=head1 DESCRIPTION

This importer class handles Molecular Dynamics' TIFF variant GEL format files.
The getGroups() method discovers which files in a set of files have the 
GEL format, and the importGroup() method imports these GEL format files into 
OME 5D image files and metadata.

See TIFFreader.pm for further discussion of plain and variant TIFF imports.

Each GEL file represents a different image; they do not form groups. The 
getGroup method will therfore import each single file 'group' into an OME
5D image. All relevant metadata carried in the TIFF files will be
stored in the OME database.

=cut



package OME::ImportEngine::GELreader;

use Class::Struct;
use strict;
use File::Basename;
use Log::Agent;
use Carp;
use OME::ImportEngine::FileUtils qw(/^.*/);
use OME::ImportEngine::Params;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::TIFFUtils;
use OME::ImportExport::Repacker::Repacker;
use base qw(OME::ImportEngine::AbstractFormat);

use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use constant WHITE_IS_ZERO   => 0;

use constant 'MD_FILETAG'    => 33445;
use constant 'MD_SCALEPIXEL' => 33446;
use constant 'MD_COLORTABLE' => 33447;
use constant 'MD_LABNAME'    => 33448;
use constant 'MD_SAMPLEINFO' => 33449;
use constant 'MD_PREPDATE'   => 33450;
use constant 'MD_PREPTIME'   => 33451;
use constant 'MD_FILEUNITS'  => 33452;

use constant 'SQUARE_ROOT'   => 2;
use constant 'LINEAR'        => 128;

my %tagnameHash = (MD_FILETAG    => 33445,
	       MD_SCALEPIXEL => 33446,
	       MD_COLORTABLE => 33447,
	       MD_LABNAME    => 33448,
	       MD_SAMPLEINFO => 33449,
	       MD_PREPDATE   => 33450,
	       MD_PREPTIME   => 33451,
	       MD_FILEUNITS  => 33452);

my %tagHash = (MD_FILETAG    => \&filetag,
	       MD_SCALEPIXEL => \&scalepixel,
	       MD_COLORTABLE => \&colortable,
	       MD_LABNAME    => \&labname,
	       MD_SAMPLEINFO => \&sampleinfo,
	       MD_PREPDATE   => \&prepdate,
	       MD_PREPTIME   => \&preptime,
	       MD_FILEUNITS  => \&fileunits);

# Offset(s) and size(s) of pixel array(s) in the TIFF file
my ($offsets_arr, $bytesize_arr);

# Special values extracted from cutom tags. Values used in pixel processing
# or stored as image attributes.

my $pixel_format;
my $pixel_scale;
my $labname;
my $sampleinfo;
my $prepdate;
my $preptime;
my $fileunits;
my $manufacturer;

=head2 Patterns Defining Groups

Unlike some other TIFF format files, GEL files do not form groups. This module
will not attempt to group GEL files together by file name patterns or any
other method.

=cut


=head1 METHODS

The following public methods are available:


=head2 B<new>


    my $importer = OME::ImportEngine->GELreader->new($session, $module_execution)

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
    $self->{super} = $self->SUPER::new($session, $module_execution);

    my %paramHash;
    $self->{params} = new OME::ImportEngine::Params(\%paramHash);
    return $self;
}


=head2 B<getGroups> S< > S< > S< >

    my $group_output_list = $importer->getGroups(\@filepaths)

This method examines the list of filenames that is passed in by
reference. Any files on the list that are GEL files are removed
from the input list and added to the output list. 

This method examines each file's contents, first looking for the 
presence of TIFF identity bytes at the beginning of the file. 
If these identity bytes are present, it then looks for the custom 
GEL tag designated MD_FILETAG. If it finds this tag, it decides the file
has the GEL format.

=cut

sub getGroups {
    my $self = shift;
    my $fref = shift;
    my $nmlen = scalar(keys %$fref);
    my @outlist;

    foreach my $key (keys %$fref) {
        my $file = $fref->{$key};

        $file->open('r');

	my $len;
	my $buf;
	
	my $tags = readTiffIFD($file);
	$file->close();

	my $customTag = MD_FILETAG;
	if (!defined($tags->{$customTag})) {
	    next;
	}

	# it's GEL format, so remove from input list, put on output list
        delete $fref->{$key};
        push @outlist, $file;
    }

    $self->{groups} = \@outlist;

    return \@outlist;
}


=head2 importGroup

    my $image = $importer->importGroup(\@files)

This method imports individual GEL format files into OME
5D images. The caller passes a set of input files by
reference. This method opens each file in turn, extracts
its metadata and pixels, and creates a corresponding OME image.

Besides the metadata it extracts from standard TIFF tag values, this
method also extracts metadata from the custom GEL tags called MD_FILETAG,
MD_SCALEPIXEL, MD_COLORTABLE, MD_LABNAME, MD_SAMPLEINFO, MD_PREPDATE,
MD_PREPTIME, and MD_FILEUNITS.

If all goes well, this method returns a pointer to a freshly created 
OME::Image. In that case, the caller should commit any outstanding
image creation database transactions. If the module detects an error,
it will return I<undef>, signalling the caller to rollback any associated
database transactions.

=cut


# Import a single group. For GEL format files, a group always contains
# just one file.

sub importGroup {
    my $self = shift;
    my $file = shift;
    my $status;


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

    ($offsets_arr, $bytesize_arr) = getStrips($tags);

    my $params = $self->getParams();
    $params->image_offsets($offsets_arr);
    $params->image_bytecounts($bytesize_arr);
    
    $params->fref($file);
    $params->oname($filename);
    $params->endian($tags->{__Endian});
    my $xref = $params->{xml_hash};
    $xref->{'RowsPerStrip'} = $tags->{TAGS->{RowsPerStrip}}->[0];
    $xref->{'Image.SizeX'} = $tags->{TAGS->{ImageWidth}}->[0];
    $xref->{'Image.SizeY'} = $tags->{TAGS->{ImageLength}}->[0];
    $xref->{'Data.BitsPerPixel'} = $tags->{TAGS->{BitsPerSample}}->[0];
    $params->byte_size($xref->{'Data.BitsPerPixel'}/8);
    $params->row_size($xref->{'Image.SizeX'} * ($params->byte_size));

    # Assumes that GEL files never represent more than 1 timepoint, wavelength,
    # or Z position.
    $xref->{'Image.SizeZ'} = 1;
    $xref->{'Image.NumTimes'} = 1;
    $xref->{'Image.NumWaves'} = 1;

    my @finfo;
    my $image;
  PROCESS:
    {
	my @custom_tags = (MD_FILETAG, MD_SCALEPIXEL, MD_COLORTABLE, MD_LABNAME, MD_SAMPLEINFO, MD_PREPDATE, MD_PREPTIME, MD_FILEUNITS);
	foreach my $tg (@custom_tags) {
	    my $t_arr = $tags->{$tg};
	    if (!defined $t_arr) {
		next;
	    }
	    my $t_hash = $$t_arr[0];
	    my $status = readTag ($self, $t_hash->{tag_id}, $t_hash->{tag_type},
				  $t_hash->{value_count}, $t_hash->{value_offset},
				  $t_hash->{current_offset});
	    last PROCESS
		unless ($status eq "");
	}

        $image = ($self->{super})->__newImage($filename);
	$self->{image} = $image;


	# pack together & store info on input file
	$self->__storeOneFileInfo(\@finfo, $file, $params, $image,
				  0, $xref->{'Image.SizeX'}-1,
				  0, $xref->{'Image.SizeY'}-1,
				  0, 0,
				  0, 0,
				  0, 0,
				  "Molecular Dynamics GEL");

	$self->{inflation} = ($pixel_format == SQUARE_ROOT) ? 2 : 1;
	my ($pixels, $pix) = 
	    ($self->{super})->__createRepositoryFile($image, 
						     $xref->{'Image.SizeX'},
						     $xref->{'Image.SizeY'},
						     $xref->{'Image.SizeZ'},
						     $xref->{'Image.NumWaves'},
						     $xref->{'Image.NumTimes'},
						     $self->{inflation} * $xref->{'Data.BitsPerPixel'});
	$self->{pix} = $pix;
	$self->{pixels} = $pixels;
	my $interpretation = $tags->{TAGS->{PhotometricInterpretation}}->[0];
	$status = readWritePixels($self, $params, $interpretation);
    }
    $file->close();

    if ($status eq "") {
	$self->__storeInputFileInfo($session, \@finfo);
	# Store info about each input channel (wavelength).
	storeChannelInfo($self, $session);
    } else {
	die "$status";
    }

    my @instrInfo;
    $instrInfo[0] = $fileunits;
    $instrInfo[1] = $manufacturer;
    $self->__storeInstrumemtInfo($image, @instrInfo);
    return $image;

}



sub readWritePixels {
    my $self = shift;
    my $params = shift;
    my $interpretation = shift;
    my $pix = $$params{pix};
    my $pixels = $$params{pixels};
    my $file      = $params->fref;
    my $xref = $params->{xml_hash};
    my $row_size       = $params->row_size;
    my $offsets_arr    = $params->image_offsets;
    my $bytecounts_arr = $params->image_bytecounts;
    my $theY = 0;
    my $buf;
    my $sz_read = 0;
    my $status = "";
    my $rows_per_strip = $xref->{'RowsPerStrip'};
    $rows_per_strip = $xref->{'Image.SizeY'}
        unless (defined $rows_per_strip);


    for (my $i = 0; $i < $#$bytecounts_arr+1; $i++) {
	my $sz = $bytecounts_arr->[$i];
	my $offset = $offsets_arr->[$i];
	$file->setCurrentPosition($offset,0);
	$buf = $file->readData($sz);
	last
	    unless ($status eq "");

	my $endian   = $params->endian;
	my $bps      = $params->byte_size;

	my $newbuf;

	if ($pixel_format == SQUARE_ROOT) {
	#    print STDERR "scaling $sz bytes of $bps bytes/pixel at scaling $pixel_scale\n";
	    $buf = Repacker::gel_scaler($buf, $sz, $bps, $pixel_scale);
	    $bps *= $self->{inflation};
	}
	if ($interpretation == WHITE_IS_ZERO) {
	    my $cnt2 = Repacker::invert($buf, $sz, $bps);
	}
	my $nPixOut;
	eval { $nPixOut = $self->{pix}->setROI($buf, 0, $theY, 0, 0, 0,
					       $xref->{'Image.SizeX'}-1,
					       $theY + $rows_per_strip, 
					       0, 0, 0,
					       ($params->{endian} eq "big")); };
	if ($@) {
	    $status = $@;
	    last;
	}
	if ($self->{plane_size}/$params->byte_size != $nPixOut) {
	    $status = "Failed to write repository file - $self->{plane_size}/".$params->byte_size." != $nPixOut";
	    last;
	}
	$theY += $rows_per_strip;
    }
    return $status;
}


# Get %params hash reference
sub getParams {
    my $self = shift;
    return $self->{params};
}



# This method reads a GEL specific tag and loads its contents into $self
sub readTag {
    my ($self, $tagname, $type, $cnt, $offset, $curr_offset) = @_;
    my $params = $self->{params};
    my $endian = $params->endian;
    my $fih    = $params->fref;
    my $cur_offset;
    my $status;


    $fih->setCurrentPosition($curr_offset,0);

    my %byNumber = reverse %tagnameHash;
    my $funcName = $byNumber{$tagname}; 
    my $func = $tagHash{$funcName};
    $status = $func->($self, $endian, $fih, $type, $cnt, $offset);

    return($status);
}


# Handle MD_FILETAG, which specifies the file's pixel formatting
sub filetag {
    my $buf;
    my $status = "";
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;
    $pixel_format = $offset;
    $status = "Unknown pixel format: $pixel_format"
	unless (($pixel_format == SQUARE_ROOT) || ($pixel_format == LINEAR));

    return($status);
}

# Handle MD_SCALEPIXEL, scaling factor to apply to pixels before processing
sub  scalepixel {
    my $status = "";
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;

    my $funcref = \&getTagValue;

    my @vals;
    eval { @vals = OME::ImportEngine::TIFFUtils::getTagValue($fih, $type, $cnt, $offset, $endian) };
    if ($@) {
	return "GELreader error calling getTagValue: $@";
    }
    $pixel_scale = pop(@vals);
    $status = "Failed to extract pixel scale"
	unless defined $pixel_scale;

    return $status;
}

# MD_COLORTABLE used to specify conversion of 16-bit images to 8-bit images.
# Since OME is not constrained to 8-bit images, read & discard the table.
sub  colortable {
    my $buf;
    my $status = "";
    my ($self, $endian, $fih, $type, $cnt) = @_;
    return $status;
}

sub labname {
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;

    my @vals = OME::ImportEngine::TIFFUtils::getTagValue($fih, $type, $cnt, $offset, $endian);
    $labname = pop(@vals);
    return "";
}


sub sampleinfo {
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;

    my @vals = OME::ImportEngine::TIFFUtils::getTagValue($fih, $type, $cnt, $offset, $endian);
    my $sampleinfo = pop(@vals);
    return "";
}

sub prepdate {
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;

    my @vals = OME::ImportEngine::TIFFUtils::getTagValue($fih, $type, $cnt, $offset, $endian);
    my $prepdate = pop(@vals);
    return "";
}

sub preptime {
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;

    my @vals = OME::ImportEngine::TIFFUtils::getTagValue($fih, $type, $cnt, $offset, $endian);
    my $preptime = pop(@vals);
    return "";
}

sub fileunits {
    my ($self, $endian, $fih, $type, $cnt, $offset) = @_;

    my @vals = OME::ImportEngine::TIFFUtils::getTagValue($fih, $type, $cnt, $offset, $endian);
    $fileunits = pop(@vals);
    $fileunits =~ s/[\x00]//g;
    $manufacturer = getManu($fileunits);
    
    return "";
}


# Return manufacturer's name depending on model name passed in
sub getManu {
    my $model = shift;
    if (($model =~ m/^rfu$/i) || 
	($model =~ m/^counts$/i) ||
	($model =~ m/o\.d\.$/i)) {
	return("Molecular Dynamics");
    } else {
	return "";
    }
}

sub storeChannelInfo {
    my ($self, $session) = @_;
    my @channelInfo;
    # Store info about each input channel (wavelength)
    push @channelInfo, {chnlNumber => 0,
			ExWave     => undef,
			EmWave     => undef,
			Fluor      => undef,
			NDfilter   => undef};
    $self->__storeChannelInfo($session, 1, @channelInfo);
}


sub getSHA1 {
    return(getCommonSHA1(@_));
}


sub cleanup {
	# clear out the TIFF tag cache
	OME::ImportEngine::TIFFUtils::cleanup();
}
=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>
L<OME::ImportEngine::TIFFreader.pm>

=cut


1;
