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
# Written by:    Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

use Config;
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
	chomp($matlab_path);
} else {
	die "Incorrect usage \n";
}

my $suffix;
if ($Config{'osname'} eq "darwin") {
	$os     = "mac";
	$suffix = "dylib";
} elsif ($Config{'osname'} eq "linux") {
	$os     = "glx86";
	$suffix = "so";
}

my @libFiles = ("eng", "mat", "mx", "ut", "dl");
my @matlabInc  = ("$matlab_path/extern/include"); 
my @matlabLib  = ("$matlab_path/bin/$os", "$matlab_path/sys/os/$os");

my $matlabIncStr = join (" -I", "", @matlabInc);
my $matlabLibStr = join (" -L", "", @matlabLib);
my $matlabLibFlags = join (" -l", "", @libFiles);

# verify that all the required matlab library files could be found in one of the library
# directories
foreach my $lib (@libFiles) {
	my $flag = 0;
	foreach my $path (@matlabLib) {
		if (-e "$path/lib$lib.$suffix") {
			$flag =1;
		}	
	}
	if ($flag eq 0) {
		print STDERR "WARNING: Required MATLAB library lib$lib.$suffix was not found in $matlabLibStr\n";
	}
}

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
