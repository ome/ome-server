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

# Global logfile filehandle and name
my $LOGFILE_NAME = "LibraryTask.log";
my $LOGFILE;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER);

# OME user information
my ($OME_UID, $OME_GID);

# Installation home
my $INSTALL_HOME;

# The libraries we're managing
my @libraries = ( {
		name => 'libssl',
		get_library_version => q{
			#include "openssl/opensslv.h"
			int main () {
				printf ("%s", SHLIB_VERSION_NUMBER);
				return (0);
			}
		},
		valid_versions => ['ge 0.9'],
	}, {
		name => 'libpng',
		get_library_version => q(
	    	#include "png.h"
	    	int main () {
			printf ("%d.%d.%d",
		        	(PNG_LIBPNG_VER / 10000),
					(PNG_LIBPNG_VER % 10000 / 100),
					(PNG_LIBPNG_VER % 100));

			return (0);
	    	}
		),
		valid_versions => ['ge 1.0'],
    }, {
		name => 'libjpeg',
		get_library_version => q{
			#include "stdio.h"
	    	#include "jpeglib.h"
	    	int main () {
				printf ("%d", JPEG_LIB_VERSION);

				return (0);
	    	}
		},
		valid_versions => ['ge 60'],
    }, {
		name => 'libtiff',
		# XXX Unfortunately, this only works with new libtiff's... *sigh*
		#get_library_version => q(
		# 	#include "tiffvers.h"
		#		/* Semi-ganked from GAIM (http://gaim.sourceforge.net/) cvs rc line parser
		#		 * src/gaimrc.c -- parse_line()
		#		 * Thanks to ChipX86 for the great idea, this version stub rocks.
		#	 */
		# 	int main () {
		#		char * c;
		#			c = (char *) calloc (strlen (TIFFLIB_VERSION_STR) + 1, sizeof(char));
		#			strcpy (c, TIFFLIB_VERSION_STR);
		#                                                                        
		#			while (*c != '\n') {
		#	   			if ((*c == '.') || ((*c >= 48) && (*c <= 57))) {
		#					printf ("%c", *c);
		#	   			}
		#	   		c++;
		#			}
		#
		#		return (0);
		#		}
		#	),
		get_library_version => q(
			#include "tiff.h"
			/* For the moment, with backwards compatability in mind we can't do
			 * anything better than check if the lib is installed and working.
			 */
			int main () {
				printf ("%s", "N/A");

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
    }, {
		name => 'libgd',
		pre_install => sub {
			my $library = shift;
			my $gdlib_config = 'gdlib-config';

			my $version_sub = sub {
	    		my $version = `gdlib-config --version`;
	    		chomp $version;
				return $? == 0 ? $version : undef;
			};

			$library->{get_library_version} = $version_sub if which($gdlib_config);
		},
		get_library_version => q(
	    	#include "gd.h"
			/* There's no crossplatform way to do this for version 1 so
		 	 * we'll assume the lib is okay if we can link against it.
		 	 * This will get overwritten with a sub if we've got version 2.
		 	 */
	    	int main () {
			printf ("%s", "N/A");

			return (0);
			}
	    ),
		valid_versions => ['ge "1.8.3"'],
	}, {
		name => 'zlib',
		get_library_version => q(
	    	#include "zlib.h"
	    	int main () {
			printf ("%s", ZLIB_VERSION);

			return (0);
	    	}
		),
		valid_versions => ['ge "1.1.4"'],
		repository_file => "$REPOSITORY/zlib-1.1.4.tar.gz",
    }, {
		name => 'libxml2',
		get_library_version => sub {
	    	my $xml2_config = "xml2-config";
			my $version;

	    	$xml2_config = whereis ("xml2-config") unless which ("$xml2_config");

			if ($xml2_config) {
	    		$version = `$xml2_config --version`;
	    		chomp $version;
			} else {
				return undef;
			}

	    	return $? == 0 ? $version : undef;
		},
		valid_versions => ['ge 2.4.20'],
		repository_file => "$REPOSITORY/libxml2-2.5.7.tar.gz",
    }, {
		name => 'libxslt',
		get_library_version => sub {
	    	my $xslt_config = "xslt-config";
			my $version;

	    	$xslt_config = whereis ("xslt-config") unless which ("$xslt_config");

			if ($xslt_config) {
	    		$version = `$xslt_config --version`;
	    		chomp $version;
			} else {
				return undef;
			}

	    	return $? == 0 ? $version : undef;
		},
		repository_file => "$REPOSITORY/libxslt-1.0.30.tar.gz",
		valid_versions => ['ge "1.0"'],
    }, {
		name => 'bzlib',
		get_library_version => q(
			#include "stdio.h"
	    	#include "bzlib.h"
			/* There's really no cross platform way to do this other than
	    	 * grep'ing for comment data so we'll just assume we've got a
	    	 * halfway decent version as long as we can compile a stub C
	    	 * app with bzlib support. Not to mention it only includes the
	    	 * "main" version not the full one, as far as I can tell there's
	    	 * absolutely no way to decern version 1.0 from 1.0.2 in the source.
			 */
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
        and croak "Unable to download package, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Unpack
    print "    \\_ Unpacking ";
    $retval = unpack_archive ($filename, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to unpack package, see $LOGFILE_NAME for details."
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
        and croak "Unable to configure library, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Compile
    print "    \\_ Compiling ";
    $retval = compile_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile library, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Install
    print "    \\_ Installing ";
    $retval = install_module ($wd, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to install library, see $LOGFILE_NAME for details."
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

    # Set our installation home
    $INSTALL_HOME = '/tmp';
	
	# Store our IWD so we can get back to it later
	my $iwd = getcwd;
    
    # chdir into our INSTALL_HOME	
    chdir ($INSTALL_HOME) or croak "Unable to chdir to \"$INSTALL_HOME\", $!";
    
    print_header ("C Library Dependency Setup");

    print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/$LOGFILE_NAME")
		or croak "Unable to open logfile \"$INSTALL_HOME/$LOGFILE_NAME\". $!";
		
	# Bad library flag
	my $bad_libraries;

    #*********
    #********* Check each module (exceptions then version)
    #*********

    print "Checking libraries\n";
    foreach my $library (@libraries) {
		print "  \\_ $library->{name}";

		my @error;

		# Pre-install
		&{$library->{pre_install}}($library) if exists $library->{pre_install};

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

	    	open (my $CHECK_C, ">", $source_file)
				or croak "Unable to create version check source file for \"$library->{name}\" $!";
			print $CHECK_C ($library->{get_library_version}, "\n"); 
	    	close ($CHECK_C);

	    	$CC = whereis ("compiler") unless which ("$CC");
			@error = `$CC $source_file -o $binary 2>&1`;

	    	if ($? == 0) {
				$library->{version} = `$binary 2>&1`;
	    
				croak "Woah! Failure to execute the check function for $library->{name}, $library->{version}"
					if $?;
	    	}
		}

		if (not $library->{version}) {
	    	# Log the error returned by get_library_version ()
	    	print $LOGFILE "ERRORS LOADING LIBRARY \"$library->{name}\" -- OUTPUT: \"", $@ || @error, "\"\n\n";

	    	print BOLD, " [NOT INSTALLED]", RESET;

			$library->{version} = 'N/A';
			
			$bad_libraries = 1;
		}

		if (check_library($library)) {
			print " $library->{version} ", BOLD, "[OK]", RESET, ".\n";
			next;
		} else {
			print " $library->{version} ", BOLD, "[UNSUPPORTED]", RESET, ".\n";
			print STDERR "\nUnsupported version \($library->{version}\) of \"$library->{name}\".\n\n";

			$bad_libraries = 1;
		}
	}

	if ($bad_libraries) {
		my $y_or_n = y_or_n ("One or more libraries is not installed or is of an unsupported version. Please read the installation notes for your platform in /doc (INSTALL.FreeBSD for example) for a detailed list of OME's library dependencies and locations to get packages if available. \n\nIf you, for example, have installed all these specific dependencies beforehand these checks may fail due to a lack of development files and you may wish to continue anyway. \n\nWould you like to continue ?");

		exit(1) unless $y_or_n;
	}

	chdir ($iwd) or croak "Unable to return to our initial working directory \"$iwd\", $!";

	print "\n";  # Spacing

    return 1;
}

sub rollback {
    croak "Rollback!\n";

    # Just a stub for now
    return 1;
}

1;
