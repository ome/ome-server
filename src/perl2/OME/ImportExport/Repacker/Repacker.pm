# OME/ImportExport/Repacker/Repacker.pm

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
# Written by:  
#
#-------------------------------------------------------------------------------


package Repacker;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Repacker ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
use OME;
our $VERSION = $OME::VERSION;

bootstrap Repacker $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Repacker - Perl extension for manipulating vectors of values
that may be of different endianess.

=head1 SYNOPSIS

  use Repacker;


=head1 DESCRIPTION

The Repack routine takes in an arbitrary Perl string (vector) of
values with a particular endian-ness and # bytes/value, and
replaces the input string (in place) with a vector of the same 
values in the specified output endian-ness.

This is identical to performing a perl "unpack($infmt, $str)"
followed by a perl "pack($outfmt, $str)". However, it is
much faster.

Returns the number of values (not bytes) in the vector, or 0 if
an internal malloc() failed or if #bytes/value was not 1, 2,or 4.


=head2 EXPORT

None by default.


=head1 AUTHOR

 Author:  Brian S. Hughes  Open Microscopy Environment, MIT

=head1 SEE ALSO

L<perl>.

=cut
