# OME/module_execution/NoopHandler.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Analysis::NoopHandler;

=head1 NAME

OME::Analysis::NoopHandler - module_execution handler for unexecute placeholder modules

=head1 SYNOPSIS

This class is instantiated automatically by the analyis engine
(specifically, by OME::Tasks::AnalysisEngine).  To use it, set the
ModuleType attribute of a module's XML description to
C<OME::Analysis::NoopHandler>.

=head1 DESCRIPTION

It is often the case that another piece of code, completely separate
from the module_execution engine, creates OME data attributes.  Further, it
might not be desirable (or feasible) to write an executable handler or
module wrapper for this piece of code.  However, in order for these
attributes to be visible to the module_execution engine, they must be fit into
a proper data-dependency tree, which requires module_execution modules to be
defined for each node in the tree.  In this case, the data-dependency
tree is describning to the module_execution engine what exactly was computed
by the outside code.  Since the module_execution engine does not control the
execution of this code, the handler for these nodes should not do
anything.  This is where the NoopHandler comes in.

The NoopHandler is used to declare that an module_execution module should
never be executed by the module_execution engine.  It is currently used by the
image importer to describe to the module_execution engine all of the
attributes it creates as a result of image import.  When the module_execution
engine comes across a NoopHandler module in an module_execution chain, it must
be able to find reusable attributes in order for execution to proceed.
In other words, the outside code must have already been run for an
analysis chain to be able to use the outside results.

=cut

use strict;
our $VERSION = '1.0';

use base qw(OME::Analysis::Handler);

# It is okay to instantiate the NoopHandler, since this will be done
# by the module_execution engine regardless of whether the module actually
# needs to execute.

sub new {
    my ($proto,$location,$session,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$module,$node);

    bless $self,$class;
    return $self;
}


# However, it is not okay for the module_execution engine to actually perform
# computations with this module.  Throw an error if it tries to.

sub startAnalysis {
    my ($self,$module_execution) = @_;
    $self->SUPER::startAnalysis($module_execution);
    die "Cannot execute a NoopHandler module";
}


# Possible TODO:  Do we need to throw errors in the other module
# interface methods?  They should never get executed if startAnalysis
# throws an error, but maybe it's better to play it safe?


1;
