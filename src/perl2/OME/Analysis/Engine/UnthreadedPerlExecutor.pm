# OME/Tasks/Analysis/Engine/UnthreadedPerlExecutor.pm

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




#-------------------------------------------------------------------------------
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------

package OME::Analysis::Engine::UnthreadedPerlExecutor;

=head1 NAME

OME::Analysis::Engine::UnthreadedPerlExecutor - an implementation of
the Executor interface which executes modules within the current Perl
interpreter

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use UNIVERSAL::require;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub executeModule {
    my ($self,$session,$chain_execution,$module,$node,
        $dependence,$target,$inputs) = @_;

    my $handler_class = $module->module_type();
    my $location = $module->location();

    croak "Malformed class name $handler_class"
      unless $handler_class =~ /^\w+(\:\:\w+)*$/;
    $handler_class->require();
    my $handler = $handler_class->new($location,$session,
                                      $chain_execution,$module,$node);

    my $module_execution = $session->Factory()->
      newObject("OME::ModuleExecution",
                {
                 module    => $module,
                 dependence => $dependence,
                 dataset    => $chain_execution->dataset(),
                 timestamp  => 'now',
                 status     => 'RUNNING'
                });

    eval {
        $handler->startAnalysis($module_execution);
        $handler->execute($dependence,$target,$inputs);
        $handler->finishAnalysis();
    };

    if ($@) {
        $module_execution->status('ERROR');
        $module_execution->error_message($@);
    } else {
        $module_execution->status('FINISHED');
    }

    $module_execution->storeObject();

    return $module_execution;
}


sub modulesExecuting { return 0; }
sub waitForAnyModules {}
sub waitForAllModules {}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>

=cut
