# OME/Matlab.pm

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


package OME::Matlab;

require 5.005_62;
use strict;
use warnings;

=head1 NAME

OME::Matlab - Perl interface to Matlab

=head1 SYNOPSIS

	use OME::Matlab;

	my $array = OME::Matlab::Array->newDoubleScalar(4);
	my $engine = OME::Matlab::Engine->open();
	my $outBuffer = " " x 512;
	
	$engine->setOutputBuffer($outBuffer, length($outBuffer));
	$engine->putVariable('x', $array);
	$engine->eval('y = x .* 8;');
	
	my $output = $engine->getVariable('y');
	print "Matlab's Output:\n $outBuffer\n";
	
=head1 DESCRIPTION

The OME::Matlab::* packages provide a Perl interface to an embedded
instance of Matlab.  This is basically just a series of XSUB wrappers
around Matlab's libmx and libeng libraries.  The OME::Matlab::Array
class provides a Perl object-oriented interface to the libmx library,
allowing Perl code to create Matlab variables.  The
OME::Matlab::Engine class provides a Perl interface to the libeng
library, which provides the Matlab embedding logic.

=head1 OME::Matlab::Array - CREATING MATLAB MATRICES

Every value in Matlab is an instance of some kind of matrix.  Scalars
are represented by 1x1 matrices; one-dimensional arrays can be
represented either by 1xn row vectors or by mx1 column vectors.
Multi-dimensional (i.e., third-order or greater) matrices are also
allowed, but are not seen as often.

In addition to its order and dimensions, each matrix also has a
I<class>, which corresponds the more common meaning of "type".  Almost
all numeric matrices in Matlab have a class of C<double>.  It is also
possible to have numeric matrices of type C<single>, and of many
flavors of integer (signed or unsigned, and 8, 16, or 32 bit).  There
also seem to be classes reserved for future support of 64-bit integer
values, but these are not implemented yet in the Matlab libraries.
Most mathematical operations, however, are only defined on C<doubles>,
so these other numeric classes are usually not that useful.

A numeric matrix can either be I<real> or I<complex>.  A complex
matrix stores two values of the appropriate class for each entry in
the matrix.  These two values correspond to a rectangular complex
number -- C<a + bi>, where C<i> equals the square root of -1.

Another common class is C<logical>, which refers to Boolean values.
Note that unlike Perl, C<logical> matrices are truly distinct from the
numeric classes; it is not the case that any numeric matrix can be
evaluated as a C<logical> matrix by looking for non-zero values.
Logical matrices are most commonly created by Matlab's logical
operators, but other functions can return them as well.

Strings are represented in Matlab by a row-vector of class C<char>.
Each character of the string is encoded as one entry in the matrix.
An array of strings is usually encoded as a two-dimensional C<char>
matrix, where the number of rows is the number of strings in the
array, and the number of columns is the length of the longest string
in the array.  All of the other strings are right-padded with spaces
to make the matrix properly rectangular.

The C<struct> class is similar to C<structs> in C.  They contain
fields, each of which contains another matrix.  In a matrix of
C<structs>, there are no extra constraints enforced on the values for
any field.  In other words, the value for field A in the first element
of a C<struct> matrix does not have to have the same order,
dimensions, or even class, as field A in the any other element.

The C<cell> class can be used to create a Matlab matrix with no
constraints on its contents -- each element of the matrix is another
matrix, of any order, dimensions, and class.

The remaining classes -- C<object> and C<function> -- are not used
very often.  For more details, consult the Matlab documentation.

B<NOTE:> In the Matlab library code, and in this document, the terms
I<matrix> and I<array> are usually used interchangably.  The only
exception is in the case of the OME::Matlab::Array constructors, in
which case the term I<matrix> implies a matrix with exactly two
dimensions, whereas I<array> implies a matrix of any order.  The term
I<scalar> always refers to a single-order, one-element matrix.

=head2 Useful constants

The libmx library declares an enumeration for all of the matrix
classes, and another to signify whether a matrix is real of complex.
These enumerations are available in Perl as a series of scalar
variables, described below.  By using the OME::Matlab package without
any import clause:

	use OME::Matlab;

you automatically have all of the constants in your namespace, and can
use them without qualification:

	print $mxCHAR_CLASS;

To require the OME::Matlab package without importing these constants,
use an empty list for the import clause:

	use OME::Matlab ();

You can also use the C<:complexities> and C<:classes> import tags to
only import one set of constants:

	use OME::Matlab qw(:complexities);

=head2 Matrix class constants (C<:classes>)

=over

=item $mxUNKNOWN_CLASS

=item $mxCELL_CLASS

=item $mxSTRUCT_CLASS

=item $mxOBJECT_CLASS

=item $mxCHAR_CLASS

=item $mxLOGICAL_CLASS

=item $mxDOUBLE_CLASS

=item $mxSINGLE_CLASS

=item $mxINT8_CLASS

=item $mxUINT8_CLASS

=item $mxINT16_CLASS

=item $mxUINT16_CLASS

=item $mxINT32_CLASS

=item $mxUINT32_CLASS

=item $mxINT64_CLASS

=item $mxUINT64_CLASS

=item $mxFUNCTION_CLASS

=back

=head2 Complexity constants (C<:complexities>)

=over

=item $mxREAL

=item $mxCOMPLEX

=back

=head2 Creating a matrix

There are a number of constructors for OME::Matlab::Array.  They allow
you to create Matlab matrices of all of the supported classes, except
for C<object> and C<function>.  There are also convenience
constructors to create scalars and second-order matrices of most of
the classes.

=head2 newDoubleScalar

	my $array = OME::Matlab::Array->newDoubleScalar($value);

Creates a new scalar matrix of class C<double>, and initializes its
only element to the value provided.

=head2 newComplexScalar

	my $array = OME::Matlab::Array->newComplexScalar($real,$imaginary);

Creates a new scalar complex matrix of class C<double>, and
initializes its only element to the value provided.

B<This method is not yet written -- holler at Doug>

=head2 newNumericScalar

	my $array = OME::Matlab::Array->newNumericScalar($value,
	                                                 [$class],
	                                                 [$complexity]);

Creates a new numeric scalar of arbitrary class and complexity.  If
$class and/or $complexity are not specified, they default to C<double>
and I<real>, respectively.  If $complexity is $mxCOMPLEX, then two
values must be given.

B<This method is not yet written -- holler at Doug>

=head2 newLogicalScalar

	my $array = OME::Matlab::Array->newLogicalScalar($value);

Creates a new scalar matrix of class C<logical>, and initializes its
only element to the value provided.  As is usual in Perl, a value of 0
signifies I<false>; any other value signifies I<true>.

=head2 newStringScalar

	my $array = OME::Matlab::Array->newStringScalar($value);

Creates a new row-vector of class C<char>.  Its height will be one,
and its width will be the length of the string provided.  Its element
will be assigned the values of the string.

=head2 newDoubleMatrix

	my $array = OME::Matlab::Array->newDoubleMatrix($m,$n,[$complexity]);

Creates a new $m x $n matrix of class C<double> and the specified
complexity.  (The complexity defaults to I<real> if unspecified.)

=head2 newNumericMatrix

	my $array = OME::Matlab::Array->newNumericMatrix($m,$n,[$class],[$complexity]);

Creates a new $m x $n matrix of the specified class and complexity.  
(defaults to C<double> and I<real> resp)

=head2 newNumericArray

	my $array = OME::Matlab::Array->newNumericArray($class,$complexity,@dim);

Creates a multidimensional matrix of the specified type $class and $complexity 
(defaults to C<double> and I<real> resp). The matrix has scalar(@dim) dimensions as
@dim is the dimesions list. Each element in the dimesions listg contains the size 
of the array in the dimension.

=head2 Memory management

=cut

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS =
  (complexities => [qw(
                       $mxREAL $mxCOMPLEX
                      )],
   classes      => [qw(
                       $mxUNKNOWN_CLASS $mxCELL_CLASS $mxSTRUCT_CLASS
                       $mxOBJECT_CLASS $mxCHAR_CLASS $mxLOGICAL_CLASS
                       $mxDOUBLE_CLASS $mxSINGLE_CLASS $mxINT8_CLASS
                       $mxUINT8_CLASS $mxINT16_CLASS $mxUINT16_CLASS
                       $mxINT32_CLASS $mxUINT32_CLASS $mxINT64_CLASS
                       $mxUINT64_CLASS $mxFUNCTION_CLASS
                      )],
  );

$EXPORT_TAGS{constants} = [
                           @{$EXPORT_TAGS{'complexities'}},
                           @{$EXPORT_TAGS{'classes'}}
                          ];

$EXPORT_TAGS{all} = [
                     @{$EXPORT_TAGS{'complexities'}},
                     @{$EXPORT_TAGS{'classes'}}
                    ];

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = (@{$EXPORT_TAGS{'constants'}});

use OME;
our $VERSION = $OME::VERSION;

our ($mxREAL,$mxCOMPLEX);
our ($mxUNKNOWN_CLASS,$mxCELL_CLASS,$mxSTRUCT_CLASS,$mxOBJECT_CLASS,
     $mxCHAR_CLASS,$mxLOGICAL_CLASS,$mxDOUBLE_CLASS,$mxSINGLE_CLASS,
     $mxINT8_CLASS,$mxUINT8_CLASS,$mxINT16_CLASS,$mxUINT16_CLASS,
     $mxINT32_CLASS,$mxUINT32_CLASS,$mxINT64_CLASS,$mxUINT64_CLASS,
     $mxFUNCTION_CLASS);

bootstrap OME::Matlab $VERSION;

$mxREAL = __mxREAL();
$mxCOMPLEX = __mxCOMPLEX();

$mxUNKNOWN_CLASS = __mxUNKNOWN_CLASS();
$mxCELL_CLASS = __mxCELL_CLASS();
$mxSTRUCT_CLASS = __mxSTRUCT_CLASS();
$mxOBJECT_CLASS = __mxOBJECT_CLASS();
$mxCHAR_CLASS = __mxCHAR_CLASS();
$mxLOGICAL_CLASS = __mxLOGICAL_CLASS();
$mxDOUBLE_CLASS = __mxDOUBLE_CLASS();
$mxSINGLE_CLASS = __mxSINGLE_CLASS();
$mxINT8_CLASS = __mxINT8_CLASS();
$mxUINT8_CLASS = __mxUINT8_CLASS();
$mxINT16_CLASS = __mxINT16_CLASS();
$mxUINT16_CLASS = __mxUINT16_CLASS();
$mxINT32_CLASS = __mxINT32_CLASS();
$mxUINT32_CLASS = __mxUINT32_CLASS();
$mxINT64_CLASS = __mxINT64_CLASS();
$mxUINT64_CLASS = __mxUINT64_CLASS();
$mxFUNCTION_CLASS = __mxFUNCTION_CLASS();

package OME::Matlab::Array;
require Exporter;

our @EXPORT = qw(printArray
		scalar
		makePersistent
		);
our @ISA = qw(Exporter);



sub print {
    my $array = shift;
    print "  Perl: $array\n";
    print "    Class:  ",$array->class_name(),"\n";
    print "    Order:  ",$array->order(),"\n";
    print "    Dims:   ",join('x',@{$array->dimensions()}),"\n";
    if ($array->is_numeric() || $array->is_logical()) {
        print "    Values: (",join(',',@{$array->getAll()}),")\n";
	}
	if ($array->is_char()){
		print "    Value: '",$array->getString(),"'\n";
	}
}

# returns the first value of the array
sub scalar {
	my $array = shift;
	
	if ($array->is_numeric() || $array->is_logical()) {
		return $array->getAll()->[0];
	}
	if ($array->is_char()){
		return $array->getString();
	}
	return undef;
}

sub makePersistent {
    my ($self,$persistent) = shift;
    $persistent = 1 unless defined $persistent;
    bless $self,
      $persistent?
        "OME::Matlab::PersistentArray":
        "OME::Matlab::Array";
}

package OME::Matlab::PersistentArray;

use base qw(OME::Matlab::Array);

sub DESTROY {}

1;

__END__

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut

