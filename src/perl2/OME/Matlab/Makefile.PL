#!/usr/bin/perl
# This script creates the Makefile that forms a perl wrapper around MATLAB's C library
# API for the MATLAB Engine

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

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $matlab_path;

if (scalar(@ARGV) eq 0) {
	print "Where is MATLAB installed?: ";
	$matlab_path = <STDIN>;
	chomp($matlab_path);
} elsif (scalar(@ARGV) eq 1) {
	$matlab_path = shift(@ARGV);
} else {
	die "Incorrect usage \n";
}

my $os = "mac"; # or "glx86";
my $suffix;
if ($os eq "mac") {
	$suffix = "dylib";
} else {
	$suffix = "so";
}

my @libFiles = ("eng", "mat", "mx", "ut");
my @matlabInc  = ("$matlab_path/extern/include"); 
my @matlabLib  = ("$matlab_path/bin/$os", "$matlab_path/sys/$os");

# check whether the required matlab library files could be found
foreach (@libFiles){	
	if (not -e "$matlab_path$/bin/$os/lib$_.$suffix"){
				print STDERR   "WARNING: Required MATLAB library lib$_.$suffix was not found in $matlab_path/bin/$os \n";
	}
}
		
my $matlabIncStr = join (" -I", "", @matlabInc);
my $matlabLibStr = join (" -L", "", @matlabLib);
my $matlabLibFlags = join (" -l", "", @libFiles);

print STDERR "Using Matlab located in $matlab_path\n";
print STDERR "  Include: $matlabIncStr\n";
print STDERR "  Lib:     $matlabLibStr $matlabLibFlags\n";

WriteMakefile(
    'NAME'		    => 'OME::Matlab',
    'VERSION_FROM'	=> '../../OME.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		    => ["-L/usr/local/lib -L/sw/lib $matlabLibStr $matlabLibFlags"], 
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		    => $matlabIncStr, # e.g., '-I/usr/include/other'
    'realclean'     => {FILES => '../blib'},
    'clean'         => {FILES => '../blib'},
);
