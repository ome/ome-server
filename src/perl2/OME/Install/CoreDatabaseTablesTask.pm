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
use OME::Tasks::ModuleExecutionManager;


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
    OME::ImportEngine::OMETIFFreader
    OME::ImportEngine::MetamorphHTDFormat
    OME::ImportEngine::DVreader
    OME::ImportEngine::STKreader
    OME::ImportEngine::BioradReader
    OME::ImportEngine::LSMreader
    OME::ImportEngine::TIFFreader
    OME::ImportEngine::BMPreader
    OME::ImportEngine::DICOMreader
    OME::ImportEngine::XMLreader
/);

# Database version
our $DB_VERSION = "2.22";

# Default analysis executor
our $DEFAULT_EXECUTOR = 'OME::Analysis::Engine::UnthreadedPerlExecutor';

# Default DB configuration
our $DEFAULT_DB_CONF = {
	Delegate => 'OME::Database::PostgresDelegate',
	User     => undef,
	Password => undef,
	Host     => undef,
	Port     => undef,
	Name     => 'ome'
};


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
   'OME::SemanticType::BootstrapExperimenterGroup',
   'OME::SemanticType::BootstrapRepository',
   'OME::Dataset',
   'OME::Project',
   'OME::Project::DatasetMap',
   'OME::Image',
   'OME::Image::DatasetMap',
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
   'OME::Analysis::Engine::Worker',
   'OME::ModuleExecution',
   'OME::ModuleExecution::ActualInput',
   'OME::ModuleExecution::SemanticTypeOutput',
   'OME::ModuleExecution::ParentalOutput',
   'OME::ModuleExecution::VirtualMEXMap',
   'OME::AnalysisChainExecution',
   'OME::AnalysisChainExecution::NodeExecution',
   'OME::Task',
   # Make sure this next one is last
   'OME::Configuration::Variable',
  );

# This global holds all the attributes created during installation (Experimenter, Group, etc).
our @INSTALLATION_ATTRIBUTES;



#*********
#********* LOCAL SUBROUTINES
#*********

sub get_db_version {
    my $dbh;
    my $sql;
    my $retval;

    print "Checking database\n";
	
    $dbh = OME::Database::Delegate->getDefaultDelegate()->connectToDatabase({RaiseError => 0,PrintError => 0})
    	or return undef;

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

	if (-d "$OME_TMP_DIR/update") {
    	delete_tree ("$OME_TMP_DIR/update");
	}

	copy_tree ("update", "$OME_TMP_DIR", sub{ ! /CVS$/i });
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
            	# By default the psql script processor doesn't stop when
            	# it encounters errors.
            	# we have to force it to stop by setting ON_ERROR_STOP.
            	# unfortunately, we can't put this all on one command
            	# line, so we have to pre-pend this to the sql file.
            	eval {
            		`echo '\\set ON_ERROR_STOP 1' > $file~`;
            		`cat $file >> $file~`;
            		`mv $file~ $file`;
            	};
                my $result = system ('psql', '-f', $file, 'ome');

                if ($result) { # non-zero exit */
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


sub load_schema {
    my $logfile = shift;
    my $retval;
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
    my $session = OME::Session->bootstrapInstance();
    my $factory = $session->Factory();
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
    $session->finishBootstrap();
    $session = undef;

    return 1;
}

sub get_installation_mex {

	my $session = shift;

    my $factory = $session->Factory();
    
	print "Creating the Installation MEX "
		and print $LOGFILE "Creating the Installation MEX\n";

    my $module = $factory->findObject ("OME::Module", {name => 'Installation'});
	print BOLD, "[FAILURE]", RESET, ".\n"
		and print $LOGFILE "Module \"Installation\" not loaded into DB - Bootstrap failed\n"
		and croak "Module \"Installation\" not loaded into DB - Bootstrap failed, see $LOGFILE_NAME details."
		unless $module;

	my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G',undef, undef, undef, 0, undef) or
		print BOLD, "[FAILURE]", RESET, ".\n"
			and print $LOGFILE "ERROR creating MEX for Installation module\n"
			and croak "ERROR creating MEX for Installation module, see $LOGFILE_NAME details.";

    # Create a universal execution for this module, so that the analysis
    # engine never tries to execute it.
    OME::Tasks::ModuleExecutionManager->
        createNEX($mex,undef,undef);

	# Update everything we've created so far to originate from this MEX
	foreach my $attr (@INSTALLATION_ATTRIBUTES) {
		# Figure out which ST definition to use for the attribute
		my ($type,$OF_attr);
		if (ref ($attr) =~ /OME::SemanticType::Bootstrap(\w+)$/) {
			$type = $factory->findObject('OME::SemanticType',{name => $1});
		} elsif (ref ($attr) eq 'OME::Image::Server::File') {
			$OF_attr = $factory->newAttribute("OriginalFile",undef,$mex, {
				SHA1 => $attr->getSHA1(), 
				Path => $attr->getFilename(), 
				FileID => $attr->getFileID(), 
				Format => 'OME XML',
				Repository => $session->findRepository(),
			});
			print BOLD, "[FAILURE]", RESET, ".\n"
				and print $LOGFILE "Could not create OriginalFile attribute for file ".$attr->getFilename()."\n"
				and croak "Could not create OriginalFile attribute for file ".$attr->getFilename().
					", see $LOGFILE_NAME details."
				unless $OF_attr;
			$attr = $OF_attr;
			$type = $attr->semantic_type() if $attr;
		} elsif (UNIVERSAL::can($attr,'semantic_type')) {
			$type = $attr->semantic_type();
		}
		print BOLD, "[FAILURE]", RESET, ".\n"
			and print $LOGFILE "Could not determine semantic type for attribute ".ref($attr)."\n"
			and croak "Could not determine semantic type for attribute ".ref($attr).
				", see $LOGFILE_NAME details."
		unless $type;

		$attr->module_execution ($mex);
		$attr->storeObject();
		

		# Make the undefined output for this module
		$factory->maybeNewObject("OME::ModuleExecution::SemanticTypeOutput", {
			module_execution => $mex,
			semantic_type    => $type,
		});
	}
	# Mark the Installation module as finished
	$mex->status('FINISHED');
	$mex->storeObject();

	# Add the bootstrap modules to the configuration
	my $configuration = $session->Configuration();
	my $originalFilesModule = $factory->
		findObject("OME::Module",name => 'Original files');
	$configuration->original_files_module($originalFilesModule);

	my $globalImportModule = $factory->
		findObject("OME::Module",name => 'Global import');
	$configuration->global_import_module($globalImportModule);



	eval {
	    $factory->commitTransaction();
    };

	print BOLD, "[FAILURE]", RESET, ".\n"
		and print $LOGFILE "ERROR committing Installation MEX to DB -- OUTPUT: \"$@\"\n"
		and croak "ERROR committing Installation MEX to DB, see $LOGFILE_NAME details."
		if $@;


	print BOLD, "[SUCCESS]", RESET, ".\n"
		and print $LOGFILE "SUCCESS creating Installation MEX\n";

    return $mex;
}

sub create_experimenter {
    my $manager = shift;
    
    print_header "Initial user creation";

    # Confirm all flag
    my $confirm_all;

	# Task blurb
	my $blurb = <<BLURB;
This user will be yourself or the person who will administer the OME environment after installation. It is internal to OME. You will use this username and password to use OME and add new OME users and groups. The default data directory option is the path on this machine which contains (or will contain) the proprietary image files (greyscale TIFF's for example) you wish to import into OME. An example default data directory would be "/home/joe/my_ome_images".
BLURB

	print wrap("", "", $blurb);
	
	print "\n";  # Spacing
	

	###
	# Try to set some defaults if we got nothing.
    if (not defined $OME_EXPER, or not $OME_EXPER) {
        if ($ADMIN_UID) {
		    my $personal_info;
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
			$OME_EXPER->{Password}  = ''; # triggers Set Password question
										  # we can't possibly recommend a password. Or can we? Default ome user password like Ur0wnd
			$confirm_all = 1;
		} else {
            $OME_EXPER->{FirstName} = '';
            $OME_EXPER->{LastName}  = '';
            $OME_EXPER->{OMEName}  = '';
            $OME_EXPER->{Email}    = '';
            $OME_EXPER->{DataDirectory}  = '';
			$OME_EXPER->{Password}  = ''; # triggers Set Password question
			$confirm_all = 0;
        }
    } else {
		$confirm_all = 1;
    }



    while (1) {
        if ($confirm_all) {
            print "            First name: ", BOLD, $OME_EXPER->{FirstName}    , RESET, "\n";
            print "             Last name: ", BOLD, $OME_EXPER->{LastName}     , RESET, "\n";
            print "              Username: ", BOLD, $OME_EXPER->{OMEName}      , RESET, "\n";
            print "        E-mail address: ", BOLD, $OME_EXPER->{Email}        , RESET, "\n";
            print "Default data directory: ", BOLD, $OME_EXPER->{DataDirectory}, RESET, "\n";
    
            print "\n";  # Spacing

			if (y_or_n ("Are these values correct ?",'y')) {
				last;
			} 
        }

        $confirm_all = 0;

        $OME_EXPER->{FirstName}     = confirm_default ("            First name", $OME_EXPER->{FirstName});
        $OME_EXPER->{LastName}      = confirm_default ("             Last name", $OME_EXPER->{LastName});
        $OME_EXPER->{OMEName}       = confirm_default ("              Username", $OME_EXPER->{OMEName});
        $OME_EXPER->{Email}         = confirm_default ("        E-mail address", $OME_EXPER->{Email});
        $OME_EXPER->{DataDirectory} = confirm_default ("Default data directory", $OME_EXPER->{DataDirectory});
		$OME_EXPER->{Password}      = ''; # triggers Set Password question
        print "\n";  # Spacing

        $confirm_all = 1;
    }

	my $password;
	($password, $OME_EXPER->{Password}) = get_password ("Set password for OME user ".$OME_EXPER->{OMEName}.": ", 6)
		    if ($OME_EXPER->{Password} eq '');
		    
	if (not -d $OME_EXPER->{DataDirectory}) {
        mkpath ($OME_EXPER->{DataDirectory}, 0, 0755)  # Internal croak
        	if y_or_n ('Directory "'.$OME_EXPER->{DataDirectory}.
            	'" does not exist. Do you want to create it ?', 'y');
		
    }
    
    if (not check_permissions ({user => $APACHE_USER, r => 1}, $OME_EXPER->{DataDirectory})) {
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

    my $session = OME::Session->bootstrapInstance();
    my $factory = $session->Factory();
    
    delete $OME_EXPER->{ExperimenterID};
    my $experimenter = $factory->
    	newObject('OME::SemanticType::BootstrapExperimenter', $OME_EXPER);

    my $group = $factory->
    	newObject('OME::SemanticType::BootstrapGroup', {
    		Name    => 'OME',
    		Leader  => $experimenter->attribute_id(),
    		Contact => $experimenter->attribute_id(),
    	});
    $experimenter->Group ($group->attribute_id());
    $experimenter->storeObject();
    my $experimenter_group = $factory->
    	newObject('OME::SemanticType::BootstrapExperimenterGroup', {
    		Experimenter => $experimenter->attribute_id(),
    		Group        => $group->attribute_id(),
    	});
	$experimenter_group->storeObject();
   
    push (@INSTALLATION_ATTRIBUTES,$experimenter,$group,$experimenter_group);

	my $session_key =  OME::SessionManager->generateSessionKey();
	my $userState = $factory->
		newObject('OME::UserState', {
			experimenter_id => $experimenter->attribute_id(),
			started         => 'now()',
			last_access     => 'now()',
			host            => hostname(),
			session_key     => $session_key,
		});
	$userState->storeObject();

	$OME_EXPER->{ExperimenterID} = $experimenter->attribute_id();
    $ENVIRONMENT->ome_exper($OME_EXPER);

    $factory->commitTransaction();
    $session->finishBootstrap();
    $session = undef;

    $session = $manager->createSession($session_key);
	croak "Could not create a session for the new user" unless $session;
    return ($session);
}


# configure guest access as needed

sub configure_guest_access {
    
    my $session = shift;
    my $factory = $session->Factory();
    my $guest_access = $ENVIRONMENT->allow_guest_access();
    # set to be zero by default
    $guest_access = 0 unless ($guest_access);

    print "\n"; #spacing
    my $confirm_all = 1;
    while (1) {
	if ($confirm_all) {
	    print "Enable Guest Access: ", BOLD, $guest_access? 'yes': 'no', RESET ,
	    "\n";
	    print "\n";  # Spacing
	    
	    (y_or_n ("Is this correct ?",'y')) and  last;
	}
	$confirm_all = 0;
	$guest_access = y_or_n("Enable guest access?",'n');
	$confirm_all = 1;
    }
    $ENVIRONMENT->allow_guest_access($guest_access);
    if ($ENVIRONMENT->allow_guest_access()) {
	my $guest =
	    $factory->findObject('@Experimenter',{FirstName=>'Guest',
	    LastName=>'User'});
	if (!$guest) {
	    print "Creating Guest User!";
	    my $module = $factory->findObject("OME::Module",name =>
					      'Administration');
	    my $mex =
		OME::Tasks::ModuleExecutionManager->createMEX($module,'G');
	    my $groupName = "GuestGroup_". $mex->id;
	    my $group = 
		$factory->maybeNewAttribute('Group',undef,$mex,
					    {Name =>$groupName});

	    $guest =
		$factory->maybeNewAttribute('Experimenter',
					    undef,$mex, {
						FirstName => 'Guest',
						LastName =>'User',
						Group => $group}); 

	    $group->Leader($guest);
	    $group->Contact($guest);
	    $group->storeObject();
	    
	    print "Guest is " . $guest . "\n";
	    my $bootstrap_experimenter =
		$factory->loadObject('OME::SemanticType::BootstrapExperimenter',
				     $guest->id());
	    $bootstrap_experimenter->OMEName('guest');
	    my $password = encrypt('abc123');
	    $bootstrap_experimenter->Password($password);
	    $bootstrap_experimenter->storeObject();

	    my $exp_group =
		$factory->newAttribute('ExperimenterGroup',
				       undef,$mex, 
				       { Experimenter=>$guest,
					 Group => $group});
	    $mex->group($group);

	    $mex->storeObject();
	    $session->commitTransaction();
	}
    }
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
	$OME_EXPER->{ExperimenterID}= $experimenter->id();

    $ENVIRONMENT->ome_exper($OME_EXPER);

}

# presence or absence of ACLs is governed by the presence of the super_user variable
# in the configuration.  The super_user must be present and set to an experimenter ID
# that is not the session's experimenter_id in order for ACLs to be active.
sub remove_ACLs () {
    my $factory = OME::Factory->new();
    
    eval {
		my $var = $factory->findObject('OME::Configuration::Variable',
				configuration_id => 1, name => 'super_user');
		$var->deleteObject();
    };

    $factory->commitTransaction();

    return 1;
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
                     started         => 'now()',
                     last_access     => 'now()',
                     host            => hostname()
                    });
        $factory->commitTransaction();
    } else {
        $userState->last_access('now()');
        $userState->host(hostname());
    }
    croak "Could not create userState object.  Something is probably very very wrong." unless $userState;

    print "  \\__ Getting session for user state ID=".$userState->id()."\n";
    # N.B.: In this case, we are not specifying the visible groups and users - they are all visible.
    my $session = OME::Session->instance($userState, $factory);

    croak "Could not create session from userState.  Something is probably very very wrong" unless defined $session;

    $userState->storeObject();
    $session->commitTransaction();

    return $session;
}



sub init_configuration {
    my $factory = OME::Factory->new();

    print_header "Initializing configuration";
    
	# Task blurb
	my $blurb = <<BLURB;
The installer will now finalize your OME environment by asking you for an LSID authority and to provide an initial user for you to use with the web interface and Java clients.

The LSID authority is a type of universal identification for your OME environment and it should be defined as the FQDN (fully qualified domain name) of the install machine; "myome.openmicroscopy.org" for example. If you are unsure of what to enter here ask your network/systems administrator or use the default as that will be adequate for most people.
BLURB

	print wrap("", "", $blurb);
	print "\n";  # Spacing

    my $lsid_def = $ENVIRONMENT->lsid ();
    my $lsid_authority;
    if ($lsid_def) {
		$lsid_authority = $lsid_def if
			y_or_n ("LSID Authority set to '$lsid_def'.  OK ?",'y');
    }

    unless ($lsid_authority) {
		$lsid_def = hostname() unless $lsid_def; 
	
	
		$lsid_authority = confirm_default ("LSID Authority", $lsid_def);
	}
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

    my $GUEST_ACCESS = $ENVIRONMENT->allow_guest_access();
	
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
             executor         => $DEFAULT_EXECUTOR,
	     allow_guest_access => $GUEST_ACCESS,
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
	
	my $MATLAB = $ENVIRONMENT->matlab_conf();
	my $APACHE = $ENVIRONMENT->apache_conf();
	
	my %update_configuration_variables = (
		# Make sure that the DB_VERSION and IMPORT_FORMATS is correct in case the data hash
		# was ignored due to a pre-existing configuration    
    	db_version     => $DB_VERSION,
		import_formats => $IMPORT_FORMATS,
		# Make sure there is an executor
		# executor       => $DEFAULT_EXECUTOR,
		super_user     => $session->experimenter_id(),
		template_dir   => $APACHE->{TEMPLATE_DIR},
	        allow_guest_access => $ENVIRONMENT->allow_guest_access(),
	);
	
	# This hash controls whether new configuration variables are created or not
	# if = 0, variable is expected to be already in the DB. If not, installer croaks
	# if = 1, variable is added to DB, as required.
	my %new_configuration_variables = (
		# these should already be there
		db_version     => 0,
		import_formats => 0,
		executor       => 1,
		# Note that there shouldn't ever be a superuser at this point
		super_user     => 1,
		template_dir   => 0,
	        allow_guest_access => 1,
	);
	
	foreach my $var_name (keys %update_configuration_variables) {
	    print "Trying to update $var_name\n";
    	my $var = $factory->findObject('OME::Configuration::Variable',
    									configuration_id => 1,
    									name => $var_name);
		if (not $var and not $new_configuration_variables{$var_name}) {
			croak "Could not retreive the configuration variable $var_name";
		} elsif (not $var) {
			$var = $factory->newObject ('OME::Configuration::Variable',
            {
            configuration_id => 1,
            name             => $var_name,
            value            => $update_configuration_variables {$var_name},
            });
		} else {
            $var->value ($update_configuration_variables {$var_name});
		}
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

    my $repository_url;
    if ($repository_def) {
		$repository_url = $repository_def if
			y_or_n ("OMEIS URL set to '$repository_def'.  OK ?",'y');
    }
    
    unless ($repository_url) {
    	$repository_def = "http://$hostname/cgi-bin/omeis" if $ENVIRONMENT->apache_conf->{OMEIS} and not $repository_def;
    	$repository_url = confirm_default ("What is the URL of the OME Image server (omeis) ?", $repository_def);
	}


	$ENVIRONMENT->omeis_url($repository_url);
	
    my $repository = $factory->
    newObject('OME::SemanticType::BootstrapRepository',
            {
             ImageServerURL => $repository_url,
             IsLocal        => 0,
            });
    $repository->storeObject;
    
    push (@INSTALLATION_ATTRIBUTES,$repository);

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

# These are things we can load without a MEX,
# But must include everything we need to create the initial MEX.
# Mainly, the experimenter and module definitions (Installation).
sub load_xml_bootstrap {
	my ($session) = @_;
	my @bootrap_files;
	
	# get list of files
	open (BOOTSTRAP_XML, "<", "src/xml/BootstrapXML" )
	or croak "Could not open file \"src/xml/BootstrapXML\". $!";
	
	while (<BOOTSTRAP_XML>) { 
		chomp;
	
		# Put the ABS paths in the array
		$_ = rel2abs ("src/xml/$_");
		push (@bootrap_files, $_) if /^[^#]/;
	}
	
	close (BOOTSTRAP_XML);
	
	print "Importing bootstrap XML\n";
	
	my $omeImport = OME::Tasks::OMEImport->new();
	
	# We'll call startImport 'cause we'll call finishImport at the end of this
	# This doesn't do much because no MEXes will be created since
	# There is no Original Files module at this point.
	OME::Tasks::ImportManager->startImport();
	my ($objects,$file,$originalFileAttr);

	# Import each XML file
	foreach my $filename (@bootrap_files) {
		print "  \\__ $filename ";
		eval {
			($objects,$file,$originalFileAttr) = $omeImport->importFile($filename,
				NoDuplicates           => 1,
				IgnoreAlterTableErrors => 1);
			};
		print BOLD, "[FAILURE]", RESET, ".\n"
			and print $LOGFILE "ERROR LOADING XML FILE \"$filename\" -- OUTPUT: \"$@\"\n"
			and croak "Error loading XML file \"$filename\", see $LOGFILE_NAME details."
		if $@;
	
		print BOLD, "[SUCCESS]", RESET, ".\n"
			and print $LOGFILE "SUCCESS LOADING XML FILE \"$filename\"\n";
		
		push (@INSTALLATION_ATTRIBUTES,$file);
	}
	
	# We'll call finishImport so that we can start a new one now that we have some
	# modules defined to register what's happening during import.
	# Otherwise, if we keep the old import, it will remember that we had
	# nothing defined, and won't make any MEXes.
	OME::Tasks::ImportManager->finishImport();
	
	# At this stage the system is basically ready for regular imports,
	# so we'll commit what we have so far.
	$session->commitTransaction();
	
	return $session;
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
        my ($importedObjects,$file,$originalFile);
        eval {
            ($importedObjects,$file,$originalFile) = $omeImport->importFile($filename,
                NoDuplicates           => 1,
                IgnoreAlterTableErrors => 1);
            };
        print BOLD, "[FAILURE]", RESET, ".\n"
            and print $logfile "ERROR LOADING XML FILE \"$filename\" -- OUTPUT: \"$@\"\n"
            and croak "Error loading XML file \"$filename\", see $LOGFILE_NAME details."
        if $@;
    
    	# Make the imported attributes visible to everyone by setting their 
    	# MEX's group permissions to NULL. This actually is overkill, since
    	# all I'm really after is the FilenamePattern
    	my %mexes;
    	foreach my $object ( @$importedObjects, $originalFile ) {
    		if( ( defined $object ) && ( UNIVERSAL::isa($object,"OME::SemanticType::Superclass") ) ) {
    			$mexes{ $object->module_execution_id } = $object->module_execution();
    		}
    	}
    	foreach my $mex ( values( %mexes ) ) {
			$mex->group( undef );
    		$mex->storeObject();
    	}

    	
        print BOLD, "[SUCCESS]", RESET, ".\n"
            and print $logfile "SUCCESS LOADING XML FILE \"$filename\"\n";
    }

    $session->commitTransaction();

    return $session;
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



sub add_DB_constraints {
    my ($session, $logfile) = @_;
    my $delegate = OME::Database::Delegate->getDefaultDelegate();
    my $factory = $session->Factory();
    my $dbh = $factory->obtainDBH();

    print "Adding Constraints for DBObjects\n";

    foreach my $class (@core_classes) {
        next if $class =~ /^OME::SemanticType::Bootstrap/;
        print "  \\__ $class ";
    
        # Add our constraints
        eval {
            $delegate->addForeignKeyConstraints($dbh,$class);
            $delegate->addNotNullConstraints($dbh,$class);
        };
        
        print BOLD, "[FAILURE]", RESET, ".\n"
            and print $logfile "ERROR Adding constraints to CLASS \"$class\" -- OUTPUT: \"$@\"\n"
            and croak "Error Adding constraints to class \"$class\", see $LOGFILE_NAME details."
            if $@;
    
    
        print BOLD, "[SUCCESS]", RESET, ".\n"
            and print $logfile "SUCCESS Adding constraints to CLASS \"$class\"\n";
    }
    
    print "Adding constraints for Semantic Types\n";
    my $ST_iter = $factory->findObjects ('OME::SemanticType');
    my $ST;
    while ($ST = $ST_iter->next() ) { 
        my ($name,$package) = ($ST->name(),$ST->getAttributeTypePackage());
        print "  \\__ $name ";
    
        # Add our constraints
        eval {
            $delegate->addForeignKeyConstraints($dbh,$package);
            $delegate->addNotNullConstraints($dbh,$package);
        };
        
        print BOLD, "[FAILURE]", RESET, ".\n"
            and print $logfile "ERROR Adding constraints to ST \"$name\" -- OUTPUT: \"$@\"\n"
            and croak "Error Adding constraints to ST \"$name\", see $LOGFILE_NAME details."
            if $@;
    
    
        print BOLD, "[SUCCESS]", RESET, ".\n"
            and print $logfile "SUCCESS Adding constraints to ST \"$name\"\n";
    }

    $factory->commitTransaction();

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
    #********* Set up the DB connection
    #*********
	print "Finding DB configuration in installation environment ";
    my $dbConf = $ENVIRONMENT->DB_conf();
    if ($dbConf) {
	    print BOLD, "[FOUND EXISTING]", RESET, ".\n";
    } else {
		$dbConf = $DEFAULT_DB_CONF;
	    print BOLD, "[USING DEFAULT]", RESET, ".\n";
    }

    my $confirm_all;

	print <<BLURB;
Database connection information
N.B.:  The database host must already be installed and running.
It must already be configured for accepting the connection
specified here, or a superuser connection from user "$POSTGRES_USER".
BLURB
    while (1) {
        if ($dbConf or $confirm_all) {
            print "   Database Delegate Class: ", BOLD, $dbConf->{Delegate}, RESET, "\n";
            print "             Database Name: ", BOLD, $dbConf->{Name}, RESET, "\n";
            print "                      Host: ", BOLD, $dbConf->{Host} ? $dbConf->{Host} : 'undefined (local)', RESET, "\n";
            print "                      Port: ", BOLD, $dbConf->{Port} ? $dbConf->{Port} : 'undefined (default)', RESET, "\n";
            print "Username for DB connection: ", BOLD, $dbConf->{User} ? $dbConf->{User} : 'undefined (process owner)', RESET, "\n";
#            print "                  Password: ", BOLD, $dbConf->{Password} ? $dbConf->{Password}:'undefined (not set)', RESET, "\n";
    
            print "\n";  # Spacing
            
			if (y_or_n ("Are these values correct ?","y")) {
				last;
			} 
        }

        $confirm_all = 0;
        print "Enter '\\' to set to ",BOLD,'undefined',RESET,"\n";
		$dbConf->{Delegate} = confirm_default ("   Database Delegate Class: ", $dbConf->{Delegate});
		$dbConf->{Name}     = confirm_default ("             Database Name: ", $dbConf->{Name});
		$dbConf->{Host}     = confirm_default ("                      Host: ", $dbConf->{Host});
		$dbConf->{Host} = undef if $dbConf->{Host} and $dbConf->{Host} eq '\\';
		$dbConf->{Port}     = confirm_default ("                      Port: ", $dbConf->{Port});
		$dbConf->{Port} = undef if $dbConf->{Port} and $dbConf->{Port} eq '\\';
		$dbConf->{User}     = confirm_default ("Username for DB connection: ", $dbConf->{User});
		$dbConf->{User} = undef if $dbConf->{User} and $dbConf->{User} eq '\\';
#		$dbConf->{Password} = confirm_default ("                  Password: ", $dbConf->{Password});
		$dbConf->{Password} = undef if $dbConf->{Password} and $dbConf->{Password} eq '\\';
        
        print "\n";  # Spacing

        $confirm_all = 1;
    }



	$ENVIRONMENT->DB_conf($dbConf);

    #*********
    #********* Create our super-users and bootstrap the DB
    #*********
	my $db_delegate = OME::Database::Delegate->getDefaultDelegate();

    # Drop our UID to the OME_USER
    # Unfortunately, we can't very well connect to the DB as the ome user
    # when this user doesn't exist yet, can we.
    euid($OME_UID);

    # Make sure our OME_USER is also a Postgres user
    print "Creating OME PostgreSQL SUPERUSER ($OME_USER)";
    print $LOGFILE "Creating OME PostgreSQL SUPERUSER ($OME_USER)\n";

    # Regardless of the RaiseError flag to DBI, trying to connect
    # as an unregistered user (in some versions of postgres/DBI) is fatal!
    eval {
		$retval = $db_delegate->createUser ($OME_USER,1);
    };
	print $LOGFILE "Result for creating OME_USER $OME_USER:\n".$db_delegate->errorStr()."\n"
    	unless $retval;
    while (not $retval) {
		# Regardless of the RaiseError flag to DBI, trying to connect
		# as an unregistered user (in some versions of postgres/DBI) is fatal!
		eval {
			$retval = $db_delegate->createUser ($OME_USER,1,$POSTGRES_USER);
		};
		last if $retval;
	    print $LOGFILE "Result for creating OME_USER $OME_USER as $POSTGRES_USER:\n"
	    	.$db_delegate->errorStr()."\n";

		my $old_euid = euid (scalar getpwnam ($POSTGRES_USER));

		# Regardless of the RaiseError flag to DBI, trying to connect
		# as an unregistered user (in some versions of postgres/DBI) is fatal!
		eval {
			$retval = $db_delegate->createUser ($OME_USER,1,$POSTGRES_USER);
		};
		euid ($old_euid);
	    print $LOGFILE "Result for creating OME_USER $OME_USER as $POSTGRES_USER "
	    	."After euid()\n".$db_delegate->errorStr()."\n" unless $retval;
		last;
    }
    print BOLD, "[FAILURE]", RESET, ".\n"
        and croak "Unable to create PostgreSQL superuser '$OME_USER', see $LOGFILE_NAME for details.\n".
        "Database error: ".$db_delegate->errorStr()."\n"
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Also make sure the Apache Unix user is a Postgres user
    print "Creating Apache PostgreSQL SUPERUSER ($APACHE_USER)";
    $retval = $db_delegate->createUser ($APACHE_USER,1);
    
    print BOLD, "[FAILURE]", RESET, ".\n"
    	and print $LOGFILE "Unable to create PostgreSQL superuser '$APACHE_USER'\n".
    		$db_delegate->errorStr()."\n"
        and croak "Unable to create PostgreSQL superuser '$APACHE_USER', see $LOGFILE_NAME for details."
        unless $retval;
    print BOLD, "[SUCCESS]", RESET, ".\n";

    # Also make sure the admin user is a Postgres user
    if ($ADMIN_USER) {
        print "Creating Admin PostgreSQL SUPERUSER ($ADMIN_USER)";
	    $retval = $db_delegate->createUser ($ADMIN_USER,1);
        
        print BOLD, "[FAILURE]", RESET, ".\n"
			and print $LOGFILE "Unable to create admin superuser '$ADMIN_USER'\n".
				$db_delegate->errorStr()."\n"
            and croak "Unable to create PostgreSQL superuser '$ADMIN_USER', see $LOGFILE_NAME for details."
            unless $retval;
        print BOLD, "[SUCCESS]", RESET, ".\n";
    }

    my ($configuration,$manager,$session);

    # Check the DB version
    my $db_db_version = get_db_version();
    if ($db_db_version) {
        print "From DB, got DB_Version = '$db_db_version'\n";
    }
	print $LOGFILE "Found an existing ome database, but it appears to be too old to be updated\n".
		$db_delegate->errorStr()."\n"
    and croak "Found an existing ome database, but it appears to be too old to be updated.\n".
        "You will have to upgrade it manually.  Sorry\n"
        if defined $db_db_version and $db_db_version eq '0';

    if (defined $db_db_version and $db_db_version =~ /Installing/) {
        my $db_delegate_errorStr = $db_delegate->errorStr();
        if (not defined $db_delegate_errorStr) { $db_delegate_errorStr = ''; }
        print $LOGFILE "Found an existing ome database in the middle of being updated\n".$db_delegate_errorStr."\n";
        print "Found an existing ome database, but apparently installation\n".
            "failed before it was complete.\n".
            "The existing ome database must be dropped before continuing.\n".
            "WARNING:  Do not do this if you have an existing functional database,\n".
            "          especially if you don't have a current backup!!!\n";

        my $drop_db = '';
        if (y_or_n ("Are you sure you want to proceed ?",'n')) {
            `/usr/sbin/apachectl restart > /dev/null 2> /dev/null`;
            `/usr/sbin/apache2ctl restart > /dev/null 2> /dev/null`;
            $drop_db = `sudo -u $ADMIN_USER dropdb ome`;
            if ($drop_db =~ /DROP DATABASE/) {
                print "Database dropped successfully.\n";
                # give Postgres some time to recover (try to
                # avoid subsequent "template1 in use" error)
                sleep 2;
            }
            else { print $LOGFILE "Error dropping database:\n$drop_db\n"; }
        }
        if ($drop_db !~ /DROP DATABASE/) {
            print "To drop the existing ome database manually:\n\n".
                "Restart Apache:\n".
                "> sudo apachectl restart\n".
                "Or if running Apache2:\n".
                "> sudo apache2ctl restart\n".
                "Then drop the ome database:\n".
                "> dropdb ome\n".
                "And run the installer again.\n\n";
            croak "Database must be dropped before continuing.\n";
        }
        else { undef $db_db_version; }
    }

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
        # At this point, we want to make sure there are no ACLs in place.
        # This is done by removing the super_user configuration variable
        # The super_user configuration variable will be set to whoever logs in below.
        remove_ACLs ();
		print "Getting a session manager\n";
        $manager = OME::SessionManager->new() or croak "Unable to make a new SessionManager.";
        # If we're answering 'y' to everything, we don't want to be interactive here
        if ($ENVIRONMENT->get_flag ('ANSWER_Y')) {
		    print "Getting a non-interactive session\n";
        	$session = bootstrap_session();
        } else {
		    print "Please log into OME to continue\n";
		    print "N.B.: This ome experimenter will become the OME super user (no access control)\n";
			# This will prevent any cached keys from working.
			my $key_lifetime = $OME::SessionManager::SESSION_KEY_LIFETIME;
			$OME::SessionManager::SESSION_KEY_LIFETIME = 0;
        	$session = $manager->TTYlogin() or croak "Unable to create an initial experimenter.";
			$OME::SessionManager::SESSION_KEY_LIFETIME = $key_lifetime;
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
        $db_delegate->createDatabase () or croak "Unable to create database!";
        load_schema ($LOGFILE) or croak "Unable to load the schema, see $LOGFILE_NAME for details.";
        init_configuration () or croak "Unable to initialize the configuration object.";
        $manager = OME::SessionManager->new() or croak "Unable to make a new SessionManager.";
        $session = create_experimenter ($manager) or croak "Unable to create an initial experimenter.";
        $configuration = $session->Configuration or croak "Unable to initialize the configuration object.";
        print_header "Bootstrapping Database";
        make_repository ($session);
        check_repository ($session);
        # Set the UID to whoever owns the install directory
        euid(0);
        euid((stat ('.'))[4]);
        load_xml_bootstrap ($session);
        my $install_mex = get_installation_mex ($session);
        print_header "Finalizing Database";
        load_xml_core ($session, $LOGFILE) or croak "Unable to load Core XML, see $LOGFILE_NAME for details.";
        load_analysis_core ($session, $LOGFILE)
        or croak "Unable to load analysis core, see $LOGFILE_NAME details.";
    }
    my $factory = $session->Factory ();

    configure_guest_access($session);

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



    # Grab our annotation and import modules and assign them to the
    # configuration object

    my $annotationModule = $factory->
      findObject("OME::Module",name => 'Annotation');
    $configuration->annotation_module($annotationModule);

    my $datasetImportModule = $factory->
      findObject("OME::Module",name => 'Dataset import');
    $configuration->dataset_import_module($datasetImportModule);

    my $imageImportModule = $factory->
      findObject("OME::Module",name => 'Image import');
    $configuration->image_import_module($imageImportModule);

    my $administrationModule = $factory->
      findObject("OME::Module",name => 'Administration');
    $configuration->administration_module($administrationModule);

    # Grab our import chain and assign it to the configuration object
    my $importChain = $factory->
    findObject("OME::AnalysisChain",name => 'Image server stats');
    $configuration->import_chain($importChain);

	# set up the default repository
    my $repository = $factory->findObject('@Repository',
    	ImageServerURL => $ENVIRONMENT->omeis_url());
    $configuration->repository($repository);

    # Update the Database version
    update_configuration ($session) or croak "Unable to update the configuration object.";

    # Update the Experimenter in the install environment
    save_exper_env ($session);	

    # Load all constraints
    add_DB_constraints ($session, $LOGFILE);

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
