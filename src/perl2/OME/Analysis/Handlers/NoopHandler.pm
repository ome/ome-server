# OME/module_execution/NoopHandler.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::Analysis::NoopHandler;

=head1 NAME

OME::Analysis::NoopHandler - analysis handler for unexecute placeholder modules

=head1 SYNOPSIS

This class is instantiated automatically by the analyis engine
(specifically, by OME::Analysis::AnalysisEngine).  To use it, set the
ModuleType attribute of a module's XML description to
C<OME::Analysis::NoopHandler>.

=head1 DESCRIPTION

It is often the case that another piece of code, completely separate
from the analysis engine, creates OME data attributes.  Further, it
might not be desirable (or feasible) to write an executable handler or
module wrapper for this piece of code.  However, in order for these
attributes to be visible to the analysis engine, they must be fit into
a proper data-dependency tree, which requires analysis modules to be
defined for each node in the tree.  In this case, the data-dependency
tree is describning to the analysis engine what exactly was computed
by the outside code.  Since the analysis engine does not control the
execution of this code, the handler for these nodes should not do
anything.  This is where the NoopHandler comes in.

The NoopHandler is used to declare that an analysis module should
never be executed by the analysis engine.  It is currently used by the
image importer to describe to the analysis engine all of the
attributes it creates as a result of image import.  When the analysis
engine comes across a NoopHandler module in an analysis chain, it must
be able to find reusable attributes in order for execution to proceed.
In other words, the outside code must have already been run for an
analysis chain to be able to use the outside results.

=cut

use strict;
our $VERSION = 2.000_000;

use base qw(OME::Analysis::Handler);

# It is okay to instantiate the NoopHandler, since this will be done
# by the analysis engine regardless of whether the module actually
# needs to execute.

sub new {
    my ($proto,$location,$session,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$module,$node);

    bless $self,$class;
    return $self;
}


# However, it is not okay for the analysis engine to actually perform
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
