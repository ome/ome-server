# OME/Install/AnalysisConfigTask
# This task configure's the Analysis Engine

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

package OME::Install::AnalysisConfigTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use English;
use Cwd;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
use Text::Wrap;

use File::Basename;
use File::Copy;
use OME::Install::Util;
use OME::Install::Terminal;
use OME::Install::Environment;

use base qw(OME::Install::InstallationTask);

# Environment and users
our $ENVIRONMENT;
our $OME_USER;
our $APACHE_USER;
our $APACHE_UID;
our $OME_GROUP;
our $OME_GID;
our $POSTGRES_USER;
our $MAINT_CONF;
our $APACHE_CONF;
our $OME_TMP_DIR;
our $OME_BASE_DIR;
our $OMEIS_BASE_DIR;
our $WORKER_CONF;


# Global logfile filehandle and name
our $LOGFILE_NAME = "AnalysisConfigTask.log";
our $LOGFILE;

# Default tasks
our $WORKER_CONF_DEF = {
	ExecutorThreaded    => 0,
	ExecutorUnthreaded  => 1,
	ExecutorDistributed => 0,
	MaxWorkers          => 0
};

sub execute {
my ($hour,$minute);
	$ENVIRONMENT = initialize OME::Install::Environment;
	$OME_USER = $ENVIRONMENT->user()
    	or croak "Unable to retrieve OME_USER!";
	$APACHE_USER = $ENVIRONMENT->apache_user()
		or croak "Unable to retrieve APACHE_USER!";
    $APACHE_UID   = getpwnam ($APACHE_USER) or croak "Unable to retrive APACHE_USER UID!";
	$OME_GROUP    = $ENVIRONMENT->group() or croak "OME group is not set!\n";
	$OME_GID      = getgrnam($OME_GROUP) or croak "Failure retrieving GID for \"$OME_GROUP\"";
	$POSTGRES_USER = $ENVIRONMENT->postgres_user()
		or croak "Unable to retrieve POSTGRES_USER!";
    $OME_TMP_DIR  = $ENVIRONMENT->tmp_dir() or croak "Unable to retrieve OME_TMP_DIR!";
    $OME_BASE_DIR = $ENVIRONMENT->base_dir() or croak "Could not get base installation environment\n";
    $OMEIS_BASE_DIR = $ENVIRONMENT->omeis_base_dir() or croak "Could not get OMEIS base directory\n";


	$WORKER_CONF = $ENVIRONMENT->worker_conf();
	
	# Get any undefined keys from the default.
	foreach (keys %$WORKER_CONF_DEF) {
		$WORKER_CONF->{$_} = $WORKER_CONF_DEF->{$_} unless exists $WORKER_CONF->{$_};
	}
	
	print "\n";  # Spacing
    print_header ("Analysis Engine Configuration ");
    print "(All verbose information logged in $OME_TMP_DIR/install/$LOGFILE_NAME)\n\n";

	# Task blurb
	my $blurb = <<BLURB;
The Analysis Engine, blah blah blah. If you are unsure of a particular question, please choose the default as that will be more than adequate for most people.
BLURB

	print wrap("", "", $blurb);
	print "\n";  # Spacing

    # Get our logfile and open it for writing
    open ($LOGFILE, ">", "$OME_TMP_DIR/install/$LOGFILE_NAME")
    or croak "Unable to open logfile \"$OME_TMP_DIR/install/$LOGFILE_NAME\" $!";
    
    print $LOGFILE "Setup Analysis Engine \n";


	# Confirm all flag
	my $confirm_all;

    while (1) {
	
		# Logical consistency checks
		if ($WORKER_CONF->{ExecutorThreaded}    < 0 or
		    $WORKER_CONF->{ExecutorUnthreaded}  < 0 or
		    $WORKER_CONF->{ExecutorDistributed} < 0 or
		    ( $WORKER_CONF->{ExecutorThreaded} + 
		      $WORKER_CONF->{ExecutorUnthreaded} +
		      $WORKER_CONF->{ExecutorDistributed} != 1)) {
		    
		    # default is unthreaded executor
		    $WORKER_CONF->{ExecutorThreaded}    = 0;
		    $WORKER_CONF->{ExecutorUnthreaded}  = 1;
		    $WORKER_CONF->{ExecutorDistributed} = 0;
		}
		
		if ($ENVIRONMENT->get_flag("UPDATE") or $confirm_all) {
			print "\n";  # Spacing

			# Ask user to confirm original entries
	
			print BOLD,"Analysis Engine Configuration:\n",RESET;
			print "     Analysis Engine Executor: ";
			if ($WORKER_CONF->{ExecutorThreaded}) {
				print BOLD, 'Threaded', RESET, "\n";
			} elsif ($WORKER_CONF->{ExecutorUnthreaded}) {
				print BOLD, 'Unthreaded', RESET, "\n";
			} elsif ($WORKER_CONF->{ExecutorDistributed}) {
				print BOLD, 'Distributed', RESET, "\n"; 
			}
			print "       Local Worker Processes: ", BOLD, 
			      "[", $WORKER_CONF->{MaxWorkers},"]", RESET, "\n";

			print "\n";  # Spacing
			y_or_n ("Are these values correct ?",'y') and last;
		}

		$confirm_all = 0;
		
		my $ans = multiple_choice("Analysis Engine Executor ", "Unthreaded", "Unthreaded", "Threaded", "Distributed"); 
		$WORKER_CONF->{ExecutorUnthreaded} = 0;
	    $WORKER_CONF->{ExecutorThreaded} = 0;
		$WORKER_CONF->{ExecutorDistributed} = 0;
		
		if ($ans eq "Unthreaded") {
		    $WORKER_CONF->{ExecutorUnthreaded} = 1;
		} elsif ($ans eq "Threaded") {
		    $WORKER_CONF->{ExecutorThreaded} = 1;
		} elsif ($ans eq "Distributed") {
		    $WORKER_CONF->{ExecutorDistributed} = 1;
		}
		
		$WORKER_CONF->{MaxWorkers} = confirm_default ('Maximum workers :', $WORKER_CONF->{MaxWorkers});
		
		$confirm_all = 1;
	}

	$ENVIRONMENT->worker_conf($WORKER_CONF);

	# Write what we got to our log
	print $LOGFILE BOLD,"Analysis Engine Configuration:\n",RESET;
	print $LOGFILE "     Analysis Engine Executor: ";
	if ($WORKER_CONF->{ExecutorThreaded}) {
		print $LOGFILE BOLD, 'Threaded', RESET, "\n";
	} elsif ($WORKER_CONF->{ExecutorUnthreaded}) {
		print $LOGFILE BOLD, 'Unthreaded', RESET, "\n";
	} elsif ($WORKER_CONF->{ExecutorDistributed}) {
		print $LOGFILE BOLD, 'Distributed', RESET, "\n"; 
	}
	print $LOGFILE "       Local Worker Processes: ", BOLD, 
		  "[", $WORKER_CONF->{MaxWorkers},"]", RESET, "\n";

	# put NonblockingSlaveWorkerCGI.pl under /OME/perl2 
	if ($WORKER_CONF->{MaxWorkers} > 0) {
		my $source = getcwd()."/src/perl2/OME/Analysis/Engine/NonblockingSlaveWorkerCGI.pl";
		my $dest = $OME_BASE_DIR."/perl2/NonblockingSlaveWorkerCGI.pl";
		copy($source,$dest) or
			print $LOGFILE "Could not copy $source to $dest \n" and
			croak "Could not copy $source to $dest: $!";
		print $LOGFILE "chmod 0755 $dest\n";
		chmod (0755,$dest) or
			print $LOGFILE "Could not chmod $dest:\n$!\n" and
			croak "Could not chmod $dest:\n$!\n";
		print $LOGFILE "chown $dest to uid: $APACHE_UID gid: $OME_GID\n";
		chown ($APACHE_UID,$OME_GID,$dest) or
			print $LOGFILE "Could not chown $dest:\n$!\n" and
			croak "Could not chown $dest:\n$!\n";
	}
	
	# do we need to test the worker by constructing http requests and checking
	# out the responses ?. Nah. Too much work. Apache problems would have already
	# been found by the ApacheConfig tests.	

	close ($LOGFILE);
	return;
}

1;
