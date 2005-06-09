# OME/Install/PerlModuleTask.pm
# This task builds the required Perl modules for the OME system.

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

package OME::Install::PerlModuleTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use English;
use Term::ANSIColor qw(:constants);
use File::Path;
use File::Basename;
use Cwd;

use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

# Default package repository
my $REPOSITORY = "http://openmicroscopy.org/packages/perl";

# Default ranlib command
my $RANLIB= "ranlib";

# Global logfile filehandle and name
my $LOGFILE_NAME = "PerlModuleTask.log";
my $LOGFILE;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER);

# OME user information
my ($OME_UID, $OME_GID);

# Installation home
my $INSTALL_HOME;

# XXX: Notes on version checking
#
# Version checking in Perl is notoriously tricky and has only become more
# muddled since the addition of v-strings in Perl 5.6.1. At the moment, at
# least CPAN doesn't accept module versions made up of characters (1.01a)
# or three numeric strings (1.0.1) so our job is a little easier (discerning
# if a module's version is numeric or a string).
#
# Numeric examples:
# $VERSION = 1.01';
# $VERSION = '1.01';
# 
# Subsequent valid_versions syntax:
# valid_versions => ['eq 1.01', 'ne 0.94']
#
# String examples:
# $VERSION = "1.01";
#
# Subsequent valid_versions syntax:
# valid_versions => ['eq "1.01"', 'ne "0.94"']
#
# You can check these version numbers in the module files themselves, for
# example:
#
# egrep 'VERSION' /usr/lib/perl5/DBI.pm
# $DBI::VERSION = "1.35";
#
# For a little more information:
# http://perlmonks.thepen.com/102368.html
#
# Of course, I don't maintain that link so don't be surprised if it disappears.
# 
# -Chris (callan@blackcat.ca)

my @modules = (
    {
	name => 'DBI',
	repository_file => "$REPOSITORY/DBI-1.30.tar.gz",
	# XXX DBI has never been a problem. In general the problem child is DBD::Pg
	# so in the collective interest of Sys-admin sanity I'm commenting the
	# version requirement out. If we have problems we can re-institute it.
	# - Chris <callan@blackcat.ca>
	#valid_versions => ['eq "1.30"', 'eq "1.32"', 'eq "1.35"']
    },{
	name => 'Digest::MD5',
	repository_file => "$REPOSITORY/Digest-MD5-2.13.tar.gz"
    },{
	name => 'MD5',
	repository_file => "$REPOSITORY/MD5-2.02.tar.gz",
	exception => sub {
		# N.B: $PERL_VERSION is broken. use $] instead.
	    if ($] > 5.008) { return 1 };
	} 
    },{
	name => 'MIME::Base64',
	repository_file => "$REPOSITORY/MIME-Base64-2.12.tar.gz"
    },{
	# XXX DEPRECATED
	#name => 'Apache::Session',
	#repository_file => "$REPOSITORY/Apache-Session-1.54.tar.gz"
    #},{
	name => 'Log::Agent',
	repository_file => "$REPOSITORY/Log-Agent-0.208.tar.gz"
    },{
    name => 'Time::HiRes',
    repository_file => "$REPOSITORY/Time-HiRes-1.65.tar.gz"
    },{
	# XXX DEPRECATED
	#name => 'Tie::IxHash',
	#repository_file => "$REPOSITORY/Tie-IxHash-1.21.tar.gz"
	#},{
	name => 'DBD::Pg',
	repository_file => "$REPOSITORY/DBD-Pg-1.22.tar.gz",
	valid_versions => ['eq 0.95', 'eq 1.01', 'eq 1.20', 'ne 1.21', 'eq 1.22'],
	pre_install => sub {
	    which ("pg_config") or croak "Unable to execute pg_config, are PostgreSQL and its development packages installed ?";

	    my $version = `pg_config --version`;
	    croak "PostgreSQL version must be >= 7.1" unless $version ge '7.1';

	    $ENV{POSTGRES_INCLUDE} = `pg_config --includedir` or croak "Unable to retrieve PostgreSQL include dir.";
	    chomp $ENV{POSTGRES_INCLUDE};
	    $ENV{POSTGRES_LIB} = `pg_config --libdir` or croak "Unable to retrieve PostgreSQL library dir.";
	    chomp $ENV{POSTGRES_LIB};

	    if ($OSNAME eq 'darwin') {
		(system ("$RANLIB $ENV{POSTGRES_LIB}/libpq.a") == 0)
		    or croak "Couldn't run $RANLIB on $ENV{POSTGRES_LIB}/libpq.a";
	    }
	    
	    $ENV{POSTGRES_LIB} .= " -lssl -lcrypto";
	}
    },{
	# XXX DEPRECATED
	#name => 'Sort::Array',
	#repository_file => "$REPOSITORY/Sort-Array-0.26.tar.gz",
	#},{
	name => 'Test::Harness',
	repository_file => "$REPOSITORY/Test-Harness-2.26.tar.gz",
	valid_versions => ['gt 2.03']
    },{
	name => 'Test::Simple',
	repository_file => "$REPOSITORY/Test-Simple-0.47.tar.gz"
    },{
	name => 'HTML::Template',
	repository_file => "$REPOSITORY/HTML-Template-2.6.tar.gz"
    },{
	name => 'IPC::Run',
	repository_file => "$REPOSITORY/IPC-Run-0.75.tar.gz"
	},{
	# XXX DEPRECATED
	#name => 'Carp::Assert',
	#repository_file => "$REPOSITORY/Carp-Assert-0.17.tar.gz"
	#},{
	name => 'Class::Accessor',
	repository_file => "$REPOSITORY/Class-Accessor-0.17.tar.gz"
    },{
	name => 'Class::Data::Inheritable',
	repository_file => "$REPOSITORY/Class-Data-Inheritable-0.02.tar.gz"
    },{
	# XXX DEPRECATED
	#name => 'IO::Scalar',
	#repository_file => "$REPOSITORY/IO-stringy-2.108.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'Class::Trigger',
	#repository_file => "$REPOSITORY/Class-Trigger-0.05.tar.gz"
	#},{
	name => 'File::Temp',
	repository_file => "$REPOSITORY/File-Temp-0.12.tar.gz"
    },{
	# XXX DEPRECATED
	#name => 'Text::CSV_XS',
	#repository_file => "$REPOSITORY/Text-CSV_XS-0.23.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'SQL::Statement',
	#repository_file => "$REPOSITORY/SQL-Statement-1.004.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'DBD::CSV',
	#repository_file => "$REPOSITORY/DBD-CSV-0.2002.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'Class::Fields',
	#repository_file => "$REPOSITORY/Class-Fields-0.14.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'Class::WhiteHole',
	#repository_file => "$REPOSITORY/Class-WhiteHole-0.03.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'Ima::DBI',
	#repository_file => "$REPOSITORY/Ima-DBI-0.27.tar.gz"
	#},{
	name => 'Exporter::Lite',
	repository_file => "$REPOSITORY/Exporter-Lite-0.01.tar.gz"
	},{
	name => 'UNIVERSAL::exports',
	repository_file => "$REPOSITORY/UNIVERSAL-exports-0.03.tar.gz"
	},{
	# XXX DEPRECATED
	#name => 'Date::Simple',
	#repository_file => "$REPOSITORY/Date-Simple-2.04.tar.gz"
	#},{
	# XXX DEPRECATED
	#name => 'Class::DBI',
	#repository_file => "$REPOSITORY/Class-DBI-0.90.tar.gz",
	#valid_versions => ['eq "0.90"']
	#},{
	name => 'GD',
	repository_file => "$REPOSITORY/GD-1.33.tar.gz",
	configure_module => sub {
	    # Since GD has an interactive configure script we need to
	    # implement a custom configure_module () subroutine that allows
	    # for an interactive install

	    my ($path, $logfile) = @_;
	    my $iwd = getcwd;  # Initial working directory

	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

	    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

	    system ("perl Makefile.PL 2>&1");

	    chdir ($iwd) or croak "Unable to chdir back into \"$iwd\", $!";

	    return 1;
	}
    },{
	name => 'URI',
	repository_file => "$REPOSITORY/URI-1.23.tar.gz"
    },{
	# XXX DEPRECATED
#	name => 'Image::Magick',
#	repository_file => "$REPOSITORY/ImageMagick-5.5.6.tar.gz"
#	#installModule => \&ImageMagickInstall
#    },{
	name => 'HTML::Tagset',
	repository_file => "$REPOSITORY/HTML-Tagset-3.03.tar.gz"
    },{
	name => 'HTML::Parser',
	repository_file => "$REPOSITORY/HTML-Parser-3.35.tar.gz",
	configure_module => sub {
	    # Since libwww has an interactive configure script we need to
	    # implement a custom configure_module () subroutine that allows
	    # for an interactive install
	    my ($path, $logfile) = @_;
	    my $iwd = getcwd;  # Initial working directory

	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

	    chdir ($path) or croak "Unable to chdir into \"$path\". $!";
		print $logfile "Configuring HTML::Parser\n";

	    system ("perl Makefile.PL 2>&1");
	
		if ($? == 0) {
		print $logfile "SUCCESS CONFIGURING HTML::Parser\n";
	
		chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
		return 1;
		}
	
		print $logfile "FAILURE CONFIGURING HTML::Parser\n";
		chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	
		return 0;
	}
    },{
	name => 'LWP',
	valid_versions => ['ne 5.80'],
	repository_file => "$REPOSITORY/libwww-perl-5.69.tar.gz",
	configure_module => sub {
	    # Since libwww has an interactive configure script we need to
	    # implement a custom configure_module () subroutine that allows
	    # for an interactive install
	    my ($path, $logfile) = @_;
	    my $iwd = getcwd;  # Initial working directory

	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

	    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

		my @output = `perl Makefile.PL -n 2>&1`;
	
		if ($? == 0) {
		print $logfile "SUCCESS CONFIGURING MODULE -- OUTPUT: \"@output\"\n\n";
	
		chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
		return 1;
		}
	
		print $logfile "FAILURE CONFIGURING MODULE -- OUTPUT: \"@output\"\n\n";
		chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	
		return 0;
	}
    },{
	name => 'XML::NamespaceSupport',
	repository_file => "$REPOSITORY/XML-NamespaceSupport-1.08.tar.gz"
    },{
	name => 'XML::Sax',
	repository_file => "$REPOSITORY/XML-SAX-0.12.tar.gz",
	# XML::SAX v0.12 doesn't report a $VERSION
	# However, XML::SAX::ParserFactory loads OK and reports properly
	get_module_version => sub {
	    my $version;
	    my $eval = 'use XML::SAX::ParserFactory; $version = $XML::SAX::ParserFactory::VERSION;';

	    eval($eval);

	    return $version ? $version : undef;
	},	
	configure_module => sub {
	    # Since XML::Sax has an interactive configure script we need to
	    # implement a custom configure_module () subroutine that allows
	    # for an interactive install

	    my ($path, $logfile) = @_;
	    my $iwd = getcwd;  # Initial working directory

	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

	    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

	    system ("perl Makefile.PL 2>&1");

	    chdir ($iwd) or croak "Unable to chdir back into \"$iwd\", $!";

	    return 1;
	}
    },{
	name => 'XML::LibXML::Common',
	repository_file => "$REPOSITORY/XML-LibXML-Common-0.12.tar.gz"
    },{
	name => 'XML::LibXML',
	repository_file => "$REPOSITORY/XML-LibXML-1.58.tar.gz",
	get_module_version => sub {
	    my $version;
	    my $eval = 'use XML::LibXML; $version = $XML::LibXML::VERSION;';

	    eval($eval);

	    return $version ? $version : undef;
	},
	valid_versions => ['ge "1.56"']
    },{
	name => 'XML::Parser',
	repository_file => "$REPOSITORY/XML-Parser-2.34.tar.gz",
    },{
	name => 'SOAP::Lite',
	repository_file => "$REPOSITORY/SOAP-Lite-0.55.tar.gz",
	valid_versions => ['ge "0.55"'],
	configure_module => sub {
	    # Since SOAP::Lite has an interactive configure script we need to
	    # implement a custom configure_module () subroutine that allows
	    # for an interactive install

	    my ($path, $logfile) = @_;
	    my $iwd = getcwd;  # Initial working directory

	    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

	    chdir ($path) or croak "Unable to chdir into \"$path\". $!";
	    system ("perl Makefile.PL --noprompt --HTTP-Apache --HTTP-Daemon --noMAILTO-Client --noHTTP-FCGI --noMQ --noJABBER --noMIMEParser 2>&1");
	    chdir ($iwd) or croak "Unable to chdir back into \"$iwd\", $!";

	    return 1;
	}
    },{
	name => 'XML::LibXSLT',
	repository_file => "$REPOSITORY/XML-LibXSLT-1.57.tar.gz",
    }
);

#*********
#********* LOCAL SUBROUTINES
#*********

sub check_module {
    my $module = shift;
    my $retval = 0;

    return 1 unless exists $module->{valid_versions};

    foreach my $valid_version (@{$module->{valid_versions}}) {
		my $eval = 'if ("$module->{version}" '.$valid_version.') { $retval = 1 }';

		eval $eval;
		last if $retval;
    }

    return $retval ? 1 : 0;
}

sub install {
    my $module = shift;
    my $filename = basename ($module->{repository_file});  # Yes, it works on URL's too *cheer*
    my $retval;
    my @output;

    #*********
    #********* Initial setup
    #*********

    # Pre-install
    if (exists $module->{pre_install}) {
		print "    \\_ Pre-install ";
		&{$module->{pre_install}};
		print BOLD, "[SUCCESS]", RESET, ".\n";
    }

    # Download
    print "    \\_ Downloading $module->{repository_file} ";
    $retval = download_package ($module, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to download package, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Unpack
    print "    \\_ Unpacking ";
    $retval = unpack_archive ($filename, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to unpack module, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    #*********
    #********* Actual module install
    #*********

    my $wd = basename ($filename, ".tar.gz");

    # Configure
    print "    \\_ Configuring ";
    $retval = &{$module->{configure_module}}($wd,$LOGFILE) if exists $module->{configure_module};
    $retval = configure_module ($wd, $LOGFILE) unless exists $module->{configure_module};
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to configure module, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Compile
    print "    \\_ Compiling ";
    $retval = compile_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile module, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Test
    print "    \\_ Testing ";
    $retval = test_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and carp "Unable to test module, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n" if $retval;

    y_or_n ("Some tests failed, would you like to continue anyway ?")
	or croak "Stopping at user request" unless $retval;    

    # Install
    print "    \\_ Installing ";
    $retval = install_module ($wd, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to install module, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    print "\n";  # Spacing

    return;
}

#*********
#********* START OF CODE
#*********

sub execute {
    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;

    # Set our globals
    $OME_BASE_DIR = $environment->base_dir()
		or croak "Unable to retrieve OME_BASE_DIR!";
    $OME_TMP_DIR = $environment->tmp_dir()
		or croak "Unable to retrieve OME_TMP_DIR!";
    $OME_USER = $environment->user()
		or croak "Unable to retrieve OME_USER!";
    
    # Store our IWD so we can get back to it later
    my $iwd = getcwd ();

    # Retrieve some user info from the password database
    $OME_UID = getpwnam($OME_USER) or croak "Failure retrieving user id for \"$OME_USER\", $!";

    # Set our installation home
    $INSTALL_HOME = "$OME_TMP_DIR/install";
    
    # chdir into our INSTALL_HOME	
    chdir ($INSTALL_HOME) or croak "Unable to chdir to \"$INSTALL_HOME\", $!";
    
    print_header ("Perl Module Dependency Setup");

    print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/$LOGFILE_NAME")
		or croak "Unable to open logfile \"$INSTALL_HOME/$LOGFILE_NAME\".$!";

    #*********
    #********* Check each module (exceptions then version)
    #*********

    print "Checking modules\n";
    foreach my $module (@modules) {
		print "  \\_ $module->{name}";

		if (exists $module->{exception} and &{$module->{exception}}) {
			print BOLD, " [OK]", RESET, ".\n";
			next;
		}

		# If we've got a get_module_version() override in the module definition use it,
		# otherwise just use the default function.
		$module->{version} = &{$module->{get_module_version}}
			if exists $module->{get_module_version};
		$module->{version} = get_module_version($module->{name})
			unless $module->{version}; 

		if (not $module->{version}) {
			# Log the error returned by get_module_version()
			print $LOGFILE "ERRORS LOADING MODULE \"$module->{name}\" -- OUTPUT FROM EVAL: \"$@\"\n\n";

			print BOLD, " [NOT INSTALLED]", RESET;
			my $retval = y_or_n("\n\nWould you like to install $module->{name} from the repository ?");

			if ($retval) {
				install ($module);
				next;
	    	} else { 
				print "**** Warning: Not installing module $module->{name}.\n\n"; 
				next;
	    	}
		}

		if (check_module($module)) {
			print " $module->{version} ", BOLD, "[OK]", RESET, ".\n";
			next;
		} else {
			print " $module->{version} ", BOLD, "[UNSUPPORTED]", RESET, ".\n";
			my $retval = y_or_n("\nWould you like to install the module from the OME repository ?");

			if ($retval) {
				install ($module);
				next;
			} else { 
				print "**** Warning: Not installing known compatible version of $module->{name}.\n\n"; 
				next;
	    	}
		}
    }

    print "\n";  # Spacing

    #*********
    #********* Return to our initial working directory and then install OME's perl modules
    #*********

    chdir ($iwd) or croak "Unable to return to our initial working directory \"$iwd\", $!";

    # Only if we're not just running a Perl check
    unless ($environment->get_flag ("PERL_CHECK")) {
    
    	#
		# CORE PERL MODULES
		#
		print_header ("Core Perl Module Setup");
    
		print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

		my $retval = 0;

		print "Installing modules\n";

		# Configure
		print "  \\_ Configuring ";
		$retval = configure_module ("src/perl2/", $LOGFILE);
    
		print BOLD, "[FAILURE]", RESET, ".\n"
		    and croak "Unable to configure module, see $LOGFILE_NAME for details."
		    unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";

		# Compile
		print "  \\_ Compiling ";
		$retval = compile_module ("src/perl2/", $LOGFILE);
    
		print BOLD, "[FAILURE]", RESET, ".\n"
		    and croak "Unable to compile module, see $LOGFILE_NAME for details."
		    unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";

		# Install
		print "  \\_ Installing ";
		$retval = install_module ("src/perl2", $LOGFILE);

		print BOLD, "[FAILURE]", RESET, ".\n"
		    and croak "Unable to install module, see $LOGFILE_NAME for details."
		    unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";
		
		#
		# MATLAB PERL MODULES
		#
		my $MATLAB_CONF_DEF = {
			INSTALL     => 0,
			USER        => undef,
			MATLAB_INST => undef,
			AS_DEV      => 0,
			MATLAB_SRC  => undef,		
		};
		my $MATLAB = defined $environment->matlab_conf()  ? $environment->matlab_conf()  : $MATLAB_CONF_DEF;
		
		print "\n";
		print_header ("Optional Perl Module Setup");
		
		print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

		my $matlab_directory; 
		
		# Confirm all flag
		my $confirm_all;
	
		while (1) {
			if ($environment->get_flag("UPDATE") or $confirm_all) {
				print "\n";  # Spacing
				
				# Change the MATLAB_SRC path always to the current directory
				# if the dev configuration option is elected
				$MATLAB->{MATLAB_SRC} = getcwd ()."/src/matlab"
					if ($MATLAB->{AS_DEV} == 1);
					
				# Ask user to confirm his/her original entries
				print BOLD,"MATLAB Perl API configuration:\n",RESET;
				print " Install MATLAB Perl API?: ", BOLD, $MATLAB->{INSTALL} ? 'yes':'no', RESET, "\n";
				print "              MATLAB User: ", BOLD, $MATLAB->{USER}, RESET, "\n" if $MATLAB->{INSTALL} ;
				print "              MATLAB Path: ", BOLD, $MATLAB->{MATLAB_INST}, RESET, "\n" if $MATLAB->{INSTALL} ;
				print "   Config MATLAB for dev?: ", BOLD, $MATLAB->{AS_DEV} ? 'yes':'no', RESET, "\n";
				print "     MATLAB .m files Path: ", BOLD, $MATLAB->{MATLAB_SRC},  RESET, "\n" if $MATLAB->{INSTALL} ;
				print "\n";  # Spacing
	
				y_or_n ("Are these values correct ?",'y') and last;
			}
			
			if (y_or_n ("Install analysis engine interface to MATLAB ?")) {
				$MATLAB->{INSTALL} = 1;
				
				if ($environment->admin_user()) {
					$MATLAB->{USER} = $environment->admin_user();
				} elsif ($environment->user()) {
					$MATLAB->{USER} = $environment->user();
				} else {
					$MATLAB->{USER} = "matlab";			
				}
				
				$MATLAB->{USER}  = confirm_default ("The user which MATLAB should be run under", $MATLAB->{USER});
				
				if (! $MATLAB->{MATLAB_INST}) {
					$MATLAB->{MATLAB_INST} = which ('matlab');
					$MATLAB->{MATLAB_INST} =~ s|/bin/matlab$||;
				}
				$MATLAB->{MATLAB_INST} = confirm_path ("Path to MATLAB installation", $MATLAB->{MATLAB_INST});
				
				if (y_or_n ("Configure MATLAB Perl API for developers?")){
					$MATLAB->{AS_DEV} = 1;
					$MATLAB->{MATLAB_SRC} = getcwd ()."/src/matlab";
				} else {
					$MATLAB->{AS_DEV} = 0;
					$MATLAB->{MATLAB_SRC} = "$OME_BASE_DIR/matlab";
				}
				$MATLAB->{MATLAB_SRC} = confirm_path ("Path to OME's matlab src files", $MATLAB->{MATLAB_SRC} );
			} else {
				$MATLAB->{INSTALL} = 0;
			}
			
			$confirm_all = 1;
		}
		
		if ($MATLAB->{INSTALL}) {
		
			#
			# MATLAB Perl API
			#
			print "Installing MATLAB Perl API \n";
			
			# Configure
			print "  \\_ Configuring ";
			$retval = configure_module("src/perl2/OME/Matlab/", $LOGFILE, 
				{options => "$MATLAB->{USER} $MATLAB->{MATLAB_INST}"});
				
			print BOLD, "[FAILURE]", RESET, ".\n"
				and croak "Unable to configure module, see $LOGFILE_NAME for details."
				unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
	
			# Compile
			print "  \\_ Compiling ";
			$retval = compile_module ("src/perl2/OME/Matlab/", $LOGFILE);
		
			print BOLD, "[FAILURE]", RESET, ".\n"
				and croak "Unable to compile module, see $LOGFILE_NAME for details."
				unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
	
			# Testing
			print "  \\_ Testing ";
			
			copy_tree("src/perl2/OME/Matlab/", $OME_TMP_DIR);  # problems here result in croaks
			fix_ownership({owner => "$MATLAB->{USER}"}, "$OME_TMP_DIR/Matlab");
			$retval = test_module ("$OME_TMP_DIR/Matlab", $LOGFILE, 
				{user =>"$MATLAB->{USER}"});
			rmtree("$OME_TMP_DIR/Matlab"); # problems here result in croaks
				
			print BOLD, "[FAILURE]", RESET, ".\n"
				and croak "Tests failed, see $LOGFILE_NAME for details."
				unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
			
			# Install
			print "  \\_ Installing ";
			euid(0);
			$retval = install_module ("src/perl2/OME/Matlab/", $LOGFILE);
	
			print BOLD, "[FAILURE]", RESET, ".\n"
				and croak "Unable to install module, see $LOGFILE_NAME for details."
				unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
			
			#
			# OMEIS MATLAB Interface
			#
			print "Installing MEX Interface to omeis-http\n";
			
			# Configure
			print "  \\_ Configuring omeis-http with MATLAB Bindings ";
			$retval = configure_module ("src/C/omeis-http", $LOGFILE, {options => "--with-MATLAB --with-MATLAB-user=$MATLAB->{USER}"});
			
			print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to configure omeis-http, see $LOGFILE_NAME for details."
			unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
			
			# Compile
			print "  \\_ Compiling omeis-http with MATLAB Bindings";
			$retval = compile_module ("src/C/omeis-http", $LOGFILE);
			
			print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to compile omeis-http, see $LOGFILE_NAME for details."
			unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
			
			#
			# OME MATLAB .m files
			#
			print "Installing OME MATLAB .m files \n";
			
			# Compile
			print "  \\_ Compiling ";
			
			$retval = compile_module ("src/matlab/", $LOGFILE);
			
			print BOLD, "[FAILURE]", RESET, ".\n"
				and croak "Unable to compile MATLAB .m files, see $LOGFILE_NAME for details."
				unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";
			
			# Installing
			print "  \\_ Installing ";
			print $LOGFILE "Copying Matlab source files from ".cwd()."/src/matlab to $OME_BASE_DIR/matlab \n"; 
			copy_tree("src/matlab", "$OME_BASE_DIR", sub{!/CVS$/i});
			$retval = 1; # if there was a problem in copy_tree, it would have
			             # croaked and died.
			print BOLD, "[FAILURE]", RESET, ".\n"
				and croak "Unable to install MATLAB .m files, see $LOGFILE_NAME for details."
				unless $retval;
			print BOLD, "[SUCCESS]", RESET, ".\n";			
		}
		$environment->matlab_conf($MATLAB);
	}
	
    return 1;
}

sub rollback {
    croak "Rollback!\n";

    # Stub for the moment.
    return 1;
}

1;
