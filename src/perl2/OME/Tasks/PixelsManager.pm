# OME/Tasks/PixelsManager.pm
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

package OME::Tasks::PixelsManager;

=head1 NAME

OME::Tasks::PixelsManager

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Image;
use OME::ModuleExecution;
use Log::Agent;

use OME::File;
use OME::Image::Pixels;
use OME::Image::LocalPixels;
use OME::Image::Server::Pixels;

use File::Spec;

# $PIXEL_TYPES{$bytesPerPixel}{$isSigned}{$isFloat}
our %PIXEL_TYPES;

$PIXEL_TYPES{1}{1}{1} = 'signed byte float?';
$PIXEL_TYPES{1}{0}{1} = 'unsigned byte float?';
$PIXEL_TYPES{1}{1}{0} = 'int8';
$PIXEL_TYPES{1}{0}{0} = 'uint8';

$PIXEL_TYPES{2}{1}{1} = 'float';
$PIXEL_TYPES{2}{0}{1} = 'unsigned float?';
$PIXEL_TYPES{2}{1}{0} = 'int16';
$PIXEL_TYPES{2}{0}{0} = 'uint16';

$PIXEL_TYPES{4}{1}{1} = 'double';
$PIXEL_TYPES{4}{0}{1} = 'unsigned double?';
$PIXEL_TYPES{4}{1}{0} = 'int32';
$PIXEL_TYPES{4}{0}{0} = 'uint32';

=head1 SYNOPSIS

=head1 DESCRIPTION

The OME::Image::Pixels interface provides a generalized way of reading
and writing to pixels files.  This is provided as a generic class to
ease the transition from a local image repository to the image server.
There are currently two implementations of this interface --
OME::Image::LocalPixels and OME::Image::Server::Pixels.

A pixels file has an explicitly defined life cycle: It can only be
written to immediately after creation.  Once the writing has finished,
and the pixels marked as complete, they cannot be written to anymore.
Further, they cannot be read from until the writing phase is finished.

=head1 METHODS

=cut

sub createOriginalFileAttribute {
    my $proto = shift;
    my ($file,$format,$mex) = @_;
    my $factory = OME::Session->instance()->Factory();

    if (UNIVERSAL::isa($file,'OME::LocalFile')) {
        my $filename = $file->getFilename();

        # See if we've already created an attribute for this file with
        # the same MEX.

        my $attr = $factory->
          findAttribute('OriginalFile',
                        {
                         module_execution => $mex,
                         Repository       => undef,
                         Path             => $filename,
                        });
        return $attr if defined $attr;

        # Nope, create a new one.

        return $factory->
          newAttribute('OriginalFile',undef,$mex,
                       {
                        Repository => undef,
                        Path       => $filename,
                        FileID     => undef,
                        SHA1       => $file->getSHA1(),
                        Format     => $format,
                       });
    } elsif (UNIVERSAL::isa($file,'OME::Image::Server::File')) {
        my $server_path = OME::Image::Server->getServerPath();
        $server_path = $server_path->as_string()
          if UNIVERSAL::isa($server_path,'URI');

        my $repository = $factory->
          findAttribute('Repository',
                        {
                         IsLocal        => 0,
                         ImageServerURL => $server_path,
                        });
        die "Cannot find a repository entry for the active image server"
          unless defined $repository;
        my $fileID = $file->getFileID();

        # See if we've already created an attribute for this file with
        # the same MEX.

        my $attr = $factory->
          findAttribute('OriginalFile',
                        {
                         module_execution => $mex,
                         Repository       => $repository,
                         FileID           => $fileID,
                        });
        return $attr if defined $attr;

        # Nope, create a new one.

        return $factory->
          newAttribute('OriginalFile',undef,$mex,
                       {
                        Repository => $repository,
                        Path       => undef,
                        FileID     => $file->getFileID(),
                        SHA1       => $file->getSHA1(),
                        Format     => $format,
                       });
    }
}

sub loadOriginalFile {
    my $proto = shift;
    my ($attr) = @_;
    my $repository = $attr->Repository();

    if ($repository->IsLocal()) {
        return OME::LocalFile->new($attr->Path());
    } else {
        $proto->activateRepository($repository);
        return OME::Image::Server::File->new($attr->FileID());
    }
}

sub findRepository {
    my $proto = shift;
    my $factory = OME::Session->instance()->Factory();
    my $repository = $factory->findAttribute('Repository');
    die "Are there really no repositories in the system?  Why not?"
      unless defined $repository;
    return $repository;
}

sub createPixels {
    my $proto = shift;

    my $repository = $proto->findRepository();
    return $repository->IsLocal()?
      $proto->localCreatePixels($repository,@_):
      $proto->serverCreatePixels($repository,@_);
}

sub loadPixels {
    my $proto = shift;
    my ($attr) = @_;
    die "loadPixels needs a Pixels attribute"
      unless UNIVERSAL::isa($attr,'OME::SemanticType::Superclass')
        && $attr->verifyType('Pixels');

    my $repository = $attr->Repository();
    return $repository->IsLocal()?
      $proto->localLoadPixels($attr):
      $proto->serverLoadPixels($attr);
}

sub findLocalRepository {
    my $proto = shift;
    my $factory = OME::Session->instance()->Factory();
    my $repository = $factory->
      findAttribute('Repository',
                    {
                     IsLocal => 1,
                    });
    die "Are there really no repositories in the system?  Why not?"
      unless defined $repository;
    return $repository;
}

sub localCreatePixels {
    my $proto = shift;
    my ($repository,$image,$mex,
        $xx,$yy,$zz,$cc,$tt,$bbp,$signed,$float) = @_;
    my $factory = OME::Session->instance()->Factory();

    # Find a local repository to store this pixels file in.
    $repository = $proto->findLocalRepository()
      unless defined $repository;
    my $path = $repository->Path();

    # Find a unique filename for the new pixels
    my $time = time();
    my $nonce = 0;
    my $filename = "${time}-${nonce}-$$.ori";
    my $pathname = File::Spec->catfile($path,$filename);
    while (-e $pathname) {
        $nonce++;
        $filename = "${time}-${nonce}-$$.ori";
        $pathname = File::Spec->catfile($path,$filename);
    }

    my $pixels = OME::Image::LocalPixels->
      new($pathname,$xx,$yy,$zz,$cc,$tt,
          $bbp,$signed,$float,OME->BIG_ENDIAN());
    my $attr = $factory->
      newAttribute('Pixels',$image,$mex,
                   {
                    SizeX          => $xx,
                    SizeY          => $yy,
                    SizeZ          => $zz,
                    SizeC          => $cc,
                    SizeT          => $tt,
                    BitsPerPixel   => $bbp*8,
                    PixelType      => $PIXEL_TYPES{$bbp}{$signed}{$float},
                    FileSHA1       => undef,
                    Repository     => $repository,
                    Path           => $filename,
                    ImageServerID  => undef,
                   });

    return ($pixels,$attr);
}

sub loadLoadPixels {
    my $proto = shift;
    my ($attr) = @_;

    my $repository = $attr->Repository();
    my $repPath = $repository->Path();
    my $pixPath = $attr->Path();

    my $pathname = File::Spec->catfile($repPath,$pixPath);
    return OME::Image::LocalPixels->open($pathname);
}

my $active_repository = undef;

sub activateRepository {
    my $proto = shift;
    my ($repository) = @_;
    die "Cannot activate a local repository"
      if $repository->IsLocal();

    # If we've already activated this repository, there's nothing to do.
    return if (defined $active_repository &&
               $repository->id() == $active_repository->id());

    my $url = $repository->ImageServerURL();
    if ($url =~ m,^/,) {
        # This looks vaguely like a local path
        OME::Image::Server->useLocalServer($url);
    } elsif ($url =~ m,^http://,) {
        # This looks vaguely like an HTTP URL
        OME::Image::Server->useRemoteServer($url);
    } else {
        # This looks weird
        die "I don't think I support an image server URL of $url";
    }

    $active_repository = $repository;
    return;
}

sub findServerRepository {
    my $proto = shift;
    my $factory = OME::Session->instance()->Factory();
    my $repository = $factory->
      findAttribute('Repository',
                    {
                     IsLocal => 0,
                    });
    die "Are there really no repositories in the system?  Why not?"
      unless defined $repository;
    return $repository;
}

sub serverCreatePixels {
    my $proto = shift;
    my ($repository,$image,$mex,
        $xx,$yy,$zz,$cc,$tt,$bbp,$signed,$float) = @_;
    my $factory = OME::Session->instance()->Factory();

    $repository = $proto->findServerRepository()
      unless defined $repository;
    $proto->activateRepository($repository);

    my $pixels = OME::Image::Server::Pixels->
      new($xx,$yy,$zz,$cc,$tt,$bbp,$signed,$float);
    my $attr = $factory->
      newAttribute('Pixels',$image,$mex,
                   {
                    SizeX          => $xx,
                    SizeY          => $yy,
                    SizeZ          => $zz,
                    SizeC          => $cc,
                    SizeT          => $tt,
                    BitsPerPixel   => $bbp*8,
                    PixelType      => $PIXEL_TYPES{$bbp}{$signed}{$float},
                    FileSHA1       => undef,
                    Repository     => $repository,
                    Path           => undef,
                    ImageServerID  => $pixels->getPixelsID(),
                   });
    return ($pixels,$attr);
}

sub serverLoadPixels {
    my $proto = shift;
    my ($attr) = @_;

    my $repository = $attr->Repository();
    $proto->activateRepository($repository);
    return OME::Image::Server::Pixels->open($attr->ImageServerID());
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut



