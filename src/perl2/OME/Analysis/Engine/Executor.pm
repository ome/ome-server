# OME/Tasks/Analysis/Engine/Executor.pm

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

package OME::Analysis::Engine::Executor;

=head1 NAME

OME::Analysis::Engine::Executor - interface for executing analysis modules

=head1 SYNOPSIS

=head1 DESCRIPTION

The analysis engine uses classes which implement the Executor
interface to actually perform the execution of an analysis module.
Default Executors are provided to execute an analysis module within
the current Perl interpreter, either in single-threaded or
multi-threaded mode, depending on how Perl was compiled.  New
implementations of the Executor class can be written to handle
different execution environments, such as clusters, which usually have
their own job control routines.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

=head1 INTERFACE METHODS

The following methods must be defined by classes implementing the
Executor interface.

=head2 executeModule

	my $module_execution = $executor->
	  executeModule($session,$module,$node,
	                $dependence,$target,
	                \%inputs);

Executes the given analysis module.  The node representing that module
in the chain is given by the $node parameter.  The %inputs hash
specifies which module executions provide input to the module.  Each
key of the hash is the integer ID's of one of the module's formal
inputs; the value is the OME::ModuleExecution object that provides
values for that input.

The values of the $dependence and $target parameters are based on the
dependence of the module.  If the module is dataset-dependent,
$dependence will equal 'D' and $target will be an OME::Dataset object;
if it is image-dependent, $dependence will equal 'I' and $target will
be an array reference of OME::Image primary key ID's.

The engine will perform the appropriate result-reuse checks before
calling this method; if it is called, then no results were eligible
for reuse, and the module needs to be executed in full.

Single-threaded Executors should execute the module completely, and
return once it is finished or has died with an error.  Multi-threaded
Executors should spawn whathever threads, processes, external
programs, etc., which are needed to execute the module, but should not
block until completion.

=cut

sub executeModule {
    my ($self,$session,$chain_execution,$module,$node,
        $dependence,$target,$inputs) = @_;
    die "OME::Analysis::Engine::Executor->executeModule is abstract";
}

=head2 modulesExecuting

	my $module_count = $executor->modulesExecuting();

Returns the number of modules which are currently being executed by
the Executor.  The analysis engine uses this to determine when a chain
has finished executing: A chain is finished when all of the following
are true:

=over

=item 1.

There are no nodes which have not been executed which are eligble for
reuse.

=item 2.

There are no modules currently being executed by the active Executor.

=back

Single-threaded Executors should always return 0, since the
executeModule will block until the module is completed.

=cut

sub modulesExecuting {
    my ($self) = @_;
    die "OME::Analysis::Engine::Executor->modulesExecuting is abstract";
}

=head2 waitForAnyModules

	$executor->waitForAnyModules();

For multi-threaded Executors, waits for at least one of the spawned
workers to finish executing a module.  Single-threaded Executors
should block in the executeModule method, so their waitForModules
methods should simply return immediately.

=cut

sub waitForAnyModules {
    my ($self) = @_;
    die "OME::Analysis::Engine::Executor->waitForAnyModules is abstract";
}

=head2 waitForAlModules

	$executor->waitForAllModules();

For multi-threaded Executors, waits for all of the spawned workers to
finish executing a module.  Single-threaded Executors should block in
the executeModule method, so their waitForModules methods should
simply return immediately.

=cut

sub waitForAllModules {
    my ($self) = @_;
    die "OME::Analysis::Engine::Executor->waitForAllModules is abstract";
}


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>

=cut
