# OME/Util/Commands.pm

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


package OME::Util::Commands;

=head1 NAME

OME::Util::Commands - helper class for putting together complex
command-line scripts

=head1 DESCRIPTION

The OME::Util::Commands class is used to create complex command-line
utility scripts.  The scripts produced with this class are similar to,
for instance, the standard cvs command, in which a single script can
perform many different classes of functions.  This functions are
organized into "command groups", each of which is implemented by a
separate Perl class.  The class are then assembled together into the
script file itself, which contains nothing more than boilerplate code.

Until such time as I can write a more thorough introduction and
overview of this, please see the omeadmin script and the
OME::Util::OMEAdmin, OME::Util::UserAdmin, and OME::Util::GroupAdmin
classes for examples.

=head1 OME::Util::Output

This class has been designed with the assumption that command groups
might need to be incorporated into different utility scripts.  To
support this fully, the command group classes should not require any
information about the scripts which are using them.  This has no real
constraints on the logic of the command groups, but can add wrinkles
to the code which creates useful diagnostic, help, and error messages.

For instance, the help message for a utility might need to print a
standard header, describing the name and version of the script.  This
cannot be included directly in the command group class.  Instead, the
script defines an implementation of the OME::Util::Output class, which
contains helper methods for printing this information out.  The
OME::Util::Commands class contains a wrapper function for each of
these methods, which performs basic error checking.  (This allows
command group classes to assume that the script provided an
implementation of each of the output methods; if any of them are
undefined, the wrapper function in this class will catch the error
before Perl complains about it.)

The methods which are available to be defined in OME::Util::Output
are:

=head2 printHeader

	OME::Util::Output->printHeader();

Prints any preliminary header for the script.  This allows, for
instance, the name and version of the script to be printed before any
detailed help messages.

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use UNIVERSAL::require;

=head2 getCommands

	my $commands = $self->getCommands();

Returns a hash of the commands defined in this command group.  Command
group classes must override this method.  The returned hash must
contain command names as keys, and method names as values.  Each
method name in the hash must be implemented as a method.  This method
will be called if the respective command is executed.  The method
takes in no parameters; but can receive the remainder of the command
line via @ARGV.

You should also implement a method with the name "[method name]_help".
This method will be called if the user requests help about the
respective item.

So, assuming that the hash returned by this method contains:

	{
	    ...
	    'add' => 'add_item',
	    ...
	}

You would need to implement an add_item method which performs the add
operation, and an add_item_help method which prints the overview help
of the command to standard out.  This help method will probably use
the printHeader command (described below).

It is also possible to nest command groups.  This could be done by
explicitly writing functions in the containing class to call the
handleCommands function in the subgroup class.  However, this occurs
relatively frequently, so a shortcut is provided.  The value of the
hash can be an array reference.  If this is the case, the array must
contain exactly one element, which should be the name of another
command group class.  The handleCommand method will transparently take
care of this case for you.

=cut

sub getCommands { return {}; }

=head2 listCommands

	$self->listCommands();

This method is called if the user requests help about this command
group, but not about one of the group's specific commands.  This class
provides a default implementation, which prints the header (via the
printHeader method), and then lists the commands defined in this group
in alphabetical order.  No further information is presented about the
commands.  Most command groups will want to override this method to
provide a more thorough overview of the command group.

=cut

sub listCommands {
    my $self = shift;
    my $commands = $self->getCommands();

    $self->printHeader();

    print "Available commands:\n";

    foreach my $command (sort keys %$commands) {
        print "  $command\n";
    }
}

=head2 handleCommand

	$self->handleCommand($help,\@supercommands);

Causes this command group to parse the beginning of the @ARGV array,
and to try to execute the command that it finds.  If the $help
parameter is set to a true value, then the method will print a help
message for that command, rather than executing it.

Arguments to the command are presented in @ARGV, just as if the
command were the body of the script itself.  This allows the command
function to use Getopt::Long to parse any remaining options on the
command line.  It is advisable for each command function to accept a
-h/--help option, and to explicitly call the help function associated
with the command when it is received.

To facilitate nested command groups (described under the getCommand
method), the handleCommand accepts the \@supercommands parameter.
This array contains a list of all of the command names used up to this
point.  This allows subcommands to rebuild the entire command name,
without making any assumptions about which other command groups
contain it.  Any recursive call to handleCommand should push the
current command name into this list before continuing.  Any initial
call to handleCommand (i.e., from the script body) should omit this
parameter.

The @supercommands array will also be passed in as a single parameter
to the execution or help methods once a final command has been
reached.  Command methods are free to ignore this if they want.

=cut

sub handleCommand {
    my ($self,$help,$supercommands) = @_;
    my $commands = $self->getCommands();
    $supercommands = [] unless defined $supercommands;

    my $command = shift @ARGV;

    if (!defined $command) {
        # The user did not specify a command, even though one was
        # needed.  Show them the help message, whether or not they
        # asked for it.

        $self->listCommands($supercommands);
    } else {
        my $base_method = $commands->{$command};
        push @$supercommands, $command;

        if (!defined $base_method) {
            # Unknown command

            $self->unknownCommand($supercommands);
        } elsif (ref($base_method) eq 'ARRAY') {
            # Name of another command group package

            my $class = $base_method->[0];
            $class->require();

            $class->handleCommand($help,$supercommands);

        } else {
            # Name of a method in this class

            if ($help) {
                # Help for a specific command

                my $help_method = "${base_method}_help";

                if (UNIVERSAL::can($self,$help_method)) {
                    $self->$help_method($supercommands);
                } else {
                    # No help available

                    $self->noHelpForCommand($supercommands);
                }
            } else {
                # Execute a specific command

                $self->$base_method($supercommands);
            }
        }
    }
}

=head2 commandName

	my $name = $self->commandName($supercommands);

Formats the @supercommands array (built automatically by the recursive
behavior of handleCommand) into something printable.

=cut

sub commandName {
    my ($self,$supercommands) = @_;

    return join(' ',@$supercommands);
}

=head2 Output functions

	my $name = $self->scriptName();
	$self->printHeader();
	$self->noHelpForCommand($supercommands);
	$self->unknownCommand($supercommands);

These functions can be used by command group classes to output various
parts of their user feedback.  The methods themselves should be
defined in an OME::Util::Output class in the script file.

=cut

sub scriptName {
    my ($self) = @_;

    if (UNIVERSAL::can('OME::Util::Output','scriptName')) {
        return OME::Util::Output->scriptName();
    } else {
        return $0;
    }
}

sub printHeader {
    my ($self) = @_;

    if (UNIVERSAL::can('OME::Util::Output','printHeader')) {
        OME::Util::Output->printHeader();
    }
}

sub noHelpForCommand {
    my ($self,$supercommands) = @_;

    my $command_name = $self->commandName($supercommands);

    if (UNIVERSAL::can('OME::Util::Output','noHelpForCommand')) {
        OME::Util::Output->noHelpForCommand($command_name);
    } else {
        $self->printHeader();
        print "No help available for '$command_name'\n";
    }
}

sub unknownCommand {
    my ($self,$supercommands) = @_;

    my $command_name = $self->commandName($supercommands);

    if (UNIVERSAL::can('OME::Util::Output','unknownCommand')) {
        OME::Util::Output->unknownCommand($command_name);
    } else {
        my $script_name = $self->scriptName();
        my $last_command = pop @$supercommands;
        my $prev_name = $self->commandName($supercommands);

        $self->printHeader();

        print <<MSG;
'$command_name' is an unknown command.

For a list of available commands:
$script_name help $prev_name
MSG
    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

