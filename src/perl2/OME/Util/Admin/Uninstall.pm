# OME/Util/Uninstall

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


package OME::Util::Uninstall;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Cwd qw(cwd abs_path);
use Carp;
use Config;
use English;
use Getopt::Long;
use File::Path; # for rmtree
use File::Spec;
use File::Find;
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

sub handleCommand {
	my ($self,$help,$commands) = @_;
	if ($help) {
		uninstall_help($self,$commands);
	} else {
		uninstall($self,$commands);
	}
}

sub uninstall_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This will effortlessly remove the OME installation from your system. All data 
will be destroyed.

Options:
      
  -a This flag signals to remove everything. 
  -f Location of the stored environment overrides the default of 
   "/etc/ome-install.store"
USAGE
    CORE::exit(1);
}

sub uninstall {
	my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
	# Default env file location 
	my $env_file = "/etc/ome-install.store";
	my $all=0;
	
	# Parse our command line options
	my $result = GetOptions('f|env-file=s' => \$env_file,
							'a|all' => \$all,
						   );
	exit(1) unless $result;
	
	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name backup with the -f flag to specify it. " if (not -e $env_file);
	
	if ($all) {
		exit 1 unless y_or_n ("You have elected to completely remove your OME installation.".
						" Your data will be destroyed. Continue?");
	}
	
	# find all the neccessary programs we will run
	my @progs = ('rm', 'dropdb');
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
	my $tmp_dir = $environment->tmp_dir();
	
	print_header("OME Uninstall");
	
	# OME Base dir
	if ( -d $base_dir) {
		if ($all or y_or_n ("Remove base OME directory \"".$base_dir."\" ?")) {
			 print "    \\_ Removing $base_dir \n";
			rmtree($base_dir);
		}
	} else {
		 print "    \\_ $base_dir already doesn't exist.\n";
	}
	
	# OMEIS Base dir
	if ( -d $omeis_base_dir) {
		if ($all or y_or_n ("Remove base OMEIS directory \"".$omeis_base_dir."\" ?")) {
			 print "    \\_ Removing $omeis_base_dir \n";
			rmtree($omeis_base_dir);
		}
	} else {
		 print "    \\_ $omeis_base_dir already doesn't exist.\n";
	}
	
	# OME Base temporary dir
	if ( -d $tmp_dir) {
		if ($all or y_or_n ("Remove base temporary directory \"".$tmp_dir."\" ?")) {
			 print "    \\_ Removing $tmp_dir \n";
			rmtree($tmp_dir);
		}
	} else {
		 print "    \\_ $tmp_dir already doesn't exist. \n";
	}
	
	# Drop our UID to the OME_USER
    euid (scalar(getpwnam $environment->user() ));
    my $db_version = eval ("OME::Install::CoreDatabaseTablesTask::get_db_version()");
    
	if ($db_version) {
		if ($all or y_or_n ("Remove Postgress database \"ome\" ?")) {
			system($prog_path{'dropdb'}." ome");
		}	
	} else {	
		print "    \\_ Postgress database ome already doesn't exist. \n";
	}
	euid(0);
	
	# remove Perl Library Files
	if ($all or y_or_n ("Uninstall OME perl packages including ome admin tool ?")) {
		uninstall_perl_libs();
		
		# uninstall ome amdin tool
		if ($environment->cron_conf->{omeadmin}) {		
			my $file_path = $environment->cron_conf()->{omeadmin_path}."/ome";
			print "    \\_ Removing $file_path \n";
			unlink($file_path);
		}
	}
}

# This is harsh and probably dangerous, it also misses the 'man' directories,
# Other than the .packlist, this should things sqeaky clean, though.

# WARNING there is exact same code in src/perl2/Makefile.PL. If you change this
# change that as well.

sub uninstall_perl_libs {
	my %searchdirs;

	foreach (@INC) {
		if ( $_ ne '.' and -d $_ ) {
			$searchdirs{$_} = 1;
		}
	}

	File::Find::find( sub {
		my @dirs = File::Spec->splitdir($File::Find::name);
	    if ($dirs[$#dirs] eq 'OME') {
	    	if ($dirs[0] eq 'home' or $dirs[0] eq 'Users'){
				print "    \\_ Ignoring ",$File::Find::name,"\n";
	    	} else {
				print "    \\_ Removing ",$File::Find::name,"\n";
				system ('rm -rf '.$File::Find::name);
				$File::Find::prune = 1;
			}
		}
	}, keys %searchdirs);

}


__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

