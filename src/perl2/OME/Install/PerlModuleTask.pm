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
use Cwd;
use Term::ANSIColor qw(:constants);
use File::Basename;

use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

# Default package repository
my $REPOSITORY = "http://openmicroscopy.org/packages/perl/";

# Default ranlib command
my $RANLIB= "ranlib";

# Global logfile filehandle
my $LOGFILE;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER);

# OME user information
my ($OME_UID, $OME_GID);

# Installation home
my $INSTALL_HOME;


my @modules = (
    {
	name => 'DBI',
	repository_file => 'http://openmicroscopy.org/packages/perl/DBI-1.30.tar.gz',
	valid_versions => ['== 1.30', '== 1.32', '== 1.35']
    },{
	name => 'Digest::MD5',
	repository_file => 'http://openmicroscopy.org/packages/perl/Digest-MD5-2.13.tar.gz'
    },{
	name => 'MD5',
	repository_file => 'http://openmicroscopy.org/packages/perl/MD5-2.02.tar.gz',
	exception => sub {
	    if ($PERL_VERSION ge v5.8.0) { return 1 };
	} 
    },{
	name => 'MIME::Base64',
	repository_file => 'http://openmicroscopy.org/packages/perl/MIME-Base64-2.12.tar.gz'
    },{
	name => 'Storable',
	repository_file => 'http://openmicroscopy.org/packages/perl/Storable-1.0.13.tar.gz'
    },{
	name => 'Apache::Session',
	repository_file => 'http://openmicroscopy.org/packages/perl/Apache-Session-1.54.tar.gz'
    },{
	name => 'Log::Agent',
	repository_file => 'http://openmicroscopy.org/packages/perl/Log-Agent-0.208.tar.gz'
    },{
	name => 'Tie::IxHash',
	repository_file => 'http://openmicroscopy.org/packages/perl/Tie-IxHash-1.21.tar.gz'
    },{
	name => 'DBD::Pg',
	repository_file => 'http://openmicroscopy.org/packages/perl/DBD-Pg-1.21.tar.gz',
	valid_versions => ['== 0.95', '== 1.01', '== 1.20', '== 1.21', '== 1.22'],
	pre_install => sub {
	    which ("pg_config") or croak "Unable to execute pg_config, is PostgreSQL installed ?";

	    my $version = `pg_config --version`;
	    croak "PostgreSQL version must be >= 7.1" unless $version ge '7.1';

	    $ENV{POSTGRES_INCLUDE} = `pg_config --includedir` or croak "Unable to retrieve PostgreSQL include dir.";
	    chomp $ENV{POSTGRES_INCLUDE};
	    $ENV{POSTGRES_LIB} = `pg_config --libdir` or croak "Unable to retrieve PostgreSQL library dir.";
	    chomp $ENV{POSTGRES_LIB};
	    $ENV{POSTGRES_LIB} .= " -lssl";

	    if ($OSNAME eq 'darwin') {
		print "*** Running $RANLIB on $ENV{POSTGRES_LIB}/libpq.a\n";
		(system ("$RANLIB $ENV{POSTGRES_LIB}/libpq.a") == 0)
		    or croak "Couldn't run $RANLIB on $ENV{POSTGRES_LIB}/libpq.a";
	    }
	}
    },{
	name => 'Sort::Array',
	repository_file => 'http://openmicroscopy.org/packages/perl/Sort-Array-0.26.tar.gz',
    },{
	name => 'Test::Harness',
	repository_file => 'http://openmicroscopy.org/packages/perl/Test-Harness-2.26.tar.gz',
	valid_versions => ['> 2.03']
    },{
	name => 'Test::Simple',
	repository_file => 'http://openmicroscopy.org/packages/perl/Test-Simple-0.47.tar.gz'
    },{
	name => 'IPC::Run',
	repository_file => 'http://openmicroscopy.org/packages/perl/IPC-Run-0.75.tar.gz'
    },{
	name => 'Term::ReadKey',
	repository_file => 'http://openmicroscopy.org/packages/perl/TermReadKey-2.21.tar.gz'
    },{
	name => 'Carp::Assert',
	repository_file => 'http://openmicroscopy.org/packages/perl/Carp-Assert-0.17.tar.gz'
    },{
	name => 'Class::Accessor',
	repository_file => 'http://openmicroscopy.org/packages/perl/Class-Accessor-0.17.tar.gz'
    },{
	name => 'Class::Data::Inheritable',
	repository_file => 'http://openmicroscopy.org/packages/perl/Class-Data-Inheritable-0.02.tar.gz'
    },{
	name => 'IO::Scalar',
	repository_file => 'http://openmicroscopy.org/packages/perl/IO-stringy-2.108.tar.gz'
    },{
	name => 'Class::Trigger',
	repository_file => 'http://openmicroscopy.org/packages/perl/Class-Trigger-0.05.tar.gz'
    },{
	name => 'File::Temp',
	repository_file => 'http://openmicroscopy.org/packages/perl/File-Temp-0.12.tar.gz'
    },{
	name => 'Text::CSV_XS',
	repository_file => 'http://openmicroscopy.org/packages/perl/Text-CSV_XS-0.23.tar.gz'
    },{
	name => 'SQL::Statement',
	repository_file => 'http://openmicroscopy.org/packages/perl/SQL-Statement-1.004.tar.gz'
    },{
	name => 'DBD::CSV',
	repository_file => 'http://openmicroscopy.org/packages/perl/DBD-CSV-0.2002.tar.gz'
    },{
	name => 'Class::Fields',
	repository_file => 'http://openmicroscopy.org/packages/perl/Class-Fields-0.14.tar.gz'
    },{
	name => 'Class::WhiteHole',
	repository_file => 'http://openmicroscopy.org/packages/perl/Class-WhiteHole-0.03.tar.gz'
    },{
	name => 'Ima::DBI',
	repository_file => 'http://openmicroscopy.org/packages/perl/Ima-DBI-0.27.tar.gz'
    },{
	name => 'Exporter::Lite',
	repository_file => 'http://openmicroscopy.org/packages/perl/Exporter-Lite-0.01.tar.gz'
    },{
	name => 'UNIVERSAL::exports',
	repository_file => 'http://openmicroscopy.org/packages/perl/UNIVERSAL-exports-0.03.tar.gz'
    },{
	name => 'Date::Simple',
	repository_file => 'http://openmicroscopy.org/packages/perl/Date-Simple-2.04.tar.gz'
    },{
	name => 'Class::DBI',
	repository_file => 'http://openmicroscopy.org/packages/perl/Class-DBI-0.90.tar.gz',
	valid_versions => ['== 0.90']
    },{
	name => 'GD',
	repository_file => 'http://openmicroscopy.org/packages/perl/GD-1.33.tar.gz'
    },{
	name => 'Image::Magick',
	repository_file => 'http://openmicroscopy.org/packages/ImageMagick-5.3.6-OSX.tar.gz'
	#installModule => \&ImageMagickInstall
    },{
	name => 'XML::NamespaceSupport',
	repository_file => 'http://openmicroscopy.org/packages/XML-NamespaceSupport-1.08.tar.gz'
    },{
	name => 'XML::Sax',
	repository_file => 'http://openmicroscopy.org/packages/XML-SAX-0.12.tar.gz',
	# XML::SAX v0.12 doesn't report a $VERSION
	# However, XML::SAX::ParserFactory loads OK and reports properly
	get_module_version => sub {
	    my $version;
	    my $eval = 'use XML::SAX::ParserFactory; $version = $XML::SAX::ParserFactory::VERSION;';

	    eval($eval);

	    return $version ? $version : undef;
	}
    },{
	name => 'XML::LibXML::Common',
	repository_file => 'http://openmicroscopy.org/packages/XML-LibXML-Common-0.12.tar.gz'
    },{
	name => 'XML::LibXML',
	repository_file => 'http://openmicroscopy.org/packages/XML-LibXML-1.53.tar.gz',
    },{
	name => 'XML::LibXSLT',
	repository_file => 'http://openmicroscopy.org/packages/XML-LibXSLT-1.53.tar.gz',
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
	my $eval = 'if ($module->{version} '.$valid_version.') { $retval = 1 }';

	eval $eval;
    }

    return $retval ? 1 : 0;
}

sub install {
    my $module = shift;
    my $filename = basename ($module->{repository_file});  # Yes, it works on URL's too *cheer*
    my $retval;
    my @output;

    $EUID = 0;

    #*********
    #********* Initial setup
    #*********

    # Pre-install
    if (exists $module->{pre_install}) {
	print "  \\_ Pre-install ";
	&{$module->{pre_install}};
	print BOLD, "[SUCCESS]", RESET, ".\n";
    }

    # Download
    print "  \\_ Downloading $module->{repository_file} ";
    $retval = download_module ($module, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to download module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Unpack
    print "  \\_ Unpacking ";
    $retval = unpack_archive ($filename, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to unpack module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    #*********
    #********* Actual module install
    #*********

    my $wd = basename ($filename, ".tar.gz");

    # Configure
    print "  \\_ Configuring ";
    $retval = configure_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to configure module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Compile
    print "  \\_ Compiling ";
    $retval = compile_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Test
    print "  \\_ Testing ";
    $retval = test_module ($wd, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to test module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Install
    print "  \\_ Installing ";
    $retval = install_module ($wd, $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to install module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

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
    
    # Store our CWD so we can get back to it later
    my $cwd = getcwd;

    # Retrieve some user info from the password database
    $OME_UID = getpwnam($OME_USER) or croak "Failure retrieving user id for \"$OME_USER\", $!";

    # Set our installation home
    $INSTALL_HOME = $OME_TMP_DIR."/install";
    
    # chdir into our INSTALL_HOME	
    chdir ($INSTALL_HOME) or croak "Unable to chdir to \"$INSTALL_HOME\", $!";
    
    print_header ("Perl Module Dependency Setup");

    print "(All verbose information logged in $INSTALL_HOME/install/PerlModuleTask.log)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/PerlModuleTask.log")
	or croak "Unable to open logfile \"$INSTALL_HOME/PerlModuleTask.log\", $!";

    #*********
    #********* Check each module (exceptions then version)
    #*********

    print "Checking modules\n";
    foreach my $module (@modules) {
	print "  \\_ $module->{name}";

	&{$module->{pre_install}} if exists $module->{pre_install};

	if (exists $module->{exception} and &{$module->{exception}}) {
	    print BOLD, " [OK]", RESET, ".\n";
	    next;
	}

	# If we've got a get_module_version() override in the module definition use it,
	# otherwise just use the default function.
	$module->{version} = &{$module->{get_module_version}} if exists $module->{get_module_version};
	$module->{version} = get_module_version($module->{name}) unless $module->{version}; 

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
    #********* Return to our original working directory and then install OME's perl modules
    #*********

    chdir ($cwd) or croak "Unable to return to our original working directory \"$cwd\", $!";

    print_header ("Core Perl Module Setup");
    
    print "(All verbose information logged in $OME_TMP_DIR/install/PerlModuleTask.log)\n\n";

    my $retval = 0;

    print "Installing modules\n";

    # Configure
    print "  \\_ Configuring ";
    $retval = configure_module ("src/perl2/", $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to configure module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Compile
    print "  \\_ Compiling ";
    $retval = compile_module ("src/perl2/", $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to compile module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Install
    print "  \\_ Installing ";
    $retval = install_module ("src/perl2", $LOGFILE);

    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to install module, see PerlModuleTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    return 1;
}

sub rollback {
    print "Rollback!\n";

    return 1;
}
