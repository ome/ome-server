# OME/Install/LibraryTask.pm
# This task builds the required libraries for the OME system.

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

package OME::Install::LibraryTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use English;
use Cwd;
use Term::ANSIColor qw(:constants);
use File::Basename;

use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

# Default package repository
my $REPOSITORY = "http://openmicroscopy.org/packages/source";

# Default ranlib command
my $RANLIB= "ranlib";

# Global logfile filehandle
my $LOGFILE;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER);

# OME user information
my ($OME_UID, $OME_GID);

# Installation home
my $INSTALL_HOME;

# The libraries we're managing
my @libraries = (
    {
	name => 'zlib',
	get_library_version => q{
	    #include "zlib.h"
	    int main () {
		printf ("%s", ZLIB_VERSION);

		return (0);
	    }
	},
	valid_versions => ['ge "1.1.3"'],
	repository_file => "$REPOSITORY/zlib-1.1.4.tar.gz",
    },{
	name => 'libxml2',
	get_library_version => sub {
	    my $xml2_config = "xml2-config";

	    $xml2_config = whereis ("xml2-config") unless which ("$xml2_config");

	    my $version = `$xml2_config --version`;
	    chomp $version;

	    return $? == 0 ? $version : undef;
	},
	valid_versions => ['ge 2.5.7'],
	repository_file => "$REPOSITORY/libxml2-2.5.7.tar.gz",
	#installModule => \&LibXMLInstall,
    },{
	name => 'libxslt',
	get_library_version => sub {
	    my $xslt_config = "xslt-config";

	    $xslt_config = whereis ("xslt-config") unless which ("$xslt_config");

	    my $version = `$xslt_config --version`;
	    chomp $version;

	    return $? == 0 ? $version : undef;
	},
	repository_file => "$REPOSITORY/libxslt-1.0.30.tar.gz",
	valid_versions => ['ge "1.0.30"'],
	#installModule => \&LibXSLTInstall,
    },{
	name => 'bzlib',
	get_library_version =>
	    # There's really no cross platform way to do this other than
	    # grep'ing for comment data so we'll just assume we've got a
	    # halfway decent version as long as we can compile a stub C
	    # app with bzlib support. Not to mention it only includes the
	    # "main" version not the full one, as far as I can tell there's
	    # absolutely no way to decern version 1.0 from 1.0.2 in the source.
	    q(
	    #include "bzlib.h"
	    int main () {
		printf ("%s", "N/A");
		return (0);
	    }
	),
	configure_library => sub {
	    my ($path, $logfile) = @_;
	    
	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';
	    print $logfile "BZLIB DOESN'T NEED TO BE CONFIGURED -- SKIPPING CONFIGURATION\n";

	    return 1;
	},
	repository_file => "$REPOSITORY/bzip2-1.0.2.tar.gz",
	#installModule => \&bzlibInstall,
    },{
	name => 'libtiff',
	get_library_version =>
	# Semi-ganked from GAIM (http://gaim.sourceforge.net/) cvs rc line parser
	# src/gaimrc.c -- parse_line ()
	# Thanks to ChipX86 for the great idea, this version stub rocks.
	    q(
	    #include "tiffvers.h"
	    int main () {
		char * c;
		c = (char *) calloc (strlen (TIFFLIB_VERSION_STR) + 1, sizeof(char));
		strcpy (c, TIFFLIB_VERSION_STR);
                                                                                
		while (*c != '\n') {
		    if ((*c == '.') || ((*c >= 48) && (*c <= 57))) {
			printf ("%c", *c);
		    }
		    c++;
		}
		free (c);

	    return (0);
	    }
	),
	configure_library => sub {
	    # Since libtiff has an interactive configure script we need to
	    # implement a custom configure_library () subroutine that allows
	    # for an interactive install
	    
	    my ($path, $logfile) = @_;
	    my $iwd = getcwd;  # Initial working directory

	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

	    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

	    system ("./configure 2>&1");

	    chdir ($iwd) or croak "Unable to chdir back into \"$iwd\", $!";

	    return 1;
	},
	valid_versions => ['ge "3.5.7"'],
	repository_file => "$REPOSITORY/tiff-v3.5.7-OSX-LZW.tar.gz",
	#installModule => \&tiffInstall,
    }
);

#*********
#********* LOCAL SUBROUTINES
#*********

sub check_library {
    my $library = shift;
    my $retval = 0;

    return 1 unless exists $library->{valid_versions};

    foreach my $valid_version (@{$library->{valid_versions}}) {
	my $eval = 'if ("$library->{version}" '.$valid_version.') { $retval = 1 }';

	eval $eval;
	last if $retval;
    }

    return $retval ? 1 : 0;
}

sub install {
    my $library = shift;
    print "$library->{repository_file}\n";
    my $filename = basename ($library->{repository_file});  # Yes, it works on URL's too *cheer*
    my $retval = 0;
    my @output;

    $EUID = 0;

    #*********
    #********* Initial setup
    #*********

    # Pre-install
    if (exists $library->{pre_install}) {
	print "    \\_ Pre-install ";
	&{$library->{pre_install}};
	print BOLD, "[SUCCESS]", RESET, ".\n";
    }

    # Download
    print "    \\_ Downloading $library->{repository_file} ";
    $retval = download_package ($library, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to download package, see LibraryTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Unpack
    print "    \\_ Unpacking ";
    $retval = unpack_archive ($filename, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to unpack package, see LibraryTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    #*********
    #********* Actual module install
    #*********

    my $wd = basename ($filename, ".tar.gz");

    # Configure
    print "    \\_ Configuring ";
    $retval = &{$library->{configure_library}}($wd, $LOGFILE) if exists $library->{configure_library};
    $retval = configure_library ($wd, $LOGFILE) unless exists $library->{configure_library};
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to configure library, see LibraryTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Compile
    print "    \\_ Compiling ";
    $retval = compile_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile library, see LibraryTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Install
    print "    \\_ Installing ";
    $retval = install_module ($wd, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to install library, see LibraryTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    return;
}

#*********
#********* START OF CODE
#*********

sub execute {
    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;

    # Set our globals
    $OME_BASE_DIR = $environment->base_dir()
	or croak "Unable to retrieve OME_BASE_DIR!";
    $OME_TMP_DIR = $environment->tmp_dir()
	or croak "Unable to retrieve OME_TMP_DIR!";
    $OME_USER = $environment->user()
	or croak "Unable to retrieve OME_USER!";
    
    # Store our IWD so we can get back to it later
    my $iwd = getcwd;

    # Retrieve some user info from the password database
    $OME_UID = getpwnam($OME_USER) or croak "Failure retrieving user id for \"$OME_USER\", $!";

    # Set our installation home
    $INSTALL_HOME = $OME_TMP_DIR."/install";
    
    # chdir into our INSTALL_HOME	
    chdir ($INSTALL_HOME) or croak "Unable to chdir to \"$INSTALL_HOME\", $!";
    
    print_header ("C Library Dependency Setup");

    print "(All verbose information logged in $INSTALL_HOME/LibraryTask.log)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/LibraryTask.log")
	or croak "Unable to open logfile \"$INSTALL_HOME/LibraryTask.log\". $!";

    #*********
    #********* Check each module (exceptions then version)
    #*********

    print "Checking libraries\n";
    foreach my $library (@libraries) {
	print "  \\_ $library->{name}";
	my @error;

	# Pre-install
	&{$library->{pre_install}} if exists $library->{pre_install};

	# Exceptions
	if (exists $library->{exception} and &{$library->{exception}}) {
	    print BOLD, " [OK]", RESET, ".\n";
	    next;
	}

	# If getting the library version requires a subroutine execute it
	if (ref ($library->{get_library_version}) eq 'CODE') {
	    $library->{version} = &{$library->{get_library_version}};
	} else {
	    # We need to compile some source in order to get our library version
	    my $binary = "$INSTALL_HOME/$library->{name}_check";
	    my $source_file = $binary.".c";
	    my $CC = "gcc";

	    open (my $CHECK_C, ">", $source_file);
	    print $CHECK_C ($library->{get_library_version}, "\n"); 
	    close ($CHECK_C);

	    $CC = whereis ("compiler") unless which ("$CC");
	    @error = `$CC $source_file -o $binary 2>&1`;

	    if ($? == 0) {
		$library->{version} = `$binary 2>&1`;
	    
		croak "Woah! Failure to execute the check function for $library->{name}, $library->{version}" if $?;
	    }
	}

	if (not $library->{version}) {
	    # Log the error returned by get_library_version ()
	    print $LOGFILE "ERRORS LOADING LIBRARY \"$library->{name}\" -- OUTPUT: \"", $@ || @error, "\"\n\n";

	    print BOLD, " [NOT INSTALLED]", RESET;
	    my $retval = y_or_n("\n\nWould you like to install $library->{name} from the repository ?");

	    if ($retval) {
		install ($library);
		next;
	    } else { 
		print "**** Warning: Not installing library $library->{name}.\n\n"; 
		next;
	    }
	}

	if (check_library($library)) {
	    print " $library->{version} ", BOLD, "[OK]", RESET, ".\n";
	    next;
	} else {
	    print " $library->{version} ", BOLD, "[UNSUPPORTED]", RESET, ".\n";
	    my $retval = y_or_n("\nWould you like to install the library from the OME repository ?");

	    if ($retval) {
		install ($library);
		next;
	    } else { 
		print "**** Warning: Not installing known compatible version of $library->{name}.\n\n"; 
		next;
	    }
	}
    }

    print "\n";  # Spacing

    return 1;
}

sub rollback {
    print "Rollback!\n";

    return 1;
}
