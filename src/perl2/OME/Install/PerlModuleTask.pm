# OME/Install/CoreSystemTask.pm
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

use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use base qw(OME::Install::InstallationTask);

#*********
#********* GLOBALS AND DEFINES
#*********

my @modules = (
    {
	name => 'DBI',
	repository_file => 'DBI-1.30.tar.gz',
	valid_versions => ['eq 1.30', 'eq 1.32', 'eq 1.35']
    },{
	name => 'Digest::MD5',
	repository_file => 'Digest-MD5-2.13.tar.gz'
    },{
	name => 'MD5',
	repository_file => 'MD5-2.02.tar.gz',
	exception => sub {
	    if ($PERL_VERSION ge v5.8.0) { return 1 };
	}

    },{
	name => 'MIME::Base64',
	repository_file => 'MIME-Base64-2.12.tar.gz'
    },{
	name => 'Storable',
	repository_file => 'Storable-1.0.13.tar.gz'
    },{
	name => 'Apache::Session',
	repository_file => 'Apache-Session-1.54.tar.gz'
    },{
	name => 'Log::Agent',
	repository_file => 'Log-Agent-0.208.tar.gz'
    },{
	name => 'Tie::IxHash',
	repository_file => 'Tie-IxHash-1.21.tar.gz'
    },{
	name => 'DBD::Pg',
	repository_file => 'DBD-Pg-1.21.tar.gz',
	valid_versions => ['eq 0.95', 'eq 1.01', 'eq 1.20', 'eq 1.21', 'eq 1.22']
	#installModule => \&DBD_Pg_Install
    },{
	name => 'Sort::Array',
	repository_file => 'Sort-Array-0.26.tar.gz',
    },{
	name => 'Test::Harness',
	repository_file => 'Test-Harness-2.26.tar.gz',
	valid_versions => ['gt 2.03']
    },{
	name => 'Test::Simple',
	repository_file => 'Test-Simple-0.47.tar.gz'
    },{
	name => 'Term::ReadKey',
	repository_file => 'TermReadKey-2.21.tar.gz'
    },{
	name => 'Carp::Assert',
	repository_file => 'Carp-Assert-0.17.tar.gz'
    },{
	name => 'Class::Accessor',
	repository_file => 'Class-Accessor-0.17.tar.gz'
    },{
	name => 'Class::Data::Inheritable',
	repository_file => 'Class-Data-Inheritable-0.02.tar.gz'
    },{
	name => 'IO::Scalar',
	repository_file => 'IO-stringy-2.108.tar.gz'
    },{
	name => 'Class::Trigger',
	repository_file => 'Class-Trigger-0.05.tar.gz'
    },{
	name => 'File::Temp',
	repository_file => 'File-Temp-0.12.tar.gz'
    },{
	name => 'Text::CSV_XS',
	repository_file => 'Text-CSV_XS-0.23.tar.gz'
    },{
	name => 'SQL::Statement',
	repository_file => 'SQL-Statement-1.004.tar.gz'
    },{
	name => 'DBD::CSV',
	repository_file => 'DBD-CSV-0.2002.tar.gz'
    },{
	name => 'Class::Fields',
	repository_file => 'Class-Fields-0.14.tar.gz'
    },{
	name => 'Class::WhiteHole',
	repository_file => 'Class-WhiteHole-0.03.tar.gz'
    },{
	name => 'Ima::DBI',
	repository_file => 'Ima-DBI-0.27.tar.gz'
    },{
	name => 'Exporter::Lite',
	repository_file => 'Exporter-Lite-0.01.tar.gz'
    },{
	name => 'UNIVERSAL::exports',
	repository_file => 'UNIVERSAL-exports-0.03.tar.gz'
    },{
	name => 'Date::Simple',
	repository_file => 'Date-Simple-2.04.tar.gz'
    },{
	name => 'Class::DBI',
	repository_file => 'Class-DBI-0.90.tar.gz',
	valid_versions => ['eq 0.90']
    },{
	name => 'GD',
	repository_file => 'GD-1.33.tar.gz'
    },{
	name => 'Image::Magick',
	repository_file => 'ImageMagick-5.3.6-OSX.tar.gz'
	#installModule => \&ImageMagickInstall
    },{
	name => 'XML::NamespaceSupport',
	repository_file => 'XML-NamespaceSupport-1.08.tar.gz'
    },{
	name => 'XML::Sax',
	repository_file => 'XML-SAX-0.12.tar.gz',
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
	repository_file => 'XML-LibXML-Common-0.12.tar.gz'
    },{
	name => 'XML::LibXML',
	repository_file => 'XML-LibXML-1.53.tar.gz',
    },{
	name => 'XML::LibXSLT',
	repository_file => 'XML-LibXSLT-1.53.tar.gz',
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
	my $eval = 'if ('.$module->{version}." $valid_version".') { $retval = 1 }';

	eval ($eval);
    }

    return $retval ? 1 : 0;
}

sub install_module {
    my $module = shift;
    print "This is where we'd install.\n";

    return;
}

#*********
#********* START OF CODE
#*********

sub execute {
    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;
    my $OME_BASE_DIR = $environment->base_dir()
	or croak "Unable to retrieve OME_BASE_DIR!";
    my $OME_TMP_DIR = $environment->tmp_dir()
	or croak "Unable to retrieve OME_TMP_DIR!";
    
    print_header ("Perl Module Setup");

    # Get our logfile and open it for reading
    open (LOGFILE, ">", $OME_TMP_DIR."/install/PerlModuleTask.log")
	or croak "Unable to open logfile \"$OME_TMP_DIR/install/PerlModuleTask.log\", $!";

    #*********
    #********* Check each module (exceptions then version)
    #*********

    print "Checking modules\n(Failure information in $OME_TMP_DIR/install/PerlModuleTask.log)\n";

    foreach my $module (@modules) {
	print "  \\_ $module->{name}";

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
	    print LOGFILE "ERRORS LOADING MODULE \"$module->{name}\" -- OUTPUT FROM EVAL: \"$@\"\n\n";

	    print BOLD, " [NOT INSTALLED]", RESET;
	    my $retval = y_or_n("\n\nWould you like to install $module->{name} from the repository ?");

	    if ($retval) {
		install_module($module);
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
		install_module($module);
		next;
	    } else { 
		print "**** Warning: Not installing known compatible version of $module->{name}.\n\n"; 
		next;
	    }
	}
    }

    return;
}

sub rollback {
    print "Rollback!\n";

    return;
}
