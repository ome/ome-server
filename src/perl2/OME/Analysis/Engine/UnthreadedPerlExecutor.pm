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

use OME::Session;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub executeModule {
    my ($self,$mex,$dependence,$target) = @_;
    my $session = OME::Session->instance();
    my $module = $mex->module();

    my $handler_class = $module->module_type();
    my $location = $module->location();

    croak "Malformed class name $handler_class"
      unless $handler_class =~ /^\w+(\:\:\w+)*$/;
    $handler_class->require();
    my $handler = $handler_class->new($mex);

    eval {
        $handler->startAnalysis();
        $handler->execute($dependence,$target);
        $handler->finishAnalysis();
    };

    if ($@) {
        $mex->status('ERROR');
        $mex->error_message($@);
        print STDERR "      Error during execution: $@\n";
    } else {
        $mex->status('FINISHED');
    }

    $mex->storeObject();
}


sub modulesExecuting { return 0; }
sub waitForAnyModules {}
sub waitForAllModules {}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>

=cut
