# OME/Util/dbAdmin.pm

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
       'connection'  => 'connection',
       'restore'     => 'restore',
       'delete'      => ['OME::Util::Delete'],
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
    backup      Backup OME data to an .tar.bz2 archive.
    restore     Restore OME data from an .tar.bz2 archive.
    delete      Delete things in the OME DB.
    connection  Configure database connection.
    chown       Change ownership of objects and MEXes in the DB.
CMDS
}

sub backup {
    my ($self, $commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
	# Default env file location 
	my $env_file;
	my $quick=0;
	my $backup_file="";
	my $result;
	
	# Parse our command line options
	$result = GetOptions('f|env-file=s' => \$env_file,
						 'q|quick' => \$quick,
						 'a|archive=s' => \$backup_file,
					    );
	exit(1) unless $result;
	
	if (scalar @ARGV) {
		$backup_file = $ARGV[0];
	}
	
	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name backup with the -f flag to specify it. " 
		  if (defined($env_file) and not -e $env_file);
		  
	if ($backup_file eq "") {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year += 1900;
		$mday = sprintf("%02d", $mday);
		$mon  = sprintf("%02d", $mon+1);
		$backup_file = confirm_default("Backup to archive",cwd()."/ome_backup_$year-$mon-$mday.tar.bz2");
	}
	
	$backup_file  =~ s/\.tar//; $backup_file  =~ s/\.bz2//;
	
	# find all the neccessary programs we will run
	my @progs = ('tar', 'pg_dump', 'touch');
	my %prog_path;
	
	foreach my $prog (@progs) {
		if (my $path = which($prog)){
			$prog_path{$prog} = $path;
		} else {
			croak "The program $prog could not be found.";
		}
	}

	# open the enviroment to get info about the OME installation
	my $environment = OME::Install::Environment->initialize($env_file);
	
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

	my $dbConf = $environment->DB_conf();
	my $dbName = 'ome';
	$dbName = $dbConf->{Name} if $dbConf->{Name};

	my $flags = '';
	$flags .= '-h '.$dbConf->{Host}.' ' if $dbConf->{Host};
	$flags .= '-p '.$dbConf->{Port}.' ' if $dbConf->{Port};
	$flags .= '-U '.$dbConf->{User}.' ' if $dbConf->{User};
	$flags .= '-Fc'; # -F (format). We use the custom archive. 
	                 # This is the most flexible format that allows reordering 
	                 # of data. Its compressed by default.
	
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
	open (FILEOUT, "> OMEmaint") or die "Couldn't open OMEmaint for writing\n";
	print FILEOUT "version=$dbAdmin_version\n";
	close (FILEOUT);
	
	# OMEIS
	if (not $quick) {
	    print "    \\_ Backing up OMEIS from $omeis_base_dir \n";
		foreach (`$prog_path{'tar'} --bzip2 -c OMEmaint --directory /tmp/ omeDB_backup --directory $omeis_base_dir Files Pixels -f $backup_file.tar.bz2 2>&1`) {
			print STDERR "\nCouldn't create tar archive: $_" and die if $_ =~ /tar/ or $_ =~ /error/ or $_ =~ /FATAL/;
		}
		print "    \\_ Compressing archive \n";
	} else {
		print "    \\_ Compressing archive \n";
		foreach (`$prog_path{'tar'} --bzip2 -c OMEmaint --directory /tmp/ omeDB_backup -f $backup_file.tar.bz2 2>&1`) {
			print STDERR "\nCouldn't create tar archive: $_" and die if $_ =~ /tar/ or $_ =~ /ERROR/ or $_ =~ /FATAL/;
		}
	}
	
	# clean up any residual files
	unlink("OMEmaint") or die "Couldn't remove OMEmaint during cleanup\n";
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

Backs up OMEIS's image repository and OME's postgress db to an .tar.bz2 archive of 
specified name.

The default naming convention is
  ome_backup_YYYY-MM-DD.tar.bz2
where YYYY-MM-DD is the date, in ISO-8601, the backup was performed.

Options:
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
	my $env_file;
	
	my $quick=0;
	my $restore_file="";
	my $result;
	
	# Parse our command line options
	$result = GetOptions('f|env-file=s' => \$env_file,
						 'q|quick' => \$quick,
						 'a|archive=s' => \$restore_file,
					    );
	exit(1) unless $result;
	
	if (scalar @ARGV) {
		$restore_file = $ARGV[0];
	}
	
	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name with the -f flag to specify it. "
		  if (defined($env_file) and not -e $env_file);

	if ($restore_file eq "") {
		my @files = glob ("ome_backup_????-??-??*");
		if (scalar @files) {
			@files = sort {$b cmp $a}  @files; # reverse order
			$restore_file = confirm_default("Restore from archive",$files[0]);
		} else {
			$restore_file = confirm_default("Restore from archive","?");		
		}
	}
	
	# find all the neccessary programs we will run
	my @progs = ('tar', 'pg_restore', 'dropdb','createdb', 'createuser');
	my %prog_path;
	
	foreach my $prog (@progs) {
		if (my $path = which($prog)) {
			$prog_path{$prog} = $path;
		} else {
			croak "The program $prog could not be found.";
		}
	}
	
	# open the enviroment to get info about the OME installation
	my $environment = OME::Install::Environment->initialize($env_file);
	
	my $postgress_user = $environment->postgres_user();
	my $base_dir = $environment->base_dir();
	my $omeis_base_dir = $environment->omeis_base_dir();
	
	# check if file exists
	if ( not -e "$restore_file" ){
		croak "Archive $restore_file does not exist.\n";	
	}
	
	print_header("OME Restore");

	# open OMEmaint version
	print "    \\_ Checking archive version \n";
	foreach (`$prog_path{'tar'} --bzip2 -x OMEmaint -f $restore_file 2>&1`) {
		print STDERR "\nCouldn't extract OMEmaint from tar archive: $_" and die 
		if $_ =~ /tar/ or $_ =~ /error/ or $_ =~ /FATAL/;
	}
		
	open (FILEIN, "< OMEmaint") or die "couldn't open OMEmaint\n";
	<FILEIN> =~ m/version=(.*$)/;
	close (FILEIN);
	if ($1 ne $dbAdmin_version) {
		croak "$restore_file is not compatible with this version of $0"; 
	}
	close (FILEIN);
	unlink "OMEmaint" or die "couldn't remove OMEmaint";
	
	# OMEIS
	my $semaphore;
	my $iwd = getcwd();
    
    # check if the OMEIS data was ever archived
    my $success = 1;
	foreach (`$prog_path{'tar'} --bzip2 -t Files Pixels -f $restore_file 2>&1`) {
		$success = 0 if $_=~ /tar/ or $_ =~ /Error/;
		# this is not a catastrophic error condition. It only means that OMEIS's
		# folders Files and Pixels aren't included in the archive
	}
	
	if (not $quick and $success) {
	    # prepare the omeis_base_dir
	    if (-d $omeis_base_dir) {
	     	if (y_or_n ("Restoring OMEIS from archive will delete all current files in ".
	   		  		"$omeis_base_dir. Continue ?")) {
				$semaphore = 1;
				
				# the  $omeis_base_dir directory itself should not be deleted - it should only be emptied.
				# this is to cover cases where $omeis_base_dir is a hand made symbolic link
				foreach (bsd_glob("$omeis_base_dir/*")) {
	   		  		rmtree($_) or die "Could not clean out $_ from $omeis_base_dir";
	   		  	}
	   		} else {
	   			$semaphore = 0;
			}	     	
	    } else {
	    	# need to make the omeis_base_dir
	    	mkdir ($omeis_base_dir) or 
	    	die "Could not create new OMEIS directory $omeis_base_dir";
	    }
	    
	    # expand the tar file directly into the OMEIS directory
	    if ($semaphore eq 1) {
			print "    \\_ Restoring OMEIS to $omeis_base_dir from archive\n";
			foreach (`$prog_path{'tar'} --bzip2 --preserve-permissions --same-owner --directory $omeis_base_dir -x Files Pixels -f $restore_file`) {
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
		if (y_or_n ("Database ome (version $db_version) was found and it will be overwritten. Continue ?")) {
			$dropdb = 1;
		}

		while ($dropdb == 1) {
			$success = 0;
			
			foreach (`su $postgress_user -c '$dropdb_path ome' 2>&1`) {
				$success = 1 if $_ =~ /DROP DATABASE/ and not $_ =~ /ERROR/;
			}
			
			if ($success == 0) {
				if (y_or_n ("Database could not be dropped. Try again ?")) {
					$dropdb = 1;
				} else {
					$dropdb = 0;
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
	
	# need to extract omeDB_backup in /tmp since postgress might not have
	# access permissions in current directory
	foreach (`$prog_path{'tar'} --bzip2 --preserve-permissions --same-owner --directory /tmp -x omeDB_backup -f $restore_file`) {
		print STDERR "\nCouldn't extract omeDB_backup from tar archive: $_" and die 
		if $_ =~ /tar/ or $_ =~ /error/ or $_ =~ /FATAL/;
	}
	
	my $dbConf = $environment->DB_conf();
	my $dbName = 'ome';
	$dbName = $dbConf->{Name} if $dbConf->{Name};

	my $flags = '';
	$flags .= '-h '.$dbConf->{Host}.' ' if $dbConf->{Host};
	$flags .= '-p '.$dbConf->{Port}.' ' if $dbConf->{Port};
	$flags .= '-U '.$dbConf->{User}.' ' if $dbConf->{User};
	
print STDERR "su $postgress_user -c '".$prog_path{'createuser'}." --adduser --createdb  ome'\n"; 	
print STDERR "su $postgress_user -c '".$prog_path{'createdb'}." $flags -T template0 $dbName'\n";
print STDERR "su $postgress_user -c '".$prog_path{'pg_restore'}." $flags -d $dbName --use-set-session-authorization /tmp/omeDB_backup'\n";
	system ("su $postgress_user -c '".$prog_path{'createuser'}." --adduser --createdb  ome'");
	system ("su $postgress_user -c '".$prog_path{'createdb'}." $flags -T template0 $dbName'");
	system ("su $postgress_user -c '".$prog_path{'pg_restore'}." $flags -d $dbName --use-set-session-authorization /tmp/omeDB_backup'");
}

sub restore_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] archive-name

Restores OMEIS's image repository and OME's postgress db from an .tar.bz2 archive of 
specified name.

By default, it looks in the current directory for an ome_backup file of this form:
  ome_backup_YYYY-MM-DD.tar.bz2
The ome_backup file with the latest YYYY-MM-DD is selected.

Options:
     -f, --env-file    
		Location of the stored environment overrides the default of 
		"/etc/ome-install.store"
     -q, --quick 
		If set, only OME's postgress db (and not OMEIS) is restored.
CMDS
}

sub connection {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
	my $env_file = "/etc/ome-install.store";

	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name with the -f flag to specify it. " if (not -e $env_file);
	
	# Parse our command line options
	my ($db,$user,$pass,$host,$port,$class);
	GetOptions('d|database=s' => \$db,
						 'u|user=s'     => \$user,
						 'h|host=s'     => \$host,
						 'p|port=i'     => \$port,
#						 'P|pass=s'     => \$pass,
						 'c|class=s'    => \$class,
	);
	
	# Get the environment and defaults
	my $environment = initialize OME::Install::Environment;
	my $defaultDBconf = {
		Delegate => 'OME::Database::PostgresDelegate',
		User     => undef,
		Password => undef,
		Host     => undef,
		Port     => undef,
		Name     => 'ome',
	};
	
	my $dbConf = $environment->DB_conf();
	$dbConf = $defaultDBconf unless $dbConf;

	$dbConf->{Delegate} = $class if $class;
	$dbConf->{User}     = $user  if $user;
	$dbConf->{Password} = $pass  if $pass;
	$dbConf->{Host}     = $host  if $host;
	$dbConf->{Port}     = $port  if $port;
	$dbConf->{Name}     = $db    if $db;
	
    my $confirm_all;

    while (1) {
        if ($dbConf or $confirm_all) {
            print "   Database Delegate Class: ", BOLD, $dbConf->{Delegate}, RESET, "\n";
            print "             Database Name: ", BOLD, $dbConf->{Name}, RESET, "\n";
            print "                      Host: ", BOLD, $dbConf->{Host} ? $dbConf->{Host} : 'undefined (local)', RESET, "\n";
            print "                      Port: ", BOLD, $dbConf->{Port} ? $dbConf->{Port} : 'undefined (default)', RESET, "\n";
            print "Username for DB connection: ", BOLD, $dbConf->{User} ? $dbConf->{User} : 'undefined (process owner)', RESET, "\n";
#            print "                  Password: ", BOLD, $dbConf->{Password} ? $dbConf->{Password}:'undefined (not set)', RESET, "\n";
    
            print "\n";  # Spacing
            
            # Don't be interactive if we got any parameters
			last if ($db or $user or $host or $port or $class);
			if (y_or_n ("Are these values correct ?","y")) {
				last;
			} 
        }

        $confirm_all = 0;
        print "Enter '\\' to set to ",BOLD,'undefined',RESET,"\n";
		$dbConf->{Delegate} = confirm_default ("   Database Delegate Class: ", $dbConf->{Delegate});
		$dbConf->{Name}     = confirm_default ("             Database Name: ", $dbConf->{Name});
		$dbConf->{Host}     = confirm_default ("                      Host: ", $dbConf->{Host});
		$dbConf->{Host} = undef if $dbConf->{Host} and $dbConf->{Host} eq '\\';
		$dbConf->{Port}     = confirm_default ("                      Port: ", $dbConf->{Port});
		$dbConf->{Port} = undef if $dbConf->{Port} and $dbConf->{Port} eq '\\';
		$dbConf->{User}     = confirm_default ("Username for DB connection: ", $dbConf->{User});
		$dbConf->{User} = undef if $dbConf->{User} and $dbConf->{User} eq '\\';
#		$dbConf->{Password} = confirm_default ("                  Password: ", $dbConf->{Password});
		$dbConf->{Password} = undef if $dbConf->{Password} and $dbConf->{Password} eq '\\';
        
        print "\n";  # Spacing

        $confirm_all = 1;
    }

	$environment->DB_conf($dbConf);
	$environment->store_to ();
}

sub connection_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

Configure the database connection.

Options:
     -d, --database
        Database name.
     -u, --user    
        User name to connect as.
     -h, --host 
        Host name of the database server.
     -p, --port 
        port number to use for connection.
     -c, --class 
        Delegate class to use for connection (default OME::Database::PostgresDelegate).
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

