#!/usr/bin/perl -w
#
# Importer.pm
# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Brian S. Hughes
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

# OME's image import class. It creates an instance of the Import-reader
# class for each image and has that instance's methods and sub-classes
# do the actual import work.
#

# ---- Public routines -------
# new()
# import_image()

# ---- Private routines ------
# get_base_name()
# sort_and_group()
# groupnames()
# store_image_metadata()
# store_image_attributes()
# store_image_pixels()
# find_repository()
# store_wavelength_info()
# store_xyz_info()
# store_image_files_xyzwt()
# removeWeirdCharacters()

package OME::ImportExport::Importer;
use strict;
use OME::ImportExport::Import_reader;
use Carp;
use File::Basename;
use Sort::Array;
use vars qw($VERSION);
$VERSION = '1.0';

sub new {
    my @image_buf;
    my %xml_elements;      # build up DB entries in here keyed by their XML element names
    my $image_group_ref;
    my $image_file;
    my $import_reader;
    my $read_status;
    my $self = {};
    my @fn_groups;


    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $image_file_list_ref = shift;         # reference list of input files
    croak "No image file to import"
	unless $image_file_list_ref;
    my $session = shift;
    $self->{session} = $session;

    sort_and_group($image_file_list_ref, \@fn_groups);
    $self->{fn_groups} = \@fn_groups;

    bless $self,$class;

}

# Actually import a single image, which may be composed from several files
sub import_image {
    my $fn;
    my $basenm;
    my $image_file;
    my $import_reader;
    my $status;
    my $read_status;
    my @image_buf;
    my %xml_elements;
    my $self = shift;
    my $dsr = shift;    # reference to Dataset object;
    my $image_group_ref = shift;

    $self->{dataset} =$dsr;
    $image_file = $$image_group_ref[0];
    $basenm = basename($image_file);
    # remove filetype extension from filename (assumes '.' delimiter)
    $basenm =~ s/\..+?$//;
    $xml_elements{'Image.Name'} = $basenm;
    $import_reader = new OME::ImportExport::Import_reader($image_group_ref, \@image_buf, \%xml_elements);
    $fn = $import_reader->Image_reader::image_file;
    $import_reader->check_type;

    $self->{did_import} = 0;
    if ($import_reader->image_type eq "Unknown") {
	carp "File $image_file has an unknown type";
    }
    else {
	$read_status = $import_reader->readFile;
	if ($read_status ne "") {
	    print "Carping: ";
	    carp $read_status;
	}
	else {
	    $status = store_image($self, \%xml_elements, \@image_buf, $image_group_ref);
	    if ($status eq "") {
		$self->{did_import} = 1;
		print "did import\n";
	    }
	    else {
		print "failed import: $status\n";
	    }
	}
    }
    $import_reader->DESTROY;

}


# Store image's metadata in the OME db, and the image data in the repository
sub store_image {
    my $self = shift;
    my $href = shift;  # reference to metadata hash;
    my $aref = shift;          # reference to pixel array
    my $image_group_ref = shift;
    my $session = $self->{session};
    my $status = "";
    my $cleaned;
    my $image;
    my $imageID;
    my $group_id;
    my $realpath;
    my $repository;
    my $attributes;

    while (1) {
	# First, clean the data
	$cleaned = removeWeirdCharacters($href);

	# determine which repository the new image should be placed in
	my $repository = findRepository($session, $aref);
	if (!defined $repository) {
	    $status = "Can\'t find repository";
	    last;
	}

	# create and populate an image object
	$status = store_image_metadata($self, $href, $session, $repository);
	last unless $status eq "";
	$image = $self->{image};

	# create and populate an image attributes object
	$status = store_image_attributes($self, $href, $session);
	last unless $status eq "";
	$attributes = $self->{'attributes'};

	# now create and write the image pixel's file
	$status = store_image_pixels($self, $href, $aref);
	last unless $status eq "";

	$status = store_wavelength_info($self, $session, $href);
	last unless $status eq "";

	$status = store_xyz_info($self, $session, $href);
	last unless $status eq "";

	$status = store_image_files_xyzwt($self, $session, $href, $image_group_ref);
	last unless $status eq "";

	# everything went OK - commit all the DB inserts
	$image->commit;
        $image->dbi_commit();
	$attributes->dbi_commit();
	$session->DBH()->commit;

	#my $ds = $self->{dataset};
	#$ds->Field("images", $image);

	last;
    }

    return $status;
}



sub get_base_name {
    my $fullnm = shift;
    my $fn;
    my @arr;

    @arr = split('/', $fullnm);  # assume Unix style filename
    $fn = $arr[$#arr];
    $fn =~ s/([\w]+).*/$1/;

    return $fn;
}



# Routine sorts the passed list of filenames,discards duplicates, and
# calls groupnames() to assemble the filenames into sibs (sibling groups).

sub sort_and_group {
    my $fns = shift;
    my $out_fns =shift;
    my @cleansed;
    
# First cleanse data by sorting input and eliminating duplicates
    @cleansed = Sort::Array::Discard_Duplicates(
						sorting      => 'ascending',
						empty_fields => 'delete',
						data         => $fns
						);
    @cleansed = reverse @cleansed;
    
# Now break filenames into sets
    groupnames(\@cleansed, $out_fns);

}

# Groups the passed set of sorted names into sets that are
# identical except for a single digit in the imputed wavelength
# field. If a filename doesn't fit into one of the name patterns
# that include a filename field, or if such a filename doesn't
# have any 'wavelength siblings', then the individual filename
# will form a group of 1.
#
# This routine will return a list composed of references to lists
# that each contain the filenames of 1 sibling group.
#
# So far, filenames are grouped only on wavelength sequences, and
# those only if the filenames have a type of ".tif".
# Input filenames will be analyzed in 1 of 3 forms: 
#   <name>_w{1,2}.tif
#   <name>_w{1,2}<more name>.tif
#   other
#
# This routine has been hardcoded for only those 3 forms. Should
# be generalized in the future.

sub groupnames {
    
    my $fns = shift;
    my $outfns = shift;
    my ($fn, $bn);
    my $matched;
    my ($pattern, $subpattern, $subp);
    my $digits = '[1-9]';
    my $fpat1 = '^(\w+_w)([1-9])(.tif+)$';
    my $fpat2 = '^(\w+_w)([1-9])(\w+)(.tif+)$';
    my $anyothers = '^(.+)$';
    my %fmts;
    my $k;
    my $i;

    
    %fmts = (fpat1 => $fpat1,
             fpat2 => $fpat2,
            );

    # if a filename matches one of the above patterns, select
    # out all the other adjacent filenames that match the same pattern.
    # Group them together, since they only vary in the '[1-9]' subfield.
    # If the original sorted filename list is reversed by the caller before
    # passing to this routine, the resulting sets of matching files will
    # be ordered from lowest to highest integer in the '[1-9]' subfield.

    while ($fn = pop @$fns) {
        $bn = basename($fn);
        $matched = 0;
        foreach $k (keys %fmts) {
            $pattern = $fmts{$k};
            if ($bn =~ m/$pattern/i) {    # found a file that matches a pattern
                $matched = 1;
                $subp = $4 ? "$3$4" : "$3";
                $subpattern = "$1$digits$subp";
                my @grp = ($fn);
                while (1) {               #    now find all similarly named files
                    if ($fn = pop @$fns) {
                        $bn = basename($fn);
                        if ($bn =~ m/$subpattern/i) {
                            push @grp, $fn;
                        }
                        else {
                            push @$fns, $fn;
                            last;
                        }
                    }
                    else {
                        last;
                    }
                }
                push @$outfns, \@grp;
            }
        }
        if ($matched == 0) {    # filename didn't match any pattern, so stick it on it's own sublist
            #push @$outfns, \($fn);
            push @$outfns, [$fn];
        }
    }

}


# Create and populate an image object
sub store_image_metadata {
    my ($self, $href, $session, $repository) = @_;
    my $status = "";
    my $image;
    my $created;
    my $name;
    my $path;

    #my $created = $href->{'Image.CreationDate'};
    $created = "now" unless $created;     # until we figure out date formatting issue

    $name = $href->{'Image.Name'}.".ori";
    $path = $repository->Field("path");
    $self->{realpath} = $path.$name;
    my $recordData = {'name' => $name,
		      'path' => $path,
		      'description' => $href->{'Image.Description'},
		      'experimenter_id' => $session->User(),
		      'group_id' => $session->User()->Field("group"),
		      'created' => $created,
		      'inserted' => "now",
		      'repository_id' => $repository};

    $image = $session->Factory->newObject("OME::Image", $recordData);
    if (!defined $image) {
	$status = "Can\'t create new image";
	return $status;
    }

    $self->{image} = $image;
    my $imageID = $image->id();

    return $status;
}


# create and populate an image attributes object
sub store_image_attributes {
    my ($self, $href, $session) = @_;
    my $status = "";
    my $image = $self->{image};
    my $recordData = {'image_id' => $image->id,
		   'size_x' => $href->{'Image.SizeX'},
		   'size_y' => $href->{'Image.SizeY'},
		   'size_z' => $href->{'Image.SizeZ'},
		   'num_waves' => $href->{'Image.NumWaves'},
		   'num_times' => $href->{'Image.NumTimes'},
		   'bits_per_pixel' => $href->{'Image.BitsPerPixel'}};
    my $attributes = $session->Factory()->newObject("OME::Image::Attributes", $recordData);

    if (!defined $attributes) {
	$status = "Can\'t create new image attribute table";
    }
    $self->{'attributes'} = $attributes;

    return $status;
}


# now create and write the image pixel's file
sub store_image_pixels {
    my ($self, $href, $aref) = @_;
    my $realpath = $self->{'realpath'};
    my $status = "";
    my $handle = new IO::File;
    my $image;
    my ($cmd, $sh, $sha1);

    print STDERR "output to $realpath\n";
    my $image_out = ">".$realpath;
    open $handle, $image_out;
    if (!defined $handle) {
	$status = "Error creating repository file";
	return $status;
    }
    
    # Assume array ref is 4-dimensional, 5th (ie, X) dimension
    # being a packed string of 16-bit integers.
    for (my $t = 0; $t < $href->{'Image.NumTimes'}; $t++)
    {
	for (my $w = 0; $w < $href->{'Image.NumWaves'}; $w++)
	{
	    for (my $z = 0; $z < $href->{'Image.SizeZ'}; $z++)
	    {
		for (my $y = 0; $y < $href->{'Image.SizeY'}; $y++)
		{
		    print $handle $aref->[$t][$w][$z][$y];
		}
	    }
	}
    }
    close $handle;

    $cmd = 'openssl sha1 '. $realpath .' |';
    open (STDOUT_PIPE,$cmd);
    $sh = <STDOUT_PIPE>;
    chomp;
    $sh =~ m/^.+= +([a-fA-F0-9]*)$/;
    $sha1 = $1;

    $image = $self->{'image'};
    $image->file_sha1($sha1);

    return $status;
}



# findRepository(session,pixel array)
# -----------------------------------
# This function should determine, based on (currently) the size of the
# pixel array, which repository an image should be stored in.  For now
# we assume that there is only one repository, with an ID of 1.
# (Which, if the bootstrap script worked properly, will be the case.)

my $onlyRepository;

sub findRepository {
    return $onlyRepository if defined $onlyRepository;
    
    my ($session, $aref) = @_;
    $onlyRepository = $session->Factory()->loadObject("OME::Repository",1);
    return $onlyRepository if defined $onlyRepository;
    die "Cannot find repository #1.";
}


# Store the information about each wavelength used in an image.
sub store_wavelength_info {
    my ($self, $session, $href) = @_;
    my $image = $self->{'image'};
    my $imageID = $image->id();

    # fill in & store rows in the image_wavelength table - 1 row per image wavelength.
    # N.B. - For each wavelength there must be a separate xyz_image_info row per time,
    #        and a separate xy_image_info row per time.
    # DB needs rule that checks this consistency & rollsback commit if violated

    # Row will be: image_id | wavenumber | ex_wavelength | em_wavelength | nd_filter | fluor

    # (code per IGG 10/6/02)
    my @WavelengthInfo = ({});
    my $wave;
    my $sth = $session->DBH()->prepare ('INSERT INTO image_wavelengths (image_id,wavenumber,ex_wavelength,em_wavelength,fluor,nd_filter) VALUES (?,?,?,?,?,?)');
    if (exists $href->{'WavelengthInfo.'} and ref($href->{'WavelengthInfo.'}) eq "ARRAY") {
	# Make sure its sorted on WaveNumber.
	@WavelengthInfo = sort {$a->{'WavelengthInfo.WaveNumber'} <=> $b->{'WavelengthInfo.WaveNumber'}} @{$href->{'WavelengthInfo.'}};
    }

    for (my $w = 0; $w < $href->{'Image.NumWaves'}; $w++) {
	$wave = $WavelengthInfo[$w];
	# Clear out the hash if WaveNumber doesn't match $w - something's screwed up.
	# We also do this if there was no WavelengthInfo to begin with.
	# FIXME:  If WaveNumber doesn't match $w at any point, there's probably a more serious problem that should result in a roll-back of this import.
	if ($wave->{'WavelengthInfo.WaveNumber'} ne $w) {
	    $wave->{'WavelengthInfo.WaveNumber'} = $w;
	    $wave->{'WavelengthInfo.ExWave'} = undef;
	    $wave->{'WavelengthInfo.EmWave'} = undef;
	    $wave->{'WavelengthInfo.Fluor'} = undef;
	    $wave->{'WavelengthInfo.NDfilter'} = undef;
	}
	$sth->execute($imageID,
		      $wave->{'WavelengthInfo.WaveNumber'},
		      $wave->{'WavelengthInfo.ExWave'},
		      $wave->{'WavelengthInfo.EmWave'},
		      $wave->{'WavelengthInfo.Fluor'},
		      $wave->{'WavelengthInfo.NDfilter'}
		      );
    }

}
    

# Calculate & store the information about each xyz_image chunk into rows in xyz_image_info
# Calls external program OME_Image_XYZ_stats, whose location is hardwired to /OME/bin
# The program output is tab-delimited columns like so:
#    Wave Time Min Max Mean GeoMean Sigma Centroid_x Centroid_y Centroid_z
# The first line contains the column headings, and is discarded. Table row looks like:
# image_id | wavenumber | timepoint | deltatime | min | max | mean | geomean | sigma | centroid_x | centroid_y | centroid_z

sub store_xyz_info {
    my ($self, $session, $href) = @_;
    my $image = $self->{'image'};
    my $imageID = $image->id();
    my $status = "";
    my $sth;

    $sth = $session->DBH()->prepare (
        'INSERT INTO xyz_image_info (image_id,wavenumber,timepoint,min,max,mean,geomean,sigma,centroid_x,centroid_y,centroid_z) VALUES (?,?,?,?,?,?,?,?,?,?,?)');
    my $Dims = join (',',($href->{'Image.SizeX'},$href->{'Image.SizeY'},$href->{'Image.SizeZ'},
        $href->{'Image.NumWaves'}, $href->{'Image.NumTimes'}, ($href->{'Image.BitsPerPixel'})/8));
    my $cmd = '/OME/bin/OME_Image_XYZ_stats Path='.$image->getFullPath().' Dims='.$Dims.' |';
    
    open (STDOUT_PIPE,$cmd);
    while (<STDOUT_PIPE>) {
        chomp;
        my @columns = split (/\t/);
        foreach (@columns) {
            # trim leading and trailing white space and set to undef unless column looks like a C float
            $_ =~ s/^\s+//;$_ =~ s/\s+$//;$_ = undef unless ($_ =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
        }
        next unless defined $columns[0];

        $sth->execute($imageID,@columns);
    }

}


# store info about each file that was a component of this image
sub store_image_files_xyzwt {
    my ($self, $session, $href, $image_group_ref) = @_;
    my $image = $self->{'image'};
    my $imageID = $image->image_id();
    print "new image id = $imageID\n";
    my $status = "";
    my $file;
    my $sth;
    my ($z, $w, $t);

    foreach $file (@$image_group_ref) {
	my $sh;
	my $sha1;
	my $endian;
	my @col;

	my $cmd = 'openssl sha1 '. $file .' |';
	open (STDOUT_PIPE,$cmd);
	$sh = <STDOUT_PIPE>;
	chomp;
	$sh =~ m/^.+= +([a-fA-F0-9]*)$/;
	$sha1 = $1;
	
	$endian = $href->{'Image_files_xyzwt.Endian'};
	$endian = ($endian eq "big") ? "TRUE" : "FALSE";
	$sth = $session->DBH()->prepare (
					 'INSERT INTO image_files_xyzwt (image_id, file_sha1, bigendian, path, host, url, x_start, x_stop, y_start, y_stop, z_start, z_stop, w_start, w_stop, t_start, t_stop) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
	
	$sth->execute($imageID, $sha1, $endian, $file, "", "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    }
}    



# removeWeirdCharacter(hash)
# --------------------------
# By weird, I mean the null character currently.  Ensures that the
# input from an image file won't trash the Postgres DBI driver (which
# a null character in the input string will do).

sub removeWeirdCharacters {
    my $hash = shift;
    my $anyRemoved = 0;

    foreach my $key (keys(%$hash)) {
        my $value = $hash->{$key};
        if (!ref($value)) {
            my $replaced = ($value =~ s/[\x00]//g);
            $hash->{$key} = $value;
            #print STDERR "   $key $replaced\n";
            $anyRemoved = $replaced if $replaced;
        }
    }

    return $anyRemoved;
}


1;
