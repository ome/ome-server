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
use English;
use Carp;
use File::Copy;
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
my $BASEDIR = \$core_dirs[0]->{path};
my $TMPDIR = \$core_dirs[1]->{path};

# Global OME user (default) and UID
my $OMEUSER = "ome"; 
my $OMEUID;

#*********
#********* LOCAL SUBROUTINES
#*********

sub fix_ownership {
    my ($user, $dir) = @_;

    # Get directory info
    my ($dir_uid, $dir_gid) = (stat("$dir"))[4,5] or croak "Unable to find directory: \"$dir\".";
    my ($uid, $gid) = (getpwnam($user))[2,3] or croak "Unable to find user: \"$user\".";

    # If we've got a wrong UID or GID do a full chown it no harm in doing both if we only need one
    if (($dir_uid != $uid) or ($dir_gid != $gid)) {
	chown ($uid, $gid, $dir) or carp "Unable to change owner of $dir, $!";
	return $! ? undef : 1;
    }
}

#*********
#********* START OF CODE
#*********

sub execute {
    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;

    print_header ("Filesystem Setup");

    # Set a proper umask
    print "Dropping umask to ", BOLD, "\"0002\"", RESET, ".\n";
    umask (0002);

    # Confirm and/or update all our installation dirs
    foreach my $directory (@core_dirs) {
	$directory->{path} = confirm_path ($directory->{description}, $directory->{path});
    }

    # Make sure our OMEUser exists if not create it
    if (not $environment->OMEUser()) {
	$OMEUSER = confirm_default ("What username do you want OME to run under ?", $OMEUSER);
	if (not getpwnam($OMEUSER)) {
	    print "User does not exist, adding \"$OMEUSER\".\n";
	    $environment->adduser($OMEUSER, $$BASEDIR)  # adduser ($user, $homedir)
		or croak "Couldn't add user, \"$OMEUSER\".";
	}
	
	# Make sure it's propagated
	$environment->OMEUser ($OMEUSER);
    }

    # Set our $OMEUID global
    $OMEUID = getpwnam($OMEUSER);

    #********
    #******** Build our core directory structure
    #********

    foreach my $directory (@core_dirs) {
	# Create the core dirs
	if (not -e $directory->{path}) { 
	    print "Creating directory ", BOLD, "\"$directory->{path}\"", RESET, ".\n";
	    mkdir $directory->{path} or croak "Unable to create directory \"$directory->{path}\": $!";
	}

	# Make sure the core dirs are owned by the $OMEUser
	fix_ownership($OMEUSER, $directory->{path}) or croak "Failure setting permissions on \"$directory->{path}\".";

	# Set the "Set-GID" bit on the dir so that all files will inherit it's GID
	chmod(02775, $directory->{path}) or croak "Failure setting GID on \"$directory->{path}\".";

	# Create each core dir's children
	foreach my $child (@{$directory->{children}}) {
	    $child = $directory->{path}."/".$child;
	    if (not -e $child) {
		# There's no need to be UID 0 for these creations
		$EUID = $OMEUID;

		print "Creating directory ", BOLD, "\"$child\"", RESET, ".\n";
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
    $EUID = $OMEUID;

    foreach my $file (@files) {
	print "  \\_ $file\n";
	copy ($file, $$BASEDIR."/xml/") or die ("Couldn't copy file ", $file, ". ", $!, ".\n");
    }

    # Back to UID 0 we go
    $EUID = 0;

    
    #********
    #******** Copy our HTML core directories from the source tree
    #********

    print "Copying HTML directories\n";
    # There's no need to be UID 0 for these creations
    $EUID = $OMEUID;

    foreach my $directory (@html_core) {
	print "  \\_ $directory\n";
	$environment->copyTree ("$directory", "$$BASEDIR/$directory");
    }
    
    # Back to UID 0 we go
    $EUID = 0;
}

sub rollback {
    print "Rollback";
    return;
}

1;
