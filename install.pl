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
use FindBin;
use File::Spec::Functions qw(catdir);
use lib catdir ($FindBin::Bin,'src','perl2');
use Carp;
use English;
use Text::Wrap;

# OME Modules
#
# This requires Storable in an eval , so its always safe unless we call
# store_to() or restore_from()
use OME::Install::Environment;

#*********
#********* GLOBALS AND DEFINES
#*********

# Main task queue
my @tasks = qw(
    OME::Install::PreInstallTask
    OME::Install::LibraryTask
    OME::Install::CoreSystemTask
    OME::Install::PerlModuleTask
    OME::Install::ApacheConfigTask
    OME::Install::CoreDatabaseTablesTask
    OME::Install::MaintenanceTask
);

# Task stack
my @tasks_done = ();

#*********
#********* LOCAL SUBROUTINES
#*********

sub run_tasks {

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
    
    my @search_paths = (
    	$env_file,
    	'/etc/ome-install.store',
    	'/OME/conf/environment.store',
    );
    $env_file = undef;
    foreach (@search_paths) {
	    if (-e $_) {
			$env_file = $_;
	    	last;
	    }
    }

    # Restore our singleton from disk
    OME::Install::Environment::restore_from ($env_file) if $env_file;

    return 1 if $env_file;
    return 0;
}

sub usage {
    my $error = shift;
    my $usage = "";

    $usage = <<USAGE;
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
  -y, --yes         Answer 'y' to all the questions (implies -u)
  -h, --help        This message

Report bugs to <ome-devel\@lists.openmicroscopy.org.uk>.

USAGE
    $usage .= "**** ERROR: $error\n\n" if $error; 

    print STDERR $usage;
    exit (1) if $error;
    exit (0);
}

#*********
#********* START OF CODE
#*********

# Set the cwd to wherever we ran the script from
chdir ($FindBin::Bin);

# Number of checks to run
my $checks_to_run = 0;

# Default env file location
my $env_file = ('/etc/ome-install.store');

# Command line options
my ($update, $perl_check, $lib_check, $check_all, $usage, $install, $answer_y);

# Parse our command line options
GetOptions ("u|update" => \$update,         # update
            "f|env-file=s" => \$env_file,   # Environment file
            "c|perl-check" => \$perl_check, # Just run the perl module task
			"l|lib-check" => \$lib_check,   # Just run the library task
			"a|check-all" => \$check_all,   # Set $perl_check, $lib_check
			"i|install" => \$install,       # Default (unused at the moment)
			"y|yes" => \$answer_y,          # Always answer 'y', set $update
			"h|help" => \$usage,            # Display help
		);

# Root check
usage (<<ERROR) unless $EUID == 0;
The installer must be run as the root user:
> sudo perl install.pl
    *** Enter your password when asked ***
Or, if you can't run sudo:
> su
    *** Enter the root user's password when asked
# perl install.pl
ERROR

# The installer cannot be run from a directory owned by root
usage (<<ERROR) if (stat ('.'))[4] == 0;
The installer cannot be run from a directory owned by root.
Please download and unpack the OME distribution as a regular user,
in a regular user's home directory.  Then run the installer as root:
> sudo perl install.pl
    *** Enter your password when asked ***
Or, if you can't run sudo:
> su
    *** Enter the root user's password when asked
# perl install.pl
ERROR

usage () if $usage;

if ($check_all) { $perl_check = 1; $lib_check = 1; $checks_to_run = 2; }

# Answer Y flag implies update flag
$update = 1 if restore_env ($env_file);
# These need a restored environment
if ( ($perl_check or $answer_y) and not $update ) {
	die "Unable to restore the installation environemnt from file";
}

if ($update) {
    my $environment = initialize OME::Install::Environment;
    $environment->set_flag ("UPDATE");
}

if ($answer_y) {
    my $environment = initialize OME::Install::Environment;
    $environment->set_flag ("ANSWER_Y");
}

if ($lib_check) {
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
eval "require Storable;";

unless ($@) {
	my $environment = initialize OME::Install::Environment;
	# Don't save these flags:
	$environment->unset_flag ('LIB_CHECK');
	$environment->unset_flag ('PERL_CHECK');
	$environment->unset_flag ('ANSWER_Y');
	$environment->store_to ("/etc/ome-install.store");
} else {
	carp "Unable to load the Storable module, continuing without a stored OME::Install::Environment!";
}

# OME installed successfully blurb
my $blurb = <<BLURB;
******************************************************************************
                      OME Install Successful!

Thank you for installing OME, you may now proceed to use your system through
either the web interface or the supplied Java client. For more information
please visit:

	http://www.openmicroscopy.org

for documentation resources:

	http://docs.openmicroscopy.org.uk

to report bugs:

	http://bugs.openmicroscopy.org.uk

to download further releases and get client bundles:

	http://cvs.openmicroscopy.org.uk

******************************************************************************
BLURB

# There's a reason it's only that long, this blurb *should* fit in a 24-line
# terminal in its entirety.
#
# -Chris <callan@blackcat.ca>

print $blurb;

exit (0);
