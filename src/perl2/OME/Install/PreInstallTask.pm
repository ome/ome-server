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
use Text::Wrap;

#use base qw(OME::Install::InstallationTask);
use OME::Install::Util;
use OME::Install::Environment;

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

sub y_or_n {
    my $text = shift;
    my $def_yorn = shift;
    my $y_or_n;
    my $environment = initialize OME::Install::Environment;
    return 1 if ($environment->get_flag ("ANSWER_Y"));

    $def_yorn = 'n' unless defined $def_yorn;
	if ($def_yorn eq 'n') {
   	    print wrap("", "", $text), " [y/", BOLD, "n", RESET, "]: ";
        $y_or_n = <STDIN>;
        chomp $y_or_n;
        if (lc($y_or_n) eq "y") { return 1 };
        return 0;
   	} else {
   	    print wrap("", "", $text), " [", BOLD, "y", RESET, "/n]: ";
        $y_or_n = <STDIN>;
        chomp $y_or_n;
        if (lc($y_or_n) eq "n") { return 0 };
        return 1;
   	}
}


# Simplified version of the OME::Install::PerlModuleTask subroutines
sub install {
    my $module = shift;
    my $filename = basename ($module->{repository_file});  # Yes, it works on URL's too *cheer*
    my $dir = basename ($filename, ".tar.gz");
    my $iwd = getcwd;  # Initial working directory

    chdir ("$INSTALL_HOME") or croak "Unable to chdir to \"$INSTALL_HOME\". $!";

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

    open ($LOGFILE, ">", "/dev/null");

    my @install_mods;
    my $module;

    # If the module is installed we'll just print the version and return
    foreach $module (@modules) {
        my $version = get_module_version ($module->{name}); 
        if ($version) {
            print $module->{name}." - Version $version \n";
        } else {
            print $module->{name}." - Not Installed!\n";
            push (@install_mods,$module);
        }
    }

    if (scalar @install_mods) {
        print wrap("", "", "\nThe OME installation system requires the Storable and Term::ReadKey modules (both included in Perl versions 5.8.0 and higher). One or more of these is missing on your system.  This installer will now install these packages for you.");
        print "\n\n";
        y_or_n ("Would you like to continue ?",'n') or die
            "Installer could not proceed without required Perl modules.\nPlease install these manually and run the installer again\n";
        print "\n";  # Spacing
        foreach (@install_mods) {
            print "Installing ".$_->{name}." ";
            print BOLD, "[INSTALLED]", RESET, ".\n" if install ($_);
        }
    }
    print "\n";  # Spacing

   close ($LOGFILE);
}

sub rollback {
    print "Rollback.\n";

}


1;
