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
use Cwd;

use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::Util;

use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

# Default core directory locations
our @core_dirs = (
    {
	name => "base",
	path => "/OME",
	description => "Base OME directory",
	children => ["xml", "bin", "perl2", "cgi", "repository", "conf"]
    },
    {
	name => "temp_base",
	path => "/var/tmp/OME",
	description => "Base temporary directory",
	children => ["lock", "sessions", "install"]
    }
);

# The HTML directories that need to be copied to the basedir
our @html_core = ("JavaScript", "html");

# The image directories that need to be copied to the basedir
our @image_core = ("images");

# Base and temp dir references
our $OME_BASE_DIR = \$core_dirs[0]->{path};
our $OME_TMP_DIR = \$core_dirs[1]->{path};

# Global OME default user, group, UID and GID
our $OME_USER = "ome"; 
our $OME_GROUP = "ome";
our $OME_UID;
our $OME_GID;

# Global Apache user
our $APACHE_USER;

# Postgres admin
our $POSTGRES_USER = "postgres";

# A Unix user that will be the ome admin (belongs to the ome group, but is not the ome user)
our $ADMIN_USER = '';

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

sub get_apache_user {
    my $username = shift;  # A user specified default if we have one

    unless ($username) {
	$username = "";

	# Grab our Apache user from the password file
	open (PW_FILE, "<", "/etc/passwd") or croak "Couldn't open /etc/passwd. $!";
	while (<PW_FILE>) {
	    chomp;
	    $username = (split ":")[0];
	    if ($username =~ /httpd|apache|www-data|www/) {
		last;
	    }
	}
    }

    close (PW_FILE);

    # It's possible we've got multiple instances of these users in the password
    # file so lets confirm things. By the same token, if that the user is of a
    # different name, ask for it.
    while (1) {
		$username = confirm_default ("What is the Unix username that Apache runs under ?", $username);
		getpwnam ($username)
			or (print "User \"$username\" does not exist, try again.\n" and next);
		last;
    }

    return $username;
}

sub get_postgres_user {
    my $username = shift;  # A user specified default if we have one

    unless ($username) {
		$username = "";

		# Grab our PostgreSQL user from the password file
		open (PW_FILE, "<", "/etc/passwd") or croak "Couldn't open /etc/passwd. $!";
		while (<PW_FILE>) {
			chomp;
			$username = (split ":")[0];
			if ($username =~ /postgres|postgre|pgsql|psql/) {
				last;
			}
		}
	}
    close(PW_FILE);

    # It's possible we've got multiple instances of these users in the password
    # file so lets confirm things. By the same token, if that the user is of a
    # different name, ask for it.
    while (1) {
		$username = confirm_default ("What is the Unix username of the Postgres default user?", $username);
		getpwnam ($username)
			or (print "User \"$username\" does not exist, try again.\n" and next);

		last;
	}

    return $username;
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

	$$OME_BASE_DIR = $environment->base_dir()      if $environment->base_dir() ;
	$$OME_TMP_DIR  = $environment->tmp_dir()       if $environment->tmp_dir() ;
	$OME_USER      = $environment->user()          if $environment->user() ;
	$APACHE_USER   = $environment->apache_user()   if $environment->apache_user() ;
	$POSTGRES_USER = $environment->postgres_user() if $environment->postgres_user() ;
	$ADMIN_USER    = $environment->admin_user()    if $environment->admin_user() ;

	# Confirm all flag
	my $confirm_all;

    while (1) {
		if ($environment->get_flag("UPDATE") or $confirm_all) {
			print "\n";  # Spacing

			# Ask user to confirm his/her original entries
			foreach my $directory (@core_dirs) {
				printf '%25s: %s%s%s%s', $directory->{description}, BOLD, $directory->{path}, RESET, "\n";
			}
	
			print "            OME groupname: ", BOLD, $OME_GROUP     , RESET, "\n";
			print "       OME Unix  username: ", BOLD, $OME_USER      , RESET, "\n";
			print "    Apache Unix  username: ", BOLD, $APACHE_USER   , RESET, "\n";
			print " Postgres admin  username: ", BOLD, $POSTGRES_USER , RESET, "\n";
			print "   Special Unix  username: ", BOLD, $ADMIN_USER    , RESET, "\n";

			print "\n";  # Spacing

			y_or_n ("Are these values correct ?") and last;
		}
		
		$confirm_all = 0;

		print "\n";  # Spacing
		# Confirm and/or update all our installation dirs
		foreach my $directory (@core_dirs) {
		   $directory->{path} = confirm_path ($directory->{description}, $directory->{path});
		}

		# Make sure the rest of the installation knows where the core directories are
		$environment->base_dir($$OME_BASE_DIR);
		$environment->tmp_dir($$OME_TMP_DIR);
    
		# Confirm and/or update our group information
		$OME_GROUP = confirm_default("The group which OME should be run under", $OME_GROUP);

		# Confirm and/or update our user information
		$OME_USER = confirm_default("The user which OME should be run under", $OME_USER);
	
		# Get and/or update our apache user information
		$APACHE_USER = get_apache_user($APACHE_USER);

		# Get and/or update our postgres admin information
		$POSTGRES_USER = get_postgres_user($POSTGRES_USER);

		# Get and/or update our "special" Unix user information
		$ADMIN_USER =
			confirm_default ("Unix user to include in the OME group (optional, i.e. your real username)", $ADMIN_USER || "");

		# Make sure the rest of the installation knows who the apache and ome users are
		$environment->user($OME_USER);
		$environment->group($OME_GROUP);
		$environment->apache_user($APACHE_USER);
		$environment->postgres_user($POSTGRES_USER);
		$environment->admin_user($ADMIN_USER);

		$confirm_all = 1;

		print "\n";  # Spacing
    }

    print "\nBuilding the core system\n";

    #********
    #******** Set up our Unix users/groups
    #********

    # Group creation if needed
    if (not $OME_GID = getgrnam($OME_GROUP)) {
		print "  \\_ Adding group ", BOLD, "\"$OME_GROUP\"", RESET, ".\n", ;
		add_group ($OME_GROUP) or croak "Failure creating group \"$OME_GROUP\"";
		$OME_GID = getgrnam($OME_GROUP) or croak "Failure retrieving GID for \"$OME_GROUP\"";
    }

    # User creation if needed
    if (not $OME_UID = getpwnam($OME_USER)) {
		print "  \\_ Adding user ", BOLD, "\"$OME_USER\"", RESET, ".\n", ;
		add_user ($OME_USER, $$OME_BASE_DIR, $OME_GROUP) or croak "Failure creating user \"$OME_GROUP\"";
		$OME_UID = getpwnam($OME_USER) or croak "Failure retrieving UID for \"$OME_USER\"";
    }

    if(not getpwnam($POSTGRES_USER)) {
	croak "Failure retrieving UID for \"$POSTGRES_USER\"";
    }

    # Add the apache and OME user to the OME group if needed
    my @members = split (/\s/, (getgrgid($OME_GID))[3]);  # Split group members on whitespace

    my $need_to_add_apache = 1;
    my $need_to_add_user = 1;
	my $need_to_add_admin_user = $ADMIN_USER ? 1 : 0;

    if (@members) {
	    foreach my $member (@members) {
		    $need_to_add_apache = 0 if $member eq $APACHE_USER;
		    $need_to_add_user = 0 if $member eq $OME_USER;
			$need_to_add_admin_user = 0 if $member eq $ADMIN_USER;
	    };
    }

    add_user_to_group ($APACHE_USER, $OME_GROUP)
		or croak "Failure adding user \"$APACHE_USER\" to group \"$OME_GROUP\""
		if $need_to_add_apache;
    add_user_to_group ($OME_USER, $OME_GROUP)
		or croak "Failure adding user \"$OME_USER\" to group \"$OME_GROUP\""
		if $need_to_add_user;
    add_user_to_group ($ADMIN_USER, $OME_GROUP)
		or croak "Failure adding user \"$ADMIN_USER\" to group \"$OME_GROUP\""
		if $need_to_add_admin_user;
    
    #********
    #******** Build our core directory structure
    #********

    foreach my $directory (@core_dirs) {
		# Create this core directory
		unless (-d $directory->{path}) { 
			print "  \\_ Creating directory ", BOLD, "\"$directory->{path}\"", RESET, ".\n";
			mkdir $directory->{path} or croak "Unable to create directory \"$directory->{path}\": $!";
		}

		# Make sure this core directory is owned by the $OMEUser
		fix_ownership($OME_USER, $directory->{path})
			or croak "Failure setting permissions on \"$directory->{path}\" $!";

		# Set the "Set-GID" bit on the dir so that all files will inherit it's GID
		chmod(02775, $directory->{path}) or croak "Failure setting GID on \"$directory->{path}\" $!";

		# Create each core dir's children
		foreach my $child (@{$directory->{children}}) {
	    	$child = $directory->{path} . "/" . $child;
	    	unless (-d $child) {
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
		copy ($file, $$OME_BASE_DIR."/xml/") or croak ("Couldn't copy file ", $file, ". ", $!, ".\n");
    }

    # Back to UID 0 we go
    $EUID = 0;
    
    print "\n";  # Spacing
    
    #********
    #******** Copy our HTML/Image core directories from the source tree
    #********

    # There's no need to be UID 0 for these creations
    $EUID = $OME_UID;

    print "Copying IMAGE directories\n";
    	foreach my $directory (@image_core) {
		print "  \\_ $directory\n";
		copy_tree ("$directory", "$$OME_BASE_DIR");
    }

    print "Copying HTML directories\n";

    # We need to be in src/ for these copies
    my $iwd = getcwd;
    chdir ("src") or croak "Unable to chdir into src/. $!";

    foreach my $directory (@html_core) {
		print "  \\_ $directory\n";
		copy_tree ("$directory", "$$OME_BASE_DIR");
    }

    chdir ($iwd) or croak "Unable to chdir back to \"$iwd\". $!";
    
    # Back to UID 0 we go
    $EUID = 0;

    print "\n";  # Spacing

    return;
}

sub rollback {
    print "Rollback";
    return;
}

1;
