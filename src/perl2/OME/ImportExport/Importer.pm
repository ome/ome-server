#!/usr/bin/perl -w
#
# OME/ImportExport/Importer.pm
#
# Copyright (C) 2003 Open Microscopy Environment
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
# sort_and_group()
# groupnames()
# store_image_metadata()
# store_image_attributes()  -- depricated? look at function def for more info
# store_image_pixels()
# find_repository()
# store_wavelength_info()
# store_xyz_info()
# store_image_files_xyzwt()
# map_image_to_dataset()
# name_only();
# check_for_duplicates();
# getSha1();
# removeWeirdCharacters()

package OME::ImportExport::Importer;
use strict;
use OME::ImportExport::Import_reader;
use Carp;
use File::Basename;
use OME::Analysis::AnalysisEngine;
use OME::Image;
use OME::Dataset;
use vars qw($VERSION);
$VERSION = 2.000_000;

sub new {
    my @image_buf;
    my $self = {};
    my @fn_groups;

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $image_file_list_ref = shift;         # reference list of input files
    croak "No image file to import"
	unless $image_file_list_ref;
    my $session = shift;
    $self->{session} = $session;

    my $config = $session->Factory()->loadObject("OME::Configuration", 1);
    $self->{config} = $config;    # load OME's configuration parameters table

    sort_and_group($image_file_list_ref, \@fn_groups);
    $self->{fn_groups} = \@fn_groups;

    bless $self,$class;
}

# Actually import a single image, which may be composed from several files
sub import_image {
    my $image_file;
    my $import_reader;
    my ($is_dupl, $first_sha1);
    my ($status, $tempfn);
    my $read_status;
    my @image_buf;
    my %xml_elements;
    my $self = shift;
    my $dsr = shift;    # reference to Dataset object;
    my $image_group_ref = shift;
    my $switch = shift; # optional switch passed at end of args
    $switch ||= "";

    $self->{dataset} =$dsr;

    my @tmp = reverse(@$image_group_ref);
    my $oname = pop(@tmp);
    $xml_elements{'Image.Name'} = name_only($oname);;
    @$image_group_ref = reverse(@tmp);
    $image_file = $$image_group_ref[0];

    $import_reader = new OME::ImportExport::Import_reader($self,
							  $image_group_ref,
							  \@image_buf,
							  \%xml_elements);
    $import_reader->check_type;
    $self->{did_import} = 0;

    ($status, $first_sha1) = check_for_duplicates($self, $switch, $image_file);
    if ($status ne "") {
	carp $status;
	return "";
    }

    if ($import_reader->image_type eq "Unknown") {
	carp "File $image_file has an unknown type";
    }
    else {
	($read_status, $tempfn) = $import_reader->readFile;
	if ($read_status ne "") {
	    carp $read_status;
	}
	else {
	    $status = store_image($self, \%xml_elements, \@image_buf, $image_group_ref, $first_sha1, $tempfn);
	    if ($status eq "") {
		$self->{did_import} = 1;
		print STDERR "did import\n";
	    }
	    else {
		print STDERR "failed import: $status\n";
	    }
	}
    }
    $import_reader->DESTROY;
}


# Store image's metadata in the OME db, and the image data in the repository
sub store_image {
    my $self = shift;
    my $href = shift;             # reference to metadata hash;
    my $aref = shift;             # reference to pixel array
    my $image_group_ref = shift;  # ref to group of imported files
    my $first_sha1 = shift;       # sha1 digest of 1st file in group
    my $tempfn = shift;
    my $session = $self->{session};
    my $status = "";
    my $image;
    my $repository;
    my $attributes;

    while (1) {
	# First, clean the data
	removeWeirdCharacters($href);

	# determine which repository the new image should be placed in
	my $repository = findRepository($session, $aref);
	if (!defined $repository) {
	    $status = "Can\'t find repository";
	    last;
	}

	# create and populate an image object
	$status = store_image_metadata($self, $href, $session,
				       $repository, $tempfn);
	last unless $status eq "";
	$image = $self->{image};

	# create and populate an image attributes object
# look at function def below for more info
# commented out by josiah 6/9/03
#	$status = store_image_attributes($self, $href, $session);
#	last unless $status eq "";
#	$attributes = $self->{'attributes'};

	$status = store_wavelength_info($self, $session, $href);
	last unless $status eq "";

	$status = store_xyz_info($self, $session, $href);
	last unless $status eq "";

	$status = store_image_files_xyzwt($self, $session, $href, $image_group_ref, $first_sha1);
	last unless $status eq "";

	$status = map_image_to_dataset($self);
	last unless $status eq "";

	# everything went OK -  commit all the DB inserts
	$image->storeObject();
	$session->commitTransaction($image);
	($self->{pixelsAttr})->storeObject();
	$session->commitTransaction($self->{pixelsAttr});
	$session->commitTransaction($self);

	last;
    }

    return $status;
}



# Routine sorts the passed list of filenames, discards duplicates, and
# calls groupnames() to assemble the filenames into sibs (sibling groups).

sub sort_and_group {
    my $fns = shift;
    my $out_fns =shift;
    my @cleansed;

# First cleanse data by sorting input and eliminating duplicates & empty lines
#  This code derived from Michael Diekmann's Sort::Array module.
    # Remove duplicates
    my %seen = ();
    my @unique = grep { ! $seen{$_}++ } @$fns;

    @unique = sort { $a cmp $b } @unique;

    # Remove all empties, and all directories
    foreach (@unique) {
	if ($_) {
	    stat($_);
	    push(@_, $_) if (! -d _);
	}
    }
    @cleansed = @_;

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
    my $fpat1 = '^(\w+)(_w)([1-9])(.tif+)$';
    my $fpat2 = '^(\w+)(_w)([1-9])(\w+)(.tif+)$';
    my %fmts;
    my $k;
    
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
                $subp = $5 ? "$4$5" : "$4";
		my $outname = $5 ? "$1" : "$1$4";
                $subpattern = "$1$2$digits$subp";
                my @grp = ($outname, $fn);
                while (1) {        #    now find all similarly named files
                    if ($fn = pop @$fns) {
                        $bn = basename($fn);
                        if ($bn =~ m/$subpattern/i) {
                            push @grp, $fn;
			    $matched++;
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
		if ($matched == 1) {   # only a singleton after all
		    splice (@grp, 0, 1, $bn);
		}
                push @$outfns, \@grp;
            }
        }
        if ($matched == 0) {    # filename didn't match any pattern, so stick it on it's own sublist
            push @$outfns, [$bn, $fn];
        }
    }

}


# Create and populate an image object
sub store_image_metadata {
    my ($self, $href, $session, $repository, $tempfn) = @_;
    my $status = "";
    my $image;
    my $created;
    my $name;
    my $path;
    my $guid;

    #my $created = $href->{'Image.CreationDate'};
    $created = "now" unless $created;     # until we figure out date formatting issue

    $name = $href->{'Image.Name'};
    $guid = $self->{config}->mac_address;
    
    my $recordData = {'name' => $name,
		      'image_guid' => $guid,
		      'description' => $href->{'Image.Description'},
		      'experimenter_id' => $session->User()->id(),
		      'group_id' => $session->User()->Group()->id(),
		      'created' => $created,
		      'inserted' => "now",
              };

    $image = $session->Factory->newObject("OME::Image", $recordData);
    if (!defined $image) {
	$status = "Can\'t create new image";
	return $status;
    }

    my $dataset = $session->Factory()->
        newObject("OME::Dataset",
                  {
                   name => 'Dummy import dataset',
                   description => '',
                   locked => 'true',
                   owner_id => $session->User()->id(),
                   group_id => undef
                  });
    $self->{dummy_dataset} = $dataset;

    my $module_execution = $session->Factory()->
      newObject("OME::ModuleExecution",
                {
                 dependence => 'I',
                 dataset_id => $dataset->id(),
                 timestamp  => 'now',
                 status     => 'FINISHED',
                 module_id => $self->{config}->import_module()->id(),
                });
    $self->{module_execution} = $module_execution;

    # Now, create the real filename.

    my $pixels = $session->Factory()->
      newAttribute("Pixels",$image,$module_execution,
                   {
                    Repository => $repository->id(),
                    'SizeX' => $href->{'Image.SizeX'},
                    'SizeY' => $href->{'Image.SizeY'},
                    'SizeZ' => $href->{'Image.SizeZ'},
                    'SizeC' => $href->{'Image.NumWaves'},
                    'SizeT' => $href->{'Image.NumTimes'},
                    'BitsPerPixel' => $href->{'Image.BitsPerPixel'},
                    'PixelType'    => ( $href->{'Image.BitsPerPixel'} eq 8 ? 'int8' : 'int16' )
                   });

    # Modified DC, 07/01/2003
    # Filename is now based on pixel attribute ID, not image ID
    # (to allow for more than one Pixels per image)
    my $qual_name = $pixels->id()."-".$name.".ori";
    $pixels->Path($qual_name);
    $pixels->storeObject();

	$image->pixels_id( $pixels->id() ); # hack added by josiah 6/9/03

    $self->{image} = $image;
    $self->{pixelsAttr} = $pixels;
    my $imageID = $image->id();
    $self->{realpath} = $image->getFullPath( $pixels );
    # rename repository file with it's permanent name
    rename ($tempfn, , $self->{realpath}) or
		$status = "failed to rename image file $self->temp_image_name() to $self->{realpath}";
	my $mode = 0444; chmod( $mode, $self->{realpath} ); 
		#allows repository file to be read by other users.
		#without this, you will have difficulties working on same images through different interfaces
	my $sha1 = getSha1($self->{realpath});

    $self->{pixelsAttr}->FileSHA1($sha1);

    return $status;
}


# this function appears to be depricated. its functionality has moved to store_image_metadata.
# this is because the size of the pixel array is now stored in 'Pixels' instead of 'Dimensions'.
# whoever wrote this should delete it when they get a chance.
#	-josiah <siah@nih.gov> June 9, 2003

# create and populate an image attributes object
sub store_image_attributes {
    my ($self, $href, $session) = @_;
    my $status = "";
    my $image = $self->{image};
    my $recordData = {#'image_id' => $image->id,
#		   'SizeX' => $href->{'Image.SizeX'},
#		   'SizeY' => $href->{'Image.SizeY'},
#		   'SizeZ' => $href->{'Image.SizeZ'},
#		   'SizeC' => $href->{'Image.NumWaves'},
#		   'SizeT' => $href->{'Image.NumTimes'},
#		   'BitsPerPixel' => $href->{'Image.BitsPerPixel'}
	};
    my $attributes = $session->Factory()->
	newAttribute("Dimensions",$image,$self->{module_execution},$recordData);

    if (!defined $attributes) {
	$status = "Can\'t create new image attribute table";
    }
    $self->{'attributes'} = $attributes;

    return $status;
}




# findRepository(session)
# -----------------------------------
# This function should determine, based on (currently) the size of the
# pixel array, which repository an image should be stored in.  For now
# we assume that there is only one repository.
# (Which, if the bootstrap script worked properly, will be the case.)

my $onlyRepository;

sub findRepository {
    return $onlyRepository if defined $onlyRepository;

    shift;
    my $session = shift;
    my @repositories = $session->Factory->findAttributes("Repository");
    $onlyRepository = $repositories[0];
    return $onlyRepository if defined $onlyRepository;
    die "Cannot find repository.";
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
    my $logical = $session->Factory()->
      newAttribute("LogicalChannel",$image,$self->{module_execution},
                   {
                    ExcitationWavelength   => $wave->{'WavelengthInfo.ExWave'},
                    EmissionWavelength   => $wave->{'WavelengthInfo.ExWave'},
                    Fluor    => $wave->{'WavelengthInfo.ExWave'},
                    NDFilter => $wave->{'WavelengthInfo.ExWave'},
                    PhotometricInterpretation => 'monochrome',
                   });

    my $component = $session->Factory()->
      newAttribute("PixelChannelComponent",$image,$self->{module_execution},
                   {
                    Pixels         => $self->{pixelsAttr}->id(),
                    Index          => $wave->{'WavelengthInfo.WaveNumber'},
                    LogicalChannel => $logical->id(),
                   });
    }

}
    

# Calculate & store the information about each xyz_image chunk into rows in xyz_image_info
# Calls external module OME_Image_XYZ_stats, whose location is hardwired to /OME/bin
# The module output is tab-delimited columns like so:
#    Wave Time Min Max Mean GeoMean Sigma Centroid_x Centroid_y Centroid_z
# The first line contains the column headings, and is discarded. Table row looks like:
# image_id | the_w | the_t | deltatime | min | max | mean | geomean | sigma | centroid_x | centroid_y | centroid_z

sub store_xyz_info {
    my ($self,$session,$href) = @_;

    my $factory = $session->Factory();
    my $view = $self->{config}->import_chain();
    # Right now this creates one new dataset for each image loaded in.
    # This is a horrible idea, and should be changed.
    my $image = $self->{'image'};
    my $image_map = $factory->
        newObject("OME::Image::DatasetMap",
                  {
                   image => $image,
                   dataset => $self->{dummy_dataset}
                  });

    if (!defined $view) {
        carp "The image import analysis chain is not defined.  Skipping predefined analyses...";
        return "";
    }

    my $engine = OME::Analysis::AnalysisEngine->new();
    eval {
        $engine->executeAnalysisView($session,$view,{},$self->{dummy_dataset});
    };
    return $@? $@ : "";
}



# store info about each file that was a component of this image
sub store_image_files_xyzwt {
    my ($self, $session, $href, $image_group_ref, $first_sha1) = @_;
    my $image = $self->{'image'};
    my $imageID = $image->id();
    print STDERR "new image id = $imageID\n";
    my $status = "";
    my $xyzwt;
    my $file;
    my $sth;
    my ($z, $w, $t);

    foreach $file (@$image_group_ref) {
	my $sha1;
	my $endian;
	my @col;

	$sha1 = $first_sha1 ? $first_sha1 : getSha1($file);
	$first_sha1 = 0;
	
	$endian = $href->{'Image_files_xyzwt.Endian'};
	$endian = ($endian eq "big") ? 't' : 'f' ;
	my $data = {'image_id' => $imageID,
			  'file_sha1' => $sha1,
			  'bigendian' => $endian,
			  'path' => $file,
			  'host' => "",
			  'url' => "",
			  'x_start' => 0,
			  'x_stop' => 0,
			  'y_start' => 0,
			  'y_stop' => 0,
			  'z_start' => 0,
			  'z_stop' => 0,
			  'w_start' => 0,
			  'w_stop' => 0,
			  't_start' => 0,
			  't_stop' => 0};

	$xyzwt = $session->Factory->newObject("OME::Image::ImageFilesXYZWT", $data);
	if (!defined $xyzwt) {
	    $status = "Can\'t create new image_files_xyzwt";
	}
	else {
	    #$xyzwt->path($file);
	    #$xyzwt->commit();
	    $xyzwt->storeObject();
	}
    }
    $self->{'xyzwt'} = $xyzwt;
    return $status;
}    


sub map_image_to_dataset {
    my $self = shift;
    my $image = $self->{image};
    my $ds = $self->{dataset};
    my $session = $self->{session};
    my $status = '';
    my $data = {'image_id'   => $image->id(),
		'dataset_id' => $ds->id()};
    
    my $i2dMap = $session->Factory->newObject("OME::Image::DatasetMap", $data);
    if (!defined $i2dMap) {
	$status = "Can\'t create new image <-> dataset map";
    }
    else {
	#$i2dMap->commit();
	$i2dMap->storeObject();
    }
    $self->{'i2dMap'} = $i2dMap;
    return $status;
}


# extract & return just the filename part of the passed path
sub name_only {
    my $basenm = basename($_[0]);
    # remove filetype extension from filename (assumes '.' delimiter)
    $basenm =~ s/\..+?$//;
    return $basenm;

}


# Stealth switch '--dupl' allows duplicate inputs. If it's not set, reject
# input file if it's already been imported.
sub check_for_duplicates {
    my ($self, $switch, $image_file) = @_;
    my ($dupl_name, $image_id, $sha1) = is_duplicate($self, $image_file);
    # the stealth switch '--dupl' allows duplicate input files
    if ($switch !~ /^--dupl/) {
	if ($dupl_name) {
	    return "\nThe source image $image_file is already in OME named $dupl_name, image_id = $image_id\n";
	}
    }
    return ("", $sha1);
}


# get the SHA1 digest of the passed file
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


sub temp_image_name {
    my $self = shift;
    $self->{tempfn} = shift if @_;
    return $self->{tempfn};
}

    


# Check if input file has already been processed 
# Always return the digest (sha1) since it's so expensive to calculate
sub is_duplicate {
    my $self = shift;
    my $infile = shift;

    my $sha1 = getSha1($infile);
    my $session = $self->{session};
    my $factory = $session->Factory();
    my $view = $factory->findObject("OME::Image::ImageFilesXYZWT",
				    file_sha1 => $sha1);
    if (defined $view) {
	my $id = $view->{image_id};
	$view = $factory->loadObject("OME::Image",$id);
	return ($view->{name}, $id, $sha1);
    } else {
	return ("", 0, $sha1);
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
