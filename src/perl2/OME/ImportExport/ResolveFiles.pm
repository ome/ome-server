# OME/Tasks/ResolveFiles.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
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

package OME::Tasks::ResolveFiles;


=pod

=head1 NAME

OME::Tasks::ResolveFiles - Package for extracting files from the ome file format

=head1 SYNOPSIS


=head1 DESCRIPTION

OME::Tasks::ResolveFiles purpose is to resolve all files embedded in an ome 
document and update xml tags accordingly. It returns a DOM representation of 
the document.

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
# importFile
# parameters:
#	$path - path to file
#
sub importFile() {
	# parameters
	my $self       = shift;
	my $inputFile  = shift;

	# resources
	my $session       = $self->{session};
	my $factory       = $session->Factory();
	my $debug         = $self->{debug};
	my $configuration = $session->Configuration();
	my $parser        = $self->{_parser};
	my $LSIDresolver  = OME::LSID->new( session => $session );

	# storage
	my @cdataFiles;
	my %fileInfo;
	my $tmpDir;

	###########################################################################
	#
	# Extract embedded files, decrease the size of the xml document
	#
	###########################################################################
		# call extractBinData
		#
		my $executionPath   = $configuration->bin_dir() . '/extractBinData';
		$tmpDir             = $session->getScratchDir('ResolveFiles');
		my ($pixelDir, $repository);
		# eval because if this is running in bootstrap, there is no Repository
		# attributes or even a Repository ST
		eval {
			my @repositories    = $factory->findAttributes( "Repository" );
			$repository         = $repositories[0];
			$pixelDir           = $session->getScratchDirRepository(repository => $repository, progName => 'ResolveFiles');
		} or $pixelDir = $tmpDir;
		
		my $fh;
		open( $fh, "$executionPath $pixelDir $tmpDir $inputFile |" );
		
		# parse extractBinData output
		my $doc  = $parser->parse_fh( $fh );
		close( $fh );
		my $root = $doc->getDocumentElement();
		
		# 2do
		# resolve external links
=pod
# this is old code that needs to be reworked. the downloader part mostly works, so i didn't want to scrap the whole thing
		my @externalsXML = $root->getElementsByTagNameNS( $BinNS, "External" );
		my $extCount = 0;
		foreach my $externalXML (@externalsXML ) {
			if( $externalXML->getAttribute( "SHA1" ) ) {
				# Save external reference to local file
				# This code nabbed from perlCheck.pl
				my $localPath = $tmpDir."/".$extCount++.".ext";
				my $href = $externalXML->getAttribute( "href" );
				my $wget = 'curl';
				my $error = `$wget -V 2>&1 1>/dev/null`;
				if (not $error) {
					print "\nDownloading $href using $wget...\n";
					$error = system ("$wget --output $localPath -O $href 2>&1 1>/dev/null");
				} else {
					$wget = 'wget';
					$error = `$wget -V 2>&1 1>/dev/null`;
					if (not $error) {
						print "\nDownloading $href using $wget...\n";
						$error = system ("$wget -nv $href 2>&1 1>/dev/null -O $localPath");
					}
				}
				die "Couldn't download $href" if $error != 0;
				
				# check calculated SHA1 against stated SHA1
				my $statedSha1 = $externalXML->getAttribute( "SHA1" );
				my $sha1 = getSha1( $localPath );
				die "SHA1 (a digital signature) for the file specified in this element:\n".
					$externalXML->toString()." does not match with the SHA1 calculated from that file.\n".
					"Stated SHA1:     ".$statedSha1."\n".
					"Calculated SHA1: ".$sha1."\n"
					unless $sha1 eq $statedSha1;
				
				# update <External>'s href to the local file.
				$externalXML->setAttribute( "href", $localPath );
			} else {
			# Handle <External>'s that used to be <BinData>'s
				my $originalPath = $externalXML->getAttribute( "href" );
				$externalXML->setAttribute( "href", $fileInfo{$originalPath}->{path} );
				$externalXML->setAttribute( "SHA1", $fileInfo{$originalPath}->{sha1} );
			}
		}
=cut
		#
		#######################################################################
		# Process the Pixels:
		# rewrite <Pixels> to ST format
		#
		# if there is no $repository, then there can be no image importing.
		# the only valid case that has no $repository is during bootstrap
		if( $repository ) {
			foreach my $imageXML( $root->getElementsByTagNameNS( $OMENS, "Image" ) ) {
				my $ca = $imageXML->getElementsByTagNameNS( $OMENS, "CustomAttributes" );
				foreach my $pixelsXML( $imageXML->getElementsByTagNameNS( $OMENS, "Pixels" ) ) {
					my $externalXML = @{ $pixelsXML->getElementsByTagNameNS( $BinNS, "External" ) }[0];
					my $href = $externalXML->getAttribute( "href" );
					my $sha1 = getSha1( $href );
					system( "mv $href ". $repository->Path().$sha1 ) eq 0
						or die "Could not move pixel file to repository.\n";
	
					$href = $sha1;
					$pixelsXML->setAttribute( "Path", $href );
					$pixelsXML->setAttribute( "FileSHA1", $sha1 );
	
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
	
					$pixelsXML->removeChild( $externalXML );
					if( ! $ca ) {
						$ca = $doc->createElementNS( $OMENS, "CustomAttributes" )	
							or die "Could not make <CustomAttributes>!";
						$imageXML->appendChild( $ca );
					}
					
					#strip out comments inside of <Pixels>
					foreach( $pixelsXML->childNodes() ) {
						$pixelsXML->removeChild( $_ );
					}
					
					$imageXML->removeChild( $pixelsXML );
					$ca->appendChild( $pixelsXML );
					
				}
			}
		}
		#
		# END 'Process the Pixels'
		#
		#######################################################################
		
	# cleanup
	if($pixelDir ne $tmpDir) {
		die "Couldn't remove directory $_: $!\n" unless rmdir ($pixelDir);
	}
	die "Couldn't remove directory $_: $!\n" unless rmdir ($tmpDir);

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
