#!/usr/bin/perl -w
# This script makes a connection to the MATLAB Engine and trys to use the MATLAB engine
# to compute 4x8. If the answer is not 32 something went wrong.

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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
# Written by:    Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

use strict;
use OME::Matlab;

print "Trying to compute 4x8 using MATLAB ...\n";
my $x = OME::Matlab::Array->newDoubleScalar(4);
my $engine = OME::Matlab::Engine->open();

if (not defined $engine) {
	print STDERR "Test Failed.\n Perl Matlab API is incorrectly installed.\n".
				 "The MATLAB engine does not start.\n";
	exit (-1);
}

$engine->putVariable('x',$x);
$engine->eval('y = x .* 8;');
my $y = $engine->getVariable('y');
print "Perl: $y\n";
print "    Class:  ",$y->class_name(),"\n";
print "    Order:  ",$y->order(),"\n";
print "    Dims:   ",join('x',@{$y->dimensions()}),"\n";
print "    Values: (",join(',',@{$y->getAll()}),")\n";

if ( ($y->class_name() eq "double") && ($y->order() eq  2) && ($y->dimensions()->[0] eq 1) && ($y->dimensions()->[1] eq 1) && ($y->getAll()->[0] eq 32)  ) {
	print "Test Passed. Perl Matlab API is correctly installed.\n";
	$engine->close();
	exit (1);
} else {
	print STDERR "Test Failed.\n Perl Matlab API is incorrectly installed.\n".
				 "The MATLAB enigne ran but gave incorrect results.";
	$engine->close();
	exit (-1);		 
}