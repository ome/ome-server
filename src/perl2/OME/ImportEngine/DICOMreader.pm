#!/usr/bin/perl -w
#
# OME::ImportEngine::DICOMreader.pm
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
# Written by: Tom Macura
#-------------------------------------------------------------------------------


#

=head1 NAME

OME::ImportEngine::DICOMreader.pm  -  DICOM format image importer


=head1 SYNOPSIS

    use OME::ImportEngine::DICOMreader
    my $dicomFormat = new DICOMreader($session, $module_execution)
    my $groups = $dicomFormat->getGroups(\@filenames)
    my $image  = $dicomFormat->importGroup(\@filenames)


=head1 DESCRIPTION

This importer class handles images in the DICOM format.

The getGroups() method discovers which files in a set of input files are
in the DICOM format. DICOM files each contain a 2D or 2D+Time image.
FIXME: each DICOM file is interpreted as its own group. The importGroup()
method will import each single DICOM file into a separate OME 5D image.

=cut

package OME::ImportEngine::DICOMreader;

use strict;
use Carp;

use OME::ImportEngine::DICOM;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::Params;

use base qw(OME::ImportEngine::AbstractFormat);
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

=head1 METHODS

The following public methods are available:


=head2 B<new>


    my $importer = OME::ImportEngine::DICOMreader->new($session, $module_execution)

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
reference. Any files on the list that are DICOM files are removed
from the input list and added to the output list. 

DICOM files can be recognized because they begins with a 128 byte 
preamble followed by the letters 'D', 'I', 'C', 'M'. 

=cut


sub getGroups {
    my $self = shift;
    my $fref = shift;
    my @outlist;

    foreach my $key (keys %$fref) {
    	my $file = $fref->{$key};

        $file->open('r');
        $file->setCurrentPosition(128,0);
        my $buf = $file->readData(4);
        $file->close();
        
      	next unless ($buf eq 'DICM');  
      	
        # it's in the DICOM format, so remove from input list, put on output list
        delete $fref->{$key};
        push @outlist, $file;
    }

    $self->{groups} = \@outlist;
    return \@outlist;
}



=head2 importGroup

    my $image = $importer->importGroup(\@files)

This method imports individual DICOM format files into OME
5D images. The caller passes a set of input files by
reference. This method opens each file in turn, extracts
its metadata and pixels, and creates a coresponding OME image.

The arrangement of the pixels in the DICOM file is assumed to be
in XYT format. We believe this assumption is meritorious.

If all goes well, this method returns a pointer to a freshly created 
OME::Image. In that case, the caller should commit any outstanding
image creation database transactions. If the module detects an error,
it will return I<undef>, signalling the caller to rollback any associated
database transactions.

=cut

sub importGroup {
    my ($self, $file, $callback) = @_;
    
    my $session = ($self->{super})->Session();
    my $factory = $session->Factory();
	my $params = $self->{params};

	my $filename = $file->getFilename();
    ($self->{super})->__nameOnly($filename);
    $params->fref($file);
    $params->oname($filename);
    
	# open file and read DICOM tags
	my $dicom_tags = OME::ImportEngine::DICOM->new(); 
	my $debug=1; # make debug true if you want the DICOM's header dumped to screen
	$dicom_tags->fill($file,$debug);
	
	# Use the DICOM tags to populate some info
	my $bits_stored = $dicom_tags->value('BitsStored');
	my $bits_allocated = $dicom_tags->value('BitsAllocated');
	my $high_bit = $dicom_tags->value('HighBit');
 	
 	# check for unsupported DICOM images
 	if ($bits_allocated != $bits_stored) {
 		print STDERR "DICOM format not supported. The number of bits allocated ($bits_allocated) doesn't".
 		" match number of bits stored ($bits_stored).\n";
 		return undef;
 	}
 	if ($bits_stored != 8 and $bits_stored != 16) {
 		print STDERR "DICOM format not supported. The number of bits stored ($bits_stored) must be".
 		" either 8 or 16.\n";
 		return undef;
 	}
 	
 	# figure out whether pixels encoding is Little endian or big endian
    my $transfer_syntax = $dicom_tags->value('TransferSyntaxUID');
    if ($transfer_syntax eq "1.2.840.10008.1.2") {
    	# implicit VR, little Endian
    	$params->endian(0);
    } elsif ($transfer_syntax eq "1.2.840.10008.1.2.1") {
   		 # explicit VR, little Endian
    	$params->endian(0);
    } elsif ($transfer_syntax eq "1.2.840.10008.1.2.2" ) {
       	# explicit VR, big Endian
    	$params->endian(1);
    } else {
    	print STDERR "DICOM format not supported. The Transfer Syntax UID is not supported.\n";
 		return undef;
    }
    
 	# get pixels dimension info
 	my $xref = $params->{xml_hash};
    $xref->{'Image.ImageType'} = "DICOM";
    $xref->{'Image.SizeX'} = $dicom_tags->value('Columns');
    $xref->{'Image.SizeY'} = $dicom_tags->value('Rows');
    $xref->{'Image.SizeZ'} = 1;
	$xref->{'Image.NumWaves'} = 1;
	if ($dicom_tags->value('NumberOfFrames')) {
	    $xref->{'Image.NumTimes'} = $dicom_tags->value('NumberOfFrames');
	} else {
	    $xref->{'Image.NumTimes'} = 1;
	}
	$xref->{'Image.isSigned'} = $dicom_tags->value('PixelRepresentation');
		
	# those idiots are trying to kill us with spaces
	print "file name is ".$file->getFilename()."\n" if $debug;
	printf "SizeX=%d SizeY=%d SizeZ=%d SizeT=%d SizeC=%d isSigned=%d\n",
	$xref->{'Image.SizeX'},
	$xref->{'Image.SizeY'},
	$xref->{'Image.SizeZ'},
	$xref->{'Image.NumTimes'},
	$xref->{'Image.NumWaves'},
	$xref->{'Image.isSigned'}  if $debug;
	
	
	$xref->{'Image.SizeX'}    =~ s/ //;
	$xref->{'Image.SizeY'}    =~ s/ //;
	$xref->{'Image.SizeZ'}    =~ s/ //;
	$xref->{'Image.NumTimes'} =~ s/ //;
	$xref->{'Image.NumWaves'} =~ s/ //;
	$xref->{'Image.isSigned'} =~ s/ //;
    $xref->{'Data.BitsPerPixel'} = $bits_allocated;
    
    $params->byte_size($xref->{'Data.BitsPerPixel'}/8);
    $params->row_size($xref->{'Image.SizeX'} * ($params->byte_size));

    					 
    my $image = ($self->{super})->__newImage($filename);
    $self->{image} = $image;
    
    # pack together & store info the input file
    my @finfo; 
    $self->__storeOneFileInfo(\@finfo, $file, $params, $image,
			      0, $xref->{'Image.SizeX'}-1,
			      0, $xref->{'Image.SizeY'}-1,
			      0, $xref->{'Image.SizeZ'}-1,
			      0, $xref->{'Image.NumWaves'}-1,
			      0, $xref->{'Image.NumTimes'}-1,
                  "DICOM");
                  
	my ($pixels, $pix) = 
	($self->{super})->__createRepositoryFile($image, 
						 $xref->{'Image.SizeX'},
						 $xref->{'Image.SizeY'},
						 $xref->{'Image.SizeZ'},
						 $xref->{'Image.NumWaves'},
						 $xref->{'Image.NumTimes'},
						 $xref->{'Data.BitsPerPixel'},
						 $xref->{'Image.isSigned'},
						 );
    $self->{pixels} = $pixels;
    
    # FIXME this needs fixing to work with the RE ST.
    my ($t, $c, $z);
    my $maxY = $xref->{'Image.SizeY'};
    my $maxZ = $xref->{'Image.SizeZ'};
    my $maxC = $xref->{'Image.NumWaves'};
    my $maxT = $xref->{'Image.NumTimes'};
    my $plane_size = $xref->{'Image.SizeX'} * $xref->{'Image.SizeY'}*$params->byte_size;
    my $offset;
    my $start_offset = $dicom_tags->value('PixelData');
    for (my $i = 0, $t = 0; $t < $maxT; $i++, $t++) {
		for ($c = 0; $c < $maxC; $c++) {
			for ($z = 0; $z < $maxZ; $z++) {
				$offset = $start_offset + ($z+$c*$maxZ+$t*$maxZ*$maxC) * $plane_size;
				$pix->convertPlane($file,$offset,$z,$c,$t,$params->endian);
				doSliceCallback($callback);
			}
		}
    }

	OME::Tasks::PixelsManager->finishPixels ($pix,$self->{pixels});
	

    $file->close();

	$self->__storeInputFileInfo ($session, \@finfo);
	
	# Store info about each input channel (wavelength).
	$self->__storeChannelInfo ($session);
	
	my $windowCenter = $dicom_tags->value('WindowCenter');
	my $windowWidth  = $dicom_tags->value('WindowWidth');
	my $rescaleIntercept = $dicom_tags->value('RescaleIntercept');
	if (not defined $rescaleIntercept) {
		$rescaleIntercept = 0;
	}
	
	if (not defined $windowCenter or not defined $windowWidth) {
		$self->__storeDisplayOptions ($session);
	} else {
		$self->__storeDisplayOptions ($session,
			{min => $windowCenter - $windowWidth/2 - $rescaleIntercept, 
			 max => $windowCenter + $windowWidth/2 - $rescaleIntercept });
	}
	
	return $image;
}

# Store channel (wavelength) info
sub storeChannelInfo {
    my $self = shift;
    my $session = shift;
    my $params = $self->{params};
    my $xref = $params->{xml_hash};
    my $numWaves = $xref->{'Image.NumWaves'};
    my @channelInfo;

    for (my $i = 0; $i < $numWaves; $i++) {
	push @channelInfo, {chnlNumber => $i,
			    ExWave     => undef,
			    EmWave     => undef,
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

Tom Macura

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut

1;
