# OME/Util/Admin/Configure.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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


#-------------------------------------------------------------------------------
# Written by:    Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------

package OME::Util::Admin::Configure;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use English;
use Getopt::Long;
use Text::Wrap;
use Term::ANSIColor qw(:constants);

use OME::Session;
use OME::Factory;
use OME::SessionManager;

use OME::Install::Util; # for euid()
use OME::Install::Terminal;
use OME::Install::Environment;

use base qw(OME::Util::Commands);

sub getCommands {
    return
      {
       'configure'     => 'configure',
      };
}

sub configure {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
	my $env_file = "/etc/ome-install.store";
	
	# idiot nets
	croak "You must run $script $command_name with uid=0 (root). " if (euid() ne 0);
	croak "Environment file '$env_file' does not exist.\n".
		  "Call $script $command_name with the -f flag to specify it. " if (not -e $env_file);

	my $environment = initialize OME::Install::Environment;
	my $OME_UID = getpwnam($environment->user()) or croak "Could not get OME user from environment\n";
	euid($OME_UID);
	
	my $session = $self->getSession();
	my $factory = $session->Factory();
	
	# Parse our command line options
	my ($db,$user,$pass,$host,$port,$class);
	my ($lsid);
	my ($templates);
	my ($matlab_user, $m_files_path);
	my ($max_local_workers);
	GetOptions('d|database=s' => \$db,
   			   'u|user=s'     => \$user,
   			   'h|host=s'     => \$host,
   			   'p|port=i'     => \$port,
   			   #'P|pass=s'    => \$pass,
   			   'c|class=s'    => \$class,
   	#		   'omeis_url=s'    => \$omeis_repository_url,
   			   'lsid_url=s'     => \$lsid,
   			   'templates=s'    => \$templates,
   			   'matlab-user=s'  => \$matlab_user,
   			   'm-files-path=s' => \$m_files_path,
   			   'max-local-workers=s' => \$max_local_workers);
   			   
	my $interactive = 0;
	$interactive = 1 if ($db or $user or $host or $port or $class or $lsid or $templates or $matlab_user or $m_files_path or $max_local_workers);

	print_header("OME Configure");
	my $blurb = <<BLURB;
This utility allows you to modify configuration variables that are critical to your OME installation. Incorrect configuration decisions are guaranteed to make OME unusable. In contrast to the installer, this tool doesn't test user inputs for logical consistency. It ought to be used very rarely and only by advanced OME system administrators. Fortunately, these settings are reversable -- we strongly recommend that you take a note of the current configuration and revert back to that configuration if your changes have ill effects. Read ome help admin configure to learn more.
BLURB
	print wrap("", "", $blurb);
	print "\n";  # Spacing


	# Get the environment and defaults
	my $defaultDBconf = {
		Delegate => 'OME::Database::PostgresDelegate',
		User     => undef,
		Password => undef,
		Host     => undef,
		Port     => undef,
		Name     => 'ome',
	};
	
	my $dbConf = $environment->DB_conf();
	$dbConf = $defaultDBconf unless $dbConf;

	$dbConf->{Delegate} = $class if $class;
	$dbConf->{User}     = $user  if $user;
	$dbConf->{Password} = $pass  if $pass;
	$dbConf->{Host}     = $host  if $host;
	$dbConf->{Port}     = $port  if $port;
	$dbConf->{Name}     = $db    if $db;
	
    my $confirm_all=1;

    while (1) {
        if ($dbConf or $confirm_all) {
        	print BOLD,"Database Configuration:\n",RESET;
            print "   Database Delegate Class: ", BOLD, $dbConf->{Delegate}, RESET, "\n";
            print "             Database Name: ", BOLD, $dbConf->{Name}, RESET, "\n";
            print "                      Host: ", BOLD, $dbConf->{Host} ? $dbConf->{Host} : 'undefined (local)', RESET, "\n";
            print "                      Port: ", BOLD, $dbConf->{Port} ? $dbConf->{Port} : 'undefined (default)', RESET, "\n";
            print "Username for DB connection: ", BOLD, $dbConf->{User} ? $dbConf->{User} : 'undefined (process owner)', RESET, "\n";
#            print "                  Password: ", BOLD, $dbConf->{Password} ? $dbConf->{Password}:'undefined (not set)', RESET, "\n";
            print "\n";  # Spacing
            
            # Don't be interactive if we got any parameters
			last if ($interactive);
			if (y_or_n ("Are these values correct ?","y")) {
				print "\n";  # Spacing
				last;
			} 
        }

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
    
	
	my $conf = $session->Configuration() ;
	$lsid = $environment->lsid ($lsid) or $lsid = $conf->lsid_authority() or
		croak "Could not get LSID url from environment or configuration\n";

	my $omeis_repository = $conf->repository();
	my $omeis_repository_url = $omeis_repository->ImageServerURL();
	
    while (1) {
        if ($confirm_all) {
    		print BOLD,"OME Server URLs: \n",RESET;
			print      "    OMEIS Server: ", BOLD, $omeis_repository_url, RESET, "\n";
			print      "  LSID Authority: ", BOLD, $lsid, RESET, "\n";
            print "\n";  # Spacing

			# Don't be interactive if we got any parameters
			last if ($interactive);
			if (y_or_n ("Are these values correct ?","y")) {
				print "\n";  # Spacing
				last;
			}
			$omeis_repository_url = confirm_default ("OMEIS Server", $omeis_repository_url);

			my $new_repository =  $factory->findObject ('OME::SemanticType::BootstrapRepository', ImageServerURL => $omeis_repository_url);
			if ($new_repository) {
				$omeis_repository = $new_repository;
				$conf->repository ($omeis_repository);
			} else {
				my $register_new = confirm_default ('The specified OMEIS URL is not a known repository. '.
					'You may either register a new repository (R) or change the hostname of the current default repository (C)',
					'R: register new OMEIS');
				if (uc ($register_new) eq 'C') {
					$omeis_repository->ImageServerURL ($omeis_repository_url);
					$omeis_repository->storeObject();
				} else {
					my $admin_mex = $self->getAdminMEX();
					$new_repository = $factory->newAttribute('Repository',undef,$admin_mex,{
						ImageServerURL => $omeis_repository_url,
						IsLocal        => 0,
            		});
					$new_repository->storeObject;
					
					# We need a OME::SemanticType::BootstrapRepository object instead of the attribute.
					$omeis_repository =  $factory->findObject ('OME::SemanticType::BootstrapRepository', ImageServerURL => $omeis_repository_url);
					die "For some reason, the new repository was not created:  New repository object not found in DB." unless $omeis_repository;
					$conf->repository ($omeis_repository);
				}
			}
			$lsid = confirm_default ("LSID Authority", $lsid);
		}
	}
	# Make sure we finish the admin mex in case we started one (no error if none started)
	$self->finishAdminMEX();

    my $apacheConf = $environment->apache_conf() or croak "Could not get Apache Configuration from environment\n";
    my $OME_BASE_DIR = $environment->base_dir() or croak "Could not get base installation directory from environment\n";
    
	$apacheConf->{TEMPLATE_DIR} = $templates if $templates; 

    while (1) {
        if ($confirm_all) {
    		print BOLD,"Web-UI HTML Templates: \n",RESET;
			print      "  Developer configuration: ", BOLD, $apacheConf->{TEMPLATE_DEV_CONF} ?'yes':'no', RESET, "\n";
			print      " HTML Templates directory: ", BOLD, $apacheConf->{TEMPLATE_DIR}, RESET, "\n";
			print "\n";  # Spacing
			
			# Don't be interactive if we got any parameters
			last if ($interactive);
			if (y_or_n ("Are these values correct ?","y")) {
				print "\n";  # Spacing
				last;
			}
	
			if (y_or_n("Use HTML Templates configuration for developers ?", $apacheConf->{TEMPLATE_DEV_CONF} ? 'y':'n')) {
				 $apacheConf->{TEMPLATE_DEV_CONF} = 1;
			} else {
				 $apacheConf->{TEMPLATE_DEV_CONF} = 0;
				 $apacheConf->{TEMPLATE_DIR} = $OME_BASE_DIR."/html/Templates";
			}
			$apacheConf->{TEMPLATE_DIR} = confirm_path ('Look for HTML Templates in:', $apacheConf->{TEMPLATE_DIR});	
			
        }
    }
    
    my $matlabConf = $environment->matlab_conf() or croak "Could not get MATLAB Configuration from environment\n";
    if (($matlab_user or $m_files_path) and not $matlabConf->{INSTALL}) {
		croak "MATLAB Perl API is not installed therefore it can't be configured.\n";
	}
	
    $matlabConf->{USER} =  $matlab_user if $matlab_user;
    $matlabConf->{MATLAB_SRC} = $m_files_path if $m_files_path;
    
    while (1) {
        if ($confirm_all) {
			print BOLD,"MATLAB Perl API configuration:\n",RESET;
			print "      MATLAB Perl API not installed.\n" and last unless $matlabConf->{INSTALL} ;
			
			print "              MATLAB User: ", BOLD, $matlabConf->{USER}, RESET, "\n";
			print "              MATLAB Path: ", BOLD, UNDERLINE, $matlabConf->{MATLAB_INST}, RESET, "\n";
			print "              MATLAB Exec: ", BOLD, UNDERLINE, $matlabConf->{EXEC}, RESET, "\n";
			print "        MATLAB Exec Flags: ", BOLD, UNDERLINE, $matlabConf->{EXEC_FLAGS}, RESET, "\n";
			print "   Config MATLAB for dev?: ", BOLD, $matlabConf->{AS_DEV} ? 'yes':'no', RESET, "\n";
			print "     MATLAB .m files Path: ", BOLD, $matlabConf->{MATLAB_SRC},  RESET, "\n";
			print "\n";  # Spacing
			
			# Don't be interactive if we got any parameters
			last if ($interactive);
			if (y_or_n ("Are these values correct ?","y")) {
				print "\n";  # Spacing
				last;
			}
			
			$matlabConf->{USER}  = confirm_default ("The user which MATLAB should be run under", $matlabConf->{USER});
			
			if (y_or_n ("Configure MATLAB Perl API for developers?")){
				$matlabConf->{AS_DEV} = 1;
				$matlabConf->{MATLAB_SRC} = "?";
			} else {
				$matlabConf->{AS_DEV} = 0;
				$matlabConf->{MATLAB_SRC} = "$OME_BASE_DIR/matlab";
			}
			$matlabConf->{MATLAB_SRC} = confirm_path ("Path to OME's matlab src files", $matlabConf->{MATLAB_SRC} );
				
		}
	}
	
    # Update configuration variables
	my %update_configuration_variables = (
		lsid_authority => $lsid,
#		super_user     => $session->experimenter_id(),
		template_dir   => $apacheConf->{TEMPLATE_DIR},
	);
	
	foreach my $var_name (keys %update_configuration_variables) {
    	my $var = $factory->findObject('OME::Configuration::Variable',
    									configuration_id => 1,
    									name => $var_name);
		if (not $var) {
			croak "Could not retreive the configuration variable $var_name";
		} else {
            $var->value ($update_configuration_variables {$var_name});
		}
	    $var->storeObject();
	}
	
    $factory->commitTransaction();
    
    euid(0);
	$environment->DB_conf($dbConf);
	$environment->omeis_url ($omeis_repository_url);
	$environment->lsid ($lsid);
	$environment->apache_conf($apacheConf);
 	$environment->matlab_conf($matlabConf);
	$environment->store_to();
}

sub configure_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

This utility allows you to modify configuration variables that are critical to
your OME installation. Exercise care when using it. It is a good practise to note
the current configuration so you can revert to it if your changes have ill-effects.

N.B: This doesn't move the OME db, it just changes the pointer to it.

Options to configure the database connection:
     -d, --database
        Database name.
     -u, --user    
        User name to connect as.
     -h, --host 
        Host name of the database server.
     -p, --port 
        port number to use for connection.
     -c, --class 
        Delegate class to use for connection (default OME::Database::PostgresDelegate).

N.B: This command only modifies the URL to your OMEIS. The OMEIS at the new url
MUST contain exactly the same data as the OMEIS at the old URL. If you want to
move OMEIS to another server, you must compile + install the omeis executable
under Apache cgi-bin and copy the Files / Pixels directory structure manually.
Changing the LSID authority is an experimental feature. Attributes that were
issued with the previous LSID authority will not be updated when the LISD
authority is renamed.

Options to configure OME server URLS:
	--omeis_url
		FQDN of your OMEIS Authority
	--lsid_url 
		FQDN of your LSID Authority
		
N.B: This does not move, create, or verify Web-UI's HTML templates. If the
templates structure is mutilated or doesn't exist in the directory pointed by
this configuration variable, the Web-UI will be severely broken.

Options to configure Web-UI's HTML templates:
     --templates-path 
        Path to HTML templates used by Web-UI
        
N.B: You cannot use this tool to modify settings pursuant to your MATLAB
installation. For example, if you installed a new version of MATLAB you must
re-run the OME installer in order that the OME/MATLAB connector be properly compiled.
If the user specified here is not licensed to run MATLAB then the analysis
engine will be unable to execute OME MATLAB modules. The m-files-path is 
recursively searched by the MATLAB connector to find .m files referenced in
the XML MATLAB analysis module definitions.

Options to configure MATLAB connection:
     --matlab-user
        System user that islicensed to run MATLAB.
     --m-files-path
        Path searched by MATLAB Handler for relevent .m interpreted scripts.

N.B: The analysis engine is used every time images are imported into OME.
Configuring the Analysis Engine for anything other than "Unthreaded" module
execution is experimental. Configure local worker processes only if OME
with distributed analysis engine is installed on your network. Read for more info:
http://cvs.openmicroscopy.org.uk/tiki/tiki-index.php?page=Distributed+Analysis+Engine

Options to configure Analysis Engine connection:
     --max-local-workers
        How many local worker processes should be allowed to execute on this machine 
CMDS
}
1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

