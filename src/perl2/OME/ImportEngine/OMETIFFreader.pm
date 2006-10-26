# OME/ImportEngine/OMETIFFreader.pm

#------------------------------------------------------------------------------
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
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# Written by:    Curtis Rueden <ctrueden@wisc.edu>
#
# Some sections based on code from Ilya Goldberg,
# Josiah Johnston, Brian Hughes and Arpun Nagaraja.
#
#------------------------------------------------------------------------------

# Notes from Ilya:
#
# 1.  Get an LSID for your repository (OMEIS):
#     $repository = $session->findRepository();
#     my $LSIDresolver = OME::Tasks::LSIDManager->new();
#     my $repositoryLSID = $LSIDresolver->getLSID($repository)
#     This should probably be done in getGroups() and stored as a class
#     variable.
#
# 2.  Manually create the pixels in OMEIS from your TIFF file
#     my $pixels = OME::Image::Server::Pixels- >new($sizeX,$sizeY,$sizeZ,
#       $sizeC,$sizeT,$bytesPerPixel,$isSigned,$isFloat);
#     $pixels->convertPlaneFromTIFF ($file,$z,$c,$t,$IFD);
#     ... This is all the standard stuff done by every importer.
#     $pixels->finishPixels();
#
# 3.  Extract your XML and parse it into a DOM
#     Parse the XML right from the string you get from the tiff tag if
#     possible.
#
# 4.  Apply the OME2OME-CA stylesheet the way its done in
#     OMEImport->importFile()
#     It's probably best to factor the stylesheet manipulation out of
#     OMEImport->importFile(), and have both importFile() and your importer
#     call this new method.
#     The method should accept a parsed OME-style DOM document and return a
#     transformed CA-style DOM document.
#
# 5.  Generate a Pixels CustomAttribute XML element (see the Pixels ST
#     declaration)
#
# 6.  Add the Pixels element to the XML you extracted from the tiff file (under
#     <Image> -> <CustomAttributes>).
#     Depending on how your Pixels are specified in your XML (if they are), you
#     will need to add the element or possibly edit the one that's already
#     there. You need to specify the FileSHA1, Repository and ImageServerID,
#     which you get from $pixels->getSHA1(), $repositoryLSID and
#     $pixels->getPixelsID(). You also have to make sure that all the other
#     elements defined for Pixels are filled in, which are self-explanatory.
# 7.  Call the OME XML DOM parser:
#     my $importedObjects =
#       $OMEimporter->processDOM($CA_doc->getDocumentElement(),
#       NoDuplicates           => 0,
#       IgnoreAlterTableErrors => 1);
# 8.  Proceed the same way that XMLreader does after calling
#     $OMEimporter->importFile();
#
# The reason you can't just call importFile() from your importer is that your
# XML file is not on the image server, and I don't think you want it there
# because the TIFF containing it is there already. Also you need to inject your
# linkage between the Image and its Pixels into the XML stage so that the rest
# of the XML parser can proceed unmodified.

package OME::ImportEngine::OMETIFFreader;

use strict;
use OME;
our $VERSION = $OME::VERSION;
use Carp;
use Log::Agent;

use OME::Image::Server;
use OME::ImportEngine::TIFFUtils;
use OME::Tasks::OMEImport;

use base qw(OME::ImportEngine::AbstractFormat);

# For a file to be OME-TIFF, it must:
#   1) be a TIFF file
#   2) have OME-XML embedded in the ImageDescription of the TIFF's first IFD
#
# For a file to be part of an OME-TIFF group, its Pixels ID must match those of
# the other OME-TIFF files in the group.
#
# Currently, only files with one Image element and one corresponding Pixels
# element are supported.
sub getGroups {
	my $self = shift;
	my $session = $self->Session();
	my $fhash = shift;
	my @inlist = values %$fhash;
	my @outlist;
	my $file;
  my $file_id;
	my $filename;

	# create XML parser
	my $parser = $self->{parser};
	if (not defined $parser) {
		$parser = XML::LibXML->new();
		die "Cannot create XML parser" unless defined $parser;
		$parser->validation(0);
		$self->{parser} = $parser;
	}

	# create XSLT stylesheet transformation
	my $stylesheet = $self->{stylesheet};
	if (not defined $stylesheet) {
		my $xslt = XML::LibXSLT->new();
		my $doc_path = $session->Configuration()->xml_dir()."/OME2OME-CA.xslt";
		my $style_doc = $parser->parse_file($doc_path);
		$stylesheet = $xslt->parse_stylesheet($style_doc);
		$self->{stylesheet} = $stylesheet;
	}

	# get an LSID for the repository
	my $repositoryLSID = $self->{repositoryLSID};
	if (not defined $repositoryLSID) {
		my $repository = $session->findRepository();
		my $LSIDresolver = OME::Tasks::LSIDManager->new();
		$repositoryLSID = $LSIDresolver->getLSID($repository);
		$self->{repositoryLSID} = $repositoryLSID;
	}

	my $groups;
	foreach $file (@inlist) {
		# ignore non-TIFF files
		next unless defined verifyTiff($file);

		# check for OME-XML in header
		$file->open('r');
		my $tags = readTiffIFD($file);
		$file->close();
		my $comment = $tags->{TAGS->{ImageDescription}}->[0];
		next unless defined $comment;

		# parse XML from comment
    my $doc;
    eval { $doc = $parser->parse_string($comment); };
		next unless defined $doc;

		# get OME/Image/Pixels element
		my $rootElement = $doc->documentElement();
		my $imageElement = ($rootElement->getChildrenByTagName('Image'))[0];
		my $pixelsElement = ($imageElement->getChildrenByTagName('Pixels'))[0];
		my @tiffData = $pixelsElement->getChildrenByTagName('TiffData');
		next unless @tiffData > 0;

		# get attributes of Pixels element
		my $dimOrder = $pixelsElement->getAttribute('DimensionOrder');
		next unless defined $dimOrder;
		my $pixelType = $pixelsElement->getAttribute('PixelType');
		next unless defined $pixelType;
		my $bigEndian = $pixelsElement->getAttribute('BigEndian');
		next unless defined $bigEndian;
		my $pixelsID = $pixelsElement->getAttribute('ID');
		next unless defined $pixelsID;
		my $sizeX = $pixelsElement->getAttribute('SizeX');
		next unless defined $sizeX;
		my $sizeY = $pixelsElement->getAttribute('SizeY');
		next unless defined $sizeY;
		my $sizeZ = $pixelsElement->getAttribute('SizeZ');
		next unless defined $sizeZ;
		my $sizeC = $pixelsElement->getAttribute('SizeC');
		next unless defined $sizeC;
		my $sizeT = $pixelsElement->getAttribute('SizeT');
		next unless defined $sizeT;

		# convert OME-XML to OMECA-XML using XSLT stylesheet
		my $CA_doc = $stylesheet->transform($doc);
		next unless defined $CA_doc;

		# get CA's OME/Image/CustomAttributes element
		$rootElement = $CA_doc->documentElement();
		$imageElement = ($rootElement->getChildrenByTagName('Image'))[0];
		my $caElement =
			($imageElement->getChildrenByTagName('CustomAttributes'))[0];
		next unless defined $caElement;

		# insert new Pixels element beneath CustomAttributes element
		$pixelsElement = ($caElement->getChildrenByTagName('Pixels'))[0];
		$pixelsElement->setAttribute('ID', $pixelsID);
		$pixelsElement->setAttribute('SizeX', $sizeX);
		$pixelsElement->setAttribute('SizeY', $sizeY);
		$pixelsElement->setAttribute('SizeZ', $sizeZ);
		$pixelsElement->setAttribute('SizeT', $sizeT);
		$pixelsElement->setAttribute('SizeC', $sizeC);
		$pixelsElement->setAttribute('PixelType', $pixelType);
		$pixelsElement->setAttribute('Repository', $repositoryLSID);

		# save parameters needed later for the actual import
    $file_id = $file->getFileID();
		$self->{$file_id}->{'CA_doc'} = $CA_doc;
		$self->{$file_id}->{'pixelsElement'} = $pixelsElement;
		$self->{$file_id}->{'dimOrder'} = $dimOrder;
		$self->{$file_id}->{'tiffData'} = \@tiffData;

		# passed all tests; add file to corresponding group list
		push (@{$groups->{$pixelsID}}, $file);
		$filename = $file->getFilename();
		logdbg "debug", "OME-TIFF: $filename parsed successfully as OME-TIFF";
		delete $fhash->{$file_id};
	}

	# construct output group list
	while (my $pixelsID = each %$groups) {
		my @groupList = @{$groups->{$pixelsID}};
		push (@outlist, {
			Files => \@groupList
		})
	}
	return \@outlist;
}

# Does the actual import into the OME database.
sub importGroup {
	my ($self, $group, $callback) = @_;
	my $session = $self->Session();
	my @images;
	my $groupList = $group->{Files};

	# get needed OMECA-XML parameters stored earlier
	# theoretically, all XML blocks for the group should be identical
	# (except for the TiffData element(s) specifying planar ordering)
	my $firstfile = @$groupList[0]->getFilename();
	logdbg "debug", "OME-TIFF: importGroup $firstfile";
	my $CA_doc = $self->{$firstfile}->{'CA_doc'};
	logdbg "debug", "OME-TIFF: OMECA-XML = ".($CA_doc->toString(1));
	my $pixelsElement = $self->{$firstfile}->{'pixelsElement'};
	my $dimOrder = $self->{$firstfile}->{'dimOrder'};

	# get attributes of Pixels element
	my $sizeX = $pixelsElement->getAttribute('SizeX');
	my $sizeY = $pixelsElement->getAttribute('SizeY');
	my $sizeZ = $pixelsElement->getAttribute('SizeZ');
	my $sizeC = $pixelsElement->getAttribute('SizeC');
	my $sizeT = $pixelsElement->getAttribute('SizeT');
	logdbg "debug",
		"OME-TIFF: importGroup: sizeZ=$sizeZ; sizeC=$sizeC; sizeT=$sizeT";
	my $pixelType = $pixelsElement->getAttribute('PixelType');

	# create pixels in OMEIS
	my ($bpp, $isSigned, $isFloat);
	if ($pixelType eq 'int8') { $bpp = 1; $isSigned = 1; $isFloat = 0; }
	elsif ($pixelType eq 'Uint8') { $bpp = 1; $isSigned = 0; $isFloat = 0; }
	elsif ($pixelType eq 'int16') { $bpp = 2; $isSigned = 1; $isFloat = 0; }
	elsif ($pixelType eq 'Uint16') { $bpp = 2; $isSigned = 0; $isFloat = 0; }
	elsif ($pixelType eq 'int32') { $bpp = 4; $isSigned = 1; $isFloat = 0; }
	elsif ($pixelType eq 'Uint32') { $bpp = 4; $isSigned = 0; $isFloat = 0; }
	elsif ($pixelType eq 'float') { $bpp = 4; $isSigned = 1; $isFloat = 1; }
	my $pixels = OME::Image::Server::Pixels->new($sizeX, $sizeY, $sizeZ,
		$sizeC, $sizeT, $bpp, $isSigned, $isFloat);

	# process each TIFF file
	my %original_files;
	foreach my $file (@$groupList) {
    my $file_id = $file->getFileID();
		my $filename = $file->getFilename();
		logdbg "debug", "OME-TIFF: importGroup: filename=$filename";

		# get TiffData element(s) stored earlier
		my @tiffData = @{$self->{$file_id}->{'tiffData'}};

		foreach my $td (@tiffData) {
			my $firstZ = $td->getAttribute('FirstZ');
			if (not defined $firstZ) { $firstZ = 0; }
			my $firstT = $td->getAttribute('FirstT');
			if (not defined $firstT) { $firstT = 0; }
			my $firstC = $td->getAttribute('FirstC');
			if (not defined $firstC) { $firstC = 0; }
			my $ifd = $td->getAttribute('IFD');
			my $numPlanes = $td->getAttribute('NumPlanes');
			if (not defined $numPlanes) {
				if (defined $ifd) { $numPlanes = 1; }
				else { $numPlanes = 2147483647; } # upper bound
			}
			if (not defined $ifd) { $ifd = 0; }
			logdbg "debug", "OME-TIFF: importGroup: $filename: <TiffData IFD=$ifd ".
				"NumPlanes=$numPlanes FirstZ=$firstZ FirstT=$firstT FirstC=$firstC>";

			# process each image plane
			my $z = $firstZ;
			my $t = $firstT;
			my $c = $firstC;
			for (my $i = 0; $i < $numPlanes; $i++) {
				my $ii = $ifd + $i;
				eval { $pixels->convertPlaneFromTIFF($file, $z, $c, $t, $ii); };
				last if $@; # trapped since TIFFUtils has no fast IFD counting routine
				logdbg "debug", "OME-TIFF: processed $filename ".
					" IFD #$ii (z=$z, t=$t, c=$c).";

				# increment ZTC position
				if ($dimOrder eq 'XYZTC') {
					$z++;
					if ($z >= $sizeZ) {
						$z = 0; $t++;
						if ($t >= $sizeT) { $t = 0; $c++; }
					}
				}
				elsif ($dimOrder eq 'XYZCT') {
					$z++;
					if ($z >= $sizeZ) {
						$z = 0; $c++;
						if ($c >= $sizeC) { $c = 0; $t++; }
					}
				}
				elsif ($dimOrder eq 'XYTZC') {
					$t++;
					if ($t >= $sizeT) {
						$t = 0; $z++;
						if ($z >= $sizeZ) { $z = 0; $c++; }
					}
				}
				elsif ($dimOrder eq 'XYTCZ') {
					$t++;
					if ($t >= $sizeT) {
						$t = 0; $c++;
						if ($c >= $sizeC) { $c = 0; $z++; }
					}
				}
				elsif ($dimOrder eq 'XYCZT') {
					$c++;
					if ($c >= $sizeC) {
						$c = 0; $z++;
						if ($z >= $sizeZ) { $z = 0; $t++; }
					}
				}
				elsif ($dimOrder eq 'XYCTZ') {
					$c++;
					if ($c >= $sizeC) {
						$c = 0; $t++;
						if ($t >= $sizeT) { $t = 0; $z++; }
					}
				}
				else { die "Unknown DimensionOrder: $dimOrder\n"; }
			}
		}

		# touch each file only once
		$original_files{$file} =
			$self->touchOriginalFile($file, 'OME TIFF')
			or die "$filename won't let me touch it! While importing OME TIFF.";
	}
	logdbg "debug", "OME-TIFF: done processing IFDs.";

	# close pixels
	$pixels->finishPixels();

	# append remaining required attributes to OMECA-XML's Pixels element
	$pixelsElement->setAttribute('FileSHA1', $pixels->getSHA1());
	$pixelsElement->setAttribute('ImageServerID', $pixels->getPixelsID());
	logdbg "debug", "OME-TIFF: attributes configured.";

	# call the OME-XML DOM parser
	my $OMEimporter = OME::Tasks::OMEImport->new();
	my $importedObjects =
		$OMEimporter->processDOM($CA_doc->getDocumentElement(),
		NoDuplicates           => 0,
		IgnoreAlterTableErrors => 1);
	logdbg "debug", "OME-TIFF: DOM processed.";

	# proceed the same way that XMLreader does after calling importFile
	foreach my $object (@$importedObjects) {
		logdbg "debug", 'OME-TIFF: processing object '.$object;
		if (UNIVERSAL::isa($object, 'OME::Image')) {
			foreach my $pixels ($object->pixels()) {
				$self->storeDisplayOptions($object);
				OME::Tasks::PixelsManager->saveThumb($pixels);
			}
			foreach my $file (@$groupList) {
				my $filename = $file->getFilename();
				logdbg "debug", "OME-TIFF: markImageFiles $filename";
				OME::Tasks::ImportManager->markImageFiles($object,
					$original_files{$file});
			}
			push (@images, $object);
		}
	}
	logdbg "debug", "OME-TIFF: Done!";

	$self->doSliceCallback($callback);

	return \@images;
}

# Gets the SHA1 of the first file in the group.
sub getSHA1 {
	my $self = shift;
	my $group = shift;
	my $file = $group->{Files}->[0];
	my $sha1 = $file->getSHA1();
	return $sha1;
}

1;
