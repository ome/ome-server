# OME/ImportExport/InsertFiles.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  Josiah Johnston <siah@nih.gov>
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

package OME::ImportExport::InsertFiles;


=pod

=head1 NAME

OME::ImportExport::InsertFiles - Package for extracting files from the ome file format

=head1 SYNOPSIS


=head1 DESCRIPTION

This package does two things: embeds files (i.e. Pixel dump from repository file)
into an OME xml document and writes the document out to file.

=cut


use strict;
use XML::LibXML;
use OME::LSID;

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
#	$file - path to output file
# 	$doc  - the DOM to write out
# optional parameters
#	$compression - the compression to use to compress the pixels
# 	$BigEndian   - 'true' | 'false' - specifies where the pixels should be inserted as bigEndian or not
#
sub exportFile {
	# parameters
	my $self        = shift;
	my $file        = shift;
	my $doc         = shift;
	my $compression = shift || 'zlib'; # default compression is zlib
	my $BigEndian   = shift || 'true';

	# resources
	my $session       = $self->{session};
	my $factory       = $session->Factory();
	my $debug         = $self->{debug};
	my $configuration = $session->Configuration();
	my $parser        = $self->{_parser};
	my $LSIDresolver  = OME::LSID->new( session => $session );
	

	my $executeInsertBinData = undef; # a flag to stuff the Pixels in the XML file
	my $root   = $doc->getDocumentElement();
	
	#######################################################################
	# Process the Pixels:
	# 	rewrite <Pixels> to OME format & add command flags
	# 	yank <Pixels> out of <CAs> and put in <Image>
	#
	foreach my $imageXML( $root->getElementsByTagNameNS( $OMENS, "Image" ) ) {

		# getElementsByTagNameNS returns the CustomAttributes under Image and Feature
		# the OME schema dictates that CustomAttributes be the last tag under Image.
		# The last element of the returned list will be either Image's CA or
		# the CA of the the last feature in Image.
		my $imageAndFeatureCAs = $imageXML->getElementsByTagNameNS( $OMENS, "CustomAttributes" );
		my $caXML = pop( @$imageAndFeatureCAs );
		
		if (defined $caXML && $caXML->parentNode()->tagName() eq 'Image' ) {
		foreach my $pixelsXML( $caXML->getElementsByTagNameNS( $OMENS, "Pixels" ) ) {

			# set up new <Bin:External>
			my $repository  = $LSIDresolver->getObject( $pixelsXML->getAttribute( "Repository" ) )
				or die "Could not resolve repository! (LSID = '".$pixelsXML->getAttribute( "Repository" )."')\n";
			my $href = $repository->Path().'/'.$pixelsXML->getAttribute("Path");
			$href =~ s/\/\//\//g; # strip out double slashes ('//')
			my $externalXML = $doc->createElementNS( $BinNS, "External" );
			$externalXML->setAttribute( "href", $href );
			$externalXML->setAttribute( "Compression", $compression ) if $compression;
			$pixelsXML->appendChild( $externalXML );


			$pixelsXML->removeAttribute( "Path" );
			$pixelsXML->removeAttribute( "FileSHA1" );
			$pixelsXML->removeAttribute( "Repository" );
			$pixelsXML->removeAttribute( "BitsPerPixel" );

			$pixelsXML->setAttribute( "DimensionOrder", "XYZCT" );
			$pixelsXML->setAttribute( "BigEndian", $BigEndian );

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
	#
	# END 'Process the Pixels'
	#
	#######################################################################
		
	# write to tmp file & send through /OME/bin/insertBinData
	if( $executeInsertBinData ) {
		my $tmpFile = $session->getTemporaryFilename( 'InsertFiles', 'ome' )
			or die "Could not get a Temporary File\n";
		$doc->toFile( $tmpFile )
			or die "Could not write to tmp file '$tmpFile'\n";
		my $cmd = $session->Configuration()->bin_dir()."/insertBinData $tmpFile > $file";
		die "When exporting, problems executing '$cmd'"
			unless system( "$cmd" ) == 0;
		die "Could not unlink temporary file '$tmpFile'\n"
			unless unlink ($tmpFile) eq 1;
	} else {
		$doc->toFile( $file );
	}
	
	return $doc;
}
#
# END sub resolveFiles
#
###############################################################################


# this function nabbed from OME::ImportExport::Importer
# i don't know if that package is stable and i don't want to introduce a new
# dependency to an unstable package.
sub getSha1 {
    my $file = shift;
    my $cmd = 'openssl sha1 '. $file .' |';
    my $sh;
    my $sha1;

    open (STDOUT_PIPE,$cmd);
    chomp ($sh = <STDOUT_PIPE>);
    $sh =~ m/^.+= +([a-fA-F0-9]*)$/;
    $sha1 = $1;
    close (STDOUT_PIPE);

    return $sha1;
}


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=cut


1;
