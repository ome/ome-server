# OME/ImportEngine/MetamorphHTDFormat.pm

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


package OME::ImportEngine::MetamorphHTDFormat;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Config;
use IO::File;
use OME::ImportEngine::ImportCommon qw(doSliceCallback);
use OME::ImportEngine::AbstractFormat;
use OME::ImportEngine::TIFFUtils;
use OME::ImportExport::Repacker::Repacker;

use OME::Tasks::PixelsManager;

use base qw(OME::ImportEngine::AbstractFormat);

# Used to create well addresses
use constant ALPHABET => [split(//,'ABCDEFGHIJKLMNOPQRSTUVWXYZ')];

# All possible capitalizations of .TIF
# Used to look for image files based on the HTD filename
use constant SUFFIXES => ['.TIF','.tif','.TIf','.TiF',
                          '.tIF','.Tif','.tIf','.tiF'];


# From "Mastering Regular Expressions"
# Works similar to split, but returns an array of values based on
# interpreting $string as a Comma-Separated Value list.

sub __parseCSV ($) {
    my ($string) = @_;
    my @new  = ();

    # the first part groups the phrase inside the quotes.
    # see explanation of this pattern in MRE
    push(@new, $+)
      while $string =~ m{"([^\"\\]*(?:\\.[^\"\\]*)*)",? ?|([^,]+),? ?|, ?}g;
    push(@new, undef) if substr($string, -1,1) eq ',';
    return @new;      # list of values that were comma-separated
}

sub __wellAddress ($$) {
    my ($x,$y) = @_;
    return sprintf("%s%02d",ALPHABET->[$y],$x+1);
}

sub getGroups {
    my ($self,$files) = @_;

    # Keep a list of the files that we're going to import, so that
    # we can remove them from $filenames at the end.
    my @files_found;

    # Keep track of the groups that we find.
    my @groups;

    my $file_opened;

    my @files = values %$files;

  FILENAME:
    foreach my $file (@files) {
        $file_opened = 0;
        my $filename = $file->getFilename();

        # We're only interested in .HTD files
        next FILENAME unless $filename =~ /\.[Hh][Tt][Dd]$/;

        #print STDERR "Found $filename\n";

        eval { $file->open('r') };
        if ($@) {
            carp "Could not open $filename - $@";
            next FILENAME;
        }

        # This flag, along with the continue block at the end of the
        # FILENAME foreach loop, allows us to just use "next FILENAME"
        # to abort the current file.  The continue block will take
        # care of cleaning up.

        $file_opened = 1;

        # Check the first line to make sure that we've got a valid
        # HTS file.

        #print "/ $/\n";

        local $/ = "\015\012";

        my $line;
        if ($line = $file->readLine()) {
            chomp($line);
            #print "$line\n";
            if ($line !~ /^"HTSInfoFile",/) {
                carp "Not an HTS file";
                next FILENAME;
            } elsif ($line !~ /Version 1\.0$/) {
                $line =~ /, ([^,]*)$/;
                my $version = $1;
                #print "'$version'\n";
                carp "Unknown HTS version";
                next FILENAME;
            }
        } else {
            carp "Could not read header line";
            next FILENAME;
        }

        # If we've gotten to this point, we have a valid header file.
        # Read all of the rest of the lines into a hash.  (This ensures
        # that reordering the lines won't break things.  Is this good?
        # Who knows.  But it won't break files that haven't been
        # reordered.)

        my $lines;

        while (my $line = $file->readLine()) {
            chomp($line);
            my @columns = __parseCSV($line);

            my $line_name = shift(@columns);
            s/^\s+// foreach @columns;  # Remove any leading whitespace
            $lines->{$line_name} = \@columns;
        }

        my $description = $lines->{Description}->[0] || "";

        # Determine which wells have been recorded.  XWells and YWells
        # determines the size of the plate.  There should then be one
        # "WellsSelection*" line for each row of wells.  The entry is
        # made of a list of TRUEs or FALSEs, one for each column of
        # wells.  This matrix determines which wells have had an image
        # recorded.

        # NOTE:  In building the @wells_used array, we do not place a
        # count into the entries of @wells_used.  This is because the
        # wells are referenced in the filename by their plate address.
        # (I.e., well [0,0] is recorded in the filename as A1.)  For
        # the other arrays (for sites and waves), this is not true.
        # Site 0, for instance is in the filename as s1.  Therefore,
        # a count is kept track as the array is built, and the index
        # of each entry is stored in the entry itself.

        my $xwells = $lines->{XWells}->[0] || 0;
        my $ywells = $lines->{YWells}->[0] || 0;
        my @wells_used;

        for (my $y = 0; $y < $ywells; $y++) {
            my $well_line = $lines->{"WellsSelection".($y+1)};
            for (my $x = 0; $x < $xwells; $x++) {
                push @wells_used, [$x,$y] if $well_line->[$x] eq 'TRUE';
            }
        }

        # Determine if multiple images were taken in each well.  If so,
        # the Sites entry will be TRUE, and the XSites, YSites, and
        # SiteSelection* entries define a matrix of sites in the same
        # way that the matrix of wells is determined above.

        my $sites = $lines->{Sites}->[0] || "FALSE";
        my @site_locations;
        my @sites;

        if ($sites eq 'TRUE') {
            my $xsites = $lines->{XSites}->[0] || 0;
            my $ysites = $lines->{YSites}->[0] || 0;
            my $site_count = 0;
            foreach (my $y = 0; $y < $ysites; $y++) {
                my $site_line = $lines->{"SiteSelection".($y+1)};
                foreach (my $x = 0; $x < $xsites; $x++) {
                    if ($site_line->[$x] eq 'TRUE') {
                        $site_count++;
                        push @sites, [$site_count,$x,$y];
                    }
                }
            }
        } else {
            push @sites, undef;
        }

        # Determine if multiple wavelengths were recorded for these
        # images.  If so, the Waves entry will be TRUE, and the
        # NWavelengths entry determines how many wavelengths were
        # captured.  Their names are specified by the WaveName*
        # entries.

        my $waves = $lines->{Waves}->[0] || "FALSE";
        my @waves;

        if ($waves eq 'TRUE') {
            my $nwaves = $lines->{NWavelengths}->[0] || 0;
            my $wave_count = 0;
            foreach (my $w = 0; $w < $nwaves; $w++) {
                my $name = $lines->{"WaveName".($w+1)}->[0];
                $wave_count++;
                push @waves, [$wave_count,$name];
            }
        } else {
            push @waves, undef;
        }

        push @files_found, $file;

        # Now that we've parsed the HTD file, we need to determine which
        # image files should be imported.

        $filename =~ /^(.*)\.[Hh][Tt][Dd]$/;
        my $base_filename = $1;

        #print STDERR "Base $base_filename\n";

        # If the @wells_used array is empty, then there are no images to
        # import for this HTD file.  If sites are not enabled in this
        # file, then the @sites array will contain a single undef.  If
        # enabled, it will contain an entry for each site that was
        # recorded in the "SiteSelection*" entries.  If the array is
        # empty, then sites were enabled, but none were marked as having
        # been recorded, and therefore no images should be imported.
        # Everything said about the @sites array applies verbatim to the
        # @waves array, as well.

        # Each (well x site) pair creates a new image.  Multiple
        # wavelengths are stored in a single image.

        # If any of the filenames defined by the well, site, and
        # wavelength matrices doesn't exist, that entire image is
        # skipped.

        foreach my $well (@wells_used) {
            foreach my $site (@sites) {
                my $group =
                  {
                   description => $description,
                   htd_file    => $file,
                   image_files => [],
                   well        => $well,
                   site        => $site,
                   wavelengths => [],
                  };

                # Make sure we find at least one wavelength before we
                # consider this group valid.
                my $group_valid = 0;

                # If any of the files don't exist, this group is
                # invalid, regardless of what $group_valid says.
                my $group_invalid = 0;

              WAVELENGTHS:
                foreach my $wave (@waves) {
                    # Build the image base
                    my $tif_base_filename = $base_filename;
                    $tif_base_filename .=
                      "_".__wellAddress($well->[0],$well->[1]);
                    $tif_base_filename .=
                      sprintf("_s%d",$site->[0])
                      if defined $site;
                    $tif_base_filename .=
                      sprintf("_w%d",$wave->[0])
                      if defined $wave;

                    my $real_file;
                  TEST_SUFFIX:
                    foreach my $suffix (@{SUFFIXES()}) {
                        my $f = "$tif_base_filename$suffix";
                        if (exists $files->{$f}) {
                            $real_file = $files->{$f};
                            last TEST_SUFFIX;
                        }
                    }

                    if (!defined $real_file) {
                        $group_invalid = 1;
                        #print STDERR "Cannot find file for $tif_base_filename\n";
                        last WAVELENGTHS;
                    }

                    $group_valid = 1;

                    push @{$group->{image_files}}, $real_file;
                    push @{$group->{wavelengths}}, $wave;
                    push @files_found, $real_file;
                }

                push @groups, $group if ($group_valid && !$group_invalid);
            }
        }

    } continue {
        # Ensure that we close the HTD file after this loop iteration,
        # no matter how that iteration finishes.

        $file->close() if $file_opened;
    }

    # Clean out the $filenames list.
    $self->__removeFiles($files,\@files_found);

    #print STDERR "\nFound ",scalar(@groups)," groups.\n";

    return \@groups;
}


sub getSHA1 {
    my ($self,$group) = @_;

    # We can't use the HTD file for the SHA1, since it's shared amongst
    # all of the images.  Any of the TIF files will do, though, so
    # we'll arbitrarily choose the first.

    my $file = $group->{image_files}->[0];

    # The group should never have been created if there are no files in
    # it.  If this is the case, die horribly.

    die "Invalid MetamorphHTDFormat group!" unless defined $file;

    return $file->getSHA1();
}


sub importGroup {
    my ($self,$group, $callback) = @_;

    my $dieStatus = "";

    # This is useful for testing purposes.  Uncomment the next two
    # lines if you don't want to import all of the images in a plate.

    #return undef if $self->{importedOne} > 5;
    #$self->{importedOne}++;

    my $session = $self->Session();
    my $factory = $session->Factory();

    my $user = $session->UserState()->experimenter();

    my $well = $group->{well};
    my $address = __wellAddress($well->[0],$well->[1]);

    my $site = $group->{site};
    my ($sample_number,$site_name);
    if (defined $site) {
        $sample_number = $site->[0];
        $site_name = " Site $sample_number";
    } else {
        $sample_number = undef;
        $site_name = "";
    }

    my $image_name = $group->{description}." Well $address$site_name";
    #print STDERR "Name $image_name\n";

    # Figure out the endian-ness of this machine.
    my $our_endian = OME->BIG_ENDIAN()? BIG_ENDIAN: LITTLE_ENDIAN;

    my $image = $self->__newImage($image_name);

    # Touch the HTD file
    my $htd_attr = $self->
      __touchOriginalFile($group->{htd_file},"MetaMorph HTD");
    print STDERR "Got attribute $htd_attr\n";
    OME::Tasks::ImportManager->markImageFiles($image,$htd_attr);

    # We can't create the pixels attribute until we know the dimensions.
    my $pixels_created = 0;
    my ($pixels,$pix);
    my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bitsPerPixel);
    $sizeZ = 1;
    $sizeC = scalar(@{$group->{wavelengths}});
    $sizeT = 1;

    my $image_invalid = 0;
    my $image_mex = OME::Tasks::ImportManager->
      getImageImportMEX($image);

    # Loop through all of the TIFF files for this image.

    my $theC = -1;
    my $buf;

  FILENAME:
    foreach my $file (@{$group->{image_files}}) {
        my $filename = $file->getFilename();

        # Touch the TIFF file
        my $tiff_attr = $self->
          __touchOriginalFile($file,"MetaMorph TIFF");
        OME::Tasks::ImportManager->markImageFiles($image,$tiff_attr);

        $theC++;
        #print STDERR "  Wavelength $theC - $filename\n";
        my $wavelength = $group->{wavelengths}->[$theC];

        $file->open('r') or last FILENAME;

        # Read the IFD for this TIFF file.

        my $ifd = readTiffIFD($file);
        if (!defined $ifd) {
            #print STDERR "Error reading IFD from $filename\n";
	    $dieStatus = "Error reading IFD from $filename\n";
            $image_invalid = 1;
            $file->close();
            last FILENAME;
        }

        #print STDERR "Tags: ",join(' ',keys %$ifd),"\n";

        # Retrieve the dimensions of this TIFF.

        my $samplesPerPix = $ifd->{TAGS->{SamplesPerPixel}}->[0] || 1;
        my $thisSizeX = $ifd->{TAGS->{ImageWidth}}->[0] || -1;
        my $thisSizeY = $ifd->{TAGS->{ImageLength}}->[0] || -1;
        my $thisBitsPerPixel = $ifd->{TAGS->{BitsPerSample}}->[0] || 0;

        # Make sure that there is only one sample per pixel.  (Multiple
        # samples per pixel are encoded in separate TIFFs with this
        # format).

        if ($samplesPerPix != 1) {
            #print STDERR "Not a monochrome image\n";
	    $dieStatus = "Not a monochrome image\n";
            $image_invalid = 1;
            $file->close;
            last FILENAME;
        }

        if (not ($thisBitsPerPixel == 8 || $thisBitsPerPixel == 16) ) {
            #print STDERR "Bits per bixel must be 8 or 16.  Got $thisBitsPerPixel.\n";
	    $dieStatus = "Bits per bixel must be 8 or 16.  Got $thisBitsPerPixel.\n";
            $image_invalid = 1;
            $file->close;
            last FILENAME;
        }

        if ($pixels_created) {
            # Verify that this TIFF is the same size as all of the others.

            if ($sizeX != $thisSizeX || $sizeY != $thisSizeY ||
                $bitsPerPixel != $thisBitsPerPixel) {
                #print STDERR "Inconsistent sizes\n";
		$dieStatus = "Inconsistent sizes\n";
                $image_invalid = 1;
                $file->close;
                last FILENAME;
            }
        } else {
            # We haven't created the repository file yet.  (We couldn't
            # before, since we didn't have the dimensions.)  Now that
            # we have all of the necessary information, create it.

            $sizeX = $thisSizeX;
            $sizeY = $thisSizeY;
            $bitsPerPixel = $thisBitsPerPixel;

            ($pixels,$pix) = $self->
              __createRepositoryFile($image,$sizeX,$sizeY,$sizeZ,
                                     $sizeC,$sizeT,$bitsPerPixel);

            $pixels_created = 1;
        }

        # Read the pixels from this TIFF.

        my $strip_offsets = $ifd->{TAGS->{StripOffsets}};
        my $strip_lengths = $ifd->{TAGS->{StripByteCounts}};
        my $rows_per_strip = $ifd->{TAGS->{RowsPerStrip}}->[0] || 0;
        my $compression = $ifd->{TAGS->{Compression}}->[0] || 1;

        # Verify that we can handle this format.

        if ($rows_per_strip <= 0) {
            #print STDERR "MetamorphHTDFormat does not support non-strip TIFFs\n";
	    $dieStatus = "MetamorphHTDFormat does not support non-strip TIFFs\n";
            $image_invalid = 1;
            $file->close;
            last FILENAME;
        }

        if ($compression != 1) {
            #print STDERR "MetamorphHTDFormat only supports uncompressed TIFFs\n";
	    $dieStatus = "MetamorphHTDFormat only supports uncompressed TIFFs\n";
            #print STDERR "$compression\n";
            $image_invalid = 1;
            $file->close;
            last FILENAME;
        }
        $file->close;

        $pix->convertPlaneFromTIFF($file,0,$theC,0);

        # Create attributes to describe the channels in this image.

        my $logical = $factory->
          newAttribute('LogicalChannel',$image,$image_mex,
                       {
                        Fluor => $wavelength->[1],
                        PhotometricInterpretation => 'monochrome',
                       });
        my $physical = $factory->
          newAttribute('PixelChannelComponent',$image,$image_mex,
                       {
                        Pixels         => $pixels,
                        Index          => $theC,
                        LogicalChannel => $logical,
                       });
	doSliceCallback($callback);

    }
	OME::Tasks::PixelsManager->finishPixels ($pix,$pixels);

    if ($image_invalid && $pixels_created) {
        # If there was an error, make sure to remove the repository file
        # since it's no longer valid.

        # FIXME:  Add an image server method to delete an
        # unfinished Pixels.
        #print STDERR "Removing repository file... UNIMPLEMENTED!!!\n";
        # $pix->delete();
    }

    if ($image_invalid) {
        die $dieStatus;
    }

    # Create attributes to describe the plate.

    print STDERR "Creating plate attributes...\n";

    my $global_module = $session->Configuration->global_import_module();
    my $plate_name = $group->{description};

    my $plate_attr = $factory->
      findAttribute('Plate',
                    {
                     Name => $plate_name,
                     'module_execution.module' => $global_module,
                     'module_execution.experimenter' => $user,
                    });

    if (defined $plate_attr) {
        print STDERR "  Found existing plate.\n";
    } else {
        print STDERR "  Creating new plate...\n";

        my $global_mex = OME::Tasks::ImportManager->
          getGlobalImportMEX();

        $plate_attr = $factory->
          newAttribute('Plate',undef,$global_mex,
                       {
                        Name => $plate_name,
                       });
    }

    print STDERR "  Creating well...\n";
    my $well_attr = $factory->
      newAttribute('ImagePlate',$image,$image_mex,
                   {
                    Plate  => $plate_attr,
                    Sample => $sample_number,
                    Well   => $address,
                   });

	return $image;

}

sub cleanup {
	# clear out the TIFF tag cache
	OME::ImportEngine::TIFFUtils::cleanup();
}

1;
