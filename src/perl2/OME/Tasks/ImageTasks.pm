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
        $session->DBH()->commit();
    };

    my $importer = OME::ImportExport::Importer->new($filenames,$project,$lambda);
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
