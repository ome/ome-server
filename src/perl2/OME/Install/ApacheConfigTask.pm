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
use Sys::Hostname;
use File::Copy;
use File::Spec;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
use Cwd;
use Text::Wrap;
use Time::localtime;
use Time::Local;

# Packages that should have been installed by now
use HTTP::Request::Common;
use LWP::UserAgent;

use OME::Install::Terminal;
use OME::Install::Environment;
use OME::Install::Util;

use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

# Things we grab from the environment
our $OME_BASE_DIR;
our $OMEIS_BASE_DIR;
our $APACHE_USER;
our $APACHE_UID;
our $OME_GROUP;
our $OME_GID;

# $APACHE comes from the install environment.
# $APACHE_CONF_DEF is the default configuration (when there isn't one in the environment)
our $APACHE;
our $APACHE_CONF_DEF = {
	DO_CONF  => 1,
	DEV_CONF => 0,
	OMEIS    => 1,
	OMEDS    => 1,
	WEB      => undef, # This gets set to DocumentRoot if its undef and DO_CONF is true.
	CGI_BIN  => undef,
	OMEIS_UP => 'midnight', # values are now, midnight and manual
	HUP      => 1,
};

# Globals
our $APACHE_WEB_INCLUDE;
our $APACHE_OMEIS_INCLUDE;
our $APACHE_OMEDS_INCLUDE;
our $APACHE_OMEIS_UPDATE_REQUIRED = 0;

# Global logfile filehandle and name
our $LOGFILE_NAME = "ApacheConfigTask.log";
our $LOGFILE;
our $OME_TMP_DIR;


#*********
#********* LOCAL SUBROUTINES
#*********

sub fix_httpd_conf {
	my $apache_info = shift;

	my $httpdConf = $apache_info->{conf};
	my $omeConf = $apache_info->{ome_conf};
	my $httpdConfBak = $apache_info->{conf_bak};

	if (not -e $httpdConf) {
		print STDERR "Cannot fix httpd.conf:  httpd.conf ($httpdConf) does not exist.\n" and
			print $LOGFILE "Cannot fix httpd.conf:  httpd.conf ($httpdConf) does not exist.\n";
		return undef;
	}

	if (not -e $omeConf) {
		print STDERR  "Cannot fix httpd.conf:  ome.conf ($omeConf) does not exist.\n" and
			print $LOGFILE "Cannot fix httpd.conf:  ome.conf ($omeConf) does not exist.\n";
		return undef;
	}

	copy ($httpdConf,$httpdConfBak) or
		print $LOGFILE "Couldn't make a copy of $httpdConf: $!\n" and
		croak "Couldn't make a copy of $httpdConf: $!\n";

	open(FILEIN, "< $httpdConf") or
		print $LOGFILE "can't open $httpdConf for reading: $!\n" and
		croak "can't open $httpdConf for reading: $!\n";

	open(FILEOUT, "> $httpdConf~") or
		print $LOGFILE "can't open $httpdConf~ for writing: $!\n" and
		croak "can't open $httpdConf~ for writing: $!\n";

	while (<FILEIN>) {
		s/#\s*LoadModule\s+perl_module/LoadModule perl_module/;
		s/#\s*AddModule\s+mod_perl\.c/AddModule mod_perl.c/;
		s/Include\s+(\/.*)*\/httpd(2)?\.ome(\.dev)?\.conf.*\n//;
		print FILEOUT;
	};
	print FILEOUT "Include $omeConf\n";
	close(FILEIN);
	close(FILEOUT);
	move ("$httpdConf~",$httpdConf) or
		print $LOGFILE "Couldn't write $httpdConf: $!\n" and
		croak "Couldn't write $httpdConf: $!\n";
	$apache_info->{hasOMEinc} = 1;
	
	return 1;
}

sub httpd_conf_OK {
	my $apache_info = shift;

	my $httpdConf = $apache_info->{conf};
	my $httpdConfBak = $apache_info->{conf_bak};
	my $apachectlBin = $apache_info->{apachectl};

	print $LOGFILE "Executing $apachectlBin configtest 2>&1\n";
	my @result = `$apachectlBin configtest 2>&1 `;
	my $error = 1;
	foreach (@result) {
		$error = 0 if $_ =~ /Syntax OK/;
	}
	return (1) if not $error;
	
	# Revert
	print STDERR "Apache reports that configuration file has errors:\n".join ("\n",@result)."\n" and
		print $LOGFILE "Apache reports that configuration file has errors:\n".join ("\n",@result)."\n";
	print STDERR "Reverting to backup configuration\n" and
		print $LOGFILE "Reverting to backup configuration in $httpdConfBak\n";
	copy ($httpdConfBak,$httpdConf)
		or print $LOGFILE "Could not copy $httpdConfBak to $httpdConf\n*** Apache configuration could not be restored !!! ***\n" and
		croak "Could not copy $httpdConfBak to $httpdConf\n*** Apache configuration could not be restored !!! ***\n";
	return (0);
}

sub httpd_restart {
	my $apache_info = shift;
	my $apachectlBin = $apache_info->{apachectl};
	print $LOGFILE "Executing $apachectlBin restart\n" and
	print `$apachectlBin restart`;
}

# Test our apache config
sub httpd_test {
	my $error;

	print "Testing Apache configuration \n";

	print $LOGFILE "Getting an LWP user agent\n";
	my $user_agent = LWP::UserAgent->new();
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Could not get a LWP user agent\n" and
		croak "Could not get a LWP user agent"
	unless $user_agent;

	
	# Test mod_perl.  Here we will make a little script that we'll put next to serve.pl
	# The script will just spit out the environment variables as seen by an apache cgi.
	# Then we'll search the output for tell-tale signs of mod_perl.
	print "  \\__ mod_perl ";

	my $script = mod_perl_script();
	my $script_path = $OME_BASE_DIR.'/perl2/mod_perl_test.pl';
	print $LOGFILE "Generated mod_perl test script:\n$script\n";
	$script_path = 'src/perl2/mod_perl_test.pl' if $APACHE->{DEV_CONF};
	print $LOGFILE "Writing script to $script_path\n";

	# Write the test script into the proper place
	open(FILE, ">", $script_path) or 
		print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Can't open $script_path for writing: $!\n" and
		croak "Can't open $script_path for writing: $!";
		
	print FILE $script;
	close (FILE);
	chmod (0755,$script_path) or
		print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Could not chmod $script_path: $!\n" and
		croak "Could not chmod $script_path: $!";
	
	# Run the test script as a cgi
	my $url = 'http://localhost/perl2/mod_perl_test.pl';
	print $LOGFILE "Making an HTTP::Request object for $url\n";
	my $request = HTTP::Request->new(GET => $url);
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Could not generate a GET request for $url\n" and
		croak "Could not generate a request for $url"
	unless $request;

	print $LOGFILE "Getting response from $url\n";
	my $response = $user_agent->request($request);
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Apache/mod_perl is not properly configured.  Did not get a response from $url.\n" and
		croak "Apache/mod_perl is not properly configured.\n".
			"Did not get a response from $url.\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $response;

	my $content = $response->content();
	print $LOGFILE "Checking response from $url\n";
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Apache/mod_perl is not properly configured.  Got an error response from $url:\n".
			"$content\n" and
		croak "Apache/mod_perl is not properly configured.  Got an error response from $url:\n".
			"$content\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	if $response->is_error();

	print $LOGFILE "Parsing response from $url\n";
	# Check for MOD_PERL
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Apache/mod_perl is not properly configured.\n".
			"MOD_PERL environment variable is missing in CGI test.\n".
			"CGI test: $url\n" and
		croak "Apache/mod_perl is not properly configured.\n".
			"MOD_PERL environment variable is missing in CGI test.\n".
			"CGI test: $url\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $content =~ /^MOD_PERL\s*=\s*(.*$)/m;

	# Check that MOD_PERL is set to something containing mod_perl
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Apache/mod_perl is not properly configured.\n".
			"MOD_PERL is \"$1\" in CGI test.  Expecting something with mod_perl.\n".
			"CGI test: $url\n" and
		croak "Apache/mod_perl is not properly configured.\n".
			"MOD_PERL is \"$1\" in CGI test.  Expecting something with mod_perl.\n".
			"CGI test: $url\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $content =~ /^MOD_PERL\s*=\s*mod_perl.*$/m;
	
	# Check for GATEWAY_INTERFACE
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Apache/mod_perl is not properly configured.\n".
			"GATEWAY_INTERFACE environment variable is missing in CGI test.\n".
			"CGI test: $url\n" and
		croak "Apache/mod_perl is not properly configured.\n".
			"GATEWAY_INTERFACE environment variable is missing in CGI test.\n".
			"CGI test: $url\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $content =~ /^GATEWAY_INTERFACE\s*=\s*(.*$)/m;

	# Check that GATEWAY_INTERFACE contains CGI-Perl
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Apache/mod_perl is not properly configured.\n".
			"GATEWAY_INTERFACE is \"$1\" in CGI test instead of \"CGI-Perl/1.1\".\n".
			"CGI test: $url\n" and
		croak "Apache/mod_perl is not properly configured.\n".
			"GATEWAY_INTERFACE is \"$1\" in CGI test instead of \"CGI-Perl/1.1\".\n".
			"CGI test: $url\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $content =~ /^GATEWAY_INTERFACE\s*=\s*CGI-Perl.*$/m;

    print BOLD, "[SUCCESS]", RESET, ".\n"
        and print $LOGFILE "mod_perl is configured correctly\n";

	# Ditch our test script
	unlink ($script_path);

	# Test omeis if we installed it
	if ($APACHE->{OMEIS}) {
		print "  \\__ omeis " and
			print $LOGFILE "Testing omeis installation\n";
		my $ENVIRONMENT = initialize OME::Install::Environment;
		omeis_test('http://localhost/cgi-bin/omeis');
		print $LOGFILE "OMEIS is configured correctly\n";

	}
}

sub omeis_test {
	my $url = shift;
	$LOGFILE = shift if @_;
	
	print $LOGFILE "Getting an LWP user agent\n";
	my $user_agent = LWP::UserAgent->new();
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Could not get a LWP user agent\n" and
		croak "Could not get a LWP user agent"
	unless $user_agent;


	# Get a request
	print $LOGFILE "Generating request for $url\n";
	my $request = HTTP::Request->new(GET => $url);
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Could not generate a request for $url.\n" and
		croak "Could not generate a request for $url\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $request;

	# Get a response
	print $LOGFILE "Getting response from $url\n";
	my $response = $user_agent->request($request);
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "OMEIS could not be reached.\n".
			"Did not get a response from $url.\n" and
		croak "OMEIS could not be reached.  Did not get a response from $url.\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $response;

	# Check the response for 'Method parameter missing'
	print $LOGFILE "Parsing response from $url\n";
	my $content = $response->content();
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "OMEIS could not be reached.\n".
			"Incorrect response from OMEIS at $url:\n$content\n" and
		croak "OMEIS could not be reached.\n".
			"Incorrect response from OMEIS at $url:\n$content\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $content =~ /Method parameter missing/m;

	print BOLD, "[SUCCESS]", RESET, ".\n"
		and print $LOGFILE "Repository is configured correctly\n";

}


sub need_omeis_update {

	my $need_update = 0;
	my $pixels_update=1;
	my $files_update=1;

	# Be the root user for this.
	my $old_UID = euid($APACHE_UID);

	if ( open(VERS, "$OME_BASE_DIR/bin/updateOMEIS -q |") ) {
 	   while (<VERS>) {
 	       $pixels_update = 0 if /^Pixels/;
 	       $files_update  = 0 if /^Files/;
		}
		close VERS;
	} else {
		$need_update = 1;
	}

	# Go back to the old UID.
	euid($old_UID);

	return ($pixels_update or $files_update or $need_update);

}

sub update_omeis {
my $sleep;

	if ($APACHE->{OMEIS_UP} eq 'now') {
		$sleep = 0;
	} elsif ($APACHE->{OMEIS_UP} eq 'manual') {
		return;
	} elsif ($APACHE->{OMEIS_UP} eq 'midnight') {
		my $timeAt  = timelocal( 0,0,0,localtime->mday()+1,localtime->mon(),localtime->year() );
		my $timeNow = timelocal(localtime->sec(),localtime->min(),localtime->hour(),localtime->mday(),localtime->mon(),localtime->year() );
		$sleep = $timeAt-$timeNow;
	} else {
		$sleep = $APACHE->{OMEIS_UP};
		$APACHE->{OMEIS_UP} = 'midnight';
	}
	
	print $LOGFILE "Forking child to exec (sleep $sleep ; $OME_BASE_DIR/bin/updateOMEIS -s)\n";
	

	my $pid = fork();
	
	if ($pid) { # parent
		print $LOGFILE "Child PID=$pid\n";
		return ($pid);
	} elsif ($pid == 0) { # child
		chdir($OMEIS_BASE_DIR);
		euid($APACHE_UID);
		exec ("(sleep $sleep ; $OME_BASE_DIR/bin/updateOMEIS -s)");
		# NOTREACHED
	} else {
		print $LOGFILE "Can't fork\n"
		 and die "Can't fork";
	}
}

sub confirm_omeis_sched {
    my $def_time_str = POSIX::strftime ( "%Y-%m-%d %H:%M", (0,0,0,localtime->mday()+1,localtime->mon(),localtime->year()) );
	my $uInput = confirm_default ('Update omeis on :', $def_time_str);
	my ($year,$mon,$mday,$hour,$min) = ($1,$2,$3,$4,$5) if $uInput =~ /(\d+)-(\d+)-(\d+)\s+(\d+):(\d+)/;
	$mon--;
	my $timeAt  = timelocal(0,$min,$hour,$mday,$mon,$year);
	my $timeNow = timelocal(localtime->sec(),localtime->min(),localtime->hour(),localtime->mday(),localtime->mon(),localtime->year() );
	
	return (0) if $timeAt-$timeNow < 60;
	return  ($timeAt-$timeNow);
}

sub get_omeis_sched_str {
	return 'now' if $APACHE->{OMEIS_UP} eq 'now';
	return 'midnight' if $APACHE->{OMEIS_UP} eq 'midnight';
	return 'manual' if $APACHE->{OMEIS_UP} eq 'manual';
	return ( scalar (CORE::localtime (time()+$APACHE->{OMEIS_UP})) );
}

sub fix_ome_conf {
	my $OME_CONF_DIR = shift;
	my $OME_DIST_BASE = getcwd;
	my @lines;
	my $file;

    my @files = glob ("$OME_CONF_DIR/httpd.*.conf $OME_CONF_DIR/httpd2.*.conf");
	
	print $LOGFILE "Replacing %OME_DIST_BASE with $OME_DIST_BASE\n";
	print $LOGFILE "Replacing %OME_INSTALL_BASE with $OME_BASE_DIR\n";

	foreach $file (@files) {
		print $LOGFILE "Reading $file\n";
		open(FILE, "<", $file) or
			print $LOGFILE "Can't open $file for reading: $!\n" and
			croak "Can't open $file for reading: $!";
		@lines = <FILE>;
		close (FILE);
		my $config = join ('',@lines); 
		$config =~ s/%OME_DIST_BASE/$OME_DIST_BASE/mg;
		$config =~ s/%OME_INSTALL_BASE/$OME_BASE_DIR/mg;
		$file =~ s/$OME_DIST_BASE/$OME_BASE_DIR/;
		print $LOGFILE "Writing $file\n";
		open(FILE, "> $file") or
			print $LOGFILE "Can't open $file for writing: $!" and
			croak "Can't open $file for writing: $!";
		print FILE $config;
		close (FILE);
	}
	
	# Add the include directives for installed components.
	$file = "$OME_CONF_DIR/httpd.ome.conf";
	print $LOGFILE "Reading $file\n";
	open (FILE, "<",$file) or
		print $LOGFILE "Can't open $file for reading: $!" and
		croak "Can't open $file for reading: $!";
	@lines = <FILE>;
	close (FILE);
	push (@lines,"$APACHE_WEB_INCLUDE\n");
	push (@lines,"$APACHE_OMEIS_INCLUDE\n");
	push (@lines,"$APACHE_OMEDS_INCLUDE\n");

	print $LOGFILE "Writing $file\n";
	open (FILE, ">",$file) or
		print $LOGFILE "Can't open $file for writing: $!" and
		croak "Can't open $file for writing: $!";
	print FILE $_ foreach (@lines);
	close (FILE);

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
    $OMEIS_BASE_DIR = $environment->omeis_base_dir() or croak "Could not get OMEIS base directory\n";
    $OME_BASE_DIR = $environment->base_dir() or croak "Could not get base installation environment\n";
	$APACHE_USER  = $environment->apache_user() or croak "Apache user is not set!\n";
    $APACHE_UID   = getpwnam ($APACHE_USER) or croak "Unable to retrive APACHE_USER UID!";
	$OME_GROUP    = $environment->group() or croak "OME group is not set!\n";
	$OME_GID      = getgrnam($OME_GROUP) or croak "Failure retrieving GID for \"$OME_GROUP\"";
    $OME_TMP_DIR  = $environment->tmp_dir() or croak "Unable to retrieve OME_TMP_DIR!";
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
    
    print "(All verbose information logged in $OME_TMP_DIR/install/$LOGFILE_NAME)\n\n";
	
	# Task blurb
	my $blurb = <<BLURB;
OME Apache web server configuration is a critical part of your OME install. OME's web interface, remote clients and image server all use this infrastructure to communicate. If you are unsure of a particular question, please choose the default as that will be more than adequate for most people.
BLURB

	print wrap("", "", $blurb);
	
	print "\n";  # Spacing

    # Get our logfile and open it for writing
    open ($LOGFILE, ">", "$OME_TMP_DIR/install/$LOGFILE_NAME")
    or croak "Unable to open logfile \"$OME_TMP_DIR/install/$LOGFILE_NAME\" $!";
    
    print $LOGFILE "Apache setup\n";

	#********
	#******** Get info from Apache's httpd.conf
	#********
	if ($APACHE->{DO_CONF}) {
		$apache_info = getApacheBin();
		$apache_info->{ome_conf} = $ome_conf;
		getApacheInfo($apache_info);
		$httpd_vers = 'httpd2' if $apache_info->{version} == 2;
		$APACHE->{WEB} = $apache_info->{DocumentRoot} unless defined $APACHE->{WEB} and $APACHE->{WEB};
		$APACHE->{CGI_BIN} = $apache_info->{cgi_bin} unless defined $APACHE->{CGI_BIN} and $APACHE->{CGI_BIN};
	}

		
	# Wether or not we need to update omeis:
	$APACHE_OMEIS_UPDATE_REQUIRED = need_omeis_update();
	$APACHE->{OMEIS_UP} = $APACHE_CONF_DEF->{OMEIS_UP} unless defined $APACHE->{OMEIS_UP};

	# Confirm all flag
	my $confirm_all;

    while (1) {
		if ($environment->get_flag("UPDATE") or $confirm_all) {
			print "\n";  # Spacing

			# Ask user to confirm his/her original entries
	
			print BOLD,"Apache configuration:\n",RESET;
			print      "        Configure Apache?: ", BOLD, $APACHE->{DO_CONF}  ?'yes':'no', RESET, "\n";
			print      "  Developer configuration: ", BOLD, $APACHE->{DEV_CONF} ?'yes':'no', RESET, "\n";
			print      "          Server restart?: ", BOLD, $APACHE->{HUP}      ?'yes':'no', RESET, "\n";
			print BOLD,"Install OME servers:\n",RESET;
			print      "           Images (omeis): ", BOLD, $APACHE->{OMEIS}    ?'yes':'no', RESET, "\n";
			print      "             Data (omeds): ", BOLD, $APACHE->{OMEDS}    ?'yes':'no', RESET, "\n";
			print      "                      Web: ", BOLD, $APACHE->{WEB}      ?'yes':'no', RESET, "\n";
			print BOLD,"Apache directories:\n",RESET if $APACHE->{WEB} or $APACHE->{OMEIS};
			print      "             DocumentRoot: ", BOLD, $APACHE->{WEB}, RESET, "\n" if $APACHE->{WEB};
			print      "                  cgi-bin: ", BOLD, $APACHE->{CGI_BIN}, RESET, "\n" if $APACHE->{OMEIS};
			if ($APACHE->{OMEIS} and $APACHE_OMEIS_UPDATE_REQUIRED) {
				print BOLD,"OMEIS Update:\n",RESET;
				print "           execute update: ", BOLD, get_omeis_sched_str() , RESET, "\n"
					if $APACHE->{OMEIS_UP} ne 'manual';
				print "          update manually: ", BOLD, "sudo -u $APACHE_USER $OME_BASE_DIR/bin/updateOMEIS\n", RESET
					if $APACHE->{OMEIS_UP} eq 'manual';
			}
			print "\n";  # Spacing

			y_or_n ("Are these values correct ?",'y') and last;
		}

		$confirm_all = 0;

		if (! y_or_n('Configure Apache server?','y') ) {
			$APACHE->{DO_CONF}  = 0;
			redo;
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
			my $cgi_bin = $APACHE->{CGI_BIN};
			$cgi_bin = $apache_info->{cgi_bin} unless $cgi_bin;
			$APACHE->{CGI_BIN} = confirm_path ('Apache cgi-bin directory :', $cgi_bin);
			while (! -e $APACHE->{CGI_BIN} or ! -d $APACHE->{CGI_BIN}) {
				$APACHE->{CGI_BIN} = confirm_path ('Apache cgi-bin directory :', $cgi_bin);
			}
			$APACHE->{OMEIS} = 1;
			if ($APACHE_OMEIS_UPDATE_REQUIRED) {
				if (y_or_n("Update OMEIS manually ?",'n')) {
					$APACHE->{OMEIS_UP} = 'manual';
				} else {
					if (y_or_n("Schedule OMEIS update for later ?",'y')) {
						$APACHE->{OMEIS_UP} = confirm_omeis_sched();
						$APACHE->{OMEIS_UP} = 'now' unless $APACHE->{OMEIS_UP};						
					} else {
						$APACHE->{OMEIS_UP} = 'now';
					}
				}
			}
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

	# Put what we have in the log file
	print $LOGFILE "Apache configuration:\n";
	print $LOGFILE "        Configure Apache?: ", $APACHE->{DO_CONF}  ?'yes':'no', "\n";
	print $LOGFILE "  Developer configuration: ", $APACHE->{DEV_CONF} ?'yes':'no', "\n";
	print $LOGFILE "          Server restart?: ", $APACHE->{HUP}      ?'yes':'no', "\n";
	print $LOGFILE "Install OME servers:\n";
	print $LOGFILE "           Images (omeis): ", $APACHE->{OMEIS}    ?'yes':'no', "\n";
	print $LOGFILE "             Data (omeds): ", $APACHE->{OMEDS}    ?'yes':'no', "\n";
	print $LOGFILE "                      Web: ", $APACHE->{WEB}      ?'yes':'no', "\n";
	print $LOGFILE "Apache directories:\n";
	print $LOGFILE "             DocumentRoot: ", $APACHE->{WEB}, "\n";
	print $LOGFILE "                  cgi-bin: ", $APACHE->{CGI_BIN}, "\n";
	if ($APACHE->{OMEIS} and $APACHE_OMEIS_UPDATE_REQUIRED) {
		print $LOGFILE "OMEIS Update:\n";
		print $LOGFILE "           execute update:", get_omeis_sched_str() , "\n"
			if $APACHE->{OMEIS_UP} ne 'manual';
		print $LOGFILE "          update manually:", "sudo -u $APACHE_USER $OME_BASE_DIR/bin/updateOMEIS\n"
			if $APACHE->{OMEIS_UP} eq 'manual';
	}

	
	# Return unless we're configuring apache
	if (not $APACHE->{DO_CONF}) {
		print $LOGFILE "Not setting up Apache\n";
		# Set a proper umask
		print "Dropping umask to ", BOLD, "\"0002\"", RESET, ".\n";
		umask (0002);
		close ($LOGFILE);
		return;
	}

	print $LOGFILE "Configuring Apache\n";

	my $httpdConf = $apache_info->{conf} or croak "Could not find httpd.conf\n";
	print $LOGFILE "httpd.conf is $httpdConf\n";
       
	if ($APACHE->{DEV_CONF}) {
		if ( not  check_permissions ({user => $APACHE_USER, r => 1, x => 1}, cwd()."/src/perl2") ) {
			print STDERR "\nYou have chosen a developer configuration, yet Apache does not have access into the\n".
						 "distribution directory (".cwd().").\n".
						 "Please re-set your permissions to give Apache access and try the install again.\n".
						 "Alternatively, you can choose to not use the developer configuration.";
			die;
		}
	}
        

	#********
	#******** Attempt to fix httpd.conf
	#********
	my $apacheBak = $apache_info->{conf_bak};
	print STDERR  "Apache httpd.conf does not have an Include directive for \"$ome_conf\"\n" 
		and print $LOGFILE "Apache httpd.conf does not have an Include directive for \"$ome_conf\"\n"
	if not $apache_info->{hasOMEinc};

	print STDERR  "Apache's mod_perl seems to be turned off in httpd.conf.\n"
		and print $LOGFILE "Apache's mod_perl seems to be turned off in httpd.conf.\n"
	if $apache_info->{mod_perl_off};

	if (not $apache_info->{hasOMEinc} or $apache_info->{mod_perl_off}) {
		if (not -w $httpdConf) {
			print $LOGFILE "Can't write to $httpdConf\n"
			and croak "  You do not have write permissions for \"$httpdConf\".\nApache is not properly configured.";
		} else {
			if ( y_or_n("fix \"$httpdConf\" ?") ) {
				print "fixing httpd.conf. The current version will be saved in ".$apache_info->{conf_bak}."\n"
					and print $LOGFILE "Fixing $httpdConf.  Backup version in ".$apache_info->{conf_bak}."\n";
				fix_httpd_conf ($apache_info) or 
					print $LOGFILE "Could not fix httpd.conf.  Apache is not configured properly.\n" and
					croak "Could not fix httpd.conf.  Apache is not configured properly.";

				print $LOGFILE "Wrote new httpd.conf\nChecking httpd.conf for errors\n";
				httpd_conf_OK ($apache_info) or 
					print $LOGFILE "Apache is not configured properly.\n" and
					croak "Apache is not configured properly.";

				print $LOGFILE "httpd.conf fixed successfully\n" and
					print "httpd.conf fixed successfully\n";
			}
		}
	}

	
	$is_dev = '-dev' if $APACHE->{DEV_CONF};

	my ($source,$dest);
	#********
	#******** Install omeis in cgi-bin
	#********
	if ($APACHE->{OMEIS}) {
		print $LOGFILE "Installing OMEIS\n";
		$source = 'src/C/omeis/omeis';
		$dest = $APACHE->{CGI_BIN}.'/omeis';
		print $LOGFILE "Copying $source to $dest\n";
		copy ($source,$dest) or
			print $LOGFILE "Could not copy $source to $dest:\n$!\n" and
			croak "Could not copy $source to $dest:\n$!\n";
		print $LOGFILE "chmod 0755 $dest\n";
		chmod (0755,$dest) or
			print $LOGFILE "Could not chmod $dest:\n$!\n" and
			croak "Could not chmod $dest:\n$!\n";
		print $LOGFILE "chown $dest to uid: $APACHE_UID gid: $OME_GID\n";
		chown ($APACHE_UID,$OME_GID,$dest) or
			print $LOGFILE "Could not chown $dest:\n$!\n" and
			croak "Could not chown $dest:\n$!\n";
		$APACHE_OMEIS_INCLUDE = "Include $OME_CONF_DIR/$httpd_vers.omeis$is_dev.conf";
		print $LOGFILE "Set APACHE_OMEIS_INCLUDE to $APACHE_OMEIS_INCLUDE\n";
		print $LOGFILE "Forking a process to upgrade OMEIS\n";
		# The child will fork off and the parent returns immediately.
		update_omeis () if $APACHE_OMEIS_UPDATE_REQUIRED;
	} else {
		$APACHE_OMEIS_INCLUDE = '';
		print $LOGFILE "Not installing OMEIS\n";
	}

	#********
	#******** Install omeds by including the omeds httpd conf in ome's httpd conf
	#********
	if ($APACHE->{OMEDS}) {
		print $LOGFILE "Installing OMEDS\n";
		$APACHE_OMEDS_INCLUDE = "Include $OME_CONF_DIR/$httpd_vers.omeds$is_dev.conf";
		print $LOGFILE "Set APACHE_OMEDS_INCLUDE to $APACHE_OMEDS_INCLUDE\n";
	} else {
		print $LOGFILE "Not installing OMEDS\n";
		$APACHE_OMEDS_INCLUDE = '';
	}

	#********
	#******** Install web by copying serve.pl and index.html
	#********
	if (length($APACHE->{WEB})) {
		print $LOGFILE "Installing WEB\n";
		$source = 'src/perl2/serve.pl';
		$dest = $OME_BASE_DIR.'/perl2/serve.pl';
		print $LOGFILE "Copying $source to $dest\n";
		copy ($source,$dest) or
			print $LOGFILE "Could not copy $source to $dest:\n$!\n" and
			croak "Could not copy $source to $dest:\n$!\n";
		print $LOGFILE "chmod 0755 $dest\n";
		chmod (0755,$dest) or
			print $LOGFILE "Could not chmod $dest:\n$!\n" and
			croak "Could not chmod $dest:\n$!\n";
		print $LOGFILE "chown $dest to uid: $APACHE_UID gid: $OME_GID\n";
		chown ($APACHE_UID,$OME_GID,$dest) or
			print $LOGFILE "Could not chown $dest:\n$!\n" and
			croak "Could not chown $dest:\n$!\n";

		$source = 'src/html/index.html';
		$dest = $APACHE->{WEB}.'/index.html';
		print $LOGFILE "Copying $source to $dest\n";
		copy ($source,$dest) or
			print $LOGFILE "Could not copy $source to $dest:\n$!\n" and
			croak "Could not copy $source to $dest:\n$!\n";
		print $LOGFILE "chmod 0755 $dest\n";
		chmod (0755,$dest) or
			print $LOGFILE "Could not chmod $dest:\n$!\n" and
			croak "Could not chmod $dest:\n$!\n";
		print $LOGFILE "chown $dest to uid: $APACHE_UID gid: $OME_GID\n";
		chown ($APACHE_UID,$OME_GID,$dest) or 
			print $LOGFILE "Could not chown $dest:\n$!\n" and
			croak "Could not chown $dest:\n$!\n";

		$APACHE_WEB_INCLUDE = "Include $OME_CONF_DIR/$httpd_vers.web$is_dev.conf";
		print $LOGFILE "Set APACHE_WEB_INCLUDE to $APACHE_WEB_INCLUDE\n";
	} else {
		print $LOGFILE "Not installing WEB\n";
		$APACHE_WEB_INCLUDE = '';
	}
	
	
	#********
	#******** Fix variables in conf/httpd.ome.*.conf
	#********
	print $LOGFILE "Fixing variables in conf/httpd.ome.*.conf\n";
	fix_ome_conf("$OME_CONF_DIR");	
	
	#********
	#******** Restart
	#********
	if ($APACHE->{HUP}) {
		print $LOGFILE "Restarting Apache\n";
		httpd_restart ($apache_info) ;
	} else {
		print $LOGFILE "Not restarting Apache\n";
	}
	
	#********
	#******** Test
	#********
	httpd_test ();
	
	print BOLD, "Don't forget to update omeis by executing\n> $OME_BASE_DIR/bin/updateOMEIS\nAt your earliest convenience !!!\n", RESET
		if $APACHE->{OMEIS} and $APACHE->{OMEIS_UP} eq 'manual' and $APACHE_OMEIS_UPDATE_REQUIRED;

	# Set a proper umask
	print "Dropping umask to ", BOLD, "\"0002\"", RESET, ".\n";
	umask (0002);

	print $LOGFILE "Apache configuration finished.\n";
	close ($LOGFILE);
    return;
}

sub rollback {
    print "Rollback";
    return;
}


sub mod_perl_script {
	return <<'SCRIPT_END';
#!/usr/bin/perl -w
use strict;
print "Content-Type: text/plain\n\n";

my ($key,$value);
while ( ($key, $value) = each %ENV)
{
        print "$key = $value\n";
}


1;
SCRIPT_END
}


1;

# Blessed array reference to ease containership handling and other goodness
# required for the Apache conf file recursive searches.
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
