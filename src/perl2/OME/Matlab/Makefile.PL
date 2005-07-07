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

use strict;
use ExtUtils::MakeMaker;
use English;

my @outputs = `perl MatlabInfo.pl @ARGV -v -a -r -i -l`;

my $matlab_vers    = $outputs[0];
my $matlab_arch    = $outputs[1];
my $matlab_dir     = $outputs[2];
my $matlab_include = $outputs[3];
my $matlab_lib     = $outputs[4];

chop($matlab_vers);
chop($matlab_arch);
chop($matlab_dir);
chop($matlab_include);
chop($matlab_lib);

my $matlab_lib_path = $matlab_lib;
if ($matlab_lib_path =~ m/-L(\S+)/ ){
	$matlab_lib_path = $1;
}

print STDERR "Matlab Vers: $matlab_vers\n";
print STDERR "Matlab Arch: $matlab_arch\n";
print STDERR "Matlab Home: $matlab_dir\n";
print STDERR "Include:  $matlab_include\n";
print STDERR "Lib:      $matlab_lib\n";
print STDERR "Lib Path: $matlab_lib_path\n\n";


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		    => 'OME::Matlab',
    'VERSION_FROM'	=> '../../OME.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		    => ["$matlab_lib -L/usr/local/lib -L/sw/lib"], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		    => "$matlab_include", # e.g., '-I/usr/include/other'
    'realclean'     => {FILES => '../blib'},
    'clean'         => {FILES => '../blib'},
);

sub MY::test {
	package MY;
	my $str = shift->SUPER::test(@_);
	if ($matlab_arch eq "mac") {
		print "Adding DYLD_LIBRARY_PATH to Make Test ...\n"
			if $str =~ s#PERL_DL_NONLAZY=1#PERL_DL_NONLAZY=1 DYLD_LIBRARY_PATH=$matlab_lib_path#;
	} else {
		print "Adding LD_LIBRARY_PATH to Make Test ...\n"
			if $str =~ s#PERL_DL_NONLAZY=1#PERL_DL_NONLAZY=1 LD_LIBRARY_PATH=$matlab_lib_path#;
	}
	return $str;
}

sub MY::const_loadlibs {
	package MY;
	my $str = shift->SUPER::const_loadlibs(@_);
	if ($matlab_arch ne "mac") {
		print "Modifying LD_RUN_PATH...\n"
			if $str =~ s#^(LD_RUN_PATH.+)$#$1:$matlab_lib_path#m;
		print "Modifying LD_LIBRARY_PATH...\n";
		$str = $str."LD_LIBRARY_PATH = $matlab_lib_path";
		
	}
	return $str;
}
