#!/usr/bin/perl
# This script implements the main user interaction with OME's installation
# framework (src/perl2/OME/Install/).
 
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

#*********
#********* INCLUDES
#*********

use warnings;
use strict;
use Getopt::Long;
use lib qw(src/perl2);
use Carp;
use English;
use Text::Wrap;

# OME Modules
require OME::Install::PreInstallTask;

#*********
#********* GLOBALS AND DEFINES
#*********

# Main task queue
my @tasks = qw(
    OME::Install::LibraryTask
    OME::Install::CoreSystemTask
    OME::Install::PerlModuleTask
    OME::Install::ApacheConfigTask
    OME::Install::CoreDatabaseTablesTask
);

# Task stack
my @tasks_done = ();

#*********
#********* LOCAL SUBROUTINES
#*********

sub run_tasks {
	print wrap("", "", "\nThe OME installation system requires the Storable and Term::ReadKey modules (both included in Perl versions 5.8.0 and higher). The system will now check for the existance of those packages and install them if needed. \n\nWould you like to continue ? [y/n]: ");
	my $y_or_n = <STDIN>;
	chomp $y_or_n;
	exit (0) unless (lc($y_or_n) eq 'y');

	print "\n";  # Spacing

    # PreInstall
    OME::Install::PreInstallTask::execute();

    # Run each task and fill our done stack
    while (my $task = shift @tasks) {
		eval "require $task";
		croak "\n\nErrors loading module: $@\n" if $@;  # Really only for debugging purposes
		$task .= "::execute()";
		eval $task;
		croak "\n\nErrors executing task: $@\n" if $@;  # Ditto as above
		push (@tasks_done, $task);
    }

    return 1;
}

sub restore_env {
    my $env_file = shift;
	require OME::Install::Environment;

    ($env_file and -e $env_file) or usage ("Unable to locate Environment file \"$env_file\".");

    # Restore our singleton from disk
    OME::Install::Environment::restore_from ($env_file);

    return 1;
}

sub usage {
    my $error = shift;
    my $usage = "";

    $usage = "**** ERROR: $error\n\n" if $error; 
    $usage .= <<USAGE;
OME install script. Bootstraps the environment and database as well as 
being able to run upgrades and sanity checks on a current installation.

Usage:
  $0 [options]

Options:
  -u, --update      do an update instead of install
  -f, --env-file    Location of the stored environment overrides
                    the default of "/OME/conf/environment.store"
  -c, --perl-check  Just run a Perl module check using the
                    stored environment
  -l, --lib-check   Just run a library check using the stored
                    environment
  -i, --install     Default execution
  -a, --check-all   Run all our sanity checks
  -h, --help        This message

Report bugs to <ome-devel\@mit.edu>.
USAGE

    print STDERR $usage;
    exit (1) if $error;
    exit (0);
}

#*********
#********* START OF CODE
#*********

# Number of checks to run
my $checks_to_run = 0;

# Default env file location
my $env_file = ('/OME/conf/environment.store');

# Command line options
my ($update, $perl_check, $lib_check, $check_all, $usage, $install);

# Parse our command line options
GetOptions ("u|update" => \$update,         # update
            "f|env-file=s" => \$env_file,   # Environment file
            "c|perl-check" => \$perl_check, # Just run the perl module task
			"l|lib-check" => \$lib_check,   # Just run the library task
			"a|check-all" => \$check_all,   # Set $perl_check, $lib_check
			"i|install" => \$install,       # Default (unused at the moment)
			"h|help" => \$usage,            # Display help
		);

# Root check
usage ("You must be root (UID 0) in order to install OME.") unless $EUID == 0;

usage () if $usage;

if ($check_all) { $perl_check = 1; $lib_check = 1; $checks_to_run = 2; }

# These need a restored environment
if ($perl_check or $update) {
	restore_env ($env_file)
}

if ($update) {
    my $environment = initialize OME::Install::Environment;
    $environment->set_flag ("UPDATE");
}

if ($lib_check) {
	require OME::Install::Environment;

    # Initialize our environment and set the LIB_CHECK flag
	my $environment = initialize OME::Install::Environment;
    $environment->set_flag ("LIB_CHECK");

    eval "require OME::Install::LibraryTask";
    croak "Errors loading module: $@\n" if $@;  # Really only for debugging purposes

    OME::Install::LibraryTask::execute ();
    croak "Errors loading module: $@\n" if $@;  # Really only for debugging purposes

    --$checks_to_run;

    exit (0) if $checks_to_run < 1;
}

if ($perl_check) {

    # Initialize our environment and set the PERL_CHECK flag
    my $environment = initialize OME::Install::Environment;
    $environment->set_flag ("PERL_CHECK");

    eval "require OME::Install::PerlModuleTask";
    croak "Errors loading module: $@\n" if $@;  # Really only for debugging purposes

    OME::Install::PerlModuleTask::execute ();
    croak "Errors loading module: $@\n" if $@;  # Really only for debugging purposes

    --$checks_to_run;

    exit (0) if $checks_to_run < 1;
}

run_tasks ();

# Store environment
eval "require Storable; require OME::Install::Environment";

unless ($@) {
	my $environment = initialize OME::Install::Environment;
	my $conf_dir = $environment->base_dir () . "/conf";
	$environment->store_to ("$conf_dir/environment.store");
} else {
	carp "Unable to load the Storable module, continuing without a stored OME::Install::Environment!";
}

exit (0);
