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
use Term::ANSIColor qw(:constants);
use File::Basename;
use File::Path;
use File::Spec::Functions qw(rel2abs);
use Log::Agent;
use Text::Wrap;
use File::Glob ':glob';

use OME::Install::Util;
use OME::Install::Environment;
use OME::Install::Terminal;
use OME::Install::ApacheConfigTask; # for omeis_test call in method check_repository
use base qw(OME::Install::InstallationTask);

# Packages needed from OME for the bootstrap
use OME::Database::Delegate;
use OME::Factory;
use OME::SessionManager;
use OME::Tasks::ImageTasks;
use OME::Tasks::SemanticTypeManager;
use OME::ImportExport::ChainImport;
use OME::Tasks::OMEImport;

# Packages that should have been installed by now
use HTTP::Request::Common;
use LWP::UserAgent;



#*********
#********* GLOBALS AND DEFINES
#*********

# Global logfile filehandle and name
our $LOGFILE_NAME = "CoreDatabaseTablesTask.log";
our $LOGFILE;

# Installation home
our $INSTALL_HOME;

# the installation environment
our $ENVIRONMENT;

# Our basedirs and user which we grab from the environment
our ($OME_BASE_DIR, $OME_TMP_DIR,  $OME_USER, $OME_UID, $OME_GROUP);

# Our Apache user & Postgres admin we'll grab from the environment
our ($APACHE_USER, $POSTGRES_USER, $ADMIN_USER, $OME_EXPER, $ADMIN_UID);

# Default import formats
# N.B.:  TIFFreader must follow ALL tiff variants
#        XMLreader is best kept last.
our $IMPORT_FORMATS = join (' ',qw/
    OME::ImportEngine::MetamorphHTDFormat
    OME::ImportEngine::DVreader
    OME::ImportEngine::STKreader
    OME::ImportEngine::BioradReader
    OME::ImportEngine::LSMreader
    OME::ImportEngine::TIFFreader
    OME::ImportEngine::DICOMreader
    OME::ImportEngine::XMLreader
/);

# Database version
our $DB_VERSION = "2.12";

# Default analysis executor
our $DEFAULT_EXECUTOR = 'OME::Analysis::Engine::UnthreadedPerlExecutor';

# $coreClasses = ([$package_to_require,$class_to_instantiate], ... )

# Each class to instantiate is listed as a pair: the package that
# should be used in the "require" statement, and the class to actually
# instantiate in the database.  If the first argument is undef, no
# require statement is executed.  This is just to deal with the fact
# that some files declare multiple DBObject subclasses; only the
# package corresponding to the filename should be "required".

our @core_classes =
  (
   'OME::LookupTable',
   'OME::LookupTable::Entry',
   'OME::DataTable',
   'OME::DataTable::Column',
   'OME::SemanticType',
   'OME::SemanticType::Element',
   'OME::SemanticType::BootstrapExperimenter',
   'OME::SemanticType::BootstrapGroup',
   'OME::SemanticType::BootstrapRepository',
   'OME::Dataset',
   'OME::Project',
   'OME::Project::DatasetMap',
   'OME::Image',
   'OME::Image::DatasetMap',
   'OME::Image::ImageFilesXYZWT',
   'OME::Feature',
   'OME::UserState',
   'OME::ViewerPreferences',
   'OME::LSID',
   'OME::Module::Category',
   'OME::Module',
   'OME::Module::FormalInput',
   'OME::Module::FormalOutput',
   'OME::AnalysisChain',
   'OME::AnalysisChain::Node',
   'OME::AnalysisChain::Link',
   'OME::AnalysisPath',
   'OME::AnalysisPath::Map',
   'OME::ModuleExecution',
   'OME::ModuleExecution::ActualInput',
   'OME::ModuleExecution::SemanticTypeOutput',
   'OME::ModuleExecution::ParentalOutput',
   'OME::ModuleExecution::VirtualMEXMap',
   'OME::AnalysisChainExecution',
   'OME::AnalysisChainExecution::NodeExecution',
   'OME::Task',
   'OME::Analysis::Engine::Worker',
   # Make sure this next one is last
   'OME::Configuration::Variable',
  );

#*********
#********* LOCAL SUBROUTINES
#*********

# Create a postgres superuser SQL: CREATE USER foo CREATEUSER
sub create_superuser {
    my ($username, $logfile) = @_;
    my $pg_uid = getpwnam ($POSTGRES_USER) or croak "Unable to retrieve PostgreSQL user UID";
    my $createuser = "createuser";
    my @outputs;
    my $retval;
    my $success;

    # Make sure we're not croaking on a silly logfile print
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    # Make sure we can see the Postgres command
    $retval = which ("$createuser");
   
    $createuser = whereis ("createuser") or croak "Unable to locate creatuser binary." unless $retval;

    # Create the user using the command line tools
    @outputs = `su $POSTGRES_USER -c "$createuser -d -a $username" 2>&1`;

    # Log and return success
    foreach (@outputs) {
        $success = 1 if $_ =~ /already exists/ or $_ =~ /^CREATE/;
    }
    if ($success) {
    print $logfile "CREATION OF USER $username SUCCESSFUL -- OUTPUT: \n".join ("\n",@outputs)."\n";
    return 1;
    }

    # Log and return failure
    print $logfile "CREATION OF USER $username FAILED -- OUTPUT: \n".join ("\n",@outputs)."\n";
    return 0;
}



sub get_db_version {
    my $dbh;
    my $sql;
    my $retval;

    print "Checking database\n";

    $dbh = DBI->connect("dbi:Pg:dbname=ome")
        or return undef;

    # Shush!
    $dbh->{PrintError} = '0';

    # Check for DB existance
    my $db_version = $dbh->selectrow_array(q{SELECT value FROM configuration WHERE name = 'db_version'});

    
    # If we're still here, that means there is an ome DB.
    # if $db_version is undef, our version is before 2.2, which introduced versioning.
    # Let's see if its 2.1 (after alpha, but before 2.2)
    if (not defined $db_version) {
        my $test = $dbh->selectrow_array(q{SELECT value FROM configuration WHERE name = 'db_instance'});
        $db_version = '2.1' if $test;
    }
    
    # Still nothing?  See if its alpha
    if (not defined $db_version) {
        my $test = $dbh->selectrow_array(q{SELECT DB_INSTANCE FROM configuration});
        $db_version = '2.0' if $test;
    }
    
    # if its still not defined, it's pre-alpha, so return '0'.
    $db_version = '0' unless defined $db_version;

    $dbh->disconnect();
    return ($db_version);
}

sub update_database {
    my $version = shift;
    my $session = OME::Session->bootstrapInstance();
    my $factory = $session->Factory();
    my $dbh = $factory->obtainDBH();
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
    
    
    print "WARNING:  You are about to update an existing ome database.\n";
    print "  If anything goes wrong before the update is finished,\n";
    print "  your database may be left in an invalid state\n";
    print "  It is HIGHLY recommended that you perform a backup before proceeding:\n";
    print "> sudo -u postgres pg_dumpall > OME-DB-DumpFile\n";
    y_or_n ("Are you sure you want to proceed ?",'n') or croak "Database update aborted by user";


	# Since we may be installing from a directory that does not have permissions
	# for a user that can acess the DB (i.e. the OME user), we have to copy the
	# update files to the temporary directory and go from there.
	# This of course, we have to do as root and then switch back.
	my $old_euid = euid (0);
    print "Copying update directories to $OME_TMP_DIR/update\n";
	copy_tree ("update", "$OME_TMP_DIR");
	fix_ownership( {
			owner => $OME_USER,
			group => $OME_GROUP,
		}, "$OME_TMP_DIR/update/");
	euid ($old_euid);


    while (defined $version and $version ne $DB_VERSION) {
        my @files = bsd_glob ("$OME_TMP_DIR/update/$version/pre/*");
        unless (scalar(@files) > 0) {
            print "  \\_ ", BOLD, "ERROR", RESET,
              " Cannot find upgrade scripts for database version $version.\n";
            return 0;
        }

        print "  \\_ Upgrading database version $version\n";
        undef $version;



        foreach my $file (@files) {
            if ($file =~ /^CHANGELOG/) {
                next;
            } elsif ($file =~ /\.sql$/) {
                eval { `psql -f $file ome` };

                if ($@) {
                    print BOLD, "[FAILURE]", RESET, ".\n";
                    croak $@;
                }
            } elsif ($file =~ /\.eval$/) {
                my $result = scalar (eval `cat $file`);

                # If there was an error, pass it out
                if ($@) {
                    print BOLD, "[FAILURE]", RESET, ".\n";
                    croak $@;
                }

                # If the script did not return true, throw an error
                unless ($result) {
                    print BOLD, "[FAILURE]", RESET, ".\n";
                    croak "eval of file $file did not return true";
                }
            }
        } # each file in the $version/pre/ directory
        # This prevents re-execution of scripts already executed in case the update chain was interrupted.
        if ($version) {
            my $var = $factory->findObject('OME::Configuration::Variable',
                    configuration_id => 1, name => 'db_version') or croak 
                    "Could not retreive the configuration variable db_version";
            $var->value ($version);
            $var->storeObject();
            $factory->commitTransaction();
        }
    } # each version prior to $DB_VERSION

    $session->finishBootstrap();
    return (1);
}

# Create our OME database
#
# RETURNS   1 on success
#       0 if the DB exists
#       0 on failure

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
    } else {
    # Create an empty DB
    print "  \\__ Initialization\n";
    $dbh->do(q{
    CREATE DATABASE ome
    }) or croak $dbh->errstr();
	}
    $dbh->disconnect();

	# Make this process euid root, and execute these things as the postgres user.
	# It is often not enough to set euid - the actual UID has to be something
	# postgres recognizes, so we need to su.
	# To make sure we can do 'su' (permissions for this directory, etc), we need to be root.
	# To make sure that postgres has a sane environment, we need to su -.
	my $old_euid = euid (0);
    print "  \\__ Adding PL-PGSQL language\n";

    # Set the PGSQL lang
	# First off, see if the postgres user knows where createlang is.
    my @CMD_OUT = `su - $POSTGRES_USER -c "which $createlang" 2>&1`;
    foreach (@CMD_OUT) {
    	chomp;
    	$retval = which ($_);
    	last if $retval;
    }

	if (not $retval) {
	    $retval = which ($createlang);
	    if (not $retval) {
			$createlang = whereis ($createlang) or croak "Unable to locate $createlang binary.";
		}
	}

	$createlang = $retval;

    @CMD_OUT = `su - $POSTGRES_USER -c "$createlang plpgsql ome" 2>&1`;
    if ($? != 0) {
    	die "Errors: \n",join ('',@CMD_OUT),"\n" unless join ('',@CMD_OUT) =~ /already installed/;
    }
    
    # Go back to what we were (should be OME_USER) so that we can connect
    # from this process.
	euid ($old_euid);

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

    print "  \\__ $class ";
    
    $class->require();

    # Add our class to the DB
    eval {
        $delegate->addClassToDatabase($dbh,$class);
    };
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and print $logfile "ERROR LOADING CLASS \"$class\" -- OUTPUT: \"$@\"\n"
        and croak "Error loading class \"$class\", see $LOGFILE_NAME details."
        if $@;


    print BOLD, "[SUCCESS]", RESET, ".\n"
        and print $logfile "SUCCESS LOADING CLASS \"$class\"\n";
    }

    $factory->commitTransaction();

    return 1;
}

sub create_experimenter {
    my $manager = shift;
    my $personal_info;
    
    if (not defined $OME_EXPER, or not $OME_EXPER) {
        if ($ADMIN_UID) {
            ($OME_EXPER->{OMEName}, $personal_info, $OME_EXPER->{DataDirectory}) = (getpwuid($ADMIN_UID))[0,6,7];
        
            if ($personal_info) {
                my $full_name = (split (',',$personal_info,2))[0];
                ($OME_EXPER->{FirstName},$OME_EXPER->{LastName}) = split (' ',$full_name,2);
            } else {
                ($OME_EXPER->{FirstName},$OME_EXPER->{LastName}) = ('','');
            }
            $OME_EXPER->{Email} = $OME_EXPER->{OMEName}.'@'.hostname();
            $OME_EXPER->{OMEName} = lc ( substr ($OME_EXPER->{FirstName}, 0, 1).$OME_EXPER->{LastName} )
                unless $OME_EXPER->{OMEName};
        } else {
            $OME_EXPER->{FirstName} = '';
            $OME_EXPER->{LastName}  = '';
            $OME_EXPER->{OMEName}  = '';
            $OME_EXPER->{Email}    = '';
            $OME_EXPER->{DataDirectory}  = '';
        }
    }

    print_header "Initial user creation";

    # Confirm all flag
    my $confirm_all;

	# Task blurb
	my $blurb = <<BLURB;
This user will be yourself or the person who will administer the OME environment after installation. It is internal to OME. You will use this username and password to use OME and add new OME users and groups. The default data directory option is the path on this machine which contains (or will contain) the proprietary image files (greyscale TIFF's for example) you wish to import into OME. An example default data directory would be "/home/joe/my_ome_images".
BLURB

	print wrap("", "", $blurb);
	
	print "\n";  # Spacing


    while (1) {
        if ($OME_EXPER or $confirm_all) {
            print "            First name: ", BOLD, $OME_EXPER->{FirstName}    , RESET, "\n";
            print "             Last name: ", BOLD, $OME_EXPER->{LastName}     , RESET, "\n";
            print "              Username: ", BOLD, $OME_EXPER->{OMEName}      , RESET, "\n";
            print "        E-mail address: ", BOLD, $OME_EXPER->{Email}        , RESET, "\n";
            print "Default data directory: ", BOLD, $OME_EXPER->{DataDirectory}, RESET, "\n";
    
            print "\n";  # Spacing

			if (y_or_n ("Are these values correct ?")) {
				last;
			} 
        }

        $confirm_all = 0;

        $OME_EXPER->{FirstName}     = confirm_default ("            First name", $OME_EXPER->{FirstName});
        $OME_EXPER->{LastName}      = confirm_default ("             Last name", $OME_EXPER->{LastName});
        $OME_EXPER->{OMEName}       = confirm_default ("              Username", $OME_EXPER->{OMEName});
        $OME_EXPER->{Email}         = confirm_default ("        E-mail address", $OME_EXPER->{Email});
        $OME_EXPER->{DataDirectory} = confirm_default ("Default data directory", $OME_EXPER->{DataDirectory});
        
        print "\n";  # Spacing

        $confirm_all = 1;
    }

    if (not -d $OME_EXPER->{DataDirectory}) {
        mkpath ($OME_EXPER->{DataDirectory}, 0, 0755)  # Internal croak
        	if y_or_n ('Directory "'.$OME_EXPER->{DataDirectory}.
            	'" does not exist. Do you want to create it ?', 'y');
		
    }
    
    if (not check_permissions ({user => $APACHE_USER, r => 1, w => 1}, $OME_EXPER->{DataDirectory})) {
    	print wrap("", "", <<PRINT);
 
OME user "$OME_EXPER->{OMEName}" data directory "$OME_EXPER->{DataDirectory}" cannot be accessed by the Apache user "$APACHE_USER". This directory and its contents should either be owned by the OME group "$OME_GROUP" or be world-readable. The recommended course of action is to change group ownership to "$OME_GROUP".
PRINT
        if (y_or_n ("OK to change group ownership of $OME_EXPER->{DataDirectory} to \"$OME_GROUP\"", 'n')) {
        	fix_ownership ({group => $OME_GROUP, recurse => 0}, $OME_EXPER->{DataDirectory});
        	print <<PRINT;
Directory ownership successfully fixed.
You will still need to make sure that the files in this directory are either owned by the OME group "$OME_GROUP" or,
That the files are group-readable.
PRINT
        }
		
	}
	
    my $password;
    ($password, $OME_EXPER->{Password}) = get_password ("Set password for OME user ".$OME_EXPER->{OMEName}.": ", 6);

    print "\n";  # Spacing

    # IGG 12/10/03:  Refactored this a wee bit to work with updates
    # Since we may be updating, see if there's an experimenter with the same OMEName.
    my $factory = OME::Factory->new();
    
    my $experimenter = $factory->
    newObject('OME::SemanticType::BootstrapExperimenter', $OME_EXPER);

    $factory->commitTransaction();
    $factory->closeFactory();
    my $session = $manager->createSession($OME_EXPER->{OMEName}, $password);

    $ENVIRONMENT->ome_exper($OME_EXPER);

    return ($session);
}


# Make sure an experimenter ends up in the stored environment
sub save_exper_env {
my $session = shift;

	croak "Trying to save OME Experimenter in installation environment without a defined session"
		unless defined $session;

	my $factory = $session->Factory();
	croak "Trying to save OME Experimenter in installation environment: Couldn't get factory for session"
		unless defined $factory;

	my $experimenter = $factory->
		findObject('OME::SemanticType::BootstrapExperimenter',id => $session->experimenter_id());
	croak "Couldn't find session owner (Experimenter ID=".$session->experimenter_id().") in DB." unless $experimenter;

	$OME_EXPER->{FirstName}     = $experimenter->FirstName();
	$OME_EXPER->{LastName}      = $experimenter->LastName();
	$OME_EXPER->{OMEName}       = $experimenter->OMEName();
	$OME_EXPER->{Email}         = $experimenter->Email();
	$OME_EXPER->{DataDirectory} = $experimenter->DataDirectory();
	$OME_EXPER->{Password}      = $experimenter->Password();

    $ENVIRONMENT->ome_exper($OME_EXPER);

}


# This little gem gets a session without logging in.
# This should only really be done if we're running this non-interactive.
sub bootstrap_session {
    my $factory = OME::Factory->new();
    croak "Couldn't create a new factory" unless $factory;
	croak "Can't get a non-interactive session:\n".
		"OME Expreimenter not defined in installation environment.\n".
		"Try doing an update first (install.pl -u)." unless $OME_EXPER;

	print "  \\__ Finding Experimenter ".$OME_EXPER->{OMEName}."\n";
	my $experimenterObj = $factory->
		findObject('OME::SemanticType::BootstrapExperimenter',OMEName => $OME_EXPER->{OMEName});
	croak "Can't get a non-interactive session:\n".
		"Can't find the OME Expreimenter that did the previous installation/update (username=".$OME_EXPER->{OMEName}.")\n".
		"Try doing an update first (install.pl -u)." unless $experimenterObj;

    print "  \\__ Getting user state for ".$experimenterObj->OMEName()."\n";
    my $userState = $factory->findObject('OME::UserState',experimenter_id => $experimenterObj->id());
    if (!defined $userState) {
        $userState = $factory->
          newObject('OME::UserState',
                    {
                     experimenter_id => $experimenterObj->id(),
                     started         => 'now',
                     last_access     => 'now',
                     host            => hostname()
                    });
        $factory->commitTransaction();
    } else {
        $userState->last_access('now');
        $userState->host(hostname());
    }
    croak "Could not create userState object.  Something is probably very very wrong." unless $userState;

    print "  \\__ Getting session for user state ID=".$userState->id()."\n";    
    my $session = OME::Session->instance($userState, $factory);

    croak "Could not create session from userState.  Something is probably very very wrong" unless defined $session;

    $userState->storeObject();
    $session->commitTransaction();

    return $session;
}



sub init_configuration {
    my $factory = OME::Factory->new();

    print_header "Initializing configuration";
    
    my $lsid_def = $ENVIRONMENT->lsid ();
    $lsid_def = hostname() unless $lsid_def; 

	# Task blurb
	my $blurb = <<BLURB;
The installer will now finalize your OME environment by asking you for an LSID authority and to provide an initial user for you to use with the web interface and Java clients.

The LSID authority is a type of universal identification for your OME environment and it should be defined as the FQDN (fully qualified domain name) of the install machine; "myome.openmicroscopy.org" for example. If you are unsure of what to enter here ask your network/systems administrator or use the default as that will be adequate for most people.
BLURB

	print wrap("", "", $blurb);
	
	print "\n";  # Spacing

    my $lsid_authority = confirm_default ("LSID Authority", $lsid_def);

    # The DB instance uniquely identifies this specific DB instance on this machine
    # Can only make one per second - sorry.
    # This is the integer returned by time() converted to a base62 string.

    my $db_instance = to_base ([0..9,'a'..'z','A'..'Z'],time());

    # The MAC address local to the system (the first one)
    # This is portable since it's using OME::Install::Util, if you're having trouble with this
    # configuration variable take a look at src/perl2/OME/Install/Util.pm.
    my $mac = get_mac ();

	# MATLAB specific settings
	my $MATLAB = $ENVIRONMENT->matlab_conf();
	
    my $configuration = OME::Configuration->new ($factory,
            {
             mac_address      => $mac,
             db_instance      => $db_instance,
             db_version       => $DB_VERSION.'-Installing',
             lsid_authority   => $lsid_authority,
             tmp_dir          => $OME_TMP_DIR,
             xml_dir          => $OME_BASE_DIR."/xml",
             bin_dir          => $OME_BASE_DIR."/bin",
             import_formats   => $IMPORT_FORMATS,
             ome_root         => $OME_BASE_DIR,
             template_dir     => $OME_BASE_DIR."/html/Templates",
             matlab_src_dir   => $MATLAB->{MATLAB_SRC},
             matlab_user      => $MATLAB->{MATLAB_USER},
             executor         => $DEFAULT_EXECUTOR,
            });

    $ENVIRONMENT->lsid ($lsid_authority);
    $factory->commitTransaction();
    $factory->closeFactory();
    return 1;
}


# Shamelessly stolen from Math::BaseCalc by Ken Williams, ken@forum.swarthmore.edu
sub to_base {
    my ($digits,$num) = @_;
    return '-'.to_base(-1*$num) if $num<0; # Handle negative numbers
    
    my $dignum = @{$digits};
    
    my $result = '';
    while ($num>0) {
        substr($result,0,0) = $digits->[ $num % $dignum ];
        $num = int ($num/$dignum);
        #$num = (($num - ($num % $dignum))/$dignum);  # An alternative to the above
    }
    return length $result ? $result : $digits->[0];
}


sub update_configuration {
    my $session = shift;
    my $factory = $session->Factory();
    my $var;

    # Make sure that the DB_VERSION and IMPORT_FORMATS is correct in case the data hash
    # was ignored due to a pre-existing configuration
    $var = $factory->findObject('OME::Configuration::Variable',
            configuration_id => 1, name => 'db_version') or croak 
            "Could not retreive the configuration variable db_version";
    $var->value ($DB_VERSION);
    $var->storeObject();

    $var = $factory->findObject('OME::Configuration::Variable',
            configuration_id => 1, name => 'import_formats') or croak 
            "Could not retreive the configuration variable import_formats";
    $var->value ($IMPORT_FORMATS);
    $var->storeObject();

    $var = $factory->findObject('OME::Configuration::Variable',
            configuration_id => 1, name => 'executor');
    unless ($var) {
        $var = $factory->newObject ('OME::Configuration::Variable',
            {
            configuration_id => 1,
            name             => 'executor',
            value            => $DEFAULT_EXECUTOR,
            });
	    $var->storeObject();
    }

    $factory->commitTransaction();
    return 1;
}

# N.B.:  This is used by the 2.4 -> 2.5 update script.
sub make_repository {
    my $session = shift;
    my $factory = $session->Factory();
    print "  \\__ Creating repository object\n";

    print "\n";  # Spacing

    my $hostname = hostname();

    # FIXME Make this a little more verbose, probably needs some explanation.
    my $repository_def = $ENVIRONMENT->omeis_url();
    $repository_def = "http://$hostname/cgi-bin/omeis" if $ENVIRONMENT->apache_conf->{OMEIS} and not $repository_def;

    my $repository_url = confirm_default ("What is the URL of the OME Image server (omeis) ?", $repository_def);
    $ENVIRONMENT->omeis_url($repository_url);

    my $repository = $factory->
    newObject('OME::SemanticType::BootstrapRepository',
            {
             ImageServerURL => $repository_url,
             IsLocal        => 0,
            });
    $repository->storeObject;

    $session->commitTransaction();
    return $repository;
}

sub check_repository {
    my $session = shift;
    my $factory = $session->Factory();

	print $LOGFILE "Checking repository\n" and
	print "Checking OMEIS repository ";
    my $repository = $factory->
    findObject('OME::SemanticType::BootstrapRepository',
            {
             IsLocal        => 0,
            });
	print $LOGFILE "Could not find remote repository object\n" and
		croak "Could not find remote repository object (looking for omeis URL)"
	unless $repository;

	my $repository_url = $repository->ImageServerURL();
	print $LOGFILE "Repository ImageServerURL is undefined!\n" and
		croak "Looking for omeis URL:  ImageServerURL is undefined in Repository object!"
	unless $repository_url;

	print $LOGFILE "Repository URL: $repository_url\n";

	if ($ENVIRONMENT->omeis_url()) {
		print $LOGFILE "ENVIRONMENT->omeis_url(): ".$ENVIRONMENT->omeis_url()."\n";
	} else {
		print $LOGFILE "ENVIRONMENT->omeis_url(): *** UNDEFINED ***\n";
	}

 	$ENVIRONMENT->omeis_url($repository_url);
 	OME::Install::ApacheConfigTask::omeis_test($ENVIRONMENT->omeis_url(), $LOGFILE );
}

sub load_xml_core {
    my ($session, $logfile) = @_;
    my @core_xml;

    # get list of files
    open (CORE_XML, "<", "src/xml/CoreXML" )
    or croak "Could not open file \"src/xml/CoreXML\". $!";

    while (<CORE_XML>) { 
        chomp;

        # Put the ABS paths in the array
        $_ = rel2abs ("src/xml/$_");
        push (@core_xml, $_) if /^[^#]/;
    }

    close (CORE_XML);

    print "Importing core XML\n";

    # Import each XML file
    my $omeImport = OME::Tasks::OMEImport->new(
        session => $session,
        # XXX: Debugging off.
        #debug => 1
    );

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

    $session->commitTransaction();

    return 1;
}

sub load_analysis_core {
    my ($session, $logfile) = @_;
    my @chains;

    print "Loading core analysis chains\n";

    # get list of files
    open( CORE_CHAINS, "<", "src/xml/CoreChains" )
    or die "Could not open file 'src/xml/CoreChains'";

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
    if ($ENV{OME_DEBUG}) {  
        logconfig(
            -prefix      => "$0",
            -level    => 'debug'
        );
    
        print STDERR "Debugging on\n";
    }

    my $retval;

    print_header "Database Bootstrap";

    # Our OME::Install::Environment
   $ENVIRONMENT = initialize OME::Install::Environment;

    # Populate globals
    $OME_BASE_DIR = $ENVIRONMENT->base_dir()
    or croak "Unable to retrieve OME_BASE_DIR!";
    $OME_TMP_DIR = $ENVIRONMENT->tmp_dir()
    or croak "Unable to retrieve OME_TMP_DIR!";
    $OME_USER = $ENVIRONMENT->user()
    or croak "Unable to retrieve OME_USER!";
    $OME_UID = getpwnam ($OME_USER)
    or croak "Unable to retrive OME_USER UID!";
    $OME_GROUP = $ENVIRONMENT->group()
    or croak "Unable to retrive OME_GROUP";
    $APACHE_USER = $ENVIRONMENT->apache_user()
    or croak "Unable to retrieve APACHE_USER!";
    $POSTGRES_USER = $ENVIRONMENT->postgres_user()
    or croak "Unable to retrieve POSTGRES_USER!";
    $ADMIN_USER = $ENVIRONMENT->admin_user();
    $OME_EXPER = $ENVIRONMENT->ome_exper();

    if ($ADMIN_USER) {
        $ADMIN_UID = getpwnam ($ADMIN_USER);
    }

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
    print "Creating OME PostgreSQL SUPERUSER ($OME_USER)";
    $retval = create_superuser ($OME_USER, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to create PostgreSQL superuser '$OME_USER', see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Also make sure the Apache Unix user is a Postgres user
    print "Creating Apache PostgreSQL SUPERUSER ($APACHE_USER)";
    $retval = create_superuser ($APACHE_USER, $LOGFILE);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to create PostgreSQL superuser '$APACHE_USER', see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Also make sure the admin user is a Postgres user
    if ($ADMIN_USER) {
        print "Creating Admin PostgreSQL SUPERUSER ($ADMIN_USER)";
        $retval = create_superuser ($ADMIN_USER, $LOGFILE);
        
        print BOLD, "[FAILURE]", RESET, ".\n"
            and croak "Unable to create PostgreSQL superuser '$ADMIN_USER', see $LOGFILE_NAME for details."
            unless $retval;
        print BOLD, "[SUCCESS]", RESET, ".\n";
    }

    # Drop our UID to the OME_USER
    euid($OME_UID);

    my ($configuration,$manager,$session);

    # Check the DB version
    my $db_db_version = get_db_version();
    if ($db_db_version) {
        print "From DB, got DB_Version = '$db_db_version'\n";
    }
    croak "Found an existing ome database, but it appears to be too old to be updated.\n".
        "You will have to upgrade it manually.  Sorry\n"
        if defined $db_db_version and $db_db_version eq '0';

    croak "Found an existing ome database, but apprently installation failed before it was complete.\n".
        "You will have to drop the existing ome database before continuing.\n".
        "WARNING:  Do not do this if you have an existing functional database\n".
        "          especially if you don't have a current backup!!!\n".
        "Restart Apache:\n".
        "> sudo apachectl restart\n".
        "Drop the ome database:\n".
        "> dropdb ome\n".
        "And run the installer again.\n"
        if defined $db_db_version and $db_db_version =~ /Installing/;

    if (defined $db_db_version) {
        print "Found existing database version $db_db_version.";
        $ENVIRONMENT->set_flag ("UPDATE");
        if ($db_db_version ne $DB_VERSION) {
            print "  Updating to $DB_VERSION.\n";
            $retval = update_database($db_db_version);
            print "  \\_ ", BOLD, "[FAILURE]", RESET, ".\n"
                and croak "Unable to update existing database, see $LOGFILE_NAME for details."
                unless $retval;
            print "  \\_ ", BOLD, "[SUCCESS]", RESET, ".\n";
        } else {
            print "  Database is current.\n";
        }
        load_schema ($LOGFILE) or croak "Unable to load the schema, see $LOGFILE_NAME for details.";
		print "Getting a session manager\n";
        $manager = OME::SessionManager->new() or croak "Unable to make a new SessionManager.";
        # If we're answering 'y' to everything, we don't want to be interactive here
        if ($ENVIRONMENT->get_flag ('ANSWER_Y')) {
		    print "Getting a non-interactive session\n";
        	$session = bootstrap_session();
        } else {
        	$session = $manager->TTYlogin() or croak "Unable to create an initial experimenter.";
       	}
        $configuration = $session->Configuration or croak "Unable to initialize the configuration object.";
        check_repository ($session);
        print_header "Finalizing Database";
        # Set the UID to whoever owns the install directory
        euid(0);
        euid((stat ('.'))[4]);
        load_xml_core ($session, $LOGFILE) or croak "Unable to load Core XML, see $LOGFILE_NAME for details.";
        load_analysis_core ($session, $LOGFILE)
        or croak "Unable to load analysis core, see $LOGFILE_NAME details.";
        $session->commitTransaction();
    } elsif (not defined $db_db_version) {
        # Create our database
        create_database ("DEBIAN") or croak "Unable to create database!";
        load_schema ($LOGFILE) or croak "Unable to load the schema, see $LOGFILE_NAME for details.";
        init_configuration () or croak "Unable to initialize the configuration object.";
        $manager = OME::SessionManager->new() or croak "Unable to make a new SessionManager.";
        $session = create_experimenter ($manager) or croak "Unable to create an initial experimenter.";
        $configuration = $session->Configuration or croak "Unable to initialize the configuration object.";
        print_header "Finalizing Database";
        make_repository ($session);
        check_repository ($session);
        # Set the UID to whoever owns the install directory
        euid(0);
        euid((stat ('.'))[4]);
        load_xml_core ($session, $LOGFILE) or croak "Unable to load Core XML, see $LOGFILE_NAME for details.";
        commit_experimenter ($session) or croak "Unable to load commit experimenter.";
        load_analysis_core ($session, $LOGFILE)
        or croak "Unable to load analysis core, see $LOGFILE_NAME details.";
    }

    # Drop our UID to the OME_USER
    euid($OME_UID);

    #*********
    #********* Finalize the DB
    #*********


    print "Finding image import module and chain.\n";

    # There should be only one of each of these.  If there's more than
    # one, we don't care which.  (Maybe we should throw an error instead ?)

    # XXX: Ported straight out of the old bootstrap, it carries the same 
    # caveats here as it did there and I have no idea what those were. -Chris

    my $factory = $session->Factory ();

    # Grab our annotation and import modules and assign them to the
    # configuration object

    my $annotationModule = $factory->
      findObject("OME::Module",name => 'Annotation');
    $configuration->annotation_module($annotationModule);

    my $originalFilesModule = $factory->
      findObject("OME::Module",name => 'Original files');
    $configuration->original_files_module($originalFilesModule);

    my $globalImportModule = $factory->
      findObject("OME::Module",name => 'Global import');
    $configuration->global_import_module($globalImportModule);

    my $datasetImportModule = $factory->
      findObject("OME::Module",name => 'Dataset import');
    $configuration->dataset_import_module($datasetImportModule);

    my $imageImportModule = $factory->
      findObject("OME::Module",name => 'Image import');
    $configuration->image_import_module($imageImportModule);

    # Grab our import chain and assign it to the configuration object
    my $importChain = $factory->
    findObject("OME::AnalysisChain",name => 'Image server stats');
    $configuration->import_chain($importChain);

    # Update the Database version
    update_configuration ($session) or croak "Unable to update the configuration object.";

    # Update the Experimenter in the install environment
    save_exper_env ($session);

    $session->commitTransaction();
    
    #*********
    #********* Logout and cleanup
    #*********
    
    $manager->logout($session);


    close ($LOGFILE);
    
    # Back to UID 0
    euid(0);

    return 1;
}

sub rollback {

    return 1;
}

1;
