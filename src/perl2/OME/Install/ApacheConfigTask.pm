# OME/Install/ApacheConfigTask.pm
# This task installs and configures the Apache portion of OME.

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
use File::Spec;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
use Cwd;

use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::Util;

use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

# Things we grab from the environment
our $OME_BASE_DIR;
our $APACHE_USER;
our $APACHE_UID;
our $OME_GROUP;
our $OME_GID;

our $APACHE;
our $APACHE_CONF_DEF = {
	DO_CONF  => 1,
	DEV_CONF => 0,
	OMEIS    => 1,
	OMEDS    => 1,
	WEB      => undef,
	HUP      => 1,
};

# Globals
our $APACHE_WEB_INCLUDE;
our $APACHE_OMEIS_INCLUDE;
our $APACHE_OMEDS_INCLUDE;


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
		s/#\s*AddModule\s+mod_perl\.c/AddModule mod_perl.c/;
		s/Include\s+(\/.*)*\/httpd\.ome(.dev)?\.conf.*\n//;
		print FILEOUT;
	};
	print FILEOUT "Include $omeConf\n";
	close(FILEIN);
	close(FILEOUT);
	move ("$httpdConf~",$httpdConf) or croak "Couldn't write $httpdConf: $!\n";
	$apache_info->{hasOMEinc} = 1;
}

sub httpd_conf_OK {
	my $apache_info = shift;

	my $httpdConf = $apache_info->{conf};
	my $httpdConfBak = $apache_info->{conf_bak};
	my $apachectlBin = $apache_info->{apachectl};
	
	my @result = `$apachectlBin configtest 2>&1 `;
	my $error = 1;
	foreach (@result) {
		$error = 0 if $_ =~ /Syntax OK/;
	}
	return (1) if not $error;
	
	# Revert
	print STDERR "Apache reports that configuration file has errors:\n".join ("\n",@result)."\n";
	copy ($httpdConfBak,$httpdConf)
		or croak "Could not copy $httpdConfBak to $httpdConf\n*** Apache configuration could not be restored !!! ***\n";
	return (0);
}

sub httpd_restart {
	my $apache_info = shift;
	my $apachectlBin = $apache_info->{apachectl};
	print `$apachectlBin restart`;
}

sub fix_ome_conf {
	my $OME_CONF_DIR = shift;
	my $OME_DIST_BASE = getcwd;
	my @lines;
	my $file;

    my @files = glob ("$OME_CONF_DIR/httpd.*.conf $OME_CONF_DIR/httpd2.*.conf");

	foreach $file (@files) {	
		open(FILE, "<", $file) or croak "Can't open $file for reading: $!";
		@lines = <FILE>;
		close (FILE);
		my $config = join ('',@lines); 
		$config =~ s/%OME_DIST_BASE/$OME_DIST_BASE/mg;
		$config =~ s/%OME_INSTALL_BASE/$OME_BASE_DIR/mg;
		$file =~ s/$OME_DIST_BASE/$OME_BASE_DIR/;
		open(FILE, "> $file") or croak "Can't open $file for writing: $!";
		print FILE $config;
		close (FILE);
	}
	
	# Add the include directives for installed components.
	$file = "$OME_CONF_DIR/httpd.ome.conf";
	open (FILE, "<",$file) or croak "Can't open $file for reading: $!";
	@lines = <FILE>;
	close (FILE);
	push (@lines,"$APACHE_WEB_INCLUDE\n");
	push (@lines,"$APACHE_OMEIS_INCLUDE\n");
	push (@lines,"$APACHE_OMEDS_INCLUDE\n");
	open (FILE, ">",$file) or croak "Can't open $file for writing: $!";
	print FILE $_ foreach (@lines);

	return (1);
}


sub getApacheBin {
	my $apache_info = {};
	my ($httpdConf,$httpdBin,$httpdRoot,$httpdVers);

	# First, get the httpd executable.
	$httpdBin = which ('httpd')
	            || which ('httpd2')
	            || which ('apache')
	            || which ('apache2')
	            || whereis ('httpd')
	            || croak "Unable to locate httpd binary";
	croak "Unable to execute httpd binary ($httpdBin)" unless -x $httpdBin;
	$apache_info->{bin} = $httpdBin;

	$apache_info->{apachectl} = which ('apachectl')
	                            || which ('apache2ctl')
	                            || whereis ("apachectl")
	                            || croak "Unable to locate apachectl binary";

	# Get the location of httpd.conf from the compiled-in options to httpd
	$httpdConf = `$httpdBin -V | grep SERVER_CONFIG_FILE | cut -d '"' -f 2`;
	chomp $httpdConf;

	$httpdRoot = `$httpdBin -V | grep HTTPD_ROOT | cut -d '"' -f 2`;
	chomp $httpdRoot;
	$apache_info->{root} = $httpdRoot;
	
	$httpdVers = `$httpdBin -V | grep 'Server version'`;
	$httpdVers = $1 if $httpdVers =~ /:\s*Apache\/(\d)/;
	croak "Could not determine Apache version\n" unless defined $httpdVers;
	$apache_info->{version} = $httpdVers;

	if (not File::Spec->file_name_is_absolute ($httpdConf) ) {
		$httpdConf = File::Spec->catfile ($httpdRoot,$httpdConf);
		$httpdConf = File::Spec->canonpath( $httpdConf ); 
	}
	$apache_info->{conf} = $httpdConf;

	return $apache_info;
}

sub getApacheInfo {
	my $apache_info = shift;
	my ($httpdConf,$omeConf);
	my ($mod_loaded,$mod_added,$mod_loaded_off,$mod_added_off);
	my @include_paths;

	$omeConf = $apache_info->{'ome_conf'};

	my @search_items = (
		# XXX Example
		#{
		#	search_elem => scalar refrerence to target (flag[1|0] or variable)
		#	regex       => perl compatible regex
		#},
		{
			# The apache server's "ServerRoot" (root for config files)
			search_elem => \$apache_info->{'ServerRoot'},
			regex       => qr/^\s*ServerRoot\s+["]*([^"|\n]+)["]*/,
		},
		{
			# Conf file has an ome conf
			search_elem => \$apache_info->{'hasOMEinc'},
			regex       => qr/\s*Include $omeConf/,
		},
		{
			# Conf file has mod_perl loaded
			search_elem => \$mod_loaded,
			regex       => qr/^\s*LoadModule\s+perl_module/,
		},
		{
			# Conf file has mod_perl added
			search_elem => \$mod_added,
			regex       => qr/^\s*AddModule\s+mod_perl.c/,
		},
		{
			# Conf file has mod_perl loader commented out (off)
			search_elem => \$mod_loaded_off,
			regex       => qr/#\s*LoadModule\s+perl_module/,
		},
		{
			# Conf file has mod_perl add commented out (off)
			search_elem => \$mod_added_off,
			regex       => qr/#\s*AddModule\s+mod_perl.c/,
		},
		{
			# Document root
			search_elem => \$apache_info->{'DocumentRoot'},
			regex       => qr/^\s*DocumentRoot\s+["]*([^"|\n]+)["]*/,
		},
		{
			# cgi-bin script alias location
			search_elem => \$apache_info->{'cgi_bin'},
			regex       => qr/^\s*ScriptAlias\s+\/cgi-bin\/\s+["]*([^"|\n]+)["]*/,
		},
	);

	my $include_set = new IncludeSet;

	# Nested anonymous subroutine for searching conf files
	my $search_func = sub {
		local (*FILE) = shift;

		while (<FILE>) {
			# Check each of our search_item regex's
			foreach my $search_item (@search_items) {
				if ($_ =~ $search_item->{'regex'}) {
					# Set variable with regex data or flag to 1
					${$search_item->{'search_elem'}} = $1 || 1;
				}
			}

			# Add to our include_set if we don't have it already
			if ($_ =~ /^\s*Include\s(.*)/ and $1 ne $omeConf) {
				$include_set->add($1) unless $include_set->contains($1);
			}
		}
	};

	$httpdConf = $apache_info->{conf};
	
	print STDERR  "Apache configuration file ($httpdConf) does not exist\n" unless -e $httpdConf;
	print STDERR  "Apache configuration file ($httpdConf) is not readable\n" unless -r $httpdConf;
#	confirm_path ('Apache configuration file', $httpdConf);
	$apache_info->{'conf'} = $httpdConf;
	croak "Could not find $httpdConf\n" unless -e $httpdConf;
	croak "Could not read $httpdConf\n" unless -r $httpdConf;

	$apache_info->{'conf_bak'} = $httpdConf.'.bak.ome';
	$omeConf = $apache_info->{'ome_conf'};

	# Open the root apache conf file
	open(FILE, "< $httpdConf")
		or croak "Couldn't open root config '$httpdConf' for reading: $!\n";

	# Parse the root apache conf file
	&$search_func(*FILE);

	close(FILE);
	
	# Parse each of the files included from the root apache conf file
	while (1) {
		my $path;
		my $i = 0;

		# Find a path we haven't searched yet
		for (my $i = 0; $i < $include_set->get_size(); $i++) {
			my $element = $include_set->get_element_by_index($i);

			if (not $include_set->examined($element)) {
				$path = $element;
				$include_set->set_examined($element);

				last;
			}
		}

		last if not defined $path;

		if (not File::Spec->file_name_is_absolute($path)) {
			# Non-absolute path must be off the ServerRoot
			$path = File::Spec->catdir($apache_info->{'ServerRoot'}, $path);
		}

		foreach my $file (glob($path)) {
			if (open (FILE, '<', $file)) {
				&$search_func(*FILE);
				close (FILE);
			} else {
				# Just a warning
				carp "**** Warning: Couldn't open include '$file' for reading: $!";
			}
		}

	}

	$apache_info->{'mod_perl_loaded'} = 1 if ($mod_loaded and $mod_added);
	$apache_info->{'mod_perl_off'} = 1 if ($mod_loaded_off or $mod_added_off);

	return $apache_info;
}



#*********
#********* START OF CODE
#*********

sub execute {
  
	# Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;
    $OME_BASE_DIR = $environment->base_dir() or croak "Could not get base installation environment\n";
	$APACHE_USER  = $environment->apache_user() or croak "Apache user is not set!\n";
    $APACHE_UID   = getpwnam ($APACHE_USER) or croak "Unable to retrive APACHE_USER UID!";
	$OME_GROUP    = $environment->group() or croak "OME group is not set!\n";
	$OME_GID      = getgrnam($OME_GROUP) or croak "Failure retrieving GID for \"$OME_GROUP\"";
	# Things the user can set
	$APACHE       = defined $environment->apache_conf()  ? $environment->apache_conf()  : $APACHE_CONF_DEF;

	# The configuration directory
	my $OME_CONF_DIR = $OME_BASE_DIR . '/conf';
	my $ome_conf = "$OME_CONF_DIR/httpd.ome.conf";
	my $is_dev = '';
	my $httpd_vers = 'httpd';

	my $apache_info;
	
	print "\n";  # Spacing
    
    print_header ("Apache Setup");
	
	#********
	#******** Get info from Apache's httpd.conf
	#********
	if ($APACHE->{DO_CONF}) {
		$apache_info = getApacheBin();
		$apache_info->{ome_conf} = $ome_conf;
		getApacheInfo($apache_info);
		$httpd_vers = 'httpd2' if $apache_info->{version} == 2;
		$APACHE->{WEB} = $apache_info->{DocumentRoot} unless defined $APACHE->{WEB} and not $APACHE->{WEB};
	}

	# Confirm all flag
	my $confirm_all;

    while (1) {
		if ($environment->get_flag("UPDATE") or $confirm_all) {
			print "\n";  # Spacing

			# Ask user to confirm his/her original entries
	
			print "       Configure Apache?: ", BOLD, $APACHE->{DO_CONF}  ?'yes':'no', RESET, "\n";
			print " Developer configuration: ", BOLD, $APACHE->{DEV_CONF} ?'yes':'no', RESET, "\n";
			print "         Server restart?: ", BOLD, $APACHE->{HUP}      ?'yes':'no', RESET, "\n";
			print BOLD,"Install OME servers:\n",RESET;
			print "          Images (omeis): ", BOLD, $APACHE->{OMEIS}    ?'yes':'no', RESET, "\n";
			print "            Data (omeds): ", BOLD, $APACHE->{OMEDS}    ?'yes':'no', RESET, "\n";
			print "                     Web: ", BOLD, $APACHE->{WEB}      ?'yes':'no', RESET, "\n";

			print "\n";  # Spacing

			y_or_n ("Are these values correct ?",'y') and last;
		}

		$confirm_all = 0;

		if (! y_or_n('Configure Apache server?','y') ) {
			$APACHE->{DO_CONF}  = 0;
			last;
		}
		$APACHE->{DO_CONF}  = 1;


		#********
		#******** Set the apache conf file we'll be using
		#********
	
		if ($apache_info->{version} == 2) {
			if (y_or_n("Use OME Apache-2.x configuration for developers?")) {
				$APACHE->{DEV_CONF} = 1;
			} else {
				$APACHE->{DEV_CONF} = 0;
			}
			$httpd_vers = 'httpd2';
		} else {
			if (y_or_n("Use OME Apache-1.x configuration for developers?")) {
				$APACHE->{DEV_CONF} = 1;
			} else {
				$APACHE->{DEV_CONF} = 0;
			}
			$httpd_vers = 'httpd';
		}
			
		croak "Could not read OME Apache configuration file ($ome_conf)\n" unless -r $ome_conf;
		getApacheInfo($apache_info) or croak "Could not get any Apache info\n";

		#********
		#******** Install omeis?
		#********
		if (y_or_n("Install image server (omeis) ?",'y')) {
			$apache_info->{cgi_bin}
				or croak "Apache httpd.conf does not have a cgi-bin directory";
			$APACHE->{OMEIS} = 1;
		} else {
			$APACHE->{OMEIS} = 0;
		}

		#********
		#******** Install omeds?
		#********
		if (y_or_n("Install data server (omeds) ?",'y')) {
			$APACHE->{OMEDS} = 1;
		} else {
			$APACHE->{OMEDS} = 0;
		}

		#********
		#******** Install web?
		#********
		if (y_or_n("Install web server ?",'y')) {
			my $docRoot = $APACHE->{WEB};
			$docRoot = $apache_info->{DocumentRoot} unless $docRoot;
			$APACHE->{WEB} = confirm_path ('Copy index.html to :', $docRoot);
			while (! -e $APACHE->{WEB}) {
				$APACHE->{WEB} = confirm_path ('Copy index.html to :', $docRoot);
			}
		} else {
			$APACHE->{WEB} = '';
		}

	print "\n";  # Spacing
	$confirm_all = 1;
	}

	$environment->apache_conf($APACHE);
	return unless $APACHE->{DO_CONF};

	my $httpdConf = $apache_info->{conf} or croak "Could not find httpd.conf\n";


	#********
	#******** Attempt to fix httpd.conf
	#********
	my $apacheBak = $apache_info->{conf_bak};
	print STDERR  "Apache httpd.conf does not have an Include directive for \"$ome_conf\"\n" if not $apache_info->{hasOMEinc};
	print STDERR  "Apache's mod_perl seems to be turned off in httpd.conf.  " if $apache_info->{mod_perl_off};
	if (not $apache_info->{hasOMEinc} or $apache_info->{mod_perl_off}) {
		if (not -w $httpdConf) {
			print "  You do not have write permissions for \"$httpdConf\".\nApache is not properly configured.";
		} else {
			if ( y_or_n("fix \"$httpdConf\" ?") ) {
				print "fixing httpd.conf. The current version will be saved in ".$apache_info->{conf_bak}."\n";
				fix_httpd_conf ($apache_info);
				httpd_conf_OK ($apache_info);
			}
		}
	}

	
	$is_dev = '-dev' if $APACHE->{DEV_CONF};

	my ($source,$dest);
	#********
	#******** Install omeis in cgi-bin
	#********
	if ($APACHE->{OMEIS}) {
		$source = 'src/C/omeis/omeis';
		$dest = $apache_info->{cgi_bin}.'/omeis';
		copy ($source,$dest) or croak "Could not copy $source to $dest:\n$!\n";
		chmod (0755,$dest) or croak "Could not chmod $dest:\n$!\n";
		chown ($APACHE_UID,$OME_GID,$dest) or croak "Could not chown $dest:\n$!\n";
		$APACHE_OMEIS_INCLUDE = "Include $OME_CONF_DIR/$httpd_vers.omeis$is_dev.conf";
	} else {
		$APACHE_OMEIS_INCLUDE = '';
	}

	#********
	#******** Install omeds by including the omeds httpd conf in ome's httpd conf
	#********
	if ($APACHE->{OMEDS}) {
		$APACHE_OMEDS_INCLUDE = "Include $OME_CONF_DIR/$httpd_vers.omeds$is_dev.conf";
	} else {
		$APACHE_OMEDS_INCLUDE = '';
	}

	#********
	#******** Install web by copying serve.pl and index.html
	#********
	if (length($APACHE->{WEB})) {
		$source = 'src/perl2/serve.pl';
		$dest = $OME_BASE_DIR.'/perl2/serve.pl';
		copy ($source,$dest) or croak "Could not copy $source to $dest:\n$!\n";
		chmod (0755,$dest) or croak "Could not chmod $dest:\n$!\n";
		chown ($APACHE_UID,$OME_GID,$dest) or croak "Could not chown $dest:\n$!\n";

		$source = 'src/html/index.html';
		$dest = $APACHE->{WEB}.'/index.html';
		copy ($source,$dest) or croak "Could not copy $source to $dest:\n$!\n";
		chmod (0755,$dest) or croak "Could not chmod $dest:\n$!\n";
		chown ($APACHE_UID,$OME_GID,$dest) or croak "Could not chown $dest:\n$!\n";
		$APACHE_WEB_INCLUDE = "Include $OME_CONF_DIR/$httpd_vers.web$is_dev.conf";
	} else {
		$APACHE_WEB_INCLUDE = '';
	}
	
	
	#********
	#******** Fix variables in conf/httpd.ome.*.conf
	#********
	fix_ome_conf("$OME_CONF_DIR");	
	
	#********
	#******** Restart
	#********
	httpd_restart ($apache_info) if $APACHE->{HUP};
	
	# Set a proper umask
	print "Dropping umask to ", BOLD, "\"0002\"", RESET, ".\n";
	umask (0002);

    return;
}

sub rollback {
    print "Rollback";
    return;
}


1;

# Blessed array reference to ease containership matching
#
# $include_set = [ [ELEMENT, EXAMINED_FLAG], ... ]
#
# Example:
#
#     $include_set = [ ["/foo/bar.conf", 0], ["/bar/foo.conf", 1] ... ]
#
package IncludeSet;

use constant ELEMENT       => 0;
use constant EXAMINED_FLAG => 1;

sub __find_offset {
	my ($self, $element) = @_;

	# Sanity
	return unless defined $element;
	
	for (my $i = 0; $i < scalar(@$self); $i++) {
		if ($self->[$i]->[ELEMENT] eq $element) {
			return $i;
		}
	}
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = [];
	
	return bless($self,$class);
}

sub add {
	my ($self, $element) = @_;

	# Sanity
	return unless defined $element;

	push (@$self, [$element, 0]) and return 1;
}

sub remove {
	my ($self, $element) = @_;

	# Sanity
	return unless defined $element;

	my $offset = $self->__find_offset($element)
		or return 0;

	splice(@$self, $offset, 1) and return 1;
}

sub get_element_by_name {
	my ($self, $element) = @_;

	# Sanity
	return unless defined $element;

	foreach (@$self) {
		if ($_->[ELEMENT] eq $element) {
			return $_->[ELEMENT]
		}
	}
}
	
sub get_element_by_index {
	my ($self, $index) = @_;

	# Sanity
	return unless defined $index or $index > @$self;

	return $self->[$index]->[ELEMENT];
}

sub get_size {
	my $self = shift;

	return scalar(@$self);
}

sub set_examined {
	my ($self, $element) = @_;
	
	# Sanity
	return unless defined $element;

	my $offset = $self->__find_offset($element);

	$self->[$offset]->[EXAMINED_FLAG] = 1;
}

sub examined {
	my ($self, $element) = @_;

	# Sanity
	return unless defined $element;

	my $offset = $self->__find_offset($element);

	return $self->[$offset]->[EXAMINED_FLAG] ? 1 : 0;
}

sub contains {
	my ($self, $test_item) = @_;

	# Sanity
	return unless defined $test_item;

	foreach (@$self) {
		return 1 if ($_ eq $test_item);
	}

	return 0;
}


1;
