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

    # Group files with recognized patterns together
    my ($groups, $infoHash) = $self->{super}->__getRegexGroups($fref);

	# process grouped DICOM images first
    foreach my $name (keys (%$groups)) {
    	next unless defined($name);
    	my @groupList;
    	my $maxZ = $infoHash->{$name}->{maxZ};

		for (my $z = 0; $z <= $maxZ; $z++) {
			my $file = $groups->{$name}[$z][0][0];
			next unless ( defined($file) );

			$file->open('r');
			$file->setCurrentPosition(128,0);
			my $buf = $file->readData(4);
			$file->close();
			
			next unless ($buf eq 'DICM');  
      	
			push (@groupList, $file);
			
			# delete the file from the hash, so it's not processed by other importers
			delete $fref->{ $file };
		}
		push (@groupList, $name); # last elment of list is just a name
    	push (@outlist, \@groupList);
    }
    
    foreach my $key (keys %$fref) {
    	my $file = $fref->{$key};
		my @groupList;
		
        $file->open('r');
        $file->setCurrentPosition(128,0);
        my $buf = $file->readData(4);
        $file->close();
        
      	next unless ($buf eq 'DICM');  
      	
        # it's in the DICOM format, so remove from input list, put on output list
        delete $fref->{$key};
        push (@groupList, $file);
        push (@groupList, $file->getFilename());
    	push (@outlist, \@groupList);
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
    my ($self, $groupList, $callback) = @_;
    
    my $session = ($self->{super})->Session();
    my $factory = $session->Factory();
	my $file = $$groupList[0];
	my $params = $self->{params};

    # use the file group's basename as the filename for the group
	my $filename = $$groupList[scalar @$groupList-1];
    ($self->{super})->__nameOnly($filename);
    
	# open file and read DICOM tags
	my $dicom_tags = OME::ImportEngine::DICOM->new(); 
	my $debug=0; # make debug true if you want the DICOM's header dumped to screen
	$dicom_tags->fill($file, $debug);
	
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
	$xref->{'Image.SizeZ'} = scalar @$groupList - 1; # remember, last groupList is base filename
	$xref->{'Image.NumWaves'} = 1;
	$xref->{'Image.NumTimes'} = $dicom_tags->value('NumberOfFrames') or 
			$xref->{'Image.NumTimes'} = 1;
	$xref->{'Image.isSigned'} = $dicom_tags->value('PixelRepresentation');
		
	# those idiots are trying to kill us with spaces
	$xref->{'Image.SizeX'} =~ s/ //; $xref->{'Image.SizeY'} =~ s/ //; $xref->{'Image.SizeZ'} =~ s/ //; $xref->{'Image.NumTimes'} =~ s/ //; $xref->{'Image.NumWaves'} =~ s/ //; $xref->{'Image.isSigned'} =~ s/ //;
    
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
    
    my $plane_size = $xref->{'Image.SizeX'} * $xref->{'Image.SizeY'}*$params->byte_size;
    my $offset;
    my ($i,$t,$z);
	my ($sizeX, $sizeY, $sizeT, $isSigned, $new_transfer_syntax);
	for ($z = 0; $z < $xref->{'Image.SizeZ'}; $z++) {
		$file = $$groupList[$z];
		
		# read DICOM tags of new file
		$dicom_tags->fill($file,$debug) unless $z == 0;
		
		$sizeX = $dicom_tags->value('Columns');
		$sizeY = $dicom_tags->value('Rows');
		$sizeT = $dicom_tags->value('NumberOfFrames') or $sizeT = 1;
		$isSigned = $dicom_tags->value('PixelRepresentation');
		$new_transfer_syntax = $dicom_tags->value('TransferSyntaxUID');
		
		$sizeX =~ s/ //; $sizeY =~ s/ //; $sizeT =~ s/ //; $isSigned =~ s/ //; $new_transfer_syntax =~ s/ //;

		# verfiy that the subsequent DICOM images have compatible dimensions
		# to the first DICOM image
		if ($transfer_syntax ne $new_transfer_syntax or
		    $xref->{'Image.SizeX'}    ne $sizeX or
   			$xref->{'Image.SizeY'}    ne $sizeY or 
	   	    $xref->{'Image.NumTimes'} ne $sizeT or
			$xref->{'Image.isSigned'} ne $isSigned ) {
			
			printf STDERR "\nDICOM images in FileName Group are incompatible.\n";
			printf STDERR "[0] TSUID=%s  [%d] TSUID=%s\n", $transfer_syntax, $z, $new_transfer_syntax;
			printf STDERR "[0] SizeX=%s  [%d] SizeX=%s\n", $xref->{'Image.SizeX'}, $z, $sizeX;
			printf STDERR "[0] SizeY=%s  [%d] SizeY=%s\n", $xref->{'Image.SizeY'}, $z, $sizeY;
			printf STDERR "[0] SizeT=%s  [%d] SizeT=%s\n", $xref->{'Image.NumTimes'}, $z, $sizeT;
			printf STDERR "[0] isSigned=%s [%d] isSigned='%s'\n", $xref->{'Image.isSigned'}, $z, $isSigned;

 			return undef;
 		}

    	for ($i = 0, $t = 0; $t < $xref->{'Image.NumTimes'}; $i++, $t++) {
			$offset = $dicom_tags->value('PixelData') + $t*$plane_size;
			$pix->convertPlane($file,$offset,$z,0,$t,$params->endian);
			doSliceCallback($callback);
		}
	    $file->close();
    }

	OME::Tasks::PixelsManager->finishPixels ($pix,$self->{pixels});
	
	$self->__storeInputFileInfo ($session, \@finfo);
	
	# Store info about each input channel (wavelength).
	$self->__storeChannelInfo ($session);
	
	# Set display options
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
    my $grp = shift;

    my $fn = $grp->[0];
    my $sha1 = $fn->getSHA1();

    return $sha1;
}

=head1 Author

Tom Macura

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut

1;
