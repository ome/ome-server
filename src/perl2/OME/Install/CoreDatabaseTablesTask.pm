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

#*********
#********* GLOBALS AND DEFINES
#*********

# Global logfile filehandle
my $LOGFILE;

# Installation home
my $INSTALL_HOME;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER, $OME_UID);

# Installation Packages
use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use base qw(OME::Install::InstallationTask);

# Packages needed from OME for the bootstrap
use OME::Database::Delegate;

# $coreClasses = ([$package_to_require,$class_to_instantiate], ... )

# Each class to instantiate is listed as a pair: the package that
# should be used in the "require" statement, and the class to actually
# instantiate in the database.  If the first argument is undef, no
# require statement is executed.  This is just to deal with the fact
# that some files declare multiple DBObject subclasses; only the
# package corresponding to the filename should be "required".

our @coreClasses =
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

    # Make sure we're not croaking on a silly logfile print
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    # Drop our UID to Postgres
    $EUID = $pg_uid;

    # Make sure we can see the Postgres command
    which ("createuser") or croak "Couldn't execute createuser (a postgres utility)! Is createuser in your \$PATH?\n";
    # Create the user using the command line tools
    $output = `createuser -d -a $username 2>&1`;

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

sub create_database {
    my $platform = shift;
    my $dbh;
    my $sql;

    $dbh = DBI->connect("dbi:Pg:dbname=template1")
      or croak "Error: $dbh->errstr()";

    $sql = <<SQL;
SELECT oid FROM pg_database WHERE lower(datname) = lower(?)
SQL

    my $find_database = $dbh->prepare($sql);
    my ($db_oid) = $dbh->selectrow_array($find_database,{},'ome');

    # This will be NULL if the database does not exist
    if (defined $db_oid) {
        $dbh->disconnect();
        return 1;
    }

    $dbh->do('CREATE DATABASE ome')
      or die $dbh->errstr();
    $dbh->disconnect();

    # Debian does this by default using Debconf, everything else needs it.
    # Atleast as far as I know. (Chris)
    if ($platform ne "DEBIAN") {
        print "Adding PL-PGSQL language...\n";
        my $CMD_OUT = `createlang plpgsql ome 2>&1`;
        die $CMD_OUT if $? != 0;
	print BOLD "[Done.]", RESET, "\n";
    }

    print "Fixing OID/INTEGER compatability bug...\n";
    $dbh = DBI->connect("dbi:Pg:dbname=ome")
      or die $dbh->errstr();
    $sql = <<SQL;
CREATE FUNCTION OID(INT8) RETURNS OID AS '
declare
  i8 alias for \$1;
begin
  return int4(i8);
end;'
LANGUAGE 'plpgsql';
SQL
    $dbh->do($sql) or die ($dbh->errstr);
    $dbh->disconnect();
    print BOLD "[Done.]", RESET, "\n";

    return 0;
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
    my $exists = create_database ("DEBIAN");
    
    # Back to UID 0
    $EUID = 0;

    croak "Database already exists!" if $exists;

    return 1;
}

sub rollback {

    return 1;
}


1;
