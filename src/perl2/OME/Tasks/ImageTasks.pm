# OME/Tasks/ImageTasks.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Tasks::ImageTasks;

use OME::Session;
use OME::Image;
use OME::ImportExport::Importer;
use IO::File;


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
            print STDERR "   $key $replaced\n";
            $anyRemoved = $replaced if $replaced;
        }
    }

    return $anyRemoved;
}


# importFiles(session,project,filenames)
# --------------------------------------
# Imports the selected files into OME.  The session is used to
# interact with the database, and all of the images are assigned to
# the given project.

sub importFiles {
    my ($session,$project,$filenames) = @_;

    return unless
        (defined $session) &&
        (defined $project) &&
        (defined $filenames);

    my @images;

    my $lambda = sub {
        my ($href, $aref) = @_;

        if (removeWeirdCharacters($href)) {
            warn "Weird characters in the metadata hash!  Did the import work properly?";
        }
        
        # determine which repository the new image should be placed in
        my $repository = findRepository($session,$aref);
        my $image = $session->Factory->newObject("OME::Image");
        my $imageID = $image->ID();
        print STDERR "Created new image #" . $imageID . "\n";
        my $name = $href->{'Image.Name'};
        $name = "Image" . $imageID unless $name;
        $image->Field("name",$name);
        $image->Field("description",$href->{'Image.Description'});
        $image->Field("experimenter",$session->User());
        #my $created = $href->{'Image.CreationDate'};
        #$created = "now" unless $created;
        my $created = "now";   # until we figure out the date formatting issue
        $image->Field("created",$created);
        $image->Field("inserted","now");
        $image->Field("repository",$repository);
        $image->Field("sizeX",$href->{'Image.SizeX'});
        $image->Field("sizeY",$href->{'Image.SizeY'});
        $image->Field("sizeZ",$href->{'Image.SizeZ'});
        $image->Field("sizeW",$href->{'Image.NumWaves'});
        $image->Field("sizeT",$href->{'Image.NumTimes'});
        $image->Field("bitsPerPixel",16);


        my $path = $imageID.".orf";
        $image->Field("path",$path);

        my $handle = new IO::File;
        my $realpath = ">".$repository->Field("path").$path;
        print STDERR "$realpath\n";
        print STDERR "$repository\n";
        open $handle, $realpath or die "Error creating repository file";

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

        print STDERR "\n";

        $image->writeObject();

	# IGG 10/06/02:  Put in a direct INSERT to deal with WavelengthInfo - until we get our API stabilized.
	# The DB needs to be consistent with regards to image_wavelengths, xy_image_info, and xyz_image_info.
	# These three tables need to be populated consistently with how many dimentions there are in the image.
	# I'm leaning towards forcing all the relevant tuples to exist in the DB, even if all columns are NULL.
	# We can do it with a rule in the DB so that an image can't be commited unless those tables have exactly
	# the right number  tuples to satisfy all of the dimensions in the image.
	# At the very least, if any tuples exist in these tables for a given image, all tuples must exist - All or nothing.
	# It would make things cleaner in many cases if they all exist anyway.
	#
	# Anyway, we need to make sure there is a WavelengthInfo array, that it has all the WaveNumber fields necessary,
	# and that its in the right order.
	# Also, we're only doing image_wavelengths for now.
    #  image_id | wavenumber | ex_wavelength | em_wavelength | nd_filter | fluor

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


	# IGG 10/07/02:  Run an external program to get image statistics, and stuff them into the DB.
    # The external program is called OME_Image_XYZ_stats, and hopefully lives in /OME/bin.
    # The table we're filling up is xyz_image_info:
    # image_id | wavenumber | timepoint | deltatime | min | max | mean | geomean | sigma | centroid_x | centroid_y | centroid_z
    # The program output is tab-delimited columns like so:
    # Wave    Time    Min     Max     Mean    GeoMean Sigma   Centroid_x      Centroid_y      Centroid_z
    # The first line contains the column headings.

    $sth = $session->DBH()->prepare (
        'INSERT INTO xyz_image_info (image_id,wavenumber,timepoint,min,max,mean,geomean,sigma,centroid_x,centroid_y,centroid_z) VALUES (?,?,?,?,?,?,?,?,?,?,?)');
    my $Dims = join (',',($href->{'Image.SizeX'},$href->{'Image.SizeY'},$href->{'Image.SizeZ'},
        $href->{'Image.NumWaves'},$href->{'Image.NumTimes'},$image->Field("bitsPerPixel")/8)
    );
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

        
    $session->DBH()->commit();

    };

    my $importer = OME::ImportExport::Importer->new($filenames,$lambda);
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


1;
