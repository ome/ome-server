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


# importFiles(session,project,filenames)
# --------------------------------------

sub importFiles {
    my ($session,$project,$filenames) = @_;

    return unless
        (defined $session) &&
        (defined $project) &&
        (defined $filenames);

    my @images;

    my $lambda = sub {
        my ($href, $aref) = @_;

        # determine which repository the new image should be placed in
        my $repository = findRepository($session,$aref);
        my $image = $session->Factory->createObject("OME::Image");
        $image->Field("name",$href->{Image.Name});
        $image->Field("description",$href->{Image.Description});
        $image->Field("experimenter",$session->User());
        $image->Field("created",$href->{Image.CreationDate});
        $image->Field("inserted","now");
        $image->Field("repository",$repository);
        $image->Field("sizeX",$href->{Image.SizeX});
        $image->Field("sizeY",$href->{Image.SizeY});
        $image->Field("sizeZ",$href->{Image.SizeZ});
        $image->Field("sizeW",$href->{Image.NumWaves});
        $image->Field("sizeT",$href->{Image.NumTimes});

        my $path = $image->Field("id").".ome";
        $image->Field("path",$path);

        my $handle = new IO::File;
        open $handle, ">" . $repository->Field("path") . $path or
            die "Error creating repository file";

        # Assume array ref is 4-dimensional, 5th (ie, X) dimension
        # being a packed string of 16-bit integers.
        for (my $t = 0; $t < $href->{Image.NumTimes}; $t++)
        {
            for (my $w = 0; $w < $href->{Image.NumTimes}; $w++)
            {
                for (my $z = 0; $z < $href->{Image.NumTimes}; $z++)
                {
                    for (my $y = 0; $y < $href->{Image.NumTimes}; $y++)
                    {
                        print $handle $aref->[$t][$w][$z][$y];
                    }
                }
            }
        }

        close $handle;

        $image->writeObject();
        $session->DBH()->commit();
    };

    my $importer = OME::ImportExport::Importer->new($filenames,$project,$lambda);
}


# findRepository(session,pixel array)
# -----------------------------------
# For now we assume that there is only one repository, with an ID of 0.

my $onlyRepository;

sub findRepository {
    return $onlyRepository if defined $onlyRepository;
    
    my ($session, $aref) = @_;
    $onlyRepository = $session->Factory()->loadObject("OME::Repository",0);
    return $onlyRepository if defined $onlyRepository;
    die "Cannot find repository #0.";
}


1;
