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
use File::Path;
use File::Basename;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
use Cwd;
use Text::Wrap;

use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::Util;

use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

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

# Default core directory locations
our @core_dirs = (
	# Base directories
    {
		name => "base",
		path => "/OME",
		description => "Base OME directory",
		children => ["xml", "bin", "perl2", "cgi", "crontab", "matlab", "Inline"],
		owner => \$OME_USER,
		group => \$OME_GROUP,
		mode => 02755, # Set the "Set-GID" bit on the dir
	},
	# OMEIS directories
	{
		name => "omeis_base",
		path => "/OME/OMEIS",
		description => "Base OMEIS directory",
		children => ["Files", "Pixels"],
		owner => \$APACHE_USER,
		group => \$OME_GROUP,
		mode => 02700,
	},
	# Temporary directories
	{
		name => "temp_base",
		path => "/var/tmp/OME",
		description => "Base temporary directory",
		children => ["lock", "sessions", "install"],
		owner => \$OME_USER,
		group => \$OME_GROUP,
		mode => 02775, # Set the "Set-GID" bit on the dir
	}
);

# The HTML directories that need to be copied to the basedir
our @html_core = ("JavaScript", "html");

# The image directories that need to be copied to the basedir
our @image_core = ("images");

# The image directories that need to be copied to the basedir
our @config_core = ("conf");

# Base and temp dir references
our $OME_BASE_DIR   = \$core_dirs[0]->{path};
our $OMEIS_BASE_DIR = \$core_dirs[1]->{path};
our $OME_TMP_DIR    = \$core_dirs[2]->{path};

#*********
#********* LOCAL SUBROUTINES
#*********

sub get_user {
    my $username = shift;

	# Grab our user from the password file if he/she is there
	open (PW_FILE, "<", "/etc/passwd") or croak "Couldn't open /etc/passwd. $!";
	while (<PW_FILE>) {
	    chomp;
	    if ((split ":")[0] =~ /$username/) {
			return 1;
		}
    }

	return 0;
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

    unless (getpwnam ($username)) {
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
		close(PW_FILE);
	}

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

	$$OME_BASE_DIR   = $environment->base_dir()       if $environment->base_dir() ;
	$$OMEIS_BASE_DIR = $environment->omeis_base_dir() if $environment->omeis_base_dir();
	$$OME_TMP_DIR    = $environment->tmp_dir()        if $environment->tmp_dir() ;
	$OME_USER        = $environment->user()           if $environment->user() ;
	$APACHE_USER     = $environment->apache_user()    if $environment->apache_user() ;
	$POSTGRES_USER   = $environment->postgres_user()  if $environment->postgres_user() ;
	$ADMIN_USER      = $environment->admin_user()     if $environment->admin_user() ;

	# Confirm all flag
	my $confirm_all;

	print "\n";  # Spacing

	# Task blurb
	my $blurb = <<BLURB;
This part of the OME install will collect the initial information required. Basic directory structure and system users will be created and the install environment setup. If you are unsure of a particular question, please choose the default as that will be more than adequate for most people.
BLURB

	print wrap("", "", $blurb);

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
			print " OME Unix admin  username: ", BOLD, $ADMIN_USER    , RESET, "\n";

			print "\n";  # Spacing

			y_or_n ("Are these values correct ?",'y') and last;
		}
		
		$confirm_all = 0;

		print "\n";  # Spacing
		# Confirm and/or update all our installation dirs
		foreach my $directory (@core_dirs) {
			$directory->{path} = normalize_path (confirm_path ($directory->{description}, $directory->{path}));			
		}

    	$environment->base_dir($$OME_BASE_DIR);
    	$environment->tmp_dir($$OME_TMP_DIR);
		$environment->omeis_base_dir($$OMEIS_BASE_DIR);
		
		# Confirm and/or update our group information
		$OME_GROUP = confirm_default("The group which OME should be run under", $OME_GROUP);

		# Confirm and/or update our user information
		$OME_USER = confirm_default("The user which OME should be run under", $OME_USER);
	
		# Get and/or update our apache user information
		$APACHE_USER = get_apache_user($APACHE_USER);

		# Get and/or update our postgres admin information
		$POSTGRES_USER = get_postgres_user($POSTGRES_USER);

		# Get and/or update our "special" Unix user information
		if (y_or_n ("Set up a separate unix admin user for OME (i.e. your unix account)?",'y') ) {
			my $admin_def = $ADMIN_USER;
			if (not defined $admin_def or not $admin_def) {
			# Who owns the cwd?
				$admin_def  = getpwuid((stat ('.'))[4]); 
			}
			undef $ADMIN_USER;
			while (not $ADMIN_USER) {
				$ADMIN_USER = confirm_default ("Unix user to include in the OME group", $admin_def);
				if (not getpwnam($ADMIN_USER)) {
					print "$ADMIN_USER doesn't exist.  Try again.\n";
					undef $ADMIN_USER;
				}
			}
		} else {
			$ADMIN_USER = '';
		}

		# Make sure the rest of the installation knows who the apache and ome users are
		$environment->user($OME_USER);
		$environment->group($OME_GROUP);
		$environment->apache_user($APACHE_USER);
		$environment->postgres_user($POSTGRES_USER);
		$environment->admin_user($ADMIN_USER);
		
		$confirm_all = 1;

		print "\n";  # Spacing
    }

	# If the user is installing from somewhere within OME_BASE_DIR, exit.
	croak <<CROAK if path_in_tree ($$OME_BASE_DIR,getcwd ());
The installer cannot be run from a directory that is anywhere within the base OME directory.
Please move the unpacked OME distribution to your home directory and run the installer again.
The OME base directory should be completely independent of the distribution's directory.
CROAK

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

    if (not getpwnam($POSTGRES_USER)) {
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

	my @user_maps = (
		{ user => $OME_USER,    flag => \$need_to_add_user },
		{ user => $ADMIN_USER,  flag => \$need_to_add_admin_user },
		{ user => $APACHE_USER, flag => \$need_to_add_apache } );
		
	foreach my $map (@user_maps) {
		my $user = $map->{'user'};
		my $flag = $map->{'flag'};

		if ($$flag) {
			if (getpwnam($user) and not get_user($user)) {
				print "\n";  # Spacing

				my $error = <<ERROR;
**** Warning: It appears that the user '$user' is either NIS, LDAP or equivilently backed. You will have to add this user to OME group '$OME_GROUP' in the /etc/group file manually. Please do so *before* continuing.
ERROR
				print wrap("", "", $error);

				print "\n";  # Spacing

				y_or_n("Are you ready to continue ?") or die;
			} else {
				add_user_to_group ($user, $OME_GROUP)
					or croak "Failure adding user \"$user\" to group \"$OME_GROUP\""
			}
		} 
	}

    print "\nBuilding the core system\n";

    #********
    #******** Build our core directory structure
    #********

    foreach my $directory (@core_dirs) {
    	my $path = $directory->{path};
		my $mode = $directory->{mode} || 02755;
		my ($owner,$group) = (
			${$directory->{owner}},
			${$directory->{group}},
		);

		print "  \\_ Checking directory ", BOLD, "\"$path\"", RESET, ".\n";


		# Create this core directory
		unless (-d $path) { 
			print "  \\_   Creating directory\n";
			mkpath($path, 0, $mode);  # Internal croak
		}
		my @stat = stat ($path);

		# Fix ownership non-recursively
		unless ($stat[4] == getpwnam ($owner) and $stat[5] == getgrnam ($group)) {
			print "  \\_   Setting ownership to ", BOLD, $owner,':',$group,RESET,".\n";
			fix_ownership(
				{owner => $owner, group => $group, recurse => 0}, $path);
		}

		# Fix permissions non-recursively
		unless ( ($stat[2] & 07777) == $mode) {
			print "  \\_   Setting permissions to ", BOLD, sprintf ("0%04o",$mode),RESET,".\n";
			fix_permissions( {mode => $mode, recurse => 0}, $path);
		}

		# Create each core dir's children
		foreach my $child (@{$directory->{children}}) {
	    	$child = $path . "/" . $child;
			print "  \\_   Checking child ", BOLD, "\"$child\"", RESET, ".\n";

			# Recursion for children is on by default, but can be over-ridden
			# in the parent.
	    	my $recurse = exists $directory->{recurse} ? $directory->{recurse} : 1 ;
	    	unless (-d $child) {
				print "  \\_     Creating directory\n";
				mkpath($child, 0, $mode);  # Internal croak
			}

	    	@stat = stat ($child);
	    	
			# Fix ownership
			unless ($stat[4] == getpwnam ($owner) and $stat[5] == getgrnam ($group) ) {
				print "  \\_     Setting ownership to ", BOLD, $owner,':',$group,RESET,
					$recurse ? ' (recursively)' : ' (non-recursively)', ".\n";
				fix_ownership(
					{owner => $owner, group => $group, recurse => $recurse}, $child);
			}
	
			# Fix permissions
			unless (($stat[2] & 07777) == $mode) {
				print "  \\_     Setting permissions to ", BOLD, sprintf ("0%04o",$mode),RESET,
					$recurse ? ' (recursively)' : ' (non-recursively)', ".\n";
				fix_permissions( {mode => $mode, recurse => $recurse}, $child);
	    	}
		}
    }

    print "\n";  # Spacing
    
    #********
    #******** Populate stylesheets
    #********

    print "Copying stylesheets\n";
    my @files = glob ("src/xml/xslt/*.xslt");

    foreach my $file (@files) {
		print "  \\_ $file\n";
		copy ($file, $$OME_BASE_DIR."/xml/") or croak ("Couldn't copy file ", $file, ". ", $!, ".\n");
		fix_ownership( {
				owner => $OME_USER,
				group => $OME_GROUP,
			}, "$$OME_BASE_DIR/xml/");
    }
    
    print "\n";  # Spacing
    
    #********
    #******** Copy our HTML/Image core directories from the source tree
    #********

    print "Copying IMAGE directories\n";
    	foreach my $directory (@image_core) {
		print "  \\_ $directory\n";
		copy_tree ("$directory", "$$OME_BASE_DIR", sub{ ! /CVS$/i });
		fix_ownership( {
				owner => $OME_USER,
				group => $OME_GROUP,
			}, "$$OME_BASE_DIR/$directory");
    }
    
	print "Copying CONFIG directories\n";
    	foreach my $directory (@config_core) {
		print "  \\_ $directory\n";
		copy_tree ("$directory", "$$OME_BASE_DIR", sub{ ! /CVS$/i });
		fix_ownership( {
				owner => $OME_USER,
				group => $OME_GROUP,
			}, "$$OME_BASE_DIR/$directory");
    }

    print "Copying HTML directories\n";

    # We need to be in src/ for these copies
    my $iwd = getcwd;
    chdir ("src") or croak "Unable to chdir into src/. $!";

    foreach my $directory (@html_core) {
		print "  \\_ $directory\n";

		# DON'T copy html/Templates	that directory requires special treatement
		# so we don't over-write user defined templates. Read [Bug 531] 
		copy_tree ("$directory", "$$OME_BASE_DIR", sub{ ! /Templates$/i and !/CVS$/i});
		fix_ownership( {
				owner => $OME_USER,
				group => $OME_GROUP,
			}, "$$OME_BASE_DIR/$directory");
    }
    

    #********
    #******** Save the configuration so far
    #********
    $environment->store_to();

    chdir ($iwd) or croak "Unable to chdir back to \"$iwd\". $!";

    print "\n";  # Spacing

    #********
    #******** Build our core binaries in src/C
    #********

    print_header ("Core Binary Setup");
    
    my $INSTALL_HOME = "$$OME_TMP_DIR/install";
    my $LOGFILE_NAME = "BinaryBuilds.log";
    my $LOGFILE;

    # Get our logfile and open it for writing
    open ($LOGFILE, ">", "$INSTALL_HOME/$LOGFILE_NAME")
		or croak "Unable to open logfile \"$INSTALL_HOME/$LOGFILE_NAME\". $!";

    print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

    my $retval = 0;

	##############
	# OMEIS
	##############
	print "Installing OMEIS\n";

    # Configure
    unless ($environment->get_flag("NO_BUILD")) {
        print "  \\_ Configuring ";
        $retval = configure_module ("src/C/omeis", $LOGFILE, {options => "--prefix=$$OME_BASE_DIR --with-omeis-root=$$OMEIS_BASE_DIR"});
         
        print BOLD, "[FAILURE]", RESET, ".\n"
            and croak "Unable to configure module, see $LOGFILE_NAME for details."
            unless $retval;
        print BOLD, "[SUCCESS]", RESET, ".\n";
    
        # Compile
        print "  \\_ Compiling ";
        $retval = compile_module ("src/C/omeis", $LOGFILE);
        
        print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile OME core binaries, see $LOGFILE_NAME for details."
            unless $retval;
        print BOLD, "[SUCCESS]", RESET, ".\n";
    }
    
	# Install
    print "  \\_ Installing ";
    $retval = install_module ("src/C/omeis", $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
	and croak "Unable to install OME core binaries, see $LOGFILE_NAME for details."
	    unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";
    
    ##############
	# OMEIS - HTTP
	##############
	print "Installing omeis-http\n";
	print "  \\_ Configuring ";
	$retval = configure_module ("src/C/omeis-http", $LOGFILE);
	 
	print BOLD, "[FAILURE]", RESET, ".\n"
		and croak "Unable to configure module, see $LOGFILE_NAME for details."
		unless $retval;
	print BOLD, "[SUCCESS]", RESET, ".\n";

	# Compile
	print "  \\_ Compiling ";
	$retval = compile_module ("src/C/omeis-http", $LOGFILE);
	
	print BOLD, "[FAILURE]", RESET, ".\n"
	and croak "Unable to compile OME core binaries, see $LOGFILE_NAME for details."
		unless $retval;
	print BOLD, "[SUCCESS]", RESET, ".\n";
        
        
	##############
	# core binaries
	##############
	
    print "Installing core binaries\n";
    
    # Set the env variable OME_ROOT so that things get installed in the right places.
    # FIXME: This is only necessary for the Makefile in src/C.
	$ENV{OME_ROOT} = $$OME_BASE_DIR;
    
    # XXX: Unneeded at the moment
    # Configure
    # print "  \\_ Configuring ";
    # $retval = configure_module ("src/C/", $LOGFILE);
    # 
    #print BOLD, "[FAILURE]", RESET, ".\n"
    #    and croak "Unable to configure module, see $LOGFILE_NAME for details."
    #    unless $retval;
    #print BOLD, "[SUCCESS]", RESET, ".\n";
    
    # Compile
    unless ($environment->get_flag("NO_BUILD")) {
        print "  \\_ Compiling ";
        $retval = compile_module ("src/C/", $LOGFILE);
        
        print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile OME core binaries, see $LOGFILE_NAME for details."
            unless $retval;
        print BOLD, "[SUCCESS]", RESET, ".\n";
    }

    # Install
    print "  \\_ Installing ";
    $retval = install_module ("src/C/", $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
	and croak "Unable to install OME core binaries, see $LOGFILE_NAME for details."
	    unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

	close ($LOGFILE);
    
    print "\n";  # Spacing
    
    
    return;
}

sub rollback {
    print "Rollback";
    return;
}

1;
