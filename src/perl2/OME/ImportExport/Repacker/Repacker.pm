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
our $VERSION = 2.000_000;

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
