#!/usr/bin/perl -w
#
# OME::ImportEngine::FileUtils.pm
#
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
# Written by:    Brian S. Hughes
#
#-------------------------------------------------------------------------------


#

=head1 NAME

 OME::ImportEngine::FileUtils - contains helper routines for file access


=head1 SYNOPSIS

  use OME::ImportEngine::FileUtils qw(/^.*/)
    or qw(routine_of_interest) 

=cut

# ---- Public routines -------
# seek_it()
# skip()
# read_it()
# seek_and_read()

# ---- Private routines ------

package OME::ImportEngine::FileUtils;
use strict;
use Carp;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use Exporter;
use base qw(Exporter);

our @EXPORT = qw( seek_it skip read_it seek_and_read );
our @EXPORT_OK = qw( seek_it skip read_it seek_and_read );

=head2 B<seek_it>
    seek_it($file_handle, $offset)

    Helper routine to position to a given offset within an open file.

=over 4

=item Input: S< > S< > S< > S< > file handle, offset from begining of file.

=item Output: S< > S< > S< > S< >status string. Null string if OK, else error msg.

=item Side effect: S< > file is positioned at requested offset

=back

=cut


sub seek_it {
    my $fh = shift;
    my $offset = shift;
    my $status = "";

    $status = "File seek error" 
	unless seek($fh, $offset, 0);

    return $status;
}



=head2 B<skip>
    skip($file_handle, $skip_length)

    Helper routine to skip ahead bytes in the passed file.

=over 4

=item Input: S< > S< > S< > S< > file handle,  # bytes to skip

=back

=cut

sub skip {
    my $fh = shift;
    my $skip_len = shift;
    my $status = "";

    $status = "File seek error" 
	unless seek($fh, $skip_len, 1);
    return $status;

}


=head2 B<read_it>
    $status = read_it($file_handle, $buffer, $length)

    Helper routine to do a file read, with error checking.

=over 4

=item Input: S< > S< > S< > S< > file handle, reference to input buffer, # bytes to read.

=item Output: S< > S< > S< > S< >status string. Null string if OK, else error msg.

=item Side effect: S< >  buffer gets filled

=back

=cut

sub read_it {
    my $fh = shift;
    my $buf = shift;
    my $len = shift;
    my $status = "";
    my $rd_len;

    if (ref($buf) eq "") {
	confess "Need to be passed a reference to a buffer";
    }
    $rd_len = read $fh, $$buf, $len;
    $status = "Error reading file"
	unless (defined $rd_len && $rd_len == $len);
    return $status;
}



=head2 B<seek_and_read>
    $status = seek_and_read($file_handle, $buffer, $offset, $length)

    Helper routine to move to a position within a file and do a read

=over 4

=item Input: S< > S< > S< > S< > file handle, input buffer, start offset, # bytes to read.

=item Output: S< > S< > S< > S< >status string. Null string if OK, else error msg.

=item Side effect: S< > buffer gets filled

=back

=cut

sub seek_and_read {
    my $fh = shift;
    my $buf = shift;
    my $offset = shift;
    my $len = shift;
    my $status = "";
    my $rd_len;

    $status = seek_it($fh, $offset);
    return $status
	unless $status eq "";
    return ($status = read_it($fh, $buf, $len));
}


=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut


1;

