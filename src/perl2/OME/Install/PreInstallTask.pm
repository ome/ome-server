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

#use base qw(OME::Install::InstallationTask);
use OME::Install::Util;

#*********
#********* GLOBALS AND DEFINES
#*********

# Installation home for the pre-install
my $INSTALL_HOME = "/tmp";

# Default package repository
my $REPOSITORY = "http://openmicroscopy.org/packages/perl";

# Modules that need to be pre-installed
my @modules = (
    {
	name => 'Term::ReadKey',
	repository_file => "$REPOSITORY/TermReadKey-2.21.tar.gz"
 	},{
	name => 'Storable',
	repository_file => "$REPOSITORY/Storable-1.0.13.tar.gz"
   	}
);

# Log filehandle for the task (right now we're using /dev/null)
my $LOGFILE;

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
sub install {
    my $module = shift;
    my $filename = basename ($module->{repository_file});  # Yes, it works on URL's too *cheer*
    my $dir = basename ($filename, ".tar.gz");
    my $iwd = getcwd;  # Initial working directory

    chdir ("$INSTALL_HOME") or croak "Unable to chdir to \"$INSTALL_HOME\". $!";

    # If the module is installed we'll just print the version and return
    my $version = get_module_version ("$module->{name}"); 
    if ($version) {
	print "Version $version ";
	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    }

    # Download
    download_package ($module, $LOGFILE)
	or croak "Unable to download \"$module->{name}\".";

    # Extract
    unpack_archive ("$filename", $LOGFILE)
	or croak "Unable to extract \"$filename\".";

    # Configure
    configure_module ($dir, $LOGFILE)
	or croak "Unable to configure \"$module->{name}\".";

    # Make
    compile_module ($dir, $LOGFILE)
	or croak "Unable to compile \"$module->{name}\".";
    
    # Test
    test_module ($dir, $LOGFILE)
	or croak "Unable to test \"$module->{name}\".";
    
    # Install
    install_module ($dir, $LOGFILE)
	or croak "Unable to install \"$module->{name}\".";

    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 1;
}

#*********
#********* START OF CODE
#*********


sub execute {
    print_header ("Pre-Installation");
    
	croak "Unable to locate a suitable compiler." unless which("cc");
	croak "Unable to locate a suitable make binary." unless which("make");

    open ($LOGFILE, ">", "/dev/null");

    print "Installing Term::ReadKey if needed. ";
    my $retval = install ($modules[0]);
    
    print BOLD, "[INSTALLED]", RESET, ".\n" if $retval;

	print "Installing Storable if needed. ";
    $retval = install ($modules[1]);

    print BOLD, "[INSTALLED]", RESET, ".\n" if $retval;

    print "\n";  # Spacing

   close ($LOGFILE);
}

sub rollback {
    print "Rollback.\n";

}


1;
