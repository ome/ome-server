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
require OME::Install::PreInstallTask;
use lib qw(src/perl2);
use Carp;

#*********
#********* GLOBALS AND DEFINES
#*********

# Tasks
my @tasks = (
    "OME::Install::CoreSystemTask",
    "OME::Install::PerlModuleTask",
    "OME::Install::LibraryTask",
    "OME::Install::CoreDatabaseTablesTask"
);

# Main task queues
my (@tasks_todo, @tasks_done);

#*********
#********* START OF CODE
#*********

# PreInstall
OME::Install::PreInstallTask::execute();

# Run our tasks
foreach my $task (@tasks) {
    eval "use $task";
    croak "Errors loading module: $@\n" if $@;  # Really only for debugging purposes
    $task .= "::execute()";
    eval $task;
    croak "Errors executing task: $@\n" if $@;  # Ditto as above
}

exit (0);
