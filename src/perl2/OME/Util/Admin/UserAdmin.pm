# OME/Util/UserAdmin.pm

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


package OME::Util::UserAdmin;

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

    my $help = 0;
    my $username = "";
    my $firstname = "";
    my $lastname = "";
    my $email = "";
    my $directory = "";
    my $password = "";
    my $group_id = "";
    my $result;

    $result = GetOptions('help|h' => \$help,
                         'username|u=s' => \$username,
                         'first-name|f=s' => \$firstname,
                         'last-name|l=s' => \$lastname,
                         'email|e=s' => \$email,
                         'directory|d=s' => \$directory,
                         'password|p=s' => \$password,
                         'group-id|g=i' => \$group_id);

    exit(1) unless $result;

    if ($help) {
        $self->addUser_help();
        exit;
    }

    my $session = $self->getSession();
    my $factory = $session->Factory();
    
    # correct user properties till OME system is happy
	while (1) {
		# correct user properties till ome admin-user is happy
		while (1) {
			$username  = confirm_default("Username?",$username);
			$firstname = confirm_default("First Name?",$firstname);
			$lastname  = confirm_default("Last Name?",$lastname);
			$email     = confirm_default("Email Address?",$email);
			$directory = confirm_path   ("Data Directory?",$directory);
			$group_id  = confirm_default("Group ID?",$group_id);
			$password  = get_password   ("Password?",6);
	
			print BOLD,"\nConfirm New User's Properties:\n",RESET;
			print      "      Username: ", BOLD, $username, RESET, "\n";
			print      "    First Name: ", BOLD, $firstname, RESET, "\n";
			print      "     Last Name: ", BOLD, $lastname, RESET, "\n";
			print      " Email Address: ", BOLD, $email, RESET, "\n";
			print      "Data Directory: ", BOLD, $directory, RESET, "\n";
			print      "      Group ID: ", BOLD, $group_id, RESET, "\n";
			
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
		if ($group_id !~ /^[0-9]+$/) {
            print STDERR "\nThe group ID must be a number.\n\n";
            $group_id = '';
            redo;
        }

        my $group = $factory->loadAttribute('Group',$group_id);
        unless (defined $group) {
            print STDERR "\nThe ID $group_id does not specify an existing group.\n\n";
            $group_id = '';
            redo;
        }

        # The Experimenter attribute type does not contain semantic
        # elements for OME name or password, so we must still add the
        # user via the bootstrap DBObject.

        my $experimenter = $factory->
          newObject('OME::SemanticType::BootstrapExperimenter',
                    {
                     OMEName       => $username,
                     FirstName     => $firstname,
                     LastName      => $lastname,
                     Email         => $email,
                     Password      => $password,
                     DataDirectory => $directory,
                     Group         => $group_id,
                    });
		$session->commitTransaction();
		
        if (defined $experimenter) {
            print "Created user #",$experimenter->id(),".\n";
            last;
        } else {
            print STDERR "Error creating user.\n";
            last;
        }
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

    -g, --group-id <id>
        Specify the group for the new user.  You'll need to have already
        looked up the ID for the new group with the "groups list"
        command.
CMDS
}

sub listUsers {
    my $self = shift;

    my $help = 0;
    my $username = "";
    my $firstname = "";
    my $lastname = "";
    my $group_id = "";
    my $tabbed = 0;
    my $result;

    $result = GetOptions('help|h' => \$help,
                         'username|u=s' => \$username,
                         'first-name|f=s' => \$firstname,
                         'last-name|l=s' => \$lastname,
                         'group-id|g=i' => \$group_id,
                         'tabbed|t' => \$tabbed);

    exit(1) unless $result;

    if ($help) {
        $self->listUsers_help();
        exit;
    }

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
    $criteria->{Group} = $group_id
      if $group_id ne '';

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
			$GID = $user->Group()->{__id};
        	$GID = '' unless defined $OMEName;
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
    -g, --group-id <id>
        Lists only those users which belong to the specified group.  The
        group is specified by its group ID.

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

    my $help = 0;
    my $user_id = "";
    my $username = "";
    my $password = "";
    my $result;

    $result = GetOptions('help|h' => \$help,
                         'id|i=i' => \$user_id,
                         'username|u=s' => \$username,
                         'password|p=s' => \$password);

    exit(1) unless $result;

    if ($help) {
        $self->listUsers_help();
        exit;
    }

    if ($username ne '' && $user_id ne '') {
        print "You cannot specify both a user ID and username.\n";
        exit 1;
    } elsif ($username eq '' && $user_id eq '') {
        print "You must specify either a user ID or username.\n";
        exit 1;
    }

    my $session = $self->getSession();
    my $factory = $session->Factory();

    my $user;

    if ($username ne '') {
        $user = $factory->
          findObject('OME::SemanticType::BootstrapExperimenter',
                     {
                      OMEName => $username,
                     });
    } else {
        $user = $factory->
          loadObject('OME::SemanticType::BootstrapExperimenter',
                     $user_id);
    }

    if (!defined $user) {
        print "The specified user does not exist.\n";
        exit 1;
    }

    print "Changing password for ",
      $user->FirstName()," ",$user->LastName(),"\n";

    my $new_password = get_password("Password? ",6);

    eval {
        $user->Password($new_password);
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
password if it is not specific on the command line via the --pasword
option.  Note that you must specify exactly one of the -i or -u
options.

Note that you might first be prompted to log into OME as an
administrative user.  This is *not* the user whose password you want
to change.

Options:
    -i, --id <user ID>
        Specify the user by their database ID.  The <user ID>
        parameter must be a positive integer, and can be found via the
        "users list" command.

    -u, --username <username>
        Specify the user by their username.

    -p, --password <password>
        Supplies the new password on the command line rather than
        prompting for it.  This is pretty insecure, since the
        command-line is publicly available to other processes, but we
        still provide it for convenience.
CMDS
}
 
sub editUser {
    my $self = shift;

    my $help = 0;
    my $user_id = "";
    my $username = "";
    my $firstname = "";
    my $lastname = "";
    my $email = "";
    my $directory = "";
    my $group_id = "";
   	my $group;
   	
   	my $result;
   	my $interactive_mode;

    $result = GetOptions('help|h' => \$help,
                         'id|i=i' => \$user_id,
                         'username|u=s' => \$username,
                         'first-name|f=s' => \$firstname,
                         'last-name|l=s' => \$lastname,
                         'email|e=s' => \$email,
                         'directory|d=s' => \$directory,
                         'group-id|g=i' => \$group_id);
	
    exit(1) unless $result;

    if ($help) {
        $self->editUser_help();
        exit;
    }


    my $session = $self->getSession();
    my $factory = $session->Factory();
    my $user;

	# Solicit Username or figure it out based on command-line args
    if ($username ne '' && $user_id ne '') {
        print "You cannot specify both a user ID and username.\n";
        exit 1;
    } elsif ($username eq '' && $user_id eq '') {
    	$interactive_mode = 1;
    	$username = confirm_default("Username?", "nemo");
    }

	# Use the specified username or userid to find the user in the database
    if ($username ne '')  {
        $user = $factory->
          findObject('OME::SemanticType::BootstrapExperimenter',
                     {
                      OMEName => $username,
                     });
    } else {
        $user = $factory->
          loadObject('OME::SemanticType::BootstrapExperimenter',
                     $user_id);
    }

    if (!defined $user) {
        print "The specified user does not exist.\n";
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
		  
		$group_id = $user->Group()->{__id}
		  if $group_id eq '';
      
      	# let user type in new properties until he is satisfied
		while (1) {
			$firstname = confirm_default("First Name?", $firstname);
			$lastname  = confirm_default("Last Name?", $lastname);
			$email     = confirm_default("Email Address?", $email);
			$directory = confirm_default("Data Directory?", $directory);
			$group_id  = confirm_default("Group ID?", $group_id);
			
			print BOLD,"\nConfirm User's New Properties:\n",RESET;
			print      "      Username: ", BOLD, $username, RESET, "\n";
			print      "    First Name: ", BOLD, $firstname, RESET, "\n";
			print      "     Last Name: ", BOLD, $lastname, RESET, "\n";
			print      " Email Address: ", BOLD, $email, RESET, "\n";
			print      "Data Directory: ", BOLD, $directory, RESET, "\n";
			print      "      Group ID: ", BOLD, $group_id, RESET, "\n";
			
			y_or_n ("Are these values correct ?",'y') and last;
		}
	}
	
	# idiot traps, Those users are trying to kill us.
	if (not -e $directory and $directory ne "") {
		if (y_or_n("The $directory directory does not exist. Create it?") ) {
			unless (mkdir $directory, 0755) {
				print "Error creating directory:\n$!\n";
				exit 1;
			}
		}
	 }

	 # Verify that the specified group exists.
	 if ($group_id !~ /^[0-9]+$/) {
		print "\nThe group ID must be a number.\n\n";
		$group_id = '';
		exit 1;
     }
        
	 if ($group_id ne '') {
	 	$group = $factory->loadAttribute('Group',$group_id);
	 	unless (defined $group) {
	 		print "The ID $group_id does not specify an existing group.\n";
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
-i or -u flags and use the edit options.

The edit is performed atomically; if there is any database error or 
inconsistency in the data, none of the other (possibly valid) changes are 
saved.

Options:
    -i, --id <user ID>
        Specify the user by their database ID.  The <user ID>
        parameter must be a positive integer, and can be found via the
        "users list" command.

    -u, --username <username>
        Specify the user by their username.

    -f, --first-name <name>
        Change the user's first name.

    -l, --last-name <name>
        Change the user's last name.

    -e, --email <email address>
        Change the user's email address.

    -d, --directory <path>
        Change the user's data directory.

    -g, --group-id <id>
        Change the user's main group.  You'll need to have already
        looked up the ID for the group with the "groups list" command.
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

