# OME/ImportExport/ResolveFiles.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::ImportExport::ResolveFiles;


=pod

=head1 NAME

OME::ImportExport::ResolveFiles - Package for resolving files from the OME file format

=head1 SYNOPSIS

=head1 DESCRIPTION

This package does two things: resolves all files embedded or references in an
OME xml document and parses the file. It returns a DOM representation of the
document.

=cut


use strict;
use XML::LibXML;
use OME::Tasks::LSIDManager;
use OME::Image::Server;
use OME::Session;
use Log::Agent;

# package constants
my $BinNS = "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd";
my $OMENS = "http://www.openmicroscopy.org/XMLschemas/OME/FC/ome.xsd";
my %pixelTypeConversion = ( bit => 1, int8 => 8, int16 => 16, int32 => 32, Uint8 => 8, Uint16 => 16, Uint32 => 32, float => 32, 'double' => 64, complex => 64, 'double-complex' => 128 );

sub new {
	# parameters
	my $proto  = shift;
	my %params = @_;
	
	# resources
	my $class          = ref($proto) || $proto;
	$params{debug}     = 0 unless exists $params{debug};
	my $debug          = $params{debug};
	my @knownParams    = ( '_parser', 'debug' );
	
	my %selfHash = map { $_ => $params{$_} } @knownParams;
	my $self = \%selfHash;
	
	# setup parser
	if (!defined $self->{_parser}) {
		my $parser = XML::LibXML->new();
		die "Cannot create XML parser"
		  unless defined $parser;
		
		$parser->validation(exists $params{ValidateXML}?
							$params{ValidateXML}: 0);
		$self->{_parser} = $parser;
	}

	# clean up & return
	bless($self,$class);
	return $self;
}


###############################################################################
#
# importFile
# parameters:
#	$path - path to file
#
sub importFile() {
	# parameters
	my ($self, $omeisFileID, $repository) = @_;

	# resources
	my $session       = OME::Session->instance();
	my $factory       = $session->Factory();
	my $parser        = $self->{_parser};
	my $LSIDresolver  = OME::Tasks::LSIDManager->new();

	# storage
	my @cdataFiles;
	my %fileInfo;

	my $xmlString = OME::Image::Server->importOMEfile( $omeisFileID );
	my $doc  = $parser->parse_string( $xmlString );
	my $root = $doc->getDocumentElement();
		
	foreach my $imageXML( $root->getElementsByTagNameNS( $OMENS, "Image" ) ) {
		my @caXML_list = $imageXML->getChildrenByTagNameNS( $OMENS, "CustomAttributes" );
		my $caXML = $caXML_list[0] if scalar @caXML_list > 0;
		if( ! $caXML ) {
			$caXML = $doc->createElementNS( $OMENS, "CustomAttributes" )	
				or die "Could not make <CustomAttributes>!";
			$imageXML->appendChild( $caXML );
		}

		foreach my $pixelsXML( $imageXML->getElementsByTagNameNS( $OMENS, "Pixels" ) ) {

			$pixelsXML->setAttribute( "SizeX", $imageXML->getAttribute( "SizeX" ) )
				unless $pixelsXML->getAttribute( "SizeX" );
			$pixelsXML->setAttribute( "SizeY", $imageXML->getAttribute( "SizeY" ) )
				unless $pixelsXML->getAttribute( "SizeY" );
			$pixelsXML->setAttribute( "SizeZ", $imageXML->getAttribute( "SizeZ" ) )
				unless $pixelsXML->getAttribute( "SizeZ" );
			$pixelsXML->setAttribute( "SizeC", $imageXML->getAttribute( "NumChannels" ) )
				unless $pixelsXML->getAttribute( "SizeC" );
			$pixelsXML->setAttribute( "SizeT", $imageXML->getAttribute( "NumTimes" ) )
				unless $pixelsXML->getAttribute( "SizeT" );

			die "When importing <Pixels>, Pixel type '".$pixelsXML->getAttribute("PixelType")."' was not recognized!\n"
				unless exists $pixelTypeConversion{ $pixelsXML->getAttribute("PixelType") };
			my $pixelSize = $pixelTypeConversion{ $pixelsXML->getAttribute("PixelType") };
			$pixelsXML->setAttribute( "BitsPerPixel", $pixelSize );
			
			$pixelsXML->setAttribute( "Repository", $LSIDresolver->getLSID( $repository ) );

			$pixelsXML->removeAttribute( "DimensionOrder" );
			$pixelsXML->removeAttribute( "BigEndian" );

			$imageXML->removeChild( $pixelsXML );
			$caXML->appendChild( $pixelsXML );
		}
	}

	return $doc;
}


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=cut


1;
