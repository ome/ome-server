# OME/File.pm
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

package OME::File;

=head1 NAME

OME::File - interface for reading files

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use File::Basename;

my %READ_MODES = map {$_,undef}
  ('','<','+<','+>','+>>','r','r+','w+','a+');
use constant READ_MODES => \%READ_MODES;

my %WRITE_MODES = map {$_,undef}
  ('+<','>','+>','>>','+>>','r+','w','w+','a','a+');
use constant WRITE_MODES => \%WRITE_MODES;

use overload
  '""' => "getFilename";

sub abstract { die __PACKAGE__." is an abstract class"; }

=head1 SYNOPSIS

=head1 DESCRIPTION

The OME::File interface provides a generalized way of reading files,
regardless of where those files are located.  Currently, the only two
implementations of the OME::File interface exist -- OME::LocalFile and
OME::Image::Server::File.

=head1 METHODS

=head2 open

	$file->open($mode);

Opens the file referred to by this object.  The mode parameter can be
either a Perl mode string (">", "+<", etc.) or an ANSI C fopen mode
string ("w", "r+", etc.).  If the open operation is not supported
(i.e., the file is always open), this method should return silently.
If an error occurs while opening the file, it should die.

=cut

sub open { abstract }

=head2 getFilename

	my $filename = $file->getFilename();

Returns the full filename of the file object.  The result must look
like a legal filename.  However, tis filename does not necessarily
correspond to a file in the local filesystem; it should be used for
informational and display purposes only.

=cut

sub getFilename { abstract }

=head2 getBaseFilename

	my $filename = $file->getBaseFilename();

Returns the base filename of the file object (i.e., excluding path and
extension).  As with the file's full filename, this does not
necessarily correspond to a file in the local filesystem.

A default implementation is provided for this method, which uses the
File::Basename module to extract the base filename from the result of
the getFilename method.

=cut

sub getBaseFilename { return basename(shift->getFilename()); }

=head2 getSHA1

	my $sha1 = $files->getSHA1();

Returns a SHA-1 digest of the entire file.

=cut

sub getSHA1 { abstract }

=head2 isReadable

	my $can_read = $file->isReadable();

Returns a boolean value indicating whether the file in question can be
read from.  (This corresponds to the file mode parameter of a
traditional C<open> call.)

=cut

sub isReadable { abstract }

=head2 isWriteable

	my $can_write = $file->isWriteable();

Returns a boolean value indicating whether the file in question can be
written to.  (This corresponds to the file mode parameter of a
standard C<open> call.)

=cut

sub isWriteable { abstract }

=head2 getLength

	my $length = $file->getLength();

Returns the length of the file in bytes.

=cut

sub getLength { abstract }

=head2 getCurrentPosition

	my $pos = $file->getCurrentPosition();

Returns the position of the file cursor.  This corresponds to a
standard C<tell> call.  This method should die if an error occurs or
if this operation is not supported.

=cut

sub getCurrentPosition { abstract }

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

sub setCurrentPosition { abstract }

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

sub readData { abstract }

=head2 writeData

	$file->writeData($data);
	$file->writeData($offset,$length);

Writes data to the file.  If the file is not writeable, this method
should die.  If called with one argument, data is written to the
current file position.  If called with two arguments, the
C<setCurrentPosition> method should be called first to set the current
file position.  In either case, upon a successful write, the current
file position will be just past the block of data written.

The method will return with no return value if the write succeeded.
If there was any kind of error, the method will die.

=cut

sub writeData { abstract }

=head2 flush

	$file->flush();

Flushes any pending outputs to the file.  This corresponds to a
standard C<flush> call.  This method should die if any errors occur.

=cut

sub flush { abstract }

=head2 close

	$file->close();

Flushing any pending outputs and closes the file.  After this method
call, calling any other OME::File method should result in an error.

=cut

sub close { abstract }

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


