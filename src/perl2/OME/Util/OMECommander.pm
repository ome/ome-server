# OME/Util/OMEAdmin.pm

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
# Written by:   Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------


package OME::Util::OMECommander;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use OME::Util::OMEAdmin;
use OME::Util::UserAdmin;
use OME::Util::GroupAdmin;
use OME::Util::dbAdmin;

use OME::SessionManager;
use OME::Session;
use OME::Tasks::ProjectManager;
use OME::Tasks::ImageTasks;

sub getCommands {
    return
      {
       'admin'   => ['OME::Util::OMEAdmin'],
       'import'  => ['OME::Util::Import'],
       'execute' => ['OME::Util::ExecuteChain'],
       'top'     => ['OME::Util::Top'],
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

ome commands are:
    admin            Commands for administering OME.
    import           Command for importing files to OME
    execute          Command for executing OME analysis chains
    top              Command for displaying progress info about OME tasks
    help <command>   Display help information about a specific command

Note that most of these commands will require you to log in as an
already-existing OME administrative user.
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

