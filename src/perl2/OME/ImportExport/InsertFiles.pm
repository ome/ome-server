# OME/ImportExport/InsertFiles.pm

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


package OME::ImportExport::InsertFiles;


=pod

=head1 NAME

OME::ImportExport::InsertFiles - Package for inserting files (i.e. Pixel data) 
into the ome file format. It is the last thing run in the export process if
data insertion is to occur.

=head1 SYNOPSIS


=head1 DESCRIPTION

This package does two things: embeds files (i.e. Pixel dump from repository file)
into an OME xml document and writes the document out to file.

=cut


use strict;
use XML::LibXML;
use OME::Tasks::LSIDManager;

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
	my @requiredParams = ('session');
	my @knownParams    = ( @requiredParams, '_parser', 'debug' );
	
	foreach (@requiredParams) {
		die ref ($class) . "->new called without required parameter '$_'"
			unless exists $params{$_}
	}

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
# exportFile
# parameters:
#	$filename - path to output file
# 	$doc  - the DOM to write out
# optional parameters
#
sub exportFile {
	# parameters
	my $self        = shift;
	my $filename        = shift;
	my $doc         = shift;

	# resources
	my $session       = $self->{session};
	my $factory       = $session->Factory();
	my $configuration = $session->Configuration();
	my $parser        = $self->{_parser};

	my $executeInsertBinData = undef; # a flag to stuff the Pixels in the XML file
	my $root   = $doc->getDocumentElement();
	
	# Process the Pixels:
	foreach my $imageXML( $root->getElementsByTagNameNS( $OMENS, "Image" ) ) {

		# getElementsByTagNameNS returns the CustomAttributes under Image and Feature
		# the OME schema dictates that CustomAttributes be the last tag under Image.
		# The last element of the returned list will be either Image's CA or
		# the CA of the the last feature in Image.
		my $imageAndFeatureCAs = $imageXML->getElementsByTagNameNS( $OMENS, "CustomAttributes" );
		my $caXML = pop( @$imageAndFeatureCAs );
		
		if (defined $caXML && $caXML->parentNode()->tagName() eq 'Image' ) {
		foreach my $pixelsXML( $caXML->getElementsByTagNameNS( $OMENS, "Pixels" ) ) {
			my $type = $pixelsXML->getAttribute( "PixelType" );
			if( $type =~ m/^u/ ) {
				$pixelsXML->setAttribute( "PixelType", ucfirst( $type ) );
			}
			$caXML->removeChild( $pixelsXML );
			my @features = $imageXML->getElementsByTagNameNS( $OMENS, "Feature" );
			if( scalar @features > 0) {
				$imageXML->insertBefore( $pixelsXML, $features[0] );
			} else {
				$imageXML->insertBefore( $pixelsXML, $caXML );
			}
			
			$executeInsertBinData = 1;
		
		} }
	} 
		
	# pack in the binary pixel data
	if( $executeInsertBinData ) {
		# this has side effect of activating OME::Image::Server
		$session->findRepository();
		
		my $tmpFile = $session->getTemporaryFilename( 'InsertFiles', 'ome' )
			or die "Could not get a Temporary File\n";
		$doc->toFile( $tmpFile )
			or die "Could not write to tmp file '$tmpFile'\n";
		my $huge_xml_string = OME::Image::Server->exportOMEFile( $tmpFile );
		open( XML_OUT, "> $filename" ) or die "Couldn't open $filename";
		print XML_OUT $huge_xml_string;
		close XML_OUT;
		
		$session->finishTemporaryFile( $tmpFile );
	} else {
		$doc->toFile( $filename );
	}
	
}

=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=cut


1;
