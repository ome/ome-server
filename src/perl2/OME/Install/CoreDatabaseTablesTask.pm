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
use Sys::Hostname;
use MIME::Base64;
use Term::ANSIColor qw(:constants);
use File::Basename;
use File::Spec::Functions qw(rel2abs);

use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use base qw(OME::Install::InstallationTask);

# Packages needed from OME for the bootstrap
use OME::Database::Delegate;
use OME::Factory;
use OME::SessionManager;
use OME::Tasks::OMEImport;

#*********
#********* GLOBALS AND DEFINES
#*********

# Global logfile filehandle and name
my $LOGFILE_NAME = "CoreDatabaseTablesTask.log";
my $LOGFILE;

# Installation home
my $INSTALL_HOME;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER, $OME_UID);

# Our Apache user we'll grab from the environment
my ($APACHE_USER);

# Default import formats
my $IMPORT_FORMATS = "OME::ImportEngine::MetamorphHTDFormat OME::ImportEngine::DVreader OME::ImportEngine::STKreader OME::ImportEngine::TIFFreader";

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
   ['OME::Configuration::Variable',
                              'OME::Configuration::Variable'],
  );

#*********
#********* LOCAL SUBROUTINES
#*********

# Create a postgres superuser SQL: CREATE USER foo CREATEUSER
sub create_superuser {
    my ($username, $logfile) = @_;
    my $pg_uid = getpwnam ("postgres") or croak "Unable to retrieve PostgreSQL user UID";
    my $createuser = "createuser";
    my $output;
    my $retval;

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
	    and croak "Error loading class \"$instantiate_class\", see $LOGFILE_NAME details."
        if $@;


	print BOLD, "[SUCCESS]", RESET, ".\n"
	    and print $logfile "SUCCESS LOADING CLASS \"$instantiate_class\"\n";
    }

    $factory->commitTransaction();

    return 1;
}

sub create_experimenter {
    my $first_name = "";
    my $last_name = "";
    my $username;
    my $e_mail;
    my $data_dir = "";

    print_header "Initial user creation";
    
    my $factory = OME::Factory->new();
    my $dbh = $factory->obtainDBH();

    while (1) {
	$first_name = confirm_default ("First name", $first_name);
	$last_name = confirm_default ("Last name", $last_name);
	$username = confirm_default ("Username", ($username or lc (substr ($first_name, 0, 1).$last_name)));  
	$e_mail = confirm_default ("E-mail address", ($e_mail or $username.'@'.hostname ()));
	$data_dir = confirm_default ("Default data directory", $data_dir);

	print "\n";  # Spacing

	print "First name: $first_name\n";
	print "Last name: $last_name\n";
	print "Username: $username\n";
	print "E-mail address: $e_mail\n";
	print "Default data directory: $data_dir\n";
	
	print "\n";  # Spacing

	y_or_n ("Are these values correct ?") and last or next;
    }
    
    if (not -d $data_dir) {
	my $y_or_n = confirm_default ("Directory \"$data_dir\" does not exist. Do you want to create it ?", "no");

	if ((lc ($y_or_n) eq 'y') or (lc ($y_or_n) eq 'yes')) {
	    mkdir ($data_dir, 0755) or croak "Unable to create directory \"$data_dir\". $!";
	}
    }

    my ($password, $hashed_password) = get_password ("Password: ", 6);

    print "\n";  # Spacing

    my $experimenter = $factory->
	newObject('OME::SemanticType::BootstrapExperimenter',
            {
             OMEName       => $username,
             FirstName     => $first_name,
             LastName      => $last_name,
             Email         => $e_mail,
             Password      => $hashed_password,
             DataDirectory => $data_dir,
            });

    $factory->commitTransaction();
    $factory->releaseDBH($dbh);

    return ($username, $password);
}

sub init_configuration {
    my $session = shift;
    my $factory = $session->Factory();

    print_header "Initializing configuration";

    my $lsid_authority = confirm_default ("LSID Authority", hostname ());

    # The DB instance uniquely identifies this specific DB instance on this machine
    # Can only make one per second - sorry.
    # There are two punctuation characters in base64: '/' and '+' (no '=' here b/c of trunctation)
    # substitute '/' with something safer - '_'.
    my $db_instance = substr (encode_base64(pack ('N',time()),''),0,6);
    $db_instance =~ s/\//_/g;

    # The MAC address local to the system (the first one)
    # This is portable since it's using OME::Install::Util, if you're having trouble with this
    # configuration variable take a look at src/perl2/OME/Install/Util.pm.
    my $mac = get_mac ();

    my $configuration = OME::Configuration->new ($factory,
            {
             mac_address      => $mac,
             db_instance      => $db_instance,
             lsid_authority   => $lsid_authority,
             tmp_dir          => $OME_TMP_DIR,
             xml_dir          => $OME_BASE_DIR."/xml",
             bin_dir          => $OME_BASE_DIR."/bin",
             import_formats   => $IMPORT_FORMATS,
             ome_root         => $OME_BASE_DIR
            });

    $session->commitTransaction();


    return $configuration;
}

sub load_xml_core {
    my ($session, $logfile) = @_;
    my @core_xml;

    my $omeImport = OME::Tasks::OMEImport->
	new(
	    session => $session,
	    # XXX: Debugging off.
	    #debug => 1
	);

    # get list of files
    open (CORE_XML, "<", "src/SQL/CoreXML" )
	or croak "Could not open file \"src/SQL/CoreXML\". $!";

    while (<CORE_XML>) { 
	chomp;

	# Put the ABS paths in the array
	$_ = rel2abs ("src/xml/$_");
	push (@core_xml, $_) if /^[^#]/;
    }

    close (CORE_XML);

    print "Importing core XML\n";

    # Import each XML file
    foreach my $filename (@core_xml) {
	print "  \\__ $filename ";
	eval {
	    $omeImport->importFile($filename,
		    NoDuplicates           => 1,
		    IgnoreAlterTableErrors => 1);
	};

	print BOLD, "[FAILURE]", RESET, ".\n"
	    and print $logfile "ERROR LOADING XML FILE \"$filename\" -- OUTPUT: \"$@\"\n"
	    and croak "Error loading XML file \"$filename\", see $LOGFILE_NAME details."
	if $@;

	print BOLD, "[SUCCESS]", RESET, ".\n"
	    and print $logfile "SUCCESS LOADING XML FILE \"$filename\"\n";
    }

    $session->commitTransaction();

    return $session;
}

sub commit_experimenter {
    my $session = shift;
    my $factory = $session->Factory();

    print "Committing our first experimenter\n";

    # Replace the instance of BootstrapExperimenter with the equivalent
    # instance of the Experimenter semantic type.
    my $experimenter = ($factory->
	findAttributes("Experimenter", undef))[0]
    or croak "Could not load Experimenter semantic types.";


    print "  \\__ Adding group\n";
    my $group = $factory->
    newAttribute("Group",undef,undef,
               {
                Name    => 'OME',
                Leader  => $experimenter->id(),
                Contact => $experimenter->id()
               });

    print "  \\__ Adding experimenter to group\n";
    $experimenter->Group($group->id());
    $experimenter->storeObject();

    print "  \\__ Creating repository object\n";
    my $repository = $factory->
    # FIXME: Yes there's a trailing slash, yes it needs to be there and no
    # I don't know why the importer doesn't detect its existance or abscence.
    newAttribute("Repository",undef,undef,
               {
                Path => $OME_BASE_DIR."/repository/"
               });


    $session->commitTransaction();

    return 1;
}

sub load_analysis_core {
    my ($session, $logfile) = @_;
    my @chains;

    print "Loading core analysis chains\n";

    # get list of files
    open( CORE_CHAINS, "<", "src/SQL/CoreChains" )
	or die "Could not open file 'CoreChains'";

    while(<CORE_CHAINS>) {
	chomp;
	
	# Put the ABS paths in the array
	$_ = rel2abs ("src/xml/$_");
	push (@chains, $_) if /^[^#]/;
    }

    close (CORE_CHAINS);

    my $chainImport = OME::ImportExport::ChainImport->
	new(session => $session);

    foreach my $filename (@chains) {
	print "  \\__ $filename ";
    
	eval {
	    $chainImport->importFile($filename, NoDuplicates => 1);
	};

	print BOLD, "[FAILURE]", RESET, ".\n"
	    and print $logfile "ERROR LOADING XML FILE \"$filename\" -- OUTPUT: \"$@\"\n"
	    and croak "Error loading XML file \"$filename\", see $LOGFILE_NAME details."
	if $@;

	print BOLD, "[SUCCESS]", RESET, ".\n"
	    and print $logfile "SUCCESS LOADING XML FILE \"$filename\"\n";
    }

    $session->commitTransaction();

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
    $APACHE_USER = $environment->apache_user()
	or croak "Unable to retrieve APACHER_USER!";

    # Set our installation home
    $INSTALL_HOME = $OME_TMP_DIR."/install";
    
    print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/$LOGFILE_NAME")
	or croak "Unable to open logfile \"$INSTALL_HOME/$LOGFILE_NAME\" $!";

    #*********
    #********* Create our super-users and bootstrap the DB
    #*********

    # Make sure our OME_USER is also a Postgres user
    print "Creating OME PostgreSQL SUPERUSER ";
    $retval = create_superuser ($OME_USER, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to create PostgreSQL superuser, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Also make sure the Apache Unix user is a Postgres user
    print "Creating Apache PostgreSQL SUPERUSER ";
    $retval = create_superuser ($APACHE_USER, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to create PostgreSQL superuser, see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Drop our UID to the OME_USER
    $EUID = $OME_UID;

    # Create our database
    create_database ("DEBIAN") or croak "Unable to create database!";
    load_schema ($LOGFILE) or croak "Unable to load the schema, see $LOGFILE_NAME for details.";
    my ($username, $password) = create_experimenter () or croak "Unable to create an initial experimenter.";
    
    # Login to OME and get our session
    my $manager = OME::SessionManager->new();
    my $session = $manager->createSession($username, $password);

    my $configuration = init_configuration ($session) or croak "Unable to initialize the configuration object.";

    # FIXME: Temporarily we need to logout/backin for the configuration variable to be initialized
    $manager->logout($session);
    $session = $manager->createSession($username, $password);
    # END

    #*********
    #********* Finalize the DB
    #*********

    print_header "Finalizing Database";
    load_xml_core ($session, $LOGFILE) or croak "Unable to load Core XML, see $LOGFILE_NAME for details.";
    commit_experimenter ($session) or croak "Unable to load commit experimenter.";
    load_analysis_core ($session, $LOGFILE)
	or croak "Unable to load analysis core, see $LOGFILE_NAME details.";

    print "Finding image import module and chain.\n";

    # There should be only one of each of these.  If there's more than
    # one, we don't care which.  (Maybe we should throw an error instead ?)

    # XXX: Ported straight out of the old bootstrap, it carries the same 
    # caveats here as it did there and I have no idea what those were. -Chris

    my $factory = $session->Factory ();

    # Grab our import module and assign it to the configuration object
    my $importModule = $factory->
	findObject("OME::Module",name => 'Importer');
    $configuration->import_module($importModule);

    # Grab our import chain and assign it to the configuration object
    my $importChain = $factory->
	findObject("OME::AnalysisChain",name => 'Image import analyses');
    $configuration->import_chain($importChain);

    $session->commitTransaction();
    
    #*********
    #********* Logout and cleanup
    #*********
    
    $manager->logout($session);

    # Back to UID 0
    $EUID = 0;

    close ($LOGFILE);

    return 1;
}

sub rollback {

    return 1;
}

1;
