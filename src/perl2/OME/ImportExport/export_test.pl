#!/usr/bin/perl -w
#
# export_test.pl
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

=pod

=head1 NAME

export_test.pl - export an OME image to an image file (not the OME format)

=head1 SYNOPSIS

perl ExportTiff.pl -image_ids=1,2,3 -output_directory=[path]

        -image_ids or -i
                comma separated list of image ids to export. the default Pixels of each image will be exported.
        -output_directory or -o
                directory to output images.

=head1 DESCRIPTION

 This program was supposed to act as a test jig for the Exporter class.
 It used the same API for Exporter as the production OME(v1).
 But it didn't work at all. So Josiah <siah@nih.gov> rewrote it against
 the modern API. Now it exports OME images as a TIFF series. The naming
 convention of the series could stand improvement/customization. But it is:
 [imageName]-Z[theZ].C[theC].T[theT].tiff

=head1 AUTHOR

Brian S. Hughes
Josiah Johnston <siah@nih.gov>

=cut

use strict;
use OME::Image;
use OME::SessionManager;
use vars qw($VERSION);
$VERSION = 2.000_000;

#collect input
my ($param_imageIDs, $param_outputDirectory) = @ARGV;

#extract input
my @imageIDs;
if($param_imageIDs) {
	if ( $param_imageIDs =~ /(-i|-image_ids)=([\d,]+)/ ) {
		@imageIDs = split( ',', $2 ) ;
	} else {
		printUsage();
		die "Could not parse image ID argument '$param_imageIDs'\n";
	}
}
my $output_directory;
if( $param_outputDirectory ) {
	($output_directory = $param_outputDirectory) =~ s/(-o|-output_directory)=//;
	$output_directory .= '/' unless $output_directory =~ m/\/$/;
}

#verify input
if( scalar @imageIDs eq 0 ) {
	printUsage();
	die "\nNo imageIDs given\n";
}
if( not defined $output_directory ) {
	printUsage();
	die "\nNo Output directory given\n";
}

#login
my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

# OME::ImportExport::Exporter has heavy reliance on depricated code and logic.
# Also the architecture of the Exporter does not follow any models used by the rest of the code base.
# In all actuality, it is depricated until someone brings it up to speed.
# Anywho, this was the line that was supposed to do the work of the following loop.
# I renamed image_list to imageIDs because that is more descriptive. Also, $export_type
# was defined as 'TIFF'. These are the wrong parameters to Exporter->new(), but that's
# what I found. 
#use OME::ImportExport::Exporter;
#my $writer = OME::ImportExport::Exporter->new(\@image_list, $export_type);


#export images
foreach my $imageID (@imageIDs) {
	my $image = $factory->loadObject( "OME::Image", $imageID )
		or die "Could not load image with id ($imageID)";

	my $pixels = $image->DefaultPixels()
		or die "Could not load default pixels (image_id=$imageID)";
	my $pix = $image->GetPix($pixels);
	my ($sizeX, $sizeY) = ($pixels->SizeX(), $pixels->SizeY() );
	for(my $theZ = 0; $theZ < $pixels->SizeZ(); $theZ++) {
		for( my $theC = 0; $theC < $pixels->SizeC(); $theC++) {
			for( my $theT = 0; $theT < $pixels->SizeT(); $theT++) {
				my $path = $output_directory.$image->name()."-Z$theZ.C$theC.T$theT.tiff";
				
				# Plane2TIFF produces black images. I don't know what's up with that.
				# Till that problem is solved, Plane2TIFF8 will have to do.
				#my $nPixOut = $pix->Plane2TIFF ($theZ,$theC,$theT,$path);
				
				my $nPixOut = $pix->Plane2TIFF8 ($theZ,$theC,$theT,$path,1,0);
				die "Tried to write ".$sizeX*$sizeY." pixels to $path, actually wrote $nPixOut.\n"
					unless $sizeX*$sizeY eq $nPixOut;
			}
		}
	}
	undef $pix;
	undef $pixels;
}

sub printUsage {
	print "Usage is:\n\tperl ExportTiff.pl -image_ids=1,2,3 -output_directory=[path]\n\n";
	print "\t-image_ids or -i\n\t\tcomma separated list of image ids to export. default Pixels of each image will be exported.\n";
	print "\t-output_directory or -o\n\t\tdirectory to output images.\n";
}
