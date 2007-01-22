# OME/Util/Dev.pm

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

package OME::Util::Dev;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);
use Getopt::Long;
Getopt::Long::Configure("bundling");

sub getCommands {
    return
      {
       'chex_stats'     => ['OME::Util::Dev::ChainStats'],
       'finish_execute' => ['OME::Util::Dev::FinishExecute'],
       'lint'           => ['OME::Util::Dev::Lint'],
       'classifier'     => ['OME::Util::Dev::Classifier'],
       'templates'      => ['OME::Util::Dev::Templates' ],
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
    chex_stats       Command for getting information about a Chain Execution
    finish_execute   Command for clearing up a Chain Execution with errors.
    classifier       Commands that facilitate the computation of Image Signatures
    lint             Command for checking/correcting syntax of OME XML files
    templates        Command for displaying progress info about OME tasks
    help <command>   Display help information about a specific command
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

