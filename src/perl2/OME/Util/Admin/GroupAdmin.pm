# OME/Util/GroupAdmin.pm

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


package OME::Util::GroupAdmin;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Getopt::Long;
use OME::Install::Terminal;

use OME::SessionManager;
use OME::Session;
use OME::Factory;

sub getCommands {
    return
      {
       'add' => 'addGroup',
       'list' => 'listGroup',
       'edit' => 'editGroup',
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

Available group-related commands are:
    add      Create a new OME group
    edit     Edit an existing OME group
    list     List existing OME group
CMDS
}

sub addGroup {
    my $self = shift;

    my $help = 0;
    my $batch = 0;
    my $name = "";
    my $leader_input = "";
    my $contact_input = "";
    my $result;

    $result = GetOptions('help|h' => \$help,
                         'batch|b' => \$batch,
                         'name|n=s' => \$name,
                         'leader|l=s' => \$leader_input,
                         'contact|c=s' => \$contact_input);

    exit(1) unless $result;

    if ($help) {
        $self->addUser_help();
        exit;
    }

    if ($batch &&
        ($name ne '' ||
         $leader_input ne '' ||
         $contact_input ne '')) {
        print <<"ERROR";
Error:  --batch option must appear alone.
ERROR
        exit 1;
    }

    my $session = OME::SessionManager->TTYlogin();
    my $factory = $session->Factory();

    my $keep = 0;
    while (1) {
        if ($batch && !$keep) {
            $name = '';
            $leader_input = '';
            $contact_input = '';
        }

        # In the prompts below, the current behavior is to re-prompt
        # for everything in the case of an error.  If we decide that a
        # better solution would to only prompt for the things that
        # _caused_ the error, then all we have to do is eliminate the
        # "|| $keep" from each of the if statements below.

        $name = confirm_default("Name?   ",$name)
          if $batch || $keep || $name eq '';

        # Allow the user to cancel the batch operation by hitting enter
        last if $name eq '';

        $leader_input  = confirm_default("Leader? ",$leader_input)
          if $batch || $keep || $leader_input eq '';

        $contact_input = confirm_default("Contact?",$contact_input)
          if $batch || $keep || $contact_input eq '';

        $keep = 0;

        # Create the group

        # Verify that the specified leader exists.

        my $leader;

        if ($leader_input =~ /^[0-9]+$/) {
            # Leader was specified by ID
            $leader = $factory->
              loadObject('OME::SemanticType::BootstrapExperimenter',
                         $leader_input);
        } else {
            $leader = $factory->
              findObject('OME::SemanticType::BootstrapExperimenter',
                         { OMEName => $leader_input });
        }

        if (!defined $leader) {
            print "Could not find the specified leader ($leader_input).\n";
            $leader_input = '';
            $keep = 1;
            redo;
        }

        # Verify that the specified contact exists.

        my $contact;

        if ($contact_input =~ /^[0-9]+$/) {
            # Contact was specified by ID
            $contact = $factory->
              loadObject('OME::SemanticType::BootstrapExperimenter',
                         $contact_input);
        } else {
            $contact = $factory->
              findObject('OME::SemanticType::BootstrapExperimenter',
                         { OMEName => $contact_input });
        }

        if (!defined $contact) {
            print "Could not find the specified contact ($contact_input).\n";
            $contact_input = '';
            $keep = 1;
            redo;
        }

        # Create the new attribute for the group

        my $group = $factory->
          newAttribute('Group',undef,undef,
                       {
                        Name    => $name,
                        Leader  => $leader,
                        Contact => $contact,
                       });

        if (defined $group) {
            print "Created group #",$group->id(),".\n";
        } else {
            print "Error creating group.\n";
        }

        $session->commitTransaction();

        last unless $batch;
    }
}

sub addGroup_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Creates a new OME group.  You can specify the information about the
new user on the command line, or type it in at the prompts.  There is
also a batch mode which allows you to type in several new groups with
a single execution of this command.

Options:
    -b, --batch
        Allows you to type in several group in one execution of this
        command.  If you specify this option, you cannot specify any
        of other data options.

    -n, --name <name>
        Specify the name of the new group.

    -l, --leader (<user ID> | <username>)
        Specify the leader of the group as either an integer user ID,
        or as a username.

    -c, --contact (<user ID> | <username>)
        Specify the contact of the group as either an integer user ID,
        or as a username.
CMDS
}

sub listGroup {
    my $self = shift;

    my $help = 0;
    my $name = "";
    my $leader_input = "";
    my $contact_input = "";
    my $tabbed = 0;
    my $result;
    my ($leader, $contact);

    $result = GetOptions('help|h' => \$help,
                         'name|n=s' => \$name,
                         'leader|l=s' => \$leader_input,
                         'contact|c=s' => \$contact_input,
                         'tabbed|t' => \$tabbed);

    exit(1) unless $result;

    if ($help) {
        $self->listUsers_help();
        exit;
    }

    my $session = OME::SessionManager->TTYlogin();
    my $factory = $session->Factory();

    my $criteria =
      {
       __order => ['Name'],
      };

    # Add to the criteria any filters specified on the command line

    $criteria->{Name} = "%${name}%"
      if $name ne '';

    if ($leader_input ne '') {
        if ($leader =~ /^[0-9]+$/) {
            $leader = $leader_input;
        } else {
            $leader = $factory->
              loadObject('OME::SemanticType::BootstrapExperimenter',
                         { OMEName => $leader_input });

            if (!defined $leader) {
                print "Cannot find user $leader_input.\n";
                exit 1;
            }
        }
        $criteria->{Leader} = $leader;
    }

    if ($contact_input ne '') {
        if ($contact =~ /^[0-9]+$/) {
            $contact = $contact_input;
        } else {
            $contact = $factory->
              loadObject('OME::SemanticType::BootstrapExperimenter',
                         { OMEName => $contact_input });

            if (!defined $contact) {
                print "Cannot find user $contact_input.\n";
                exit 1;
            }
        }
        $criteria->{Contact} = $contact;
    }

    my @groups = $factory->
      findAttributes('Group',$criteria);

    if ($tabbed) {
        foreach my $group (@groups) {
            print join("\t",
                       $group->id(),
                       $group->Name(),
                       $group->Leader()->id(),
                       $group->Contact()->id()),
                  "\n";
        }
    } else {
        my $max_id_len = 3;
        foreach my $group (@groups) {
            my $id = $group->id();
            $max_id_len = $id
              if (length($id) > $max_id_len);
        }

        my $name_len = 15;
        my $user_len = (72 - $name_len - $max_id_len - 3) / 2;

        printf "%-*.*s %-*.*s %-*.*s %-*.*s\n",
          $max_id_len, $max_id_len, "GID",
          $name_len, $name_len, "Group Name",
          $user_len, $user_len, "Leader",
          $user_len, $user_len, "Contact";

        print
          "-" x $max_id_len, " ",
          "-" x $name_len, " ",
          "-" x $user_len, " ",
          "-" x $user_len, "\n";
	
		my ($GID, $GroupName, $leaderFirstName, $leaderLastName,
		    $contactFirstName, $contactLastName);
		
        foreach my $group (@groups) {
            $leader = $group->Leader();
            $contact = $group->Contact();

			$GID = $group->id();
			$GID = '' unless defined $GID;
			$GroupName = $group->Name();
			$GroupName = '' unless defined $GroupName;
			$leaderFirstName = $leader->FirstName();
			$leaderFirstName = '' unless defined $leaderFirstName;
			$leaderLastName = $leader->LastName();
			$leaderLastName = '' unless defined $leaderLastName;
			$contactFirstName = $contact->FirstName();
			$contactFirstName = '' unless defined $contactFirstName;
			$contactLastName = $contact->LastName();
			$contactLastName = '' unless defined $contactLastName;
			
			printf "%-*.*s %-*.*s %-*.*s %-*.*s\n",
              $max_id_len, $max_id_len, $GID,
              $name_len, $name_len, $GroupName,
              $user_len, $user_len, $leaderFirstName." ".$leaderLastName,
              $user_len, $user_len, $contactFirstName." ".$contact->LastName;
        }
    }
}

sub listGroup_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Lists all of the groups matching the specified criteria.  For each one
that is found, displays the group ID and name, and names of the group
leader and contact person.

Filter options:
    -n, --name <name>
        Lists the groups with a matching name.  You can specify a
        partial name; any groups containing the specified string will
        be returned.

    -l, --leader (<user ID> | <username>)
        List the groups with the specified leader.  The leader can be
        specified either by an integer user ID, or a username.

    -c, --contact (<user ID> | <username>)
        List the groups with the specified contact.  The contact can
        be specified either by an integer user ID, or a username.

Output options:
    -t, --tabbed
        Causes the groups to be printed with no headers, in
        tab-separated form, suitable for automatic parsing.  The
        output columns will be, in order:
            ID, Name, Leader ID, Contact ID
CMDS
}

sub editGroup {
    my $self = shift;

    my $help = 0;
    my $group_id = "";
    my $name = "";
    my $leader_input = "";
    my $contact_input = "";
    my $result;

    $result = GetOptions('help|h' => \$help,
                         'id|i=i' => \$group_id,
                         'name|n=s' => \$name,
                         'leader|l=s' => \$leader_input,
                         'contact|c=s' => \$contact_input);

    exit(1) unless $result;

    if ($help) {
        $self->addUser_help();
        exit;
    }

    if ($group_id eq '') {
        print "You must specify a group to edit with the -i option.\n";
        exit 1;
    }

    my $session = OME::SessionManager->TTYlogin();
    my $factory = $session->Factory();

    my $group = $factory->loadAttribute('Group',$group_id);

    if (!defined $group) {
        print "Group #${group_id} does not exist.\n";
        exit 1;
    }

    # Verify that the specified leader exists.

    my $leader;

    if ($leader_input ne '') {
        if ($leader_input =~ /^[0-9]+$/) {
            # Leader was specified by ID
            $leader = $factory->
              loadObject('OME::SemanticType::BootstrapExperimenter',
                         $leader_input);
        } else {
            $leader = $factory->
              findObject('OME::SemanticType::BootstrapExperimenter',
                         {
                          OMEName => $leader_input });
        }

        if (!defined $leader) {
            print "Could not find the specified leader ($leader_input).\n";
            exit 1;
        }
    }

    # Verify that the specified contact exists.

    my $contact;

    if ($contact_input ne '') {
        if ($contact_input =~ /^[0-9]+$/) {
            # Contact was specified by ID
            $contact = $factory->
              loadObject('OME::SemanticType::BootstrapExperimenter',
                         $contact_input);
        } else {
            $contact = $factory->
              findObject('OME::SemanticType::BootstrapExperimenter',
                         {
                          OMEName => $contact_input });
        }

        if (!defined $contact) {
            print "Could not find the specified contact ($contact_input).\n";
            exit 1;
        }
    }

    # Make the changes

    $group->Name($name)
      if $name ne '';

    $group->Leader($leader->id())
      if defined $leader;

    $group->Contact($contact->id())
      if defined $contact;

    eval {
        $group->storeObject();
        $session->commitTransaction();
    };

    if ($@) {
        print "Error editing group:\n$@\n";
        exit 1;
    } else {
        print "Changes saved.\n";
    }

}

sub editGroup_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name \[<options>]

Edits an existing OME group.  You specify the group to edit with the
-i option.  You must specify the modified values for the group on the
command line; no prompting is done.  The edit is performed atomically;
if there is any database error or inconsistency in the data, none of
the other (possibly valid) changes are saved.

Options:
    -i, --id <group ID>
        Specify the group to edit by its database ID.  The <group ID>
        parameter must be a positive integer, and can be found via the
        "groups list" command.

Edit options:
    -n, --name <name>
        Change the group's name.

    -l, --leader (<user ID> | <username>)
        Change the group's leader.  The leader is specified as either
        an integer user ID, or as a username.

    -c, --contact (<user ID> | <username>)
        Change the group's contact.  The contact is specified as
        either an integer user ID, or as a username.
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

