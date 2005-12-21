# OME/Util/Data/dbAdmin.pm

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


package OME::Util::Data::dbAdmin;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Cwd;
use Carp;
use English;
use Getopt::Long;
use File::Copy;
use File::Glob ':glob'; # for bsd_glob
use File::Path; # for rmtree
use File::stat;
use Term::ANSIColor qw(:constants);

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
       'backup'      => 'backup',
       'restore'     => 'restore',
       'export'      => ['OME::Util::Data::Export'],
       'delete'      => ['OME::Util::Data::Delete'],
       'chown'       => 'chown',
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
    backup      Backup OME data to an (optionally) compressed tar archive.
    restore     Restore OME data from an (optionally) compressed tar archive.
    export      Export objects as XML files.
    delete      Delete objects in the OME DB.
    chown       Change ownership of objects and MEXes in the DB.
CMDS
}

sub backup {
    my ($self, $commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
	my $force;
	my $quick=0;
	my $backup_file="";
	my $compression="none";
	
	# Parse our command line options
	GetOptions('f|force'      => \$force,
    		   'q|quick'      => \$quick,
			   'a|archive=s'  => \$backup_file,
			   'c|compression=s'=> \$compression,
			  );

	if (scalar @ARGV) {
		$backup_file = $ARGV[0];
	}
	
	# idiot nets
	die "You must run $script $command_name with uid=0 (root).\n" if (euid() ne 0);
	my $comp_ext; 	# compression parameter impacts file suffix and tar-command flag
	my $comp_flag;
	if ($compression eq "none") {
		$comp_ext = '';
		$comp_flag= '';
	} elsif ($compression eq "gzip") {
		$comp_ext = '.gz';
		$comp_flag= '--gzip';
	} elsif ($compression eq "bzip2") {
		$comp_ext = '.bz2';
		$comp_flag= '--bzip2';
	} else {
		die "'$compression is an unsupported compression algorithm.\n";
	}
	
	if ($backup_file eq "") {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year += 1900;
		$mday = sprintf("%02d", $mday);
		$mon  = sprintf("%02d", $mon+1);
		
		if ($force) {
			$backup_file = cwd()."/ome_backup_$year-$mon-$mday";
			print "Backup to archive ", BOLD, "[".cwd()."/ome_backup_$year-$mon-$mday"."]", RESET, "\n";
		} else {
			$backup_file = confirm_default("Backup to archive",cwd()."/ome_backup_$year-$mon-$mday");
		}
	}
	
	# find all the neccessary programs we will run
	my @progs = ('tar', 'pg_dump', 'touch');
	my %prog_path;
	
	foreach my $prog (@progs) {
		if (my $path = which($prog)){
			$prog_path{$prog} = $path;
		} else {
			die "The program $prog could not be found.";
		}
	}
	
	# open the enviroment to get info about the OME installation
	my $environment = OME::Install::Environment->initialize();
	
	my $postgress_user = $environment->postgres_user();
	my $base_dir = $environment->base_dir();
	my $omeis_base_dir = $environment->omeis_base_dir();
	
	# check if file exists
	if (-e "$backup_file.tar$comp_ext") {
		print STDERR "Archive $backup_file.tar$comp_ext already exists and shall be overwritten.\n";
		if (not $force) {
			y_or_n("Continue?") ? unlink "$backup_file.tar$comp_ext" : exit();
		}
	}
	
	# warn about OMEIS size
	if (not $quick) {
		print STDERR BOLD, "Warning:", RESET, " You have elected to backup OMEIS. Use the ", BOLD, "-q", RESET,
					" flag if this was not your intention.\nBe advised that this operation,",
					" depending on the size of your OMEIS repository (its size and location\n",
					"are printed below), is likely to take a long time.\n";
		print BOLD, `du -hs $omeis_base_dir`, RESET;
		$force or y_or_n("Continue?") or exit();
	}
	
	print_header("OME Backup");
	
	# ome db 
	print "    \\_ Backing up postgress database ome\n";

	my $dbConf = $environment->DB_conf();
	my $dbName = 'ome';
	$dbName = $dbConf->{Name} if $dbConf->{Name};

	my $flags = '';
	$flags .= '-h '.$dbConf->{Host}.' ' if $dbConf->{Host};
	$flags .= '-p '.$dbConf->{Port}.' ' if $dbConf->{Port};
	$flags .= '-U '.$dbConf->{User}.' ' if $dbConf->{User};
	$flags .= '-Fc'; # -F (format). 
					 # -p: use the plain text SQL script file this should be the most portable 
					 # -c: custom archive suitable for input into pg_restore

	print STDERR "su $postgress_user -c '".$prog_path{'pg_dump'}." $flags $dbName > /tmp/omeDB_backup'\n";

	# backup database and watch output from pg_dump
	foreach (`su $postgress_user -c '$prog_path{'pg_dump'} $flags $dbName > /tmp/omeDB_backup' 2>&1`) {
		print STDERR "\nDatabase Backup Failed: $_" and die if $_ =~ /pg_dump/ or $_ =~ /ERROR/ or $_ =~ /FATAL/;
	}
	
	# check the size of omeDB_backup
	if (stat("/tmp/omeDB_backup")->size < 1024) {
		print STDERR "\nDatabase Backup Failed: /tmp/omeDB_backup is less than 1024 bytes in size \n";
		die;
	}
	
	# log version of backup
	open (FILEOUT, "> /tmp/OMEmaint") or die "Couldn't open OMEmaint for writing\n";
	print FILEOUT "version=$dbAdmin_version\n";
	close (FILEOUT);
	
	# OMEIS
	if (not $quick) {
	    print "    \\_ Backing up OMEIS from $omeis_base_dir \n";
	    print STDERR "$prog_path{'tar'} $comp_flag -cf '$backup_file.tar$comp_ext' --directory /tmp OMEmaint omeDB_backup --directory $omeis_base_dir Files Pixels\n";
		foreach (`$prog_path{'tar'} $comp_flag -cf '$backup_file.tar$comp_ext' --directory /tmp OMEmaint omeDB_backup --directory $omeis_base_dir Files Pixels 2>&1`) {
			print STDERR "\nCouldn't create tar archive: $_" and die if $_ =~ /tar/ or $_ =~ /error/ or $_ =~ /FATAL/;
		}
		print "    \\_ Compressing archive \n" unless $compression eq "none";
	} else {
		print "    \\_ Compressing archive \n" unless $compression eq "none";
		print STDERR "$prog_path{'tar'} $comp_flag -cf '$backup_file.tar$comp_ext' --directory /tmp OMEmaint omeDB_backup \n";
		foreach (`$prog_path{'tar'} $comp_flag -cf '$backup_file.tar$comp_ext' --directory /tmp OMEmaint omeDB_backup 2>&1`) {
			print STDERR "\nCouldn't create tar archive: $_" and die if $_ =~ /tar/ or $_ =~ /ERROR/ or $_ =~ /FATAL/;
		}
	}
	
	# clean up any residual files
	unlink("/tmp/OMEmaint") or die "Couldn't remove /tmp/OMEmaint during cleanup\n";
	unlink("/tmp/omeDB_backup") or die "Couldn't remove /tmp/omeDB_backup during cleanup\n";
}

sub backup_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

Backs up OMEIS's image repository and OME's postgress db to a tar archive of 
the specified name. If compression is prescribed, the archive will have a
.gz or .bz2 suffix.

The default naming convention is
  ome_backup_YYYY-MM-DD.tar*
where YYYY-MM-DD is the date, in ISO-8601, when the backup was performed.

Options:
	-a,  --archive
		Specify path to archive that will be created.
		
	-c,  --compression
		Specify compression algorithm that will be applied to archive.
		"none" [default], "gzip", "bzip2"

	-q, --quick 
		If set, only OME's postgress db (and not OMEIS) is backed up.
		
	-f, --force    
		If set, there will be no further user confirmations.
CMDS
}

sub restore {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
	my $quick=0;
	my $restore_file="";
	my $force;
	
	# Parse our command line options
	GetOptions('f|force' => \$force,
			   'q|quick' => \$quick,
			   'a|archive=s' => \$restore_file,
			  );

	if (scalar @ARGV) {
		$restore_file = $ARGV[0];
	}
	
	# idiot nets
	die "You must run $script $command_name with uid=0 (root).\n" if (euid() ne 0);
	
	if ($restore_file eq "") {
		my @files = glob ("ome_backup_????-??-??*");
		if (scalar @files) {
			@files = sort {$b cmp $a}  @files; # reverse order
			
			if ($force) {
				print "Restore from archive ", BOLD, "[$files[0]]\n", RESET;
				$restore_file = $files[0];
			} else {
				$restore_file = confirm_default("Restore from archive", $files[0]);
			}
			
		} else {
			$restore_file = confirm_default("Restore from archive","?");		
		}
	}
	
	# find all the neccessary programs we will run
	my @progs = ('tar', 'pg_restore', 'dropdb','createdb', 'createuser', 'psql');
	my %prog_path;
	
	foreach my $prog (@progs) {
		if (my $path = which($prog)) {
			$prog_path{$prog} = $path;
		} else {
			die "The program $prog could not be found.";
		}
	}
	
	# open the enviroment to get info about the OME installation
	my $environment = OME::Install::Environment->initialize();
	
	my $postgress_user = $environment->postgres_user();
	my $base_dir = $environment->base_dir();
	my $omeis_base_dir = $environment->omeis_base_dir();
	
	# check if file exists
	if ( not -e $restore_file ){
		die "Archive $restore_file does not exist.\n";	
	}
	
	my $comp_flag = '';
	if ($restore_file =~ /.tar$/) {
		$comp_flag = '';
	} elsif ($restore_file =~/.tar.gz$/) {
		$comp_flag = '--gzip';
	} elsif ($restore_file =~/.tar.bz2$/) {
		$comp_flag = '--bip2';
	} else {
		die '$restore_file has unknown extension.\n';
	}
	
	print_header("OME Restore");

	# extract OMEmaint version and omeDB_backup
	# need to extract omeDB_backup in /tmp since postgress might not have
	# access permissions in current directory
	print "    \\_ Extracting postgres database ome and checking archive version \n";
	print STDERR "$prog_path{'tar'} $comp_flag --preserve-permissions --same-owner --directory /tmp -xf '$restore_file' OMEmaint omeDB_backup\n";
	foreach (`$prog_path{'tar'} $comp_flag --preserve-permissions --same-owner --directory /tmp -xf '$restore_file' OMEmaint omeDB_backup 2>&1`) {
		print STDERR "\nCouldn't extract OMEmaint and omeDB_backup from tar archive: $_" and die 
		if $_ =~ /tar/ or $_ =~ /error/ or $_ =~ /FATAL/;
	}
	
	open (FILEIN, "< /tmp/OMEmaint") or die "couldn't open /tmp/OMEmaint\n";
	<FILEIN> =~ m/version=(.*$)/;
	close (FILEIN);
	if ($1 ne $dbAdmin_version) {
		die "$restore_file is not compatible with this version of $0"; 
	}
	close (FILEIN);
	unlink "/tmp/OMEmaint" or die "couldn't remove /tmp/OMEmaint";
	
	# OMEIS
	my $semaphore = 0;
	my $iwd = getcwd();
    
    # check if the OMEIS data was ever archived
    my $success = 1;
	if (not $quick) {
		print "    \\_ Checking archive for OMEIS files \n";
		print STDERR "$prog_path{'tar'} $comp_flag -tf '$restore_file' Files/lastFileID\n";
		foreach (`$prog_path{'tar'} $comp_flag -tf '$restore_file' Files/lastFileID 2>&1`) {
			$success = 0 if $_=~ /tar/ or $_ =~ /Error/;
			# this is not a catastrophic error condition. It only means that OMEIS's
			# folders Files and Pixels aren't included in the archive
		}
	}
	
	if (not $quick and $success) {
		# warn about OMEIS size
		print BOLD, "Warning:", RESET, " You have elected to restore OMEIS. Use the ", BOLD, "-q", RESET,
			" flag if this was not your intention.\nBe advised that this operation,",
			" depending on the size of your OMEIS repository (its estimated size is printed\n",
			" below), is likely to take a long time.\n";
		print BOLD, `ls -lh $restore_file`, RESET;
		$force or y_or_n("Continue?") or exit();
		
	    # prepare the omeis_base_dir
	    if (-d $omeis_base_dir) {
	    	if ($force) {
	    		print "Restoring OMEIS from archive will delete all current files in ".
	   		  		"$omeis_base_dir. Continue ? ", BOLD, "[y", RESET, "/n", BOLD, "]\n", RESET;
	   			$semaphore = 1;  		
	    	} elsif (y_or_n ("Restoring OMEIS from archive will delete all current files in ".
	   		  		"$omeis_base_dir. Continue ?")) {
				$semaphore = 1;
				
				# the  $omeis_base_dir directory itself should not be deleted - it should only be emptied.
				# this is to cover cases where $omeis_base_dir is a hand made symbolic link
				foreach (bsd_glob("$omeis_base_dir/*")) {
	   		  		rmtree($_) or die "Could not clean out $_ from $omeis_base_dir";
	   		  	}
	   		}
	    } else {
	    	# need to make the omeis_base_dir
	    	mkdir ($omeis_base_dir) or 
	    	die "Could not create new OMEIS directory $omeis_base_dir";
	    }
	    
	    # expand the tar file directly into the OMEIS directory
	    if ($semaphore eq 1) {
			print "    \\_ Restoring OMEIS to $omeis_base_dir from archive\n";
			print STDERR "$prog_path{'tar'} $comp_flag --preserve-permissions --same-owner --directory $omeis_base_dir -xf '$restore_file' Files Pixels\n";
			foreach (`$prog_path{'tar'} $comp_flag --preserve-permissions --same-owner --directory $omeis_base_dir -xf '$restore_file' Files Pixels`) {
				print STDERR "\nCouldn't extract OMEIS's Files and Pixels from tar archive: $_" 
				and die if $_ =~ /tar/ or $_ =~ /error/ or $_ =~ /FATAL/;
			}
		}
	}
	
	# restoring ome db 
	print "    \\_ Restoring postgress database ome\n";
	
	# Drop our UID to the OME_USER
    euid (scalar(getpwnam $environment->user() ));
    my $db_version = eval ("OME::Install::CoreDatabaseTablesTask::get_db_version()");
    euid (0);
    
    my ($dropdb, $dropdb_path);
    $dropdb = 0;
    $dropdb_path = $prog_path{'dropdb'};

	if (defined($db_version)) {
	
		if ($force) {
			print "Database ome (version $db_version) was found and it will be overwritten. ".
			"Continue ? ", BOLD, "[y", RESET, "/n", BOLD, "]\n", RESET;
			$dropdb = 1;
		} else {	   		  		
			$dropdb = 1 if (y_or_n ("Database ome (version $db_version) was found and it will be overwritten. Continue ?"));
		}
		
		while ($dropdb == 1) {
			$success = 0;
			
			foreach (`su $postgress_user -c '$dropdb_path ome' 2>&1`) {
				$success = 1 if $_ =~ /DROP DATABASE/ and not $_ =~ /ERROR/;
			}
			
			if ($success == 0) {
				if ($force) {
					print "Database could not be dropped. Try again ? ", 
					BOLD, "[y", RESET, "/n", BOLD, "]\n", RESET;
					print BOLD, "\t[WAITING 15 SECONDS]", RESET, "\n" and sleep 15;
				} else {
					y_or_n ("Database could not be dropped. Try again ?") ? $dropdb = 0: $dropdb = 1; 
				}
			} else {
				# success == 1
				last;
			}
		}
		
		if ($dropdb == 0) {
			# user doesn't want to overwrite database, so we exit
			exit();
		}
	}
	
	# remember omeDB_backup was extracted to /tmp
	my $dbConf = $environment->DB_conf();
	my $dbName = 'ome';
	$dbName = $dbConf->{Name} if $dbConf->{Name};

	my $flags = '';
	$flags .= '-h '.$dbConf->{Host}.' ' if $dbConf->{Host};
	$flags .= '-p '.$dbConf->{Port}.' ' if $dbConf->{Port};
	$flags .= '-U '.$dbConf->{User}.' ' if $dbConf->{User};
	
print STDERR "su $postgress_user -c '".$prog_path{'createuser'}." --adduser --createdb  ome'\n"; 	
	system ("su $postgress_user -c '".$prog_path{'createuser'}." --adduser --createdb  ome'");

print STDERR "su $postgress_user -c '".$prog_path{'createdb'}." $flags -T template0 $dbName'\n";
	system ("su $postgress_user -c '".$prog_path{'createdb'}." $flags -T template0 $dbName'");

print STDERR "su $postgress_user -c '".$prog_path{'pg_restore'}." $flags -d $dbName --use-set-session-authorization /tmp/omeDB_backup'\n";
	system ("su $postgress_user -c '".$prog_path{'pg_restore'}." $flags -d $dbName --use-set-session-authorization /tmp/omeDB_backup'");





# these are the commands used to restore a pg_backup archives made with the -p Format
# print STDERR "su $postgress_user -c '".$prog_path{'psql'}." $flags $dbName < /tmp/omeDB_backup'";
#	system ("su $postgress_user -c '".$prog_path{'psql'}." $flags $dbName < /tmp/omeDB_backup'");
}

sub restore_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] archive-name

Restores OMEIS's image repository and OME's postgress db from a .tar archive of 
specified name. This utility, as applicable, decompresses the archive.

By default, it looks in the current directory for an ome_backup file of this form:
  ome_backup_YYYY-MM-DD.tar*
The ome_backup file with the latest YYYY-MM-DD is selected.

Options:
	-a,  --archive
		Specify path to existing archive.
		
	-q, --quick 
		If set, only OME's postgress db (and not OMEIS) is extracted from archive.
		
	-f, --force    
		If set, there will be no further user confirmations.
CMDS
}


sub chown {
    my ($self, $commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    my $session = $self->getSession();
    my $factory = $session->Factory();
	
	# Parse our command line options
	my ($group_in,$user_in,$projects,$datasets,$images,$MEXes);
	GetOptions('g|group=s' => \$group_in,
						 'u|user=s'  => \$user_in,
						 'p|project' => \$projects,
						 'd|dataset' => \$datasets,
						 'i|image'   => \$images,
						 'm|MEX'   => \$MEXes,
	);
	
	my ($user,$group);
	
    if ($group_in) {
    	if (not $group_in eq '#undefined#') {
	        $group = $self->__getObject('OME::SemanticType::BootstrapGroup',$group_in);
			die "Unable to find Group $group_in\n" unless $group;
		}
    }
    
    if ($user_in) {
        $user = $self->__getObject('OME::SemanticType::BootstrapExperimenter',$user_in);
        die "Unable to find Experimenter $user_in\n" unless $user;
    }
	
    my @objects = @ARGV;
    my ($object_type,$object_in,$object);
    $object_type = 'OME::Project' if $projects;
    $object_type = 'OME::Dataset' if $datasets;
    $object_type = 'OME::Image' if $images;
    $object_type = 'OME::ModuleExecution' if $MEXes;
    
    foreach $object_in (@objects) {
        $object = $self->__getObject ($object_type,$object_in);
        if ($object) {
            $object->owner ($user) if $user_in;
            $object->group ($group) if $group_in;
            $object->storeObject();
            print "Changing ownership of $object_type $object_in\n";
        } else {
            print STDERR "$object_type $object_in not found\n";
        }
    }

    eval {
        $session->commitTransaction();
    };

    if ($@) {
        print "Error committing transaction.  Database was not modified!:\n$@\n";
        exit 1;
    } else {
        print "Changes saved.\n";
    }
    
}


sub __getObject {
    my $self = shift;
    my ($type,$obj_in) = @_;
    my $object;
    my $session = $self->getSession();
    my $factory = $session->Factory();
    my $field = 'name';
    $field = 'OMEName' if $type =~ /Experimenter$/;
    $field = 'Name' if $type =~ /Group$/;

    if ($obj_in =~ /^[0-9]+$/) {
        # Object was specified by ID
        $object = $factory->loadObject($type,$obj_in);
    } else {
        $object = $factory->findObject($type,{$field => $obj_in });
    }
    return $object;
}


sub chown_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] [<project <ID|name>> | <dataset <ID|name>> | <image <ID|name>> | MEXes]...

Change user and group ownership.

Options:
     -g, --group (<group ID> | <group name>)
     	Specify group to change ownership to.
     	Use #undefined# (with the #'s) to set it to NULL (make it public).
     -u, --user (<user ID> | <username>)
     	Specify user to change ownership to
     -p, --project
        Parameters are project IDs or names
     -d, --dataset
        Parameters are dataset IDs or names
     -i, --image
        Parameters are dataset IDs or names
     -m, --MEX
        Parameters are Module Execution IDs (MEXes)
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

