#!/usr/bin/perl
#
# This script implements the main user interaction with OME's installation
# framework (src/perl2/OME/Install/).
 
# Copyright (C) 2003 Open Microscopy Environment
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

use warnings;
use strict;

#*********
#********* INCLUDES
#*********

use Getopt::Long;
use OME::Install::Environment;

#*********
#********* GLOBALS AND DEFINES
#*********

# Command line options
my ($skipPasswordCheck, $defaultDirectories, $defaultUserDetails, $help, $fast);

# Our OME::Install::Environment
my $environment;

#*********
#********* LOCAL SUBROUTINES
#*********

# Usage display
sub usage {
	my $usage = <<USAGE;
Bootstrap the OME database, create inital user(s) and do environment setup.

Usage:
  $0 [options]

Options:
  -s, --skip-password-check	Skip the password check
  -d, --default-directories	Run default directory creation (UID 0 is
  				required as the OME directories are off
				the root)
  -n, --default-user-details	Use default user details for the 
				creation of the initial OME experimenter
  -f, --fast			Fast operation for developers who know
  				they want the default OME directory
				structure, want default user details and
				want to skip the password check
  -h, --help			This message

Report bugs to <ome-devel\@mit.edu>.
USAGE

	print STDERR $usage;
	exit (0);
}

#*********
#********* START OF CODE
#*********

GetOptions ("s|skip-password-check", \$skipPasswordCheck,	# Skip the PW check
	    "d|default-directories", \$defaultDirectories,	# Use default OME dirs
	    "n|default-user-details", \$defaultUserDetails,	# Use default user details
	    "f|fast", \$fast,					# Fast operation
	    "h|help", \$help					# Show usage
	    );

# CLI flag logic
if ($fast) { $skipPasswordCheck 	= 1;
	     $defaultDirectories 	= 1;
	     $defaultUserDetails	= 1; }
if ($help) { usage() }

# Initialize our environment
$environment = getInstance OME::Install::Environment;

# We need to drop our umask so that everyone can create files.
print "Dropping umask to \"0000\".\n";
umask (0000);
