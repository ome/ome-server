# OME/Install/CoreSystemTask.pm
# This task initializes the core OME system which currently consists of the 
# OME_BASE directory structure and ome user/group.

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

package OME::Install::CoreSystemTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use English;
use Carp;
use File::Copy;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;

use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::Util;

use base qw(OME::Install::InstallationTask);

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
my @children = ("xml", "bin", "perl2", "cgi", "repository");
foreach my $child (@children) {
    push (@{$core_dirs[0]{children}}, $child); 
}

# Populate children (Base temporary directory)
@children = ("lock", "sessions");
foreach my $child (@children) {
    push (@{$core_dirs[1]{children}}, $child); 
}

# The HTML directories that need to be copied to the basedir
my @html_core = ("JavaScript", "html", "images");

# Base and temp dir references
my $OME_BASE_DIR = \$core_dirs[0]->{path};
my $OME_TMP_DIR = \$core_dirs[1]->{path};

# Global OME default user, group, UID and GID
my $OME_USER = "ome"; 
my $OME_GROUP = "ome";
my $OME_UID;
my $OME_GID;

#*********
#********* LOCAL SUBROUTINES
#*********

sub fix_ownership {
    my ($user, $dir) = @_;

    # Get directory info
    my ($dir_uid, $dir_gid) = (stat($dir))[4,5] or croak "Unable to find directory: \"$dir\"";
    my ($uid, $gid) = (getpwnam($user))[2,3] or croak "Unable to find user: \"$user\"";

    # If we've got a wrong UID or GID do a full chown, no harm in doing both if we only need one
    if (($dir_uid != $uid) or ($dir_gid != $gid)) {
	chown ($uid, $gid, $dir) or croak "Unable to change owner of $dir, $!";
    }
    
    return 1;
}

#*********
#********* START OF CODE
#*********

sub execute {
    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;
    
    print_header ("Core System Setup");

    #********
    #******** Confirmation and/or updates of defaults
    #********

    # Set a proper umask
    print "Dropping umask to ", BOLD, "\"0002\"", RESET, ".\n";
    umask (0002);

    # Confirm and/or update all our installation dirs
    foreach my $directory (@core_dirs) {
	$directory->{path} = confirm_path ($directory->{description}, $directory->{path});
    }
    
    # Confirm and/or update our group information
    $OME_GROUP = confirm_default ("The group which OME should be run under", $OME_GROUP);

    # Confirm and/or update our user information
    $OME_USER = confirm_default ("The user which OME should be run under", $OME_USER);

    print "\nBuilding the core system\n";

    #********
    #******** Set up our Unix user/group
    #********

    # Group creation if needed
    if (not $OME_GID = getgrnam($OME_GROUP)) {
	print "  \\_ Adding group ", BOLD, "\"$OME_GROUP\"", RESET, ".\n", ;
	add_group($OME_GROUP);
	$OME_GID = getgrnam($OME_GROUP) or croak "Failure creating group \"$OME_GROUP\"";
    }

    # User creation if needed
    if (not $OME_UID = getpwnam($OME_USER)) {
	print "  \\_ Adding user ", BOLD, "\"$OME_USER\"", RESET, ".\n", ;
	add_user ($OME_USER, $$OME_BASE_DIR, $OME_GROUP);
	$OME_UID = getpwnam($OME_USER) or croak "Failure creating user \"$OME_USER\"";
    }
    
    #********
    #******** Build our core directory structure
    #********

    foreach my $directory (@core_dirs) {
	# Create the core dirs
	if (not -e $directory->{path}) { 
	    print "  \\_ Creating directory ", BOLD, "\"$directory->{path}\"", RESET, ".\n";
	    mkdir $directory->{path} or croak "Unable to create directory \"$directory->{path}\": $!";
	}

	# Make sure the core dirs are owned by the $OMEUser
	fix_ownership($OME_USER, $directory->{path}) or croak "Failure setting permissions on \"$directory->{path}\" $!";

	# Set the "Set-GID" bit on the dir so that all files will inherit it's GID
	chmod(02775, $directory->{path}) or croak "Failure setting GID on \"$directory->{path}\" $!";

	# Create each core dir's children
	foreach my $child (@{$directory->{children}}) {
	    $child = $directory->{path}."/".$child;
	    if (not -e $child) {
		# There's no need to be UID 0 for these creations
		$EUID = $OME_UID;

		print "  \\_ Creating directory ", BOLD, "\"$child\"", RESET, ".\n";
		mkdir $child or croak "Unable to create directory \"$child\": $!";

		# Back to UID 0 we go
		$EUID = 0;
	    }
	}
    }

    print "\n";  # Spacing
    
    #********
    #******** Populate stylesheets
    #********

    print "Copying stylesheets\n";
    my @files = glob ("src/xml/xslt/*.xslt");
    # There's no need to be UID 0 for these creations
    $EUID = $OME_UID;

    foreach my $file (@files) {
	print "  \\_ $file\n";
	copy ($file, $$OME_BASE_DIR."/xml/") or die ("Couldn't copy file ", $file, ". ", $!, ".\n");
    }

    # Back to UID 0 we go
    $EUID = 0;
    
    print "\n";  # Spacing
    
    #********
    #******** Copy our HTML core directories from the source tree
    #********

    print "Copying HTML directories\n";
    # There's no need to be UID 0 for these creations
    $EUID = $OME_UID;

    foreach my $directory (@html_core) {
	print "  \\_ $directory\n";
	copy_tree ("$directory", "$$OME_BASE_DIR/$directory");
    }
    
    # Back to UID 0 we go
    $EUID = 0;
}

sub rollback {
    print "Rollback";
    return;
}

1;
