#!/usr/bin/perl -w
# OME/Tests/OMEmaint.pl

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

#-------------------------------------------------------------------------------
#
# Written by:    Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

use strict;
use warnings;
use Carp;
use Cwd;
use English;
use File::Path;
use Getopt::Long;
use OME::Install::Util;
use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::CoreDatabaseTablesTask;

use DBI;

require Storable;

sub usage {
    my $error = shift;
    my $usage = "";

    $usage = <<USAGE;
OME maintenance script.

Usage:
  $0 [options]

Options:
  -b, --backup      backup OMEIS and OME's postgress db. Returns a .tar.bz2 
                    of specified name.
  -r, --restore	    restore OMEIS and OME's postgress db from a .tar.bz2
                    created apriori by $0 -b.
  -f, --env-file    Location of the stored environment overrides
                    the default of "/OME/conf/environment.store"
  -q                If set, only OME's postgress db is backuped or restored
  -h, --help        This message

Report bugs to <ome-devel\@lists.openmicroscopy.org.uk>.

USAGE
    $usage .= "**** ERROR: $error\n\n" if $error; 

    print STDERR $usage;
    exit (1) if $error;
    exit (0);
}

# what if wwe want to restore a backup created with an older version of OMEmaint.pl ?
my $version = "0.0";

#*********
#********* START OF CODE
#*********

# Default env file location 
my $env_file = ('/OME/conf/environment.store');

my ($backup_file, $restore_file, $usage, $quick);

# Parse our command line options
GetOptions ("b|backup=s" =>  \$backup_file,
            "r|restore=s" => \$restore_file,
            "f|env-file=s" => \$env_file,
            "q" => \$quick,
            "h|help" => \$usage,
           );
            
usage () if $usage;

# idiot nets
usage ("$0 must be called with either the -b or -r flags.") 
	if (not $backup_file and not $restore_file);
	
usage ("$0 cannot be called with both the -b and -r flags.") 
	if ($backup_file and $restore_file);	
	
croak "Environment file '$env_file' does not exist.\n".
	  "Call $0 with the -f flag to specify it.\n" if (not -e $env_file);

croak "This script must be run with uid=0 (root).\n" if ($< ne 0);

if ($backup_file) {
	$backup_file  =~ s/\.tar//; $backup_file  =~ s/\.bz2//; $backup_file  =~ s/\.gzip//;
}
if ($restore_file) {
	$restore_file =~ s|\.tar||; $restore_file =~ s|\.bz2||; $restore_file =~ s|\.gzip||;
}

# find all the neccessary programs we will run
my @progs = ('tar', 'bzip2', 'pg_dump', 'pg_restore', 'psql', 'sudo', 'touch', 'mv', 
			'dropdb','createdb', 'createuser');
my %prog_path;

foreach my $prog (@progs) {
	if (my $path = which($prog)){
		$prog_path{$prog} = $path;
	} else {
		croak "The program $prog could not be found.";
	}
}

# open the enviroment to get info about the OME installation
my $environment = initialize OME::Install::Environment;
$environment = OME::Install::Environment::restore_from($env_file);

my $postgress_user = $environment->postgres_user();
my $base_dir = $environment->base_dir();
my $omeis_base_dir = $environment->omeis_base_dir();

# back up -b option
if ($backup_file) {

	# check if file exists
	if (-e "$backup_file.tar" or -e "$backup_file.tar.bz2"){
		if (y_or_n("Archive $backup_file.tar.bz2 already exists and shall be overwritten. Continue?")) {
			unlink "$backup_file.tar" if (-e "$backup_file.tar");
			unlink "$backup_file.tar.bz2" if (-e "$backup_file.tar.bz2");
		} else {
			exit();
		}
	}
	
	print_header("OME Backup");
	# OMEIS
	if (not $quick) {
	    print "    \\_ Backing up OMEIS from $omeis_base_dir \n";
		system ($prog_path{'tar'}." -c $omeis_base_dir > $backup_file.tar");
	}
	
	# ome db 
	print "    \\_ Backing up postgress database ome\n";
	system($prog_path{'sudo'}." -u $postgress_user ".$prog_path{'pg_dump'}." -Fc ome > omeDB_backup");
	system ($prog_path{'tar'}." --remove-files --append omeDB_backup --file $backup_file.tar");
		
	# log OMEmaint version
	open (FILEOUT, ">> OMEmaint");
	print FILEOUT "version=$version\n";
	close (FILEOUT);
	system ($prog_path{'tar'}." --remove-files --append OMEmaint --file $backup_file.tar");
	
	# combine and compress
	print "    \\_ Compressing archive \n";
	unlink "$backup_file.tar.bz2" if (-e "$backup_file.tar.bz2");
	system ($prog_path{'bzip2'}. " $backup_file.tar");
	
} elsif ($restore_file) {

	# check if file exists
	if ( not -e "$restore_file.tar.bz2" and not -e "$restore_file.tar"){
		croak "Archive $restore_file.tar.bz2 does not exist.\n";	
	}
	
	print_header("OME Restore");
	
	# de compress
	if (not -e "$restore_file.tar"){
		print "    \\_ Decompressing archive \n";
		system ($prog_path{'bzip2'}. " -d  $restore_file.tar.bz2");
	}
	system ($prog_path{'tar'}. " --preserve-permissions --same-owner -xf $restore_file.tar");
	
	
	# open OMEmaint version
	open (FILEIN, "< OMEmaint");
	<FILEIN> =~ m/version=(.*$)/;
	close (FILEIN);
	if( $1 ne $version){
		croak "$restore_file.tar.bz2 is not compatible with this version of $0"; 
	}
	close (FILEIN);
	unlink "OMEmaint";
	
	# OMEIS
	my $semaphore = 1;
	if (not $quick) {
	    print "    \\_ Restoring OMEIS from $omeis_base_dir \n";
	    if (-d $omeis_base_dir) {
	     	if (y_or_n ("Restoring OMEIS from archive will delete all current files in ".
	   		  		"$omeis_base_dir. Continue ?")) {
	   		  	rmtree($omeis_base_dir);
	   		} else {
	   			$semaphore = 0;
			}	     	
	    }
	    
	    if ($semaphore eq 1){
			system ($prog_path{'mv'}. " ./OME/OMEIS ". $base_dir);
			rmdir ("OME");
	    }
	}
	
	# restoring ome db 
	print "    \\_ Restoring postgress database ome\n";
	# Drop our UID to the OME_USER
    $EUID = getpwnam ($environment->user());
    my $db_version = eval ("OME::Install::CoreDatabaseTablesTask::get_db_version()");
    
	if ($db_version) {
		if (y_or_n ("Database ome was found and it will be overwritten. Continue ?")) {
			system($prog_path{'dropdb'}." ome");
		}	
	}
	$EUID = 0;
	$EUID = getpwnam ($postgress_user);
	system ($prog_path{'createuser'}." --adduser --createdb  ome");
	system ($prog_path{'createdb'}." ome");
	system ($prog_path{'pg_restore'}." -d ome omeDB_backup");
	unlink ("omeDB_backup");
}
