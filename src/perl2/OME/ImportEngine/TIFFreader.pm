#!/usr/bin/perl -w
#
# OME::ImportEngine::TIFFreader.pm
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
#				 Arpun Nagaraja
#
#-------------------------------------------------------------------------------


#

=head1 NAME

OME::ImportEngine::TIFFreader.pm  -  single & group TIFF image importer


=head1 SYNOPSIS

    use OME::ImportEngine::TIFFreader
    my $tiffFormat = new TIFFreader($session, $module_execution)
    my $groups = $tiffFormat->getGroups(\@filenames)
    my $image = $tiffFormat->importGroup(\@filenames)

=head1 DESCRIPTION

This importer class handles regular TIFF format images. The getGroups()
method discovers which files in a set of files have the TIFF format,
and the importGroup() method imports TIFF format files into OME 5D
image files and metadata.

See http://partners.adobe.com/asn/developer/pdfs/tn/TIFF6.pdf for the
complete TIFF specification.

The  getGroups() method will assemble groups of TIFF files that
together comprise a 5D image, as well as identifying single stand-alone
TIFF files. The importGroup() method will import a multi-file
group, stitching together the individual TIFF images into a single
5D OME image. It will also import a single file 'group' into an OME
5D image. All relevant metadata carried in the TIFF files will be
stored in the OME database.

This module will take ownership of any input file that has the
base TIFF format. But various 3rd party image files are also based
on the TIFF format, with additional custom features of their own.
If these files get passed to this importer, it will pull them in,
losing any custom metadata or formatting carried in these files.
For this reason, all TIFF variant importers must be called before 
this importer gets called.

=cut



package OME::ImportEngine::TIFFreader;
use Class::Struct;
use strict;
use File::Basename;
use Carp;
use OME::ImportEngine::Params;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::TIFFUtils;
use base qw(OME::ImportEngine::AbstractFormat);

use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

=head2 Patterns Defining Groups

All the files in a TIFF file group will have the same filename pattern. 
Each filename will have a common base, and a variable part that identifies 
the instance of a group variable that the file represents. For instance,
a TIFF group that has images of the same plate well taken at 2 different
illumination wavelengths could have files named "plate4_well54_w1.tiff"
and "plate4_well54_w2.tiff".

To group related files together, a call to __getRegexGroups() in the superclass
is used, followed by sorting and verification that files are indeed tiffs.

=cut

=head1 METHODS

The following public methods are available:


=head2 B<new>


    my $importer = OME::ImportEngine->TIFFreader->new($session, $module_execution)

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
}


=head2 B<getGroups> S< > S< > S< >

    my $group_output_list = $importer->getGroups(\@filepaths)

This method examines the list of filenames that is passed in by
reference. If a file contains the TIFF identifyer bytes in its begining,
it is declared to be TIFF format. Any files on the list that are 
declared TIFF files are removed from the input list and added to the 
output list. 

If a set of these TIFF files match any of the criteria that define a 
group, that set is added as an array to the output list. Any TIFF file 
that does not belong to such a group is placed into its own array (a 
group of 1) and placed on the output list. 

For each group, this method also determines what the OME repository 
image filename will be for that group. It then pushes this output name 
onto the arrary of input filenames; the importGroup() method will later 
extract it and create it in the repository to hold the new import.

=cut


sub getGroups {
    my $self = shift;
    my $fref = shift;
    my @outlist;
    my $xref;
    
    # Group files with recognized patterns together
    # Sort them by channels, z's, then timepoints
    my ($groups, $infoHash) = $self->{super}->__getRegexGroups($fref);

    foreach my $name ( keys (%$groups) ) {
    	next unless defined($name);
    	my @groupList;
    	my $maxZ = $infoHash->{ $name }->{ maxZ };
		my $maxT = $infoHash->{ $name }->{ maxT };
		my $maxC = $infoHash->{ $name }->{ maxC };

		for (my $t = 0; $t <= $maxT; $t++) {
    		for (my $z = 0; $z <= $maxZ; $z++) {
    			for (my $c = 0; $c <= $maxC; $c++) {
    				my $file = $groups->{ $name }[$z][$t][$c];
    				next unless ( defined($file) );
    				
    				# skip this image unless it's a tiff
    				next unless ( defined(verifyTiff($file)) );
    				
    				push (@groupList, $file);
    				$xref->{ $file }->{ 'Image.SizeZ' } = $maxZ;
    				$xref->{ $file }->{ 'Image.NumTimes' } = $maxT;
    				$xref->{ $file }->{ 'Image.NumWaves' } = $maxC;
    				
    				# delete the file from the hash, so it's not processed by other importers
    				delete $fref->{ $file };
    			}
    		}
    	}
    	push (@groupList, $name);
    	push (@outlist, \@groupList) if ( scalar(@groupList) > 0 );
    }
    
    # Now look at the rest of the files in the list to see if you have any other tiffs.
    foreach my $file ( values %$fref ) {
    	my @groupList;
    	
    	# skip this image unless it's a tiff
    	next unless (defined(verifyTiff($file)));
    	
    	my $filename = $file->getFilename();
    	my $basename = ($self -> {super}) -> __nameOnly( $filename );
    	
    	push (@groupList, $file);
    	push (@groupList, $basename);
    	$xref->{ $file }->{ 'Image.SizeZ' } = 1;
    	$xref->{ $file }->{ 'Image.NumTimes' } = 1;
    	$xref->{ $file }->{ 'Image.NumWaves' } = 1;
    	push (@outlist, \@groupList);
    	delete $fref->{ $file };
    }
    
#     foreach my $element ( @outlist )
# 	{
# 		print "Loop: \n";
# 		foreach my $temp ( @$element )
# 		{
# 			print "\t$temp\n";
# 		}
# 	}
    
    # Store the xml hash for later use in importGroup.
    $self->{ params }->{ xml_hash } = $xref;
	
    return \@outlist;
}


=head2 importGroup

    my $image = $importer->importGroup(\@filenames)

This method imports a group of related TIFF files into a single
OME 5D image. The caller passes the ordered set of input files 
comprising the group  (plus the name of the output file to create)
by reference. This method opens each file in turn, extracting its
metadata and pixels, and adding them to the accumulating OME pixels
and metadata.

TIFF files carry metadata in one or more sections called IFDs. Each IFD
holds a set of information fields called tag fields. These fields hold
metadata values as bytes, shorts, longs, rationals, or ASCII strings.
This method, via the helper method readTiffIFD, locates and reads all
the tag values. It stores values of interest to OME into the OME
database.

TIFF files carry pixel data in one or more sections called strips. Each
strip contains an integral number of consequetive image I<rows>. Each
row contains one image width number of pixels. This method reads
the rows from the strips, and assembles them into planes in the 5D OME
image. Each input file contains the pixels for one plane.

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
	$file->open('r');
	my $tag0 =  readTiffIFD($file, 0);
	$file->close();
	
	my $filename = $file->getFilename();

    my $params = $self->{params};
    my $xref = $params->{xml_hash};
    
    $params->fref($file);
    $params->oname($filename);
    $params->endian($tag0->{__Endian});
    
	$xref->{ $file }->{'Image.SizeX'} = $tag0->{TAGS->{ImageWidth}}->[0];
	$xref->{ $file }->{'Image.SizeY'} = $tag0->{TAGS->{ImageLength}}->[0];
	$xref->{ $file }->{'Data.BitsPerPixel'} = $tag0->{TAGS->{BitsPerSample}}->[0];
	$params->byte_size( $self->__bitsPerPixel2bytesPerPixel($xref->{ $file}->{'Data.BitsPerPixel'}));
	
	# for rgb tiffs, each single image gives three channels
	if ($tag0->{TAGS->{PhotometricInterpretation}}->[0] == PHOTOMETRIC->{RGB}){
		$xref->{ $file }->{'Image.NumWaves'} = 3;
	}
	
	my $basename = pop @$groupList;
	my $image = ($self->{super})->__newImage($basename);
	$self->{image} = $image;

	# pack together & store info in input file
	my @finfo;
	$self->__storeOneFileInfo(\@finfo, $file, $params, $image,
				  0, $xref->{ $file }->{'Image.SizeX'}-1,
				  0, $xref->{ $file }->{'Image.SizeY'}-1,
				  0, $xref->{ $file }->{'Image.SizeZ'}-1,
				  0, $xref->{ $file }->{'Image.NumWaves'}-1,
				  0, $xref->{ $file }->{'Image.NumTimes'}-1,
				  "TIFF");

	my ($pixels, $pix) = 
	($self->{super})->__createRepositoryFile($image, 
						 $xref->{ $file }->{'Image.SizeX'},
						 $xref->{ $file }->{'Image.SizeY'},
						 $xref->{ $file }->{'Image.SizeZ'},
						 $xref->{ $file }->{'Image.NumWaves'},
						 $xref->{ $file }->{'Image.NumTimes'},
						 $xref->{ $file }->{'Data.BitsPerPixel'});
	$self->{pixels} = $pixels;
	
	my $maxZ = $xref->{ $file }->{'Image.SizeZ'};
	my $maxT = $xref->{ $file }->{'Image.NumTimes'};
	my $maxC = $xref->{ $file }->{'Image.NumWaves'};
	my @channelInfo;
	
	# Do a check for RGB.  If it's RGB, each file has 3 channels.
	if ($tag0->{TAGS->{PhotometricInterpretation}}->[0] == PHOTOMETRIC->{RGB}) {
		foreach my $file (@$groupList) {
			eval
			{
				$pix->convertPlaneFromTIFF($file, 0, 0, 0);
			};
			die "RGB convertPlaneFromTIFF failed: $@\n" if $@;
			doSliceCallback($callback);
			for (my $i = 0; $i < 3; $i++) {
				push @channelInfo, {chnlNumber => $i,
					ExWave     => undef,
					EmWave     => undef,
					Fluor      => undef,
					NDfilter   => undef};
			}
		}

	# This isn't RGB, so import it normally.  The files are processed in this way because
	# of the sorting done in the getGroups method.
	} else {
		for (my $t = 0; $t < $maxT; $t++) {
			for (my $z = 0; $z < $maxZ; $z++) {
    			for (my $c = 0; $c < $maxC; $c++) {
    				eval
    				{
						my $file = shift( @$groupList );
						$pix->convertPlaneFromTIFF($file, $z, $c, $t);						
					};
					
					push @channelInfo, {chnlNumber => $c,
						ExWave     => undef,
						EmWave     => undef,
						Fluor      => undef,
						NDfilter   => undef};
							
					die "convertPlaneFromTIFF failed: $@\n" if $@;
					doSliceCallback($callback);
				}
			}
		}
	}
	OME::Tasks::PixelsManager->finishPixels( $pix, $pixels );
	
	$self->__storeInputFileInfo($session,\@finfo);
	
	# Store info about each input channel (wavelength)
	if ($tag0->{TAGS->{PhotometricInterpretation}}->[0] eq PHOTOMETRIC->{RGB}) {
		$self-> __storeChannelInfoRGB ($session, scalar(@$groupList)*3, @channelInfo);
		$self-> __storeDisplayOptions ($session, {min => 0, max => 2**$xref->{ $file }->{'Data.BitsPerPixel'}-1});
	} else {
		$self-> __storeChannelInfo ($session, scalar(@$groupList), @channelInfo);
		$self-> __storeDisplayOptions ($session);
	}
	return $image;
}

sub getSHA1 {
    my $self = shift;
    my $grp = shift;

    my $fn = $grp->[0];
    my $sha1 = $fn->getSHA1();

    return $sha1;
}

sub cleanup {
	# clear out the TIFF tag cache
	OME::ImportEngine::TIFFUtils::cleanup();
}

=head1 Authors

Brian S. Hughes
Arpun Nagaraja

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut

1;







