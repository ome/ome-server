# OME/Install/PreInstallTask.pm
# This module does all the Pre-Install setup, it requires no special modules and
# anything that is included shouldn't either.

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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

package OME::Install::PreInstallTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use English;
use Carp;
use Cwd;
use File::Basename;
use Term::ANSIColor qw(:constants);

use base qw(OME::Install::InstallationTask);
use OME::Install::Util;

#*********
#********* GLOBALS AND DEFINES
#*********

# Installation home for the pre-install
my $INSTALL_HOME = "/tmp";

# Repository for the modules
my $REPOSITORY = "http://openmicroscopy.org/packages/perl/";

#*********
#********* LOCAL SUBROUTINES
#*********

# Ripped from OME::Install::Terminal
sub print_header {
    my $header_text = shift;
    my $strlen = length($header_text) + 2;

    print BOLD;
    print "-" x $strlen, "\n";
    print " $header_text\n";
    print "-" x $strlen, "\n\n";
    print RESET;
}

# Simplified version of the OME::Install::PerlModuleTask subroutines
sub install_readkey {
    my $downloader;
    my $module_url = "http://openmicroscopy.org/packages/perl2/TermReadKey-2.21.tar.gz";
    my $cwd = getcwd;

    # If ReadKey is installed we'll just return
    my $version = get_module_version ("Term::ReadKey"); 
    if ($version) {
	print "Version $version ";
	return 1;
    }
   
    # Find a useable download app (curl|wget)
    if (system ("which wget 2>&1 >/dev/null") == 0) {
	$downloader = "wget -N";
    } elsif (system ("which curl 2>&1 >/dev/null") == 0) {
	$downloader = "curl -O";
    } else {
	croak "Unable to find a valid downloader for Term::ReadKey install.";
    }

    # Download
    (system ("$downloader $module_url 2>&1 >/dev/null") == 0)
	or croak "Unable to download \"$module_url\" using \"$downloader\".";

    # Extract
    (system ("tar zxf TermReadKey-2.21.tar.gz 2>&1 >/dev/null") == 0)
	or croak "Unable to extract \"$INSTALL_HOME/TermReadKey-2.21.tar.gz\".";

    # Go inside the build directory
    chdir ("TermReadKey-2.2.1") or croak "Unable to chdir into \"TermReadKey-2.2.1\". $!";

    # Configure
    (system ("perl Makefile.PL") == 0)
	or croak "Unable to configure Term::ReadKey.";

    # Make
    (system ("make") == 0)
	or croak "Unable to compile Term::ReadKey.";
    
    # Test
    (system ("make test") == 0)
	or croak "Unable to test Term::ReadKey.";
    
    # Install
    (system ("make install") == 0)
	or croak "Unable to install Term::ReadKey.";

    return 1;
}

#*********
#********* START OF CODE
#*********


sub execute {
    print_header ("Pre-Installation");

    print "Installing Term::ReadKey if needed. ";
    my $retval = install_readkey ();

    print BOLD, "[INSTALLED]", RESET, ".\n" if $retval;

    print "\n";  # Spacing

    return;
}

sub rollback {
    print "Rollback.\n";

    return;
}
