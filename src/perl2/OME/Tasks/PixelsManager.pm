# OME/Tasks/PixelsManager.pm
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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------

package OME::Tasks::PixelsManager;

=head1 NAME

OME::Tasks::PixelsManager

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Image;
use OME::ModuleExecution;
use Log::Agent;

use OME::File;
use OME::Image::Pixels;
use OME::Image::LocalPixels;
use OME::Image::Server::Pixels;

use File::Spec;

# $PIXEL_TYPES{$bytesPerPixel}{$isSigned}{$isFloat}
our %PIXEL_TYPES;

$PIXEL_TYPES{1}{1}{0} = 'int8';
$PIXEL_TYPES{1}{0}{0} = 'uint8';

$PIXEL_TYPES{2}{1}{0} = 'int16';
$PIXEL_TYPES{2}{0}{0} = 'uint16';

# "unsigned float" doesn't exist but we map that to float anyway
$PIXEL_TYPES{4}{1}{1} = 'float';
$PIXEL_TYPES{4}{0}{1} = 'float';
$PIXEL_TYPES{4}{1}{0} = 'int32';
$PIXEL_TYPES{4}{0}{0} = 'uint32';

our %PIXEL_INFO;

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides methods to accomplish common Pixel tasks.

=head1 METHODS

=head2 createOriginalFileAttribute

=cut

sub createOriginalFileAttribute {
    my $proto = shift;
    my ($file,$format,$mex) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    if (UNIVERSAL::isa($file,'OME::LocalFile')) {
        my $filename = $file->getFilename();

        # See if we've already created an attribute for this file with
        # the same MEX.

        my $attr = $factory->
          findAttribute('OriginalFile',
                        {
                         module_execution => $mex,
                         Repository       => undef,
                         Path             => $filename,
                        });
        return $attr if defined $attr;

        # Nope, create a new one.

        $attr = $factory->
          newAttribute('OriginalFile',undef,$mex,
                       {
                        Repository => undef,
                        Path       => $filename,
                        FileID     => undef,
                        SHA1       => $file->getSHA1(),
                        Format     => $format,
                       });
        die "Could not create OriginalFile attribute"
          unless defined $attr;
        return $attr;
    } elsif (UNIVERSAL::isa($file,'OME::Image::Server::File')) {
        my $repository = $session->findRepository();
        my $fileID = $file->getFileID();

        # See if we've already created an attribute for this file with
        # the same MEX.

        my $attr = $factory->
          findAttribute('OriginalFile',
                        {
                         module_execution => $mex,
                         Repository       => $repository,
                         FileID           => $fileID,
                        });
        return $attr if defined $attr;

        # Nope, create a new one.

        $attr = $factory->
          newAttribute('OriginalFile',undef,$mex,
                       {
                        Repository => $repository,
                        Path       => $file->getFilename(),
                        FileID     => $file->getFileID(),
                        SHA1       => $file->getSHA1(),
                        Format     => $format,
                       });
        die "Could not create OriginalFile attribute"
          unless defined $attr;
        return $attr;
    }
}

=head2 loadOriginalFile

=cut

sub loadOriginalFile {
    my $proto = shift;
    my ($attr) = @_;
    my $repository = $attr->Repository();

    if ($repository->IsLocal()) {
        return OME::LocalFile->new($attr->Path());
    } else {
        OME::Session->instance()->activateRepository($repository);
        return OME::Image::Server::File->new($attr->FileID());
    }
}

=head2 getPixelType

Usage

	my $pixelType = OME::Tasks::PixelsManager->getPixelType(
		$bytesPerPixel,$isSigned,$isFloat);

retrieves the name of a Pixel type from a description.
=cut
sub getPixelType {
	my ($proto, $bpp, $signed, $float) = @_;
	return $PIXEL_TYPES{$bpp}{$signed}{$float};
}

=head2 getPixelTypeInfo

Usage
	my ($bytesPerPixel, $isSigned, $isFloat) = 
		OME::Tasks::PixelsManager->getPixelTypeInfo( $pixels->PixelType() );

=cut

sub getPixelTypeInfo {
	my ($proto,$pixelType) = @_;
	$proto->__populatePixelInfo() unless( %PIXEL_INFO );
	$pixelType = lc( $pixelType );
	die "'$pixelType' is not a recognized Pixel type"
		unless exists $PIXEL_INFO{$pixelType};
	return @{ $PIXEL_INFO{$pixelType} };
}

=head2 createPixels

Usage:
    my ($pixels_data, $pixels_attr) = OME::Tasks::PixelsManager->
      createPixels($image,$module_execution, {
        SizeX        => $sizeX,
        SizeY        => $sizeY,
        SizeZ        => $sizeZ,
        SizeC        => $sizeC,
        SizeT        => $sizeT,
        PixelType    => $pixelType
      } );

Creates Object representations of the pixels data (see
OME::Image::Pixels) and the pixels attribute (see
OME::SemanticTypes::Superclass and Pixels Semantic Type Definition).

OME::Tasks::PixelsManager->finishPixels($pixels_data, $pixels_attr) will need to be
called after the data has been written.

=cut
sub createPixels {
    my $proto = shift;
    my $repository = OME::Session->instance()->findRepository();

    return $repository->IsLocal()?
      $proto->localCreatePixels($repository,@_):
      $proto->serverCreatePixels($repository,@_);
}

=head2 finishPixels

Usage:
    OME::Tasks::PixelsManager->finishPixels($pixels_data, $pixels_attr);

Finalizes the pixels data, sets the FileSHA1 of the pixels attribute,
and sets the thumbnail.

=cut
sub finishPixels {
    my ($proto, $pixels_data, $pixels_attr) = @_;

	$pixels_attr->ImageServerID ($pixels_data->finishPixels());
	$pixels_attr->FileSHA1( $pixels_data->getSHA1() );
	$pixels_attr->storeObject();
}

=head2 loadPixels

	# load the pixels data object (see OME::Image::Pixels for interface)
	my $pixels_data = OME::Tasks::PixelsManager->loadPixels( $pixels_attr );

=cut
sub loadPixels {
    my $proto = shift;
    my ($attr) = @_;
    die "loadPixels needs a Pixels attribute"
      unless UNIVERSAL::isa($attr,'OME::SemanticType::Superclass')
        && $attr->verifyType('Pixels');

    my $repository = $attr->Repository();
    return $repository->IsLocal()?
      $proto->localLoadPixels($attr):
      $proto->serverLoadPixels($attr);
}


=head2 saveThumb

Usage: 
	# set the image thumbnail to the default display options
	OME::Tasks::PixelsManager->saveThumb( $pixels_attr );

	# set the image thumbnail to the provided DisplayOptions attribute
	OME::Tasks::PixelsManager->saveThumb( $pixels_attr, $displayOptions );

=cut
sub saveThumb {
    my ($proto, $pixels_attr, $display_options) = @_;
    my $image = $pixels_attr->image();
    my $pixels_data = $proto->loadPixels( $pixels_attr );

 	# save default display options to omeis as thumbnail settings.
	$display_options = $proto->getDisplayOptions($pixels_attr)
		unless $display_options;
	$pixels_data->setThumb( $display_options );
}


=head2 getThumbURL

	# retrieve the URL for the thumbnail of the specified pixels attribute
	my $thumbnailURL = OME::Tasks::PixelsManager->getThumbURL($pixels);

	# retrieve the URL for the thumbnail of the specified pixels id
	my $thumbnailURL = OME::Tasks::PixelsManager->getThumbURL($pixelsID);

=cut
sub getThumbURL{
	my $self    = shift;
	my $session = OME::Session->instance();
	my $pixels  = shift;
	# load from id unless it's already loaded.
	( $pixels = $session->Factory()->loadAttribute( "Pixels", $pixels )
		or die "Couldn't load Pixels ID = $pixels" )
		unless ref( $pixels );
	my $rep     = $pixels->Repository();
	return undef if($rep->IsLocal());
	return $rep->ImageServerURL()."?Method=GetThumb&PixelsID=".$pixels->ImageServerID();
}


=head2 getDisplayOptions

Usage: 
	my $displayOptions = OME::Tasks::PixelsManager->getDisplayOptions( $pixels_attr );
	will load displayOptions

=cut
sub getDisplayOptions {
    my ($proto, $pixels_attr) = @_;
    my $session = OME::Session->instance();
    
	# Try to load display options
	my $displayOptions = $session->Factory()->findAttribute( 'DisplayOptions', 
		{Pixels => $pixels_attr } );
	return $displayOptions;
}

sub localCreatePixels {
    my $proto = shift;
    my ($repository,$image,$mex,$data_hash) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    # Find a local repository to store this pixels file in.
    $repository = $session->findLocalRepository()
      unless defined $repository;
    my $path = $repository->Path();

    # Find a unique filename for the new pixels
    my $time = time();
    my $nonce = 0;
    my $filename = "${time}-${nonce}-$$.ori";
    my $pathname = File::Spec->catfile($path,$filename);
    while (-e $pathname) {
        $nonce++;
        $filename = "${time}-${nonce}-$$.ori";
        $pathname = File::Spec->catfile($path,$filename);
    }

    my $pixels = OME::Image::LocalPixels->new(
        $pathname,
        $data_hash->{SizeX},
      	$data_hash->{SizeY},
      	$data_hash->{SizeZ},
      	$data_hash->{SizeC},
      	$data_hash->{SizeT},
      	$proto->getPixelTypeInfo( $data_hash->{PixelType} ),
      	OME->BIG_ENDIAN());

	$data_hash->{ Repository } = $repository;
	$data_hash->{ Path }       = $filename;
    my $attr = $factory->
      newAttribute('Pixels',$image,$mex,$data_hash);

    return ($pixels,$attr);
}

sub localLoadPixels {
    my $proto = shift;
    my ($attr) = @_;

    my $repository = $attr->Repository();
    my $repPath = $repository->Path();
    my $pixPath = $attr->Path();

    my $pathname = File::Spec->catfile($repPath,$pixPath);
    return OME::Image::LocalPixels->open($pathname);
}

sub serverCreatePixels {
    my $proto = shift;
    my ($repository,$image,$mex,$data_hash) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    $repository = $session->findRepository()
      unless defined $repository;

    my $pixels = OME::Image::Server::Pixels->new(
      	$data_hash->{SizeX},
      	$data_hash->{SizeY},
      	$data_hash->{SizeZ},
      	$data_hash->{SizeC},
      	$data_hash->{SizeT},
      	$proto->getPixelTypeInfo( $data_hash->{PixelType} )
    );

	$data_hash->{ Repository }    = $repository;
	$data_hash->{ ImageServerID } = $pixels->getPixelsID();
    my $attr = $factory->
      newAttribute('Pixels',$image,$mex,$data_hash);
    return ($pixels,$attr);
}

sub serverLoadPixels {
    my $proto = shift;
    my ($attr) = @_;

    my $repository = $attr->Repository();
    OME::Session->instance()->activateRepository ($repository);
    return OME::Image::Server::Pixels->open($attr->ImageServerID());
}

sub __populatePixelInfo {
	foreach my $bytesPerPixel (keys %PIXEL_TYPES) {
		foreach my $isSigned (keys %{ $PIXEL_TYPES{$bytesPerPixel} }) {
			foreach my $isFloat (keys %{ $PIXEL_TYPES{$bytesPerPixel}{$isSigned} }) {
				$PIXEL_INFO{$PIXEL_TYPES{$bytesPerPixel}{$isSigned}{$isFloat}} = 
					[ $bytesPerPixel, $isSigned, $isFloat ];
			}	
		}	
	}	
}

sub __defaultBlackWhiteLevels {
	my ( $statsHash, $channelIndex, $theT ) = @_;
	my ( $blackLevel, $whiteLevel );
	
	$blackLevel = int( 0.5 + $statsHash->{ $channelIndex }{ $theT }->{Geomean} );
	$blackLevel = $statsHash->{ $channelIndex }{ $theT }->{Minimum}
		if $blackLevel < $statsHash->{ $channelIndex }{ $theT }->{Minimum};
	$whiteLevel = int( 0.5 + $statsHash->{ $channelIndex }{ $theT }->{Geomean} + 4*$statsHash->{ $channelIndex }{ $theT }->{Geosigma} );
	$whiteLevel = $statsHash->{ $channelIndex }{ $theT }->{Maximum}
		if $whiteLevel > $statsHash->{ $channelIndex }{ $theT }->{Maximum};
	return ( $blackLevel, $whiteLevel );
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut



