# OME/LocalFile.pm
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

package OME::LocalFile;

=head1 NAME

OME::File - interface for reading files

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::File);

use IO::File;

use constant HANDLE   => 0;
use constant FILENAME => 1;
use constant MODE     => 2;

=head1 DESCRIPTION

This class provides an implementation of the OME::File interface for
accessing files in the local filesystem.

=head1 METHODS

=head2 new

	my $file = OME::LocalFile->new($filename);

Creates a new OME::File which refers to a file on the local
filesystem.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($filename) = @_;

    my $self = [undef,$filename,undef];
    bless $self,$class;
    return $self;
}

=head2 open

	$file->open($mode);
	my $file = OME::LocalFile->open($filename,$mode);

Opens a local file for access via the OME::File interface.  This
method can be called as a constructor, to create a new file object and
immediately open it; or can be called on an already-created object to
open it.  The mode parameter can be either a Perl mode string (">",
"+<", etc.) or an ANSI C fopen mode string ("w", "r+", etc.).  If any
errors occur, this method will die.

=cut

sub open {
    my $class = shift;
    my $mode;
    my $self;

    if (!ref($class)) {
        my $filename;
        ($filename,$mode) = @_;
        $self = [undef,$filename,undef];
        bless $self,$class;
    } else {
        ($mode) = @_;
        $self = $class;
    }

    die "File already opened!" if defined $self->[HANDLE];

    my $file = IO::File->new($self->[FILENAME],$mode)
      or die "Error opening ".$self->[FILENAME]." with mode $mode: $!";
    $self->[HANDLE] = $file;
    $self->[MODE]   = $mode;

    return $self;
}

=head2 getFilename

	my $filename = $file->getFilename();

Returns the full filename of the file object.  For OME::LocalFile,
this is the location of the file in the local filesystem; this
filename can be passed to the standard file-I/O routines to access the
file without going through the OME::File interface.

=cut

sub getFilename { shift->[FILENAME]; }

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
    my $filename = $self->[FILENAME];

    my $cmd = "openssl sha1 $filename |";
    my $sh;
    my $sha1;

    CORE::open (STDOUT_PIPE,$cmd);
    chomp ($sh = <STDOUT_PIPE>);
    $sh =~ m/^.+= +([a-fA-F0-9]*)$/;
    $sha1 = $1;
    close (STDOUT_PIPE);

    return $sha1;
}

=head2 isReadable

	my $can_read = $file->isReadable();

Returns a boolean value indicating whether the file in question can be
read from.  (This corresponds to the file mode parameter of a
traditional C<open> call.)

=cut

sub isReadable {
    my $self = shift;
    my $mode = $self->[MODE];
    return defined $mode && exists $self->READ_MODES()->{$mode};
}

=head2 isWriteable

	my $can_write = $file->isWriteable();

Returns a boolean value indicating whether the file in question can be
written to.  (This corresponds to the file mode parameter of a
standard C<open> call.)

=cut

sub isWriteable {
    my $self = shift;
    my $mode = $self->[MODE];
    return defined $mode && exists $self->WRITE_MODES()->{$mode};
}

=head2 getLength

	my $length = $file->getLength();

Returns the length of the file in bytes.

=cut

sub getLength { -s shift->[FILENAME] }

=head2 getCurrentPosition

	my $pos = $file->getCurrentPosition();

Returns the position of the file cursor.  This corresponds to a
standard C<tell> call.  This method should die if an error occurs or
if this operation is not supported.

=cut

sub getCurrentPosition {
    my $fh = shift->[HANDLE];
    die "File not open!" unless defined $fh;
    return $fh->tell();
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
    my ($self,$pos,$whence) = @_;
    my $fh = $self->[HANDLE];
    $whence ||= 0;
    die "File not open!" unless defined $fh;
    $fh->seek($pos,$whence);
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

    my $fh = $self->[HANDLE];
    die "File not open!" unless defined $fh;
    my $length;

    # If there are two parameters, perform a seek first.
    if (defined $val2) {
        $fh->seek($val1,0);
        $length = $val2;
    } else {
        $length = $val1;
    }

    # If called in void context, we don't need to read any data, but we
    # should seek past the data we would have read.
    unless (defined wantarray) {
        die "Could not read data: $!" unless $fh->seek($length,1);
        return;
    }

    my $buf;
    my $bytesRead = $fh->read($buf,$length);
    die "Could not read data: $!" unless defined $bytesRead;

    if (wantarray) {
        return ($buf,$bytesRead);
    } else {
        die "Could not read data: only $bytesRead bytes read, not $length"
          unless $bytesRead == $length;
        return $buf;
    }
}

=head2 readLine

	my $line = $file->readLine();

Reads data from the file from the current position (as set by the
C<setCurrentPosition> method) up to the first occurrence of the C<$/>
variable.  If C<$/> is set to "", C<\n> will be used as the line
terminator.

=cut

sub readLine {
    my ($self) = @_;

    my $fh = $self->[HANDLE];
    die "File not open!" unless defined $fh;

    return <$fh>;
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

sub writeData {
    my ($self,$val1,$val2) = @_;

    my $fh = $self->[HANDLE];
    die "File not open!" unless defined $fh;
    my $data;

    # If there are two parameters, perform a seek first.
    if (defined $val2) {
        $fh->seek($val1,0);
        $data = $val2;
    } else {
        $data = $val1;
    }

    $fh->print($data) or die "Could not write data: $!";
    return;
}

=head2 flush

	$file->flush();

Flushes any pending outputs to the file.  This corresponds to a
standard C<flush> call.  This method should die if any errors occur.

=cut

sub flush {
    my $fh = shift->[HANDLE];
    die "File not open!" unless defined $fh;
    $fh->flush() or die "Could not flush: $!";
}

=head2 close

	$file->close();

Flushing any pending outputs and closes the file.  After this method
call, calling any other OME::File method should result in an error.

=cut

sub close {
    my $self = shift;
    my $fh = $self->[HANDLE];
    die "File not open!" unless defined $fh;
    $fh->close() or die "Could not close: $|";
    $self->[HANDLE] = undef;
    $self->[MODE]   = undef;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


