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

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Make sure we have a matlab executable
my @extra_paths = glob ("/Applications/MATLAB*/bin");
push (@extra_paths,glob ("/Applications/matlab*/bin"));
push (@extra_paths,glob ("/Applications/Matlab*/bin"));
my $matlab_path = which ('matlab',\@extra_paths);

if (scalar(@ARGV) eq 1) {
	$matlab_path = shift(@ARGV);
}

my $path_test = $matlab_path;
$path_test = "$matlab_path/bin/matlab" unless -x $path_test and -f $path_test;
$path_test = "$matlab_path/matlab" unless -x $path_test and -f $path_test;
die "Could not find matlab executable" unless -x $path_test and -f $path_test;
$matlab_path = $path_test;

# Execute matlab with a -n flag to get the ARCH and MATLAB variables.
my ($matlab_dir, $matlab_arch, $matlab_vers);
foreach (`$matlab_path -n`) {
	$matlab_arch = $1 if $_ =~ /\s+ARCH\s+=\s+(.+)$/;
	$matlab_dir  = $1 if $_ =~ /\s+MATLAB\s+=\s(.+)$/;
}
foreach (`$matlab_path -nojvm -r quit`) {
	$matlab_vers = $1 if $_ =~ /^\s*Version\s*(\S+)\s+/;
}

die "Could not find matlab architecture." unless $matlab_arch;
die "Could not find matlab home." unless $matlab_dir;
die "Could not find matlab version." unless $matlab_vers;

# Figure out the required Matlab lib and includes, this varies version to version
# and architecture to architecture
my ($matlab_include, $matlab_lib, $matlab_lib_cmd);
if ($matlab_vers =~ /6\.5\.0.+/) {
	$matlab_include = "$matlab_dir/extern/include";
	$matlab_lib = "$matlab_dir/extern/lib/$matlab_arch";
	$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat";
	$matlab_lib_cmd .= " -L$matlab_dir/sys/os/mac -ldl" if $matlab_arch eq 'mac';
	
} elsif ($matlab_vers =~ /7\.0\.0.+/)  {
	$matlab_include = "$matlab_dir/extern/include";
	$matlab_lib = "$matlab_dir/bin/$matlab_arch";
	$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat -licudata -licui18n -licuuc -lustdio -lz";
} else {
	print STDERR "WARNING Matlab Version $matlab_vers not supported.\n";	
}

print STDERR "  Matlab Vers: $matlab_vers\n";
print STDERR "  Matlab Arch: $matlab_arch\n";
print STDERR "  Matlab Home: $matlab_dir\n\n";
print STDERR "  Include: $matlab_include\n";
print STDERR "  Lib:     $matlab_lib\n\n";

WriteMakefile(
    'NAME'		    => 'OME::Matlab',
    'VERSION_FROM'	=> '../../OME.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		    => ["$matlab_lib_cmd -L/usr/local/lib -L/sw/lib"], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		    => "-I$matlab_include", # e.g., '-I/usr/include/other'
    'realclean'     => {FILES => '../blib'},
    'clean'         => {FILES => '../blib'},
);

sub MY::test {
	package MY;
	my $str = shift->SUPER::test(@_);
	if ($matlab_arch eq "mac") {
		print "Adding DYLD_LIBRARY_PATH to Make Test ...\n"
			if $str =~ s#PERL_DL_NONLAZY=1#PERL_DL_NONLAZY=1 DYLD_LIBRARY_PATH=/Applications/MATLAB6p5/extern/lib/mac#m;
	}
	return $str;
}

sub MY::const_loadlibs {
	package MY;
	my $str = shift->SUPER::const_loadlibs(@_);
	if ($matlab_arch ne "mac") {
		print "Modifying LD_RUN_PATH...\n"
			if $str =~ s#^(LD_RUN_PATH.+)$#$1:$matlab_dir/bin/$matlab_arch:$matlab_dir/sys/os/$matlab_arch#m;
	}
	return $str;
}

# Ported from FreeBSD's /usr/bin/which
#
# Copyright (c) 1995 Wolfram Schneider <wosch@FreeBSD.org>. Berlin.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# Implements the standard "which" functionality, searching the path for a
# certain binary.
#
# RETURNS	The absolute path to the binary or 0 if nothing is found
#

sub which {
    my $prog = shift;
    my $extra_paths = shift;

    my @path = split(/:/, $ENV{'PATH'});
    if ($ENV{'PATH'} =~ /:$/) {
        $#path = $#path + 1;
        $path[$#path] = "";
    }

	push (@path,'/usr/sbin');
	push (@path,@$extra_paths) if $extra_paths;

    if ("$prog" =~ '/' && -x "$prog" && -f "$prog") {
        return $prog;
    } else {
        foreach my $dir (@path) {
            $dir = "." if !$dir;
            if (-x "$dir/$prog" && -f "$dir/$prog") {
                return "$dir/$prog";
            }
        }
    }

    return 0;
}

# END modified BSD Licensed code


