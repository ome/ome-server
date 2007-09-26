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
use Getopt::Long;
use ExtUtils::MakeMaker;

my ($matlab_version, $matlab_lib, $matlab_include);
GetOptions ('version=s' => \$matlab_version,
			'lib=s'      => \$matlab_lib,
			'include=s'  => \$matlab_include);
			
die "cmd-line parameters -lib and -include must be specified. \n".
	"e.g: perl Makefile.pl -lib='-L/Applications/MATLAB704/bin/mac -lmx -leng -lut -lmat -licudata -licui18n -licuuc -lustdio -lz' -include='-I/Applications/MATLAB704/extern/include'\n"
	if (not defined($matlab_lib) or not defined ($matlab_include));

my $matlab_lib_path = $matlab_lib;
$matlab_lib_path = $1
	if ($matlab_lib_path =~ m/-L(\S+)/ );

my $define = '';

$define = '-DPRE_73' if ($matlab_version =~ /7\.[0,1,2]\.0.+/ or $matlab_version =~ /6\.+/); 

print "define is $define\n\n";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		    => 'OME::Matlab',
    'VERSION_FROM'	=> '../../OME.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		    => ["$matlab_lib -L/usr/local/lib -L/sw/lib"], # e.g., '-lm'
    'DEFINE'		=> $define,
    'INC'		    => "$matlab_include", # e.g., '-I/usr/include/other'
    'realclean'     => {FILES => '../blib'},
    'clean'         => {FILES => '../blib'},
);

sub MY::test {
	package MY;
	my $str = shift->SUPER::test(@_);
	$str =~ s#PERL_DL_NONLAZY=1#PERL_DL_NONLAZY=1 LD_LIBRARY_PATH=$matlab_lib_path DYLD_LIBRARY_PATH=$matlab_lib_path#;
	return $str;
 }

sub MY::const_loadlibs {
	package MY;
	my $str = shift->SUPER::const_loadlibs(@_);
	print "Modifying LD_RUN_PATH...\n"
		if $str =~ s#^(LD_RUN_PATH.+)$#$1:$matlab_lib_path#m;
	print "Modifying LD_LIBRARY_PATH...\n";
	$str = $str."LD_LIBRARY_PATH = $matlab_lib_path";		
	return $str;
}
