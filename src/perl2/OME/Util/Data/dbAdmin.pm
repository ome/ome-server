# OME/Util/UserAdmin.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:   Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------


package OME::Util::dbAdmin;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Cwd;
use Carp;
use English;
use Getopt::Long;
use File::Path; # for rmtree
use File::Copy;

use OME::SessionManager;
use OME::Session;
use OME::Factory;

use OME::Install::Util;
use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::CoreDatabaseTablesTask; # used for OME::Install::CoreDatabaseTablesTask::get_db_version()

use DBI;

require Storable;
my $dbAdmin_version = "2.2.1";

sub getCommands {
    return
      {
       'backup' => 'backup',
       'restore' => 'restore',
      };
}

sub listCommands {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    
    print <<"CMDS";
Usage:
    $script $command_name [command] [options]

Available OME database related commands are:
    backup      Backup OME data to an .tar.bz2 archive.
    restore     Restore OME data from an .tar.bz2 archive.
CMDS
}

sub backup {
    my ($self, $commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
	# Default env file location 
	my $env_file = "/etc/ome-install.store";
	my $quick=0;
	my $backup_file="";
	my $result;
	
	# Parse our command line options
	$result = GetOptions('f|env-file=s' => \$env_file,
						 'q|quick' => \$quick,
						 'a|archive=s' => \$backup_file,
					    );
	exit(1) unless $result;
	
	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name backup with the -f flag to specify it. " if (not -e $env_file);
	if ($backup_file eq "") {
		$backup_file = confirm_default("Backup to archive",cwd()."/ome_backup.tar.bz2");
	}
	
	$backup_file  =~ s/\.tar//; $backup_file  =~ s/\.bz2//;
	
	# find all the neccessary programs we will run
	my @progs = ('tar', 'pg_dump', 'pg_restore', 'psql', 'sudo', 'touch', 'mv', 
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
	
	# ome db 
	print "    \\_ Backing up postgress database ome\n";
	system($prog_path{'sudo'}." -u $postgress_user ".$prog_path{'pg_dump'}." -Fc ome > omeDB_backup");
 	
	# log version of backup
	open (FILEOUT, ">> OMEmaint");
	print FILEOUT "version=$dbAdmin_version\n";
	close (FILEOUT);
	
	# OMEIS
	if (not $quick) {
	    print "    \\_ Backing up OMEIS from $omeis_base_dir \n";
	    print "    \\_ Compressing archive \n";
		system ($prog_path{'tar'}." --bzip2 -cf $backup_file.tar.bz2 $omeis_base_dir OMEMaint omeDB_backup");
	} else {
		print "    \\_ Compressing archive \n";
		system ($prog_path{'tar'}." --bzip2 -cf $backup_file.tar.bz2 OMEMaint omeDB_backup");
	}
	
	# clean up any residual files
	unlink("OMEMaint");
	unlink("omeDB_backup");
}

sub backup_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

Backs up OMEIS's image repository and OME's postgress db to an .tar.bz2 archive of 
specified name.

Options:
     -a, --archive
	 	Full path to the archive.
     -f, --env-file    
		Location of the stored environment overrides the default of 
		"/etc/ome-install.store"
     -q, --quick 
		If set, only OME's postgress db (and not OMEIS) is backed up.
CMDS
}

sub restore {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
	# Default env file location 
	my $env_file = "/etc/ome-install.store";
	my $quick=0;
	my $restore_file="";
	my $result;
	
	# Parse our command line options
	$result = GetOptions('f|env-file=s' => \$env_file,
						 'q|quick' => \$quick,
						 'a|archive=s' => \$restore_file,
					    );
	exit(1) unless $result;
	
	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name with the -f flag to specify it. " if (not -e $env_file);

	if ($restore_file eq "") {
		$restore_file = confirm_default("Restore from archive",cwd()."/ome_backup.tar.bz2");
	}

	$restore_file  =~ s/\.tar//; $restore_file  =~ s/\.bz2//;
	
	# find all the neccessary programs we will run
	my @progs = ('tar', 'pg_dump', 'pg_restore', 'psql', 'sudo', 'touch', 'mv', 
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
	
	# check if file exists
	if ( not -e "$restore_file.tar.bz2" and not -e "$restore_file.tar"){
		croak "Archive $restore_file.tar.bz2 does not exist.\n";	
	}
	
	print_header("OME Restore");
	
	# de compress
	if (not -e "$restore_file.tar"){
		print "    \\_ Decompressing archive \n";
		system ($prog_path{'tar'}. " --bzip2 --preserve-permissions --same-owner -xf $restore_file.tar.bz2");
	}	
	
	# open OMEmaint version
	open (FILEIN, "< OMEmaint");
	<FILEIN> =~ m/version=(.*$)/;
	close (FILEIN);
	if( $1 ne $dbAdmin_version){
		croak "$restore_file.tar.bz2 is not compatible with this version of $0"; 
	}
	close (FILEIN);
	unlink "OMEmaint";
	
	# OMEIS
	my $semaphore = 1;
	if (not $quick and -d './OME/OMEIS') {
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
    euid (scalar(getpwnam $environment->user() ));
    my $db_version = eval ("OME::Install::CoreDatabaseTablesTask::get_db_version()");
    
	if ($db_version) {
		if (y_or_n ("Database ome was found and it will be overwritten. Continue ?")) {
			system($prog_path{'dropdb'}." ome");
		}	
	}
	
	# need to move omeDB_backup up to /tmp since postgress might not have
	# access permissions in current directory
	euid (0);
	copy("omeDB_backup","/tmp/omeDB_backup") or croak "ERROR: Could not copy omeDB_backup to /tmp";
	
	euid (scalar(getpwnam $postgress_user));
	system ($prog_path{'createuser'}." --adduser --createdb  ome");
	system ($prog_path{'createdb'}." ome");
	system ($prog_path{'pg_restore'}." -d ome /tmp/omeDB_backup");
	euid (0);
	unlink ("omeDB_backup");
}

sub restore_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

Restores OMEIS's image repository and OME's postgress db from an .tar.bz2 archive of 
specified name.

Options:
     -a, --archive
	 	Full path to the archive.
     -f, --env-file    
		Location of the stored environment overrides the default of 
		"/etc/ome-install.store"
     -q, --quick 
		If set, only OME's postgress db (and not OMEIS) is restored.
CMDS
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

