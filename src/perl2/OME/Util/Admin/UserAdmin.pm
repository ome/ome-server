# OME/Util/Admin/UserAdmin.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#-------------------------------------------------------------------------------


package OME::Util::Admin::UserAdmin;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Getopt::Long;
use Term::ANSIColor qw(:constants);
use OME::Install::Terminal;

use OME::SessionManager;
use OME::Session;
use OME::Factory;

sub getCommands {
    return
      {
       'add' => 'addUser',
       'passwd' => 'changePassword',
       'list' => 'listUsers',
       'edit' => 'editUser',
      };
}

sub listCommands {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name <command> [<options>]

Available user-related commands are:
    add      Create a new OME user
    edit     Edit an existing OME user
    list     List existing OME users
    passwd   Change an OME user's password
CMDS
}

sub addUser {
    my $self = shift;

    my $username = "";
    my $firstname = "";
    my $lastname = "";
    my $email = "";
    my $directory = "";
    my $password = "";
    my $group_input = "";
    my $result;

    $result = GetOptions('username|u=s' => \$username,
                         'first-name|f=s' => \$firstname,
                         'last-name|l=s' => \$lastname,
                         'email|e=s' => \$email,
                         'directory|d=s' => \$directory,
                         'password|p=s' => \$password,
                         'group|g=s' => \$group_input);

    exit(1) unless $result;
    
    my $session = $self->getSession();
    my $factory = $session->Factory();
    my $ldap_conf = $session->Configuration()->ldap_conf();
    
    # correct user properties till OME system is happy
	while (1) {
		# correct user properties till ome admin-user is happy
		while (1) {
			$username    = confirm_default("Username?",$username);
			while( (not defined $username) || ($username eq '') ) {
				print BOLD,"Username must be specified.\n", RESET;
				$username    = confirm_default("Username?",$username);
			}
			
			$firstname   = confirm_default("First Name?",$firstname);
			$lastname    = confirm_default("Last Name?",$lastname);
			while( (not defined $lastname) || ($lastname eq '') ) {
				print BOLD,"Last name must be specified.\n", RESET;
				$lastname    = confirm_default("Last Name?",$lastname);
			}
			$email       = confirm_default("Email Address?",$email);
			$directory   = confirm_path   ("Data Directory?",$directory);
			$group_input = confirm_default("Group (Name or ID)?",$group_input);
			while ( (not defined $group_input) || ($group_input eq '') ) {
				print BOLD, "Each experimenter must belong to a group.\n", RESET;
				print "If you don't specify an existing group,\n".
					  "a new one with that name will be made for you.\n";
				$group_input = confirm_default("Group (Name or ID)?",$group_input);
						
			}
			
			# The user can be ldap-only or both local and ldap (though ldap takes precedence).
			# If ldap-only, they do not have a password in the DB
			# Either way, we check if they can log into ldap if we're using ldap.
			# If they can login to ldap, we ask if they want local logins as well.
			# If they do, we set their local password to the ldap password they used.
			# If ldap login fails, we ask for a DB password.
			if ($ldap_conf->{use}) {
				print "LDAP authentication is enabled.\n";
				my ($ldap_password,$crypt_passwd) = get_password   ("LDAP Password?");
				if (OME::SessionManager->authenticate_LDAP ($ldap_conf,$username,$ldap_password)) {
					print "LDAP authentication successful\n";
					if ( y_or_n ('Allow local logins as well?','n') ) {
						$password = $crypt_passwd;
					} else {
						# No local password
						$password = undef;
					}
				} else {
					print "LDAP authentication failed - setting up a local user\n";
					if (length ($ldap_password) >= 6) {
						$password = $crypt_passwd;
					} else {
						$password = get_password   ("Local Password?",6);
					}
				}
			} else {
				$password    = get_password   ("Local Password?",6);
			}
			
	
			print BOLD,"\nConfirm New User's Properties:\n",RESET;
			print      "      Username: ", BOLD, $username, RESET, "\n";
			print      "    First Name: ", BOLD, $firstname, RESET, "\n";
			print      "     Last Name: ", BOLD, $lastname, RESET, "\n";
			print      " Email Address: ", BOLD, $email, RESET, "\n";
			print      "Data Directory: ", BOLD, $directory, RESET, "\n";
			print      "         Group: ", BOLD, $group_input, RESET, "\n";
			
			y_or_n ("Are these values correct ?",'y') and last;
		}
			
        # verify the data directory 
        if (not -e $directory) {
            print "\n";
            
            if (y_or_n("The $directory directory does not exist. Create it?")) {
                unless (mkdir $directory, 0755) {
                    print STDERR "Error creating directory:\n$!\n";
                }
            }
        }

        # Verify that the username will be unique.
        my $existing = $factory->
          findObject('OME::SemanticType::BootstrapExperimenter',
                     {
                      OMEName => $username,
                     });

        if (defined $existing) {
            print STDERR "\nThe username '$username' is taken.\n\n";
            $username = '';
            redo;
        }

		# Verify that the specified group exists.
		my $group;
		my $new_group;
		my $mex = $self->getAdminMEX();
		$group = $self->getGroup ($group_input);
		unless (defined $group) {			
			# Give the user a chance to create the group.
			print "Group $group_input could not be found.\n";
			if (y_or_n ("Create Group $group_input with $username as its leader?",'n')) {
				$group = $factory->newAttribute('Group',undef,$mex, {
					Name    => $group_input,
				}) or 
					die "Could not create new group";
				$new_group = 1;
			} else {
				print STDERR "\nThe experimenter must belong to a group.\n\n";
				$group_input = '';
				redo;
			}
		}

        # The Experimenter attribute type does not contain semantic
        # elements for OME name or password, so we must still add the
        # user via the bootstrap DBObject.

        my $experimenter = $factory->newAttribute('Experimenter', undef, $mex, {
				FirstName        => $firstname,
				LastName         => $lastname,
				Email            => $email,
				Group            => $group,
		});
		unless ($experimenter) {
			$session->rollbackTransaction();
			die "Failed to create experimenter - newAttribute returned NULL";
		}
		my $bootstrap_experimenter = $factory->loadObject (
			'OME::SemanticType::BootstrapExperimenter',$experimenter->id());
		$bootstrap_experimenter->OMEName($username);
		$bootstrap_experimenter->Password($password);
		$bootstrap_experimenter->DataDirectory($directory);
		$bootstrap_experimenter->storeObject();

		if ($new_group) {
			$group->Leader ($experimenter);
			$group->Contact ($experimenter);
			$group->storeObject();
		}

		# Make sure there is an ExperimenterGroup object for this association
		my $exp_group = $factory->findObject ('@ExperimenterGroup', {
			Experimenter => $experimenter,
			Group        => $group,
		});
		unless ($exp_group) {
			$exp_group = $factory->newAttribute('ExperimenterGroup',undef,$mex, {
				Experimenter => $experimenter,
				Group        => $group,
			});
		}

		# Set the MEX's group to the experimenter's group
		# So that they can always see themsleves.
		$mex->group ($group);
		$mex->storeObject();

		$self->finishAdminMEX();
		$session->commitTransaction();
		print "Created user  #",$experimenter->id(),".\n";
		print "Created group #",$group->id(),".\n" if $new_group;
		last;
    }
}

sub addUser_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Creates a new OME user.  You can specify the information about the new
user on the command line, or type it in at the prompts.
You can also simultaneously create a new group and its leader/contact.

Options:

    -u, --username <name>
        Specify the username for the new user.

    -f, --first-name <name>
        Specify the first name for the new user.

    -l, --last-name <name>
        Specify the last name for the new user.

    -e, --email <name>
        Specify the email address for the new user.

    -d, --directory <name>
        Specify the data directory for the new user.

    -p, --password <password>
        Supplies the user's password on the command line rather than
        prompting for it.  This is pretty insecure, since the
        command-line is publicly available to other processes, but we
        still provide it for convenience.

    -g, --group (<id> | <name>)
        Specify the group for the new user.  If the group doesn't exist, a new
        one can be made with the specified user as its leader/contact.
CMDS
}

sub listUsers {
    my $self = shift;

    my $username = "";
    my $firstname = "";
    my $lastname = "";
    my $group_input = "";
    my $primary_group_input = "";
    my $tabbed = 0;
    my $result;

    $result = GetOptions('username|u=s' => \$username,
                         'first-name|f=s' => \$firstname,
                         'last-name|l=s' => \$lastname,
                         'group|g=s' => \$group_input,
                         'primary-group|p=s' => \$primary_group_input,
                         'tabbed|t' => \$tabbed);

    exit(1) unless $result;

    my $session = $self->getSession();
    my $factory = $session->Factory();

    my $criteria =
      {
       __order => ['LastName','FirstName'],
      };

    # Add to the criteria any filters specified on the command line

    $criteria->{OMEName} = $username
      if $username ne '';
    $criteria->{FirstName} = ['LIKE',"%${firstname}%"]
      if $firstname ne '';
    $criteria->{LastName} = ['LIKE',"%${lastname}%"]
      if $lastname ne '';
    
    my $group;
    if ($group_input ne '') {
    	$group = $self->getGroup ($group_input);
		unless (defined $group) {
			print "Group $group_input could not be found.\n";
			exit 1;
		}
	    $criteria->{'ExperimenterGroupList.Group'} = $group;
    }
    
    my $primary_group;
    if ($primary_group_input ne '') {
    	$group = $self->getGroup ($primary_group_input);
		unless (defined $group) {
			print "Group $primary_group_input could not be found.\n";
			exit 1;
		}
	    $criteria->{Group} = $group;
    }

    my @users = $factory->
      findObjects('OME::SemanticType::BootstrapExperimenter',
                  $criteria);

    if ($tabbed) {
        foreach my $user (@users) {
            print join("\t",
                       $user->id(),
                       $user->OMEName(),
                       $user->FirstName(),
                       $user->LastName(),
                       $user->Email()),
                  "\n";
        }
    } else {
        my $max_id_len = 3;
        
        # set the ID field length to the width of the longest ID
        foreach my $user (@users) {
            $max_id_len = length($user->id()) if (length($user->id()) > $max_id_len);
        }

        my $username_len = 8;
        my $name_len = 20;
		my $email_len = 20;
		my $directory_len = 20;
		my $group_len = 3;
		
        printf "%-*.*s %-*.*s %-*.*s %-*.*s %-*.*s %-*.*s\n",
          $max_id_len, $max_id_len, "ID",
          $group_len, $group_len, "GID",
          $username_len, $username_len, "Username",
          $name_len, $name_len, "Name",
          $email_len, $email_len, "Email",
          $directory_len, $directory_len, "Data Directory";

        print
          "-" x $max_id_len, " ",
          "-" x $group_len, " ",
          "-" x $username_len, " ",
          "-" x $name_len, " ",
          "-" x $email_len, " ",
          "-" x $directory_len, "\n";
        
        my ($OMEName, $ID, $GID, $FirstName, $LastName, $Email, $DataDirectory);
        

        foreach my $user (@users) {
        	
        	$OMEName = $user->OMEName();
        	$OMEName = '' unless defined $OMEName;
			$ID = $user->id();
        	$ID = '' unless defined $ID;
			$GID = defined $user->Group() ? $user->Group()->id() : '';
        	$FirstName = $user->FirstName();
        	$FirstName = '' unless defined $FirstName;
        	$LastName = $user->LastName();
        	$LastName = '' unless defined $LastName;
        	$Email = $user->Email();
        	$Email = '' unless defined $Email;
	       	$DataDirectory = $user->DataDirectory();
        	$DataDirectory = '' unless defined $DataDirectory;
        	
        	printf "%-*.*s %-*.*s %-*.*s %-*.*s %-*.*s %-*.*s\n",
              $max_id_len, $max_id_len, $ID,
          	  $group_len, $group_len, $GID,
          	  $username_len, $username_len, $OMEName,
              $name_len, $name_len, ($FirstName. " ". $LastName),
              $email_len, $email_len, $Email,
          	  $directory_len, $directory_len, $DataDirectory;
        }
    }
}

sub listUsers_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Lists all of the users matching the specified criteria.  Displays the
user ID, username, and full name for any that are found.

Filter options:
    -g, --group (<id> | <name>)
        Lists only those users who belong to the specified group.

    -p, --primary-group (<id> | <name>)
        Lists only those users who's primary group is the specified group.

    -u, --username <name>
        Lists the user which has the given username.

    -f, --first-name <name>
        Lists the users with a matching first name.  You can specify a
        partial name; any users containing the specified string will
        be returned.

    -l, --last-name <name>
        Lists the users with a matching last name.  You can specify a
        partial name; any users containing the specified string will
        be returned.

Output options:
    -t, --tabbed
        Causes the users to be printed with no headers, in tab-separated
        form, suitable for automatic parsing.  The output columns will
        be, in order:
            ID, Username, FirstName, LastName, Email
CMDS
}

sub changePassword {
    my $self = shift;

    my $user_input = "";
    my $password = '';
    my $ldap_only;
    my $result;

    $result = GetOptions(
    	'user|u=s' => \$user_input,
		'password|p=s' => \$password,
		'ldap|l' => \$ldap_only,
	);

    exit(1) unless $result;

    if ($user_input eq '') {
        print "You must specify either a user ID or username.\n";
        exit 1;
    }

    my $session = $self->getSession();
    my $factory = $session->Factory();

    my $user = $self->getExperimenter ($user_input);
    if (!defined $user) {
        print "The specified user \"$user_input\" does not exist.\n";
        exit 1;
    }

	if ($ldap_only) {
		$password = undef;
	} elsif (length ($password) < 6) {
    	$password = get_password("Password? ",6);
    } else { # Command-line password has to be encrypted before storing in DB
    	$password = encrypt($password);
    }

	if ($password) {
		print "Changing password for ",$user->FirstName()," ",$user->LastName(),"\n";
	} else {
		print "Un-setting password, making ",$user->FirstName()," ",$user->LastName()," LDAP-only\n";
	}

    eval {
        $user->Password($password);
        $user->storeObject();
        $session->commitTransaction();
    };

    if ($@) {
        print "There was an error changing the password:\n$@\n";
        exit 1;
    } else {
        print "Password successfully changed.\n";
    }
}

sub changePassword_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Changes the password for an existing OME user.  Prompts for the new
password if it is not specific on the command line via the -p/--pasword
option, or if its too short.

Can be used to disable local login for users (-l/--ldap option).

Note that you might first be prompted to log into OME as an
administrative user.  This is *not* the user whose password you want
to change.

This utility only changes the local password for local authentication against the OME DB.
If LDAP authentication is being used, this will not change the passowrd on the LDAP server!
To make the user ldap-only or disable local login, use the -l option.
To enable or change local authentication, assign a local password interactively or with -p

Options:
    -u, --user (<username> | <ID>)
        Specify the user by their username or database ID.

    -p, --password <password>
        Supplies the new password on the command line rather than
        prompting for it.  This is insecure, since the
        command-line is publicly available to other processes.

    -l, --ldap
        Supplying the -l option un-sets the local password, making the user LDAP-only.
CMDS
}
 
sub editUser {
    my $self = shift;

    my $user_input = '';
    my $firstname = '';
    my $lastname = '';
    my $email = '';
    my $directory = '';
    my $group_input = '';
   	my $group;
   	
   	my $result;
   	my $interactive_mode;

    $result = GetOptions('user|u=s' => \$user_input,
                         'first-name|f=s' => \$firstname,
                         'last-name|l=s' => \$lastname,
                         'email|e=s' => \$email,
                         'directory|d=s' => \$directory,
                         'group|g=s' => \$group_input);
	
    exit(1) unless $result;

    my $session = $self->getSession();
    my $factory = $session->Factory();
    my $user;

	# Solicit Username or figure it out based on command-line args
    if ($user_input eq '') {
    	$interactive_mode = 1;
    	$user_input = confirm_default("Username or ID?", "nemo");
    }

	$user = $self->getExperimenter ($user_input);

    if (!defined $user) {
        print "The specified user \"$user_input\" does not exist.\n";
        exit 1;
    }
    
	if ($interactive_mode) {
		# load the selected user's current properties
		$firstname = $user->FirstName()
		  if $firstname eq '';
		
		$lastname = $user->LastName()
		  if $lastname eq '';
	
		$email = $user->Email()
		  if $email eq '';
	
		$directory = $user->DataDirectory()
		  if $directory eq '';
		  
		$group_input = $user->Group()->Name()
		  if $group_input eq '';
      
      	# let user type in new properties until he is satisfied
		while (1) {
			$firstname   = confirm_default("First Name?", $firstname);
			$lastname    = confirm_default("Last Name?", $lastname);
			while( (not defined $lastname) || ($lastname eq '') ) {
				print BOLD,"Last name must be specified.\n", RESET;
				$lastname    = confirm_default("Last Name?",$lastname);
			}
			$email       = confirm_default("Email Address?", $email);
			$directory   = confirm_default("Data Directory?", $directory);
			
			$group_input = confirm_default("Group (Name or ID)?",$group_input);
			while ( (not defined $group_input) || ($group_input eq '') ) {
				print BOLD, "Each experimenter must belong to a group.\n", RESET;
				print "If you don't specify an existing group,\n".
					  "a new one with that name will be made for you.\n";
				$group_input = confirm_default("Group (Name or ID)?",$group_input);
						
			}
			
			print BOLD,"\nConfirm User's New Properties:\n",RESET;
			print      "      Username: ", BOLD, $user->OMEName(), RESET, "\n";
			print      "    First Name: ", BOLD, $firstname, RESET, "\n";
			print      "     Last Name: ", BOLD, $lastname, RESET, "\n";
			print      " Email Address: ", BOLD, $email, RESET, "\n";
			print      "Data Directory: ", BOLD, $directory, RESET, "\n";
			print      "         Group: ", BOLD, $group_input, RESET, "\n";
			
			y_or_n ("Are these values correct ?",'y') and last;
		}
	}
	
	# idiot traps, Those users are trying to kill us.
	if (not -e $directory and $directory ne '') {
		if (y_or_n("The $directory directory does not exist. Create it?") ) {
			unless (mkdir $directory, 0755) {
				print "Error creating directory:\n$!\n";
				exit 1;
			}
		}
	 }

	 # Verify that the specified group exists.
	if ($group_input ne '') {
		$group = $self->getGroup ($group_input);
		unless (defined $group) {
			print "Group $group_input could not be found.\n";
			exit 1;
		}
	}
		
	$user->FirstName($firstname)
	  if $firstname ne '';
	
    $user->LastName($lastname)
      if $lastname ne '';

    $user->Email($email)
      if $email ne '';

    $user->DataDirectory($directory)
      if $directory ne '';

    $user->Group($group)
      if defined $group;

    eval {
        $user->storeObject();
        $session->commitTransaction();
    };

    if ($@) {
        print STDERR "Error editing user:\n$@\n";
        exit 1;
    }
}

sub editUser_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Edits an existing OME user. 

If you don't want to use this utility in interactive mode, specify the user with the 
-u flag and use the edit options.

The edit is performed atomically; if there is any database error or 
inconsistency in the data, none of the other (possibly valid) changes are 
saved.

Options:
    -u, --user (<user ID> | <user name>)
        Specify the user by their username or database ID.

    -f, --first-name <name>
        Change the user's first name.

    -l, --last-name <name>
        Change the user's last name.

    -e, --email <email address>
        Change the user's email address.

    -d, --directory <path>
        Change the user's data directory.

    -g, --group (<id> | <name>)
        Change the user's main group.
CMDS
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

