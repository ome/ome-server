# OME/Image/Server/File.pm
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

package OME::Image::Server::File;

=head1 NAME

OME::File - interface for reading files

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::File);

use Carp;
use OME::Image::Server;
use Log::Agent;
use File::Spec;


use constant FILE_ID    => 0;
use constant FILENAME   => 1;
use constant LENGTH     => 2;
use constant CURSOR     => 3;
use constant PATH       => 4;
use constant REPOSITORY => 5;

=head1 DESCRIPTION

This class provides an implementation of the OME::File interface for
accessing files which have been uploaded to an OME image server.  The
file I/O is implemented via the OME::Image::Server class. 

=head1 METHODS

=head2 new

	my $file = OME::Image::Server::File->new($fileID);
	my $file = OME::Image::Server::File->new($fileID,$repository);
	my $file = OME::Image::Server::File->new($fileID,$repository,$path);
	my $file = OME::Image::Server::File->new($fileID,$path);

Opens an image server file for access via the OME::File interface.
The $repository parameter is a Repository attribute (OME::SemanticType subclass)
describing where the file object is stored.  If it is not provided, it is set
by calling OME::Session->instance()->findRemoteRepository().
The file itself must have already been uploaded to this image server;
it is specified by the file ID returned from the C<uploadFile> method.
The $path parameter is optional, and is used by the upload() method to
store the original path that was used for the upload.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($fileID,$param2,$param3) = @_;
    my ($repository,$path);

    if (ref ($param2)) {
    	$repository = $param2;
    } elsif (defined $param2) {
    	$path = $param2;
    }
    $path = $param3 if $param3 and not $path;

	$repository = OME::Session->instance()->findRemoteRepository()
		unless $repository;

    my $self = [];
    $self->[FILE_ID] = $fileID;
    $self->[FILENAME] = undef;
    $self->[LENGTH] = undef;
    $self->[CURSOR] = 0;
    $self->[PATH] = $path;
    $self->[REPOSITORY] = $repository;
    bless $self,$class;
    return $self;
}

=head2 upload

	my $file = OME::Image::Server::File->upload($localFile, $repository);

=cut

sub upload {
    my $proto = shift;
    my ($localFile,$repository) = @_;
	$repository = OME::Session->instance()->findRemoteRepository()
		unless $repository;

    return $localFile if UNIVERSAL::isa($localFile,__PACKAGE__);

    my $filename;
    if (!ref($localFile)) {
        $filename = $localFile;
    } elsif (UNIVERSAL::isa($localFile,'OME::LocalFile')) {
        $filename = $localFile->getFilename();
    } else {
        die "Cannot upload a non-local file";
    }

	die "Can't upload directory $filename" if -d $filename;
	die "Can't upload $filename: no such file" unless -e $filename;
	die "Can't upload $filename: not a regular file" unless -f $filename;
	die "Can't upload $filename: not readable" unless -r $filename;


    my $fileID = OME::Image::Server->uploadFile($repository,$filename);
    die "Could not upload file $filename" unless defined $fileID;
    return $proto->new($fileID,$repository,File::Spec->rel2abs($filename));
}

=head2 open

	$file->open($mode);

If asked to open the file for reading, this method does nothing.
(Image server files are always open.)  If asked to open the file for
writing, this method throws an error.  (Image server files are
read-only.)

=cut

sub open {
    my ($self,$mode) = @_;
    die "Cannot open on OME::Image::Server::File for writing"
      if exists $self->WRITE_MODES()->{$mode};
    $self->setCurrentPosition(0);
    return 1;
}

=head2 getFileID

	my $fileID = $file->getFileID();

=cut

sub getFileID { shift->[FILE_ID] }

=head2 getFilename

	my $filename = $file->getFilename();

Returns the full filename of the file object.  The result must look
like a legal filename.  However, tis filename does not necessarily
correspond to a file in the local filesystem; it should be used for
informational and display purposes only.

=cut

sub __loadInfo {
    my $self = shift;
    return if defined $self->[FILENAME];
    my ($filename,$length) = OME::Image::Server->
      getFileInfo($self->[REPOSITORY],$self->[FILE_ID]);
    $self->[FILENAME] = $filename;
    $self->[LENGTH] = $length;
    return;
}

sub getFilename {
    my $self = shift;
    $self->__loadInfo();
    return $self->[FILENAME];
}

sub getPath {
	return (shift->[PATH]);
}

=head2 getBaseFilename

	my $filename = $file->getBaseFilename();

Returns the base filename of the file object (i.e., excluding path and
extension).  As with the file's full filename, this does not
necessarily correspond to a file in the local filesystem.

A default implementation is provided for this method, which uses the
File::Basename module to extract the base filename from the result of
the getFilename method.

=cut

# inherit getBaseFilename from OME::File

=head2 getSHA1

	my $sha1 = $files->getSHA1();

Returns a SHA-1 digest of the entire file.

=cut

sub getSHA1 {
    my $self = shift;
    return OME::Image::Server->getFileSHA1($self->[REPOSITORY],$self->[FILE_ID]);
}

=head2 getRepository

	my $repository = $file->getRepository();

Returns the Repository attribute (OME::SemanticType subclass) describing where
the file object is stored ($repository->id() and $repository->ImageServerURL() are
useful methods).

=cut

sub getRepository {
	return (shift->[REPOSITORY]);
}

=head2 isReadable

	my $can_read = $file->isReadable();

Returns a boolean value indicating whether the file in question can be
read from.  (This corresponds to the file mode parameter of a
traditional C<open> call.)

=cut

sub isReadable { 1 }

=head2 isWriteable

	my $can_write = $file->isWriteable();

Returns a boolean value indicating whether the file in question can be
written to.  (This corresponds to the file mode parameter of a
standard C<open> call.)

=cut

sub isWriteable { 0 }

=head2 getLength

	my $length = $file->getLength();

Returns the length of the file in bytes.

=cut

sub getLength {
    my $self = shift;
    $self->__loadInfo();
    return $self->[LENGTH];
}

=head2 getCurrentPosition

	my $pos = $file->getCurrentPosition();

Returns the position of the file cursor.  This corresponds to a
standard C<tell> call.  This method should die if an error occurs or
if this operation is not supported.

=cut

sub getCurrentPosition { shift->[CURSOR] }

=head2 eof

		$file->eof();

Returns 1 if the file cursor is at end or past the end of the file. 
Returns 0 otherwise.

=cut

sub eof {
	my $self = shift;
	$self->__loadInfo(); # does nothing if info is already loaded
	
	return 1 if ($self->[CURSOR] >= $self->[LENGTH]-1);
	return 0;
}

=head2 setCurrentPosition

	$file->setCurrentPosition($position,[$whence]);

Sets the position of the file cursor.  This corresponds to a standard
C<seek> call.  The $whence parameter can be 0 to set it to an absolute
position from the start of the file in bytes (the default), 1 to set
it to a value relative to the current position, or 2 to set it to an
absolute position from the end of the file in bytes.  For the $whence
parameter you can use the SEEK_SET, SEEK_CUR, and SEEK_END constants
from the Fcntl module.  This method should die if an error occurs or
if this operation is not supported.

=cut

sub setCurrentPosition {
    my ($self,$newpos,$whence) = @_;
    my $curpos = $self->[CURSOR];
    $self->__loadInfo();
    my $length = $self->[LENGTH];
    if (!defined $whence || $whence == 0) {
        # $newpos is good
    } elsif ($whence == 1) {
        $newpos = $curpos+$newpos;
    } elsif ($whence == 2) {
        $newpos = $length+$newpos;
    } else {
        die "Illegal whence value";
    }

    die "Illegal position value: $newpos in file ".$self->[FILENAME].", length = $length"
      unless ($newpos >= 0) && ($newpos < $length);
    $self->[3] = $newpos;
}

=head2 readData

	my $data = $file->readData($length);
	my $data = $file->readData($offset,$length);

	my ($data,$bytes_read) = $file->readData($length);
	my ($data,$bytes_read) = $file->readData($offset,$length);

Reads data from the file.  If the file is not readable, this method
should die.  If called with one argument, data is read from the
current file position.  If called with two arguments, the
C<setCurrentPosition> method should be called first to set the current
file position.  In either case, upon a successful read, the current
file position will be just past the block of data read in.

If the method is called in scalar context, it returns the data read
from the file.  If the exact amount of data requested (in bytes)
cannot be read, for any reason, the method should die.

If the method is called in list context, it should try to read as much
data as possible, up to the requested amount, and return both the data
and the number of bytes actually read.  In this case, the method
should only die if a fatal error occurs, which prevents the read from
taking place at all.

=cut

sub readData {
    my ($self,$val1,$val2) = @_;

    my $length;

    # If there are two parameters, perform a seek first.
    if (defined $val2) {
        $self->setCurrentPosition($val1);
        $length = $val2;
    } else {
        $length = $val1;
    }

    Carp::confess "Cannot call readData without a length!"
      unless defined $length;

    # If called in void context, we don't need to read any data, but we
    # should seek past the data we would have read.
    unless (defined wantarray) {
        die "Could not read data: $!"
          unless $self->setCurrentPosition($length,1);
        return;
    }

    my $fileID = $self->[FILE_ID];
    my $curpos = $self->[CURSOR];
    my $buf = OME::Image::Server->readFile($self->[REPOSITORY],$fileID,$curpos,$length);
    die "Could not read data: $!" unless defined $buf;
    my $bytesRead = length($buf);
    $self->[CURSOR] += $bytesRead;

    if (wantarray) {
        return ($buf,$bytesRead);
    } else {
        die "Could not read data: only $bytesRead bytes read, not $length"
          unless $bytesRead == $length;
        return $buf;
    }
}

=head2 writeData

	$file->writeData($data);
	$file->writeData($offset,$data);

Writes data to the file.  If the file is not writeable, this method
should die.  If called with one argument, data is written to the
current file position.  If called with two arguments, the
C<setCurrentPosition> method should be called first to set the current
file position.  In either case, upon a successful write, the current
file position will be just past the block of data written.

The method will return with no return value if the write succeeded.
If there was any kind of error, the method will die.

=cut

sub writeData { die "Operation not supported" }

=head2 flush

	$file->flush();

Flushes any pending outputs to the file.  This corresponds to a
standard C<flush> call.  This method should die if any errors occur.

=cut

sub flush { return }

=head2 close

	$file->close();

Flushing any pending outputs and closes the file.  After this method
call, calling any other OME::File method should result in an error.

=cut

sub close { return }

=head2 delete

	$file->delete();

This will physically delete the file from the server.  Use with caution.
Note that making any subsequent server calls on this file will result in an error.

=cut

sub delete {
    my $self = shift;
    my $fileID;
	
	# N.B: why we have the eval? An OMEIS repository only allows deleteFile() 
	# to be called from local (not remote) connections. After ome import uploads
	# an image file that turns out to be of an unsupported format,
	# it needs to remove the file from the image repository by calling this delete()
	# function. If ome import uploaded the file to a remote OMEIS repository, then
	# that file cannot be deleted (i.e. OME::Image::Server->deleteFile() dies hence this
	# eval)
	
	# The longer term solution is a synchronization script that would be run locally on
	# the remote OMEIS to delete the left-over Files/Pixels. This script would be
	# written in perl, contain a list of OME servers this OMEIS services, connect via
	# Postgress user authentication to each OME server (so to have super-user/full access
	# to all Pixels/Files). The script would compare each FileID/PixelsID stored in OMEIS
	# against OME servers and see which Pixels/Files are un-neccessary and delete them.
    eval {
    	$fileID = OME::Image::Server->deleteFile($self->[REPOSITORY],$self->[FILE_ID]);
    };
    warn $@ if $@;

    return $fileID;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


