# OME/Install/FileSystemTask.pm

# Copyright (C) 2003 Open Microscopy Environment
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Install::FileSystemTask;


#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;

use OME::Install::Terminal;
use OME::Install::InstallationTask;
use OME::Install::Environment;

#*********
#********* GLOBALS AND DEFINES
#*********

# Default core directory locations
my @core_dirs = (
    {
	name => "base",
	path => "/OME",
	description => "Base OME directory",
    },
    {
	name => "temp_base",
	path => "/var/tmp/OME",
	description => "Base temporary directory",
    }
);

# Populate children (Base OME directory)
my @children = ("xml", "bin", "html", "JavaScript", "images", "perl2", "cgi", "repository");
foreach my $child (@children) {
    push (@{$core_dirs[0]{children}}, $child); 
}

# Populate children (Base temporary directory)
@children = ("lock", "sessions");
foreach my $child (@children) {
    push (@{$core_dirs[1]{children}}, $child); 
}


#*********
#********* LOCAL SUBROUTINES
#*********

# NIL

#*********
#********* START OF CODE
#*********

sub execute {
    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;

    print_header ("Filesystem Setup");

    # We need to drop our umask so that everyone can create files.
    print "Dropping umask to ", BOLD, "\"0000\"", RESET, ".\n";
    umask (0000);

    # Confirm and/or update all our installation dirs
    foreach my $directory (@core_dirs) {
	$directory->{path} = confirm_default ($directory->{description}, $directory->{path});
    }

    foreach my $directory (@core_dirs) {
	# Create the core dirs
	if (not -e $directory->{path}) { 
	    print "Creating directory ", BOLD, "\"$directory->{path}\"", RESET, ".\n";
	    mkdir $directory->{path} or croak "Unable to create directory \"$directory->{path}\": $!";
	}
	# Create each core dir's children
	foreach my $child (@{$directory->{children}}) {
	    $child = $directory->{path}."/".$child;
	    if (not -e $child) { 
		print "Creating directory ", BOLD, "\"$child\"", RESET, ".\n";
		mkdir $child or croak "Unable to create directory \"$child\": $!";
	    }
	}
    }
}

sub rollback {
    print "Rollback";
    return;
}

1;
