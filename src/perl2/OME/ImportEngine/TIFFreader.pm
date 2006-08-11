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
use Log::Agent;
use OME::ImportEngine::TIFFUtils;
use base qw(OME::ImportEngine::AbstractFormat);

use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use Carp;
use Data::Dumper;
=head2 Patterns Defining Groups

All the files in a TIFF file group will have the same filename pattern. 
Each filename will have a common base, and a variable part that identifies 
the instance of a group variable that the file represents. For instance,
a TIFF group that has images of the same plate well taken at 2 different
illumination wavelengths could have files named "plate4_well54_w1.tiff"
and "plate4_well54_w2.tiff".

To group related files together, a call to getRegexGroups() in the superclass
is used, followed by sorting and verification that files are indeed tiffs.

=cut

=head1 METHODS

The following public methods are available:



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
	my ($filename,$file);
	my %TIFFs;
	
	# ignore any non-tiff files.
	while ( ($filename,$file) = each %$fref ) {
		$TIFFs{$filename} = $file if defined(verifyTiff($file));
	}

    # Group files with recognized patterns together
    # Sort them by Z's, channels, then timepoints
    my ($groups, $infoHash) = $self->getRegexGroups(\%TIFFs);

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
					delete $TIFFs{ $filename };
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
    
    # Now look at the rest of the files in the list to see if you have any other tiffs.
    foreach $file ( values %TIFFs ) {    	
    	
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
		delete $TIFFs{ $filename };
    }
	
    return \@outlist;
}


=head2 importGroup

    my $image = $importer->importGroup($groupHash)
    $groupHash contains:
    	Files => an array reference to a list of file objects
    	BaseName => a string to use as the base name for this group of files.

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
    my ($self, $group, $callback) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    
    my $groupList = $group->{Files};
    
    my $file = $groupList->[0];
	$file->open('r');
	my $tag0 =  readTiffIFD($file, 0);
	$file->close();
	
	my $filename = $file->getFilename();
    
	my $sizeX = $tag0->{TAGS->{ImageWidth}}->[0];
	my $sizeY = $tag0->{TAGS->{ImageLength}}->[0];
	my $sizeZ = $group->{nZfiles};
	my $sizeC = $group->{nCfiles};
	my $sizeT = $group->{nTfiles};
	my $bpp = $tag0->{TAGS->{BitsPerSample}}->[0];

	
	# for rgb tiffs, each single image gives three channels
	my $isRGB;
	if ($tag0->{TAGS->{PhotometricInterpretation}}->[0] == PHOTOMETRIC->{RGB}){
		$sizeC *= 3;
		$isRGB = 1;
	}

	my $basename = $group->{BaseName};
	my $image = $self->newImage($basename);
	$self->{image} = $image;

	my ($pixels, $pix) = $self->createRepositoryFile($image, 
						 $sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp);
	
	my @channelInfo;

	# The files are processed in this way because
	# of the sorting done in the getGroups method.
	for (my $z = 0; $z < $sizeZ; $z++) {
		for (my $c = 0; $c < $sizeC; $c++) {
			for (my $t = 0; $t < $sizeT; $t++) {
				eval {
					$file = shift( @$groupList );
					logdbg "debug",  "shifted ".$file->getFilename();
					$pix->convertPlaneFromTIFF($file, $z, $c, $t);						
				};
				die "convertPlaneFromTIFF failed: $@\n" if $@;
				# If it's RGB, each file has 3 channels.
				my $c1;
				if ($isRGB) {
					$c1 = $c+2;
				} else {
					$c1 = $c;
				}
				$self->doSliceCallback($callback);
				$self->storeOneFileInfo($file, $image,
					0, $sizeX-1,
					0, $sizeY-1,
					$z, $z,
					$c, $c1,
					$t, $t,
					"TIFF");
				$c = $c1; # make sure to advance c properly if its RGB
			}
		}
	}

	for (my $c = 0; $c < $sizeC; $c++) {
		push @channelInfo, {chnlNumber => $c,
							ExWave     => undef,
							EmWave     => undef,
							Fluor      => undef,
							NDfilter   => undef};
	}
	OME::Tasks::PixelsManager->finishPixels( $pix, $pixels );
		
	# Store info about each input channel (wavelength)
	if ($isRGB) {
		$self->storeChannelInfoRGB($image, @channelInfo);
		my %display_options = map{ 
			$_ => {
				BlackLevel => 0, 
				WhiteLevel => (2**$bpp)-1,
			}
		} ( 0..($sizeC-1) );
		$self->storeDisplayOptions ($image, \%display_options);
	} else {
		$self->storeChannelInfo ($image, @channelInfo);
		$self->storeDisplayOptions ($image);
	}
	return $image;
}

sub getSHA1 {
    my $self = shift;
    my $grp = shift;

    my $file = $grp->{Files}->[0];
    my $sha1 = $file->getSHA1();

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







