#!/usr/bin/perl -w
#
# OME/ImportExport/FileUtils.pm
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

# This class contains the helper routines for file access

# ---- Public routines -------
# seek_it()
# skip()
# read_it()
# seek_and_read()

# ---- Private routines ------

package OME::ImportExport::FileUtils;
use strict;
use Carp;
use vars qw($VERSION);
$VERSION = 2.000_000;


# helper routine to position to a given offset within an open file
# Input: file handle, offset.
# Output: status string. Null string if OK, else error msg.
# Side effect: file is positioned at requested offset
# seek always done from begining of file.

sub seek_it {
    my $fh = shift;
    my $offset = shift;
    my $status = "";

    $status = "File seek error" 
	unless seek($fh, $offset, 0);

    return $status;
}


sub skip {
    my $fh = shift;
    my $skip_len = shift;
    my $buf;

    read $fh, $buf, $skip_len;
}

# helper routine to do a file read, with error checking.
# Input: file handle, buffer for input, and # bytes to read.
# Output: status string. Null string if OK, else error msg.
# Side effect: buffer gets filled
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


# helper routine to move to a position within a file and do a read, with error checking.
# Input: file handle, buffer for input, start offset in file, and # bytes to read.
# Output: status string. Null string if OK, else error msg.
# Side effect: buffer gets filled

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

1;

