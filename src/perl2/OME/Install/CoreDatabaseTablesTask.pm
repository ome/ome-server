# OME/Install/CoreDatabaseTablesTask.pm
# Builds the core database tables of OME

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

package OME::Install::CoreDatabaseTablesTask;

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

# Packages needed from OME for the bootstrap
use OME::Database::Delegate;
use OME::Factory;

#*********
#********* GLOBALS AND DEFINES
#*********

# Global logfile filehandle
my $LOGFILE;

# Installation home
my $INSTALL_HOME;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER, $OME_UID);

# Default import formats
my $IMPORT_FORMATS = "OME::ImportEngine::MetamorphHTDFormat OME::ImportEngine::DVreader";

# $coreClasses = ([$package_to_require,$class_to_instantiate], ... )

# Each class to instantiate is listed as a pair: the package that
# should be used in the "require" statement, and the class to actually
# instantiate in the database.  If the first argument is undef, no
# require statement is executed.  This is just to deal with the fact
# that some files declare multiple DBObject subclasses; only the
# package corresponding to the filename should be "required".

our @core_classes =
  (
   ['OME::LookupTable',       'OME::LookupTable'],
   [undef,                    'OME::LookupTable::Entry'],
   ['OME::DataTable',         'OME::DataTable'],
   [undef,                    'OME::DataTable::Column'],
   ['OME::SemanticType',      'OME::SemanticType'],
   [undef,                    'OME::SemanticType::Element'],
   [undef,                    'OME::SemanticType::BootstrapExperimenter'],
   [undef,                    'OME::SemanticType::BootstrapGroup'],
   [undef,                    'OME::SemanticType::BootstrapRepository'],
   ['OME::Dataset',           'OME::Dataset'],
   ['OME::Project',           'OME::Project'],
   ['OME::Project',           'OME::Project::DatasetMap'],
   ['OME::Image',             'OME::Image'],
   ['OME::Image',             'OME::Image::DatasetMap'],
   ['OME::Image',             'OME::Image::ImageFilesXYZWT'],
   ['OME::Feature',           'OME::Feature'],
   ['OME::Session',           'OME::Session'],
   ['OME::ViewerPreferences', 'OME::ViewerPreferences'],
   ['OME::Module::Category',  'OME::Module::Category'],
   ['OME::Module',            'OME::Module'],
   ['OME::Module',            'OME::Module::FormalInput'],
   ['OME::Module',            'OME::Module::FormalOutput'],
   ['OME::AnalysisChain',     'OME::AnalysisChain'],
   ['OME::AnalysisChain',     'OME::AnalysisChain::Node'],
   ['OME::AnalysisChain',     'OME::AnalysisChain::Link'],
   ['OME::AnalysisPath',      'OME::AnalysisPath'],
   ['OME::AnalysisPath',      'OME::AnalysisPath::Map'],
   ['OME::ModuleExecution',   'OME::ModuleExecution'],
   ['OME::ModuleExecution',   'OME::ModuleExecution::ActualInput'],
   ['OME::ModuleExecution',   'OME::ModuleExecution::SemanticTypeOutput'],
   ['OME::AnalysisChainExecution',
                              'OME::AnalysisChainExecution'],
   ['OME::AnalysisChainExecution',
                              'OME::AnalysisChainExecution::NodeExecution'],
   # Make sure this next one is last
   ['OME::Configuration',     'OME::Configuration'],
  );

#*********
#********* LOCAL SUBROUTINES
#*********

# Create a postgres superuser SQL: CREATE USER foo CREATEUSER
sub create_superuser {
    my ($username, $logfile) = @_;
    my $pg_uid = getpwnam ("postgres") or croak "Unable to retrieve PostgreSQL user UID";
    my $output;
    my $retval;
    my $createuser = "createuser";

    # Make sure we're not croaking on a silly logfile print
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    # Drop our UID to Postgres
    $EUID = $pg_uid;

    # Make sure we can see the Postgres command
    $retval = which ("$createuser");
   
    $createuser = whereis ("createuser") or croak "Unable to locate creatuser binary." unless $retval;

    # Create the user using the command line tools
    $output = `$createuser -d -a $username 2>&1`;

    # Back to UID 0
    $EUID = 0;

    # Log and return success
    if (($output =~ /already exists/) or ($output =~ /^CREATE/)) {
	print $logfile "CREATION OF USER $username SUCCESSFUL -- OUTPUT: \"$output\"\n";
	return 1;
    }

    # Log and return failure
    print $logfile "CREATION OF USER $username FAILED -- OUTPUT: \"$output\"\n";
    return 0;
}

# Create our OME database
#
# RETURNS	1 on success
# 		0 if the DB exists
# 		0 on failure

sub create_database {
    my $dbh;
    my $sql;
    my $retval;
    my $createlang = "createlang";

    print "Creating database\n";

    $dbh = DBI->connect("dbi:Pg:dbname=template1")
      or croak "Error: $dbh->errstr()";

    # Find database SQL

    # Check for DB existance
    my $find_database = $dbh->prepare(q{
	SELECT oid FROM pg_database WHERE lower(datname) = lower(?)
    }) or croak $dbh->errstr;

    my ($db_oid) = $dbh->selectrow_array($find_database,{},'ome');

    # This will be NULL if the database does not exist
    if (defined $db_oid) {
	print "  \\__ Exists\n";
        $dbh->disconnect();
        return 0;
    }

    # Create an empty DB
    print "  \\__ Initialization\n";
    $dbh->do(q{
	CREATE DATABASE ome
    }) or croak $dbh->errstr();

    $dbh->disconnect();

    # Set the PGSQL lang
    $retval = which ("$createlang");
   
    $createlang = whereis ("createlang") or croak "Unable to locate creatlang binary." unless $retval;

    print "  \\__ Adding PL-PGSQL language\n";
    my $CMD_OUT = `$createlang plpgsql ome 2>&1`;
    die $CMD_OUT if $? != 0;

    # Fix our little object ID bug
    print "  \\__ Fixing OID/INTEGER compatability bug\n";
    $dbh = DBI->connect("dbi:Pg:dbname=ome")
      or croak $dbh->errstr();
    $dbh->do(q{
	CREATE FUNCTION OID(INT8) RETURNS OID AS '
	declare
	    i8 alias for $1;
	begin
	    return int4(i8);
	end;'
	LANGUAGE 'plpgsql';
    }) or croak $dbh->errstr;
    
    $dbh->disconnect();

    return 1;
}

sub load_schema {
    my $logfile = shift;
    my $retval;
    my $delegate = OME::Database::Delegate->getDefaultDelegate();

    my $factory = OME::Factory->new();
    my $dbh = $factory->obtainDBH();

    print "Loading the database schema\n";

    foreach my $class (@core_classes) {
	my ($require_class, $instantiate_class) = @$class;

	print "  \\__ ", $require_class || "", " $instantiate_class ";
	
	$require_class->require() if defined $require_class;

	# Add our class to the DB
	eval {
	    $delegate->addClassToDatabase($dbh,$instantiate_class);
	};
    
	print BOLD, "[FAILURE]", RESET, ".\n"
	    and print $logfile "ERROR LOADING CLASS \"$instantiate_class\" -- OUTPUT: \"$@\"\n"
	    and croak "Error loading class \"$instantiate_class\", see CoreDatabaseTablesTask.log for details."
        unless not $@;


	print BOLD, "[SUCCESS]", RESET, ".\n"
	    and print $logfile "SUCCESS LOADING CLASS \"$instantiate_class\"\n";
    }

    $factory->commitTransaction();

    return 1;
}

sub create_experimenter {
    print_header "Initial user creation";
    
    my $factory = OME::Factory->new();
    my $dbh = $factory->obtainDBH();

    my $first_name = question ("First name: ");
    my $last_name = question ("Last name: ");
    my $username = confirm_default ("Username: ", substr ($first_name, 0, 1).$last_name);  
    my $e_mail = question ("E-mail address: ");
    my $data_dir = question ("Default data directory: ");
    
    if (not -d $data_dir) {
	my $y_or_n = confirm_default ("Directory \"$data_dir\" does not exist. Do you want to create it ?", "no");

	if ((lc ($y_or_n) eq 'y') or (lc ($y_or_n) eq 'yes')) {
	    mkdir ($data_dir, 0755) or croak "Unable to create directory \"$data_dir\". $!";
	}
    }

    my ($password, $hashed_password) = get_password ("Password: ", 6);

    my $experimenter = $factory->
	newObject('OME::SemanticType::BootstrapExperimenter',
            {
             OMEName       => $first_name." ".$last_name,
             FirstName     => $first_name,
             LastName      => $last_name,
             Email         => $e_mail,
             Password      => $hashed_password,
             DataDirectory => $data_dir,
            });

    $factory->commitTransaction();
    $factory->releaseDBH($dbh);

    return 1;
}


#*********
#********* START OF CODE
#*********

sub execute {
    my $retval;

    print_header "Database Bootstrap";

    # Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;

    # Populate globals
    $OME_BASE_DIR = $environment->base_dir()
	or croak "Unable to retrieve OME_BASE_DIR!";
    $OME_TMP_DIR = $environment->tmp_dir()
	or croak "Unable to retrieve OME_TMP_DIR!";
    $OME_USER = $environment->user()
	or croak "Unable to retrieve OME_USER!";
    $OME_UID = getpwnam ($OME_USER)
	or croak "Unable to retrive OME_USER UID!";

    # Set our installation home
    $INSTALL_HOME = $OME_TMP_DIR."/install";
    
    print "(All verbose information logged in $INSTALL_HOME/CoreDatabaseTablesTask.log)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/CoreDatabaseTablesTask.log")
	or croak "Unable to open logfile \"$INSTALL_HOME/CoreDatabaseTablesTask.log\", $!";

    #*********
    #********* Create our super-user and bootstrap the DB
    #*********

    # Make sure our OME_USER is also a Postgres user
    print "Creating PostgreSQL SUPERUSER ";
    $retval = create_superuser ($OME_USER, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to create PostgreSQL superuser, see CoreDatabaseTablesTask.log for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Drop our UID to the OME_USER
    $EUID = $OME_UID;

    # Create our database
    create_database ("DEBIAN") or croak "Unable to create database!";
    load_schema ($LOGFILE) or croak "Unable to load the schema, see CoreDatabaseTablesTask.log for details.";
    create_experimenter () or croak "Unable to create an initial experimenter.";

    # Back to UID 0
    $EUID = 0;

    close ($LOGFILE);

    return 1;
}

sub rollback {

    return 1;
}


1;
