# OME/Install/ApacheConfigTask.pm
# This task initializes the core OME system which currently consists of the 
# OME_BASE directory structure and ome user/group.

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

package OME::Install::ApacheConfigTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use English;
use Carp;
use File::Copy;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
use Cwd;

use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::Util;

use base qw(OME::Install::InstallationTask);


#*********
#********* LOCAL SUBROUTINES
#*********

sub fix_httpd_conf {
	my $apache_info = shift;

	my $httpdConf = $apache_info->{conf};
	my $omeConf = $apache_info->{ome_conf};
	my $httpdConfBak = $apache_info->{conf_bak};

	if (not -e $httpdConf) {
		print STDERR "Cannot fix httpd.conf:  httpd.conf ($httpdConf) does not exist.\n";
		return undef;
	}

	if (not -e $omeConf) {
		print STDERR  "Cannot fix httpd.conf:  ome.conf ($omeConf) does not exist.\n";
		return undef;
	}

	copy ($httpdConf,$httpdConfBak) or croak "Couldn't make a copy of $httpdConf: $!\n";
	open(FILEIN, "< $httpdConf") or croak "can't open $httpdConf for reading: $!\n";
	open(FILEOUT, "> $httpdConf~") or croak "can't open $httpdConf~ for writing: $!\n";
	while (<FILEIN>) {
		s/#\s*LoadModule\s+perl_module/LoadModule perl_module/;
		s/#\s*AddModule\s+mod_perl\.c/LoadModule mod_perl.c/;
		s/Include\s+(\/.*)*\/httpd\.ome(.dev)?\.conf.*\n//;
		print FILEOUT;
	};
	print FILEOUT "Include $omeConf\n";
	close(FILEIN);
	close(FILEOUT);
	move ("$httpdConf~",$httpdConf) or croak "Couldn't write $httpdConf: $!\n";
	$apache_info->{hasOMEinc} = 1;
}

sub copy_ome_conf {
    my $OME_INSTALL_BASE = shift;
	my $OME_DIST_BASE = getcwd;
    my @files = glob ($OME_DIST_BASE.'/conf/httpd.ome*.conf');
	my $file;

	foreach $file (@files) {	
		open(FILE, "< $file") or croak "can't open $file for reading: $!\n";
		my @lines = <FILE>;
		close (FILE);
		my $config = join ('',@lines); 
		$config =~ s/%OME_DIST_BASE/$OME_DIST_BASE/mg;
		$config =~ s/%OME_INSTALL_BASE/$OME_INSTALL_BASE/mg;
		$file =~ s/$OME_DIST_BASE/$OME_INSTALL_BASE/;
		open(FILE, "> $file") or croak "can't open $file for writing: $!\n";
		print FILE $config;
		close (FILE);
	}

	return (1);
}


sub getApacheBin {
	my $apache_info = {};
	my $httpdBin;

	# First, get the httpd executable.
	$httpdBin = which ('httpd');
   
    $httpdBin = whereis ("httpd") or croak "Unable to locate httpd binary." unless $httpdBin;

	$apache_info->{bin} = $httpdBin;
	return $apache_info;
}


sub getApacheInfo {
	my $apache_info = shift;
	my ($httpdConf,$httpdBin,$httpdRoot,$omeConf);

	$httpdBin = $apache_info->{bin};
	
	if (-x $httpdBin) {
		# Get the location of httpd.conf from the compiled-in options to httpd
		$httpdConf = `$httpdBin -V | grep SERVER_CONFIG_FILE | cut -d '"' -f 2`;
		chomp $httpdConf;
	
		$httpdRoot = `$httpdBin -V | grep HTTPD_ROOT | cut -d '"' -f 2`;
		chomp $httpdRoot;
		$apache_info->{root} = $httpdRoot;
	
		if (not File::Spec->file_name_is_absolute  ($httpdConf) ) {
			$httpdConf = File::Spec->catfile ($httpdRoot,$httpdConf);
			$httpdConf = File::Spec->canonpath( $httpdConf ); 
		}
	} else {
		print STDERR  "httpd ($httpdBin) is not executable\n";
		return undef;
	}

	print STDERR  "Apache configuration file (httpd.conf) does not exist\n" unless -e $httpdConf;
	print STDERR  "Apache configuration file (httpd.conf) is not readable\n" unless -r $httpdConf;
	confirm_path ('Apache configuration file (httpd.conf)', $httpdConf);
	croak "Could not find Apache configuration file\n" unless -e $httpdConf;
	croak "Could not read Apache configuration file\n" unless -r $httpdConf;

	if (-r $httpdConf) {
		$apache_info->{conf} = $httpdConf;
		$apache_info->{conf_bak} = $httpdConf.'.bak.ome';
		$omeConf = $apache_info->{ome_conf};
	
		# Parse httpd.conf to see if it includes ome.conf
		if ( open(FILE, "< $httpdConf") ) {
			my ($mod_loaded,$mod_added,$mod_loaded_off,$mod_added_off);
			while (<FILE>) {
				$apache_info->{hasOMEinc} = 1 if $_ =~ /\s*Include $omeConf/;
				$mod_loaded = 1 if $_ =~ /^\s*LoadModule perl_module/;
				$mod_added = 1 if $_ =~ /^\s*AddModule mod_perl.c/;
				$mod_loaded_off = 1 if $_ =~ /#\s*LoadModule\s+perl_module/;
				$mod_added_off = 1 if $_ =~ /#\s*AddModule\s+mod_perl\.c/;
				$apache_info->{DocumentRoot} = $1 if $_ =~ /^\s*DocumentRoot\s+["]*([^"]+)["]*/;
			}
			$apache_info->{mod_perl_loaded} = 1 if ($mod_loaded and $mod_added);
			$apache_info->{mod_perl_off} = 1 if ($mod_loaded_off or $mod_added_off);
		} else {
			print STDERR  "Could not open httpd.conf ($httpdConf) for reading: $!\n";
		}
	}

	return $apache_info;
}



#*********
#********* START OF CODE
#*********

sub execute {
	return unless y_or_n('Configure Apache server?');
  
	# Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;
    
    print_header ("Apache Setup");

    #********
    #******** Gather information about the Apache executable and its configuration file (httpd.conf)
    #********

    # Set a proper umask
    print "Dropping umask to ", BOLD, "\"0002\"", RESET, ".\n";
    umask (0002);

    my $OME_BASE_DIR = $environment->base_dir() or croak "Could not get base installation environment\n";

	my $apache_info = getApacheBin();

    
    #********
    #******** Fix paths in conf/httpd.ome.*.conf
    #********
	copy_ome_conf($OME_BASE_DIR);
	
	my $ome_conf = $OME_BASE_DIR.'/conf/httpd.ome.dev.conf';
	$ome_conf = $OME_BASE_DIR.'/conf/httpd.ome.conf'
		unless y_or_n("Use OME Apache configuration for developers ($ome_conf)?");

	croak "Could not read OME Apache configuration file \"\n" unless -r $ome_conf;
	$apache_info->{ome_conf} = $ome_conf;

    
    #********
    #******** Get info from Apache's httpd.conf
    #********
	getApacheInfo($apache_info) or croak "Could not get any Apache info\n";
	my $httpdConf = $apache_info->{conf} or croak "Could not find httpd.conf\n";

    
    #********
    #******** Attempt to fix httpd.conf
    #********
	print STDERR  "Apache httpd.conf does not have an Include directive for \"$ome_conf\"\n" if not $apache_info->{hasOMEinc};
	print STDERR  "Apache's mod_perl seems to be turned off in httpd.conf\n" if $apache_info->{mod_perl_off};
	if (not $apache_info->{hasOMEinc} or $apache_info->{mod_perl_off}) {
		if (not -w $httpdConf) {
			print "  You do not have write permissions for \"$httpdConf\".\nApache is not properly configured.";
		} else {
			if ( y_or_n("fix \"$httpdConf\" ?") ) {
				print "fixing httpd.conf. The current version will be saved in ".$apache_info->{conf_bak}."\n";
				fix_httpd_conf($apache_info);
			}
		}
	}

    
    #********
    #******** Copy index.html?
    #********
    my $docRoot = $apache_info->{DocumentRoot};
	if ( y_or_n ("Copy OME's index.html to DocumentRoot directory \"$docRoot\" ?") ) {
	    my ($fromIndex,$toIndex) = (getcwd.'/src/html/index.html',$docRoot.'/index.html');
		copy ($fromIndex,$toIndex) or croak "Could not copy \"$fromIndex\" to \"$toIndex\":\n$!\n";
	}
	
    print "\n";  # Spacing

    return;
}

sub rollback {
    print "Rollback";
    return;
}

1;
