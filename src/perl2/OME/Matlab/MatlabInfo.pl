#!/usr/bin/perl
# This script gathers and returns info about the current matlab installation
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
use English;
use Getopt::Long;

# command line options
my $result;
my $ver  = 0;
my $arch = 0;
my $root = 0;
my $inc  = 0;
my $lib  = 0;
my $path = 0;

GetOptions('v|version' => \$ver,
			'a|arch' => \$arch,
			'r|root' => \$root,
			'i|include' => \$inc,
			'l|lib' => \$lib,
			'p|path' => \$path);
$result = $ver + $arch + $root + $inc + $lib + $path;

# Make sure we have a matlab executable
my @extra_paths = glob ("/Applications/MATLAB*/bin");
push (@extra_paths,glob ("/Applications/matlab*/bin"));
push (@extra_paths,glob ("/Applications/Matlab*/bin"));
my $matlab_path = which ('matlab',\@extra_paths);
my $matlab_user;

if (scalar(@ARGV) >= 1) {
	$matlab_user = shift(@ARGV);
	die "You must run the makefile as root to pass it a matlab_user" 
		if ($EUID ne 0);
}
if (scalar(@ARGV) >= 1) {
	$matlab_path = shift(@ARGV);
}

my $path_test = $matlab_path;
$path_test = "$matlab_path/bin/matlab" unless -x $path_test and -f $path_test;
$path_test = "$matlab_path/matlab" unless -x $path_test and -f $path_test;
die "Could not find matlab executable" unless -x $path_test and -f $path_test;
$matlab_path = $path_test;
$matlab_path =~ s/\/\//\//;

# Execute matlab with a -n flag to get the ARCH and MATLAB variables.
my ($matlab_dir, $matlab_arch, $matlab_vers);
my @outputs = `$matlab_path -n`;
foreach (@outputs) {
	$matlab_arch = $1 if $_ =~ /\s+ARCH\s+=\s+(.+)$/;
	$matlab_dir  = $1 if $_ =~ /\s+MATLAB\s+=\s(.+)$/;
}
die "Could not find matlab architecture.\n@outputs" unless $matlab_arch;
die "Could not find matlab home.\n@outputs" unless $matlab_dir;

# can we fulfill all the user's queries without launching the matlab executable?
if ($result > 0) {
	print ("$matlab_path\n") and $result--   if ($path);
	print ("$matlab_arch\n") and $result--   if ($arch);
	print ("$matlab_dir\n")  and $result--   if ($root);
	exit unless $result > 0;
}

#
# Additional Info requries executing matlab.
#
if (defined $matlab_user) {
	@outputs = `su $matlab_user -c '$matlab_path -nojvm -r quit'`; 
} else {
	@outputs = `$matlab_path -nojvm -r quit`; 
}

foreach (@outputs) {
	$matlab_vers = $1 if $_ =~ /^\s*Version\s*(\S+)\s+/;
}
die "Could not find matlab version.\n@outputs" unless $matlab_vers;

# Figure out the required Matlab lib and includes, this varies version to version
# and architecture to architecture
my ($matlab_include, $matlab_lib, $matlab_lib_cmd);
if ($matlab_vers =~ /6\.5\.0.+/) {
	$matlab_include = "-I$matlab_dir/extern/include";
	$matlab_lib = "$matlab_dir/extern/lib/$matlab_arch";
	$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat";
	$matlab_lib_cmd .= " -L$matlab_dir/sys/os/mac -ldl" if $matlab_arch eq 'mac';
	
} elsif ($matlab_vers =~ /7\.0\.0.+/ or $matlab_vers =~ /7\.0\.1.+/
	or $matlab_vers =~ /7\.0\.4.+/)  {
	$matlab_include = "-I$matlab_dir/extern/include";
	$matlab_lib = "$matlab_dir/bin/$matlab_arch";
	$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat -licudata -licui18n -licuuc -lustdio -lz";
	
} else {
	print STDERR "WARNING Matlab Version $matlab_vers not supported.\n";	
}

# present the matlab info to the user depending on specified parameters
if (not $result) {
	print STDERR "Matlab Path: $matlab_path\n";
	print STDERR "Matlab Vers: $matlab_vers\n";
	print STDERR "Matlab Arch: $matlab_arch\n";
	print STDERR "Matlab Root: $matlab_dir\n\n";
	print STDERR "Include: $matlab_include\n";
	print STDERR "Lib:     $matlab_lib_cmd\n";
	exit;
}

print ("$matlab_vers\n")    if ($ver);
print ("$matlab_include\n") if ($inc);
print ("$matlab_lib_cmd\n") if ($lib);

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