# OME/Analysis/Engine.pm

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


package OME::Analysis::Engine;

=head1 NAME

OME::Analysis::Engine - OME analysis subsystem

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::SemanticType;
use OME::AnalysisChain;
use OME::ModuleExecution;
use OME::AnalysisChainExecution;
use OME::Analysis::Engine::Executor;
use OME::Analysis::Engine::DataPaths;
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ChainManager;

our $DEBUG = 1;
sub __debug { print STDERR @_ if $DEBUG; }

=head2 checkInputs

	$self->checkInputs();

Verifies that every formal input has zero or one links feeding it.  It
a formal input has zero links feeding it, verifies that the user input
provided for the input (defaulting to null) is valid, according to the
input's optional and list specification.  Also verifies that each link
is well-formed; i.e., that the "from output" belongs to the "from
node", the "to input" belongs to the "to node", and that the types of
the "from output" and "to input" match.

=cut

sub checkInputs {
    my $self = shift;
    my $factory = OME::Session->instance()->Factory();

    my $chain = $self->{chain};

    my %node_inputs;

    # First, sort the chain's links by to-node and to-input.  This
    # allows us to verify that each input has at most one inbound link.
    # Simultaneously, verify that the links are well-formed (i.e., that
    # the from-output belongs to the from-node, the to-input belongs to
    # the to-node, and that the link is well-typed).

    foreach my $link ($chain->links()) {
        my $from_node = $link->from_node();
        my $from_output = $link->from_output();
        my $to_node = $link->to_node();
        my $to_input = $link->to_input();

        my $long_name =
          $from_node->module()->name().".".
          $from_output->name()." -> ".
          $to_node->module()->name().".".
          $to_input->name();
        my $short_name =
          $to_node->module()->name().".".
          $to_input->name();

        die
          "$long_name: 'From output' does not belong to 'from node'"
            if ($from_output->module()->id() ne
                $from_node->module()->id());

        die
          "$long_name: 'To input' does not belong to 'to node'"
            if ($to_input->module()->id() ne
                $to_node->module()->id());

        # The link is well-typed if the from-output is untyped, or if
        # the from-output and to-input have the same type.

        die
          "$long_name: Types don't match"
            unless (!defined $from_output->semantic_type())
              || ($from_output->semantic_type()->id() eq
                  $to_input->semantic_type()->id());

        die
          "$short_name: Two links cannot feed into the same input!"
            if (exists $node_inputs{$to_node->id()}->{$to_input->id()});

        $node_inputs{$to_node->id()}->{$to_input->id()} = $link;
    }

    my @nodes = $chain->nodes();
    foreach my $node (@nodes) {
        my $module = $node->module();
        my @inputs = $module->inputs();

      INPUT:
        foreach my $formal_input (@inputs) {
            my $nodeID = $node->id();
            my $inputID = $formal_input->id();

            # This input has values specified by a data link.
            if (defined $node_inputs{$nodeID}->{$inputID}) {
                # If the user tried to specify values for this inputs,
                # that's bad.
                die "Cannot execute chain -- free input ".
                  $formal_input->name()." in module ".$module->name().
                  " has both user-specified values and a data link"
                  if defined $self->{user_inputs}->{$inputID};

                next INPUT;
            }

            my $user_input = $self->{user_inputs}->{$inputID};
            if (defined $user_input) {
                if (ref($user_input) ne 'ARRAY') {
                    $user_input = [$user_input];
                    $self->{user_inputs}->{$inputID} = $user_input;
                }

                foreach my $input_mex (@$user_input) {
                    die "User inputs must be MEXes"
                      unless UNIVERSAL::isa($input_mex,'OME::ModuleExecution');
                }
            } else {
                # TODO: Support non-specified user inputs.  We would
                # just assume that the user wants to specify an input
                # of "nothing".

                die "Cannot execute chain -- unspecified free input ".
                  $formal_input->name()." in module ".$module->name();
            }
        }
    }
}

=head2 calculateDependences

	$self->calculateDependences();

Determines whether each node in the active chain is a global,
per-dataset or per-image module.  If a module outputs any global
attributes (which is only allowed if all of its inputs are global
attributes), then the module is global.  If a module takes in any
dataset inputs, or outputs any dataset outputs, or if any of its
immediate predecessors nodes are per-dataset, then it as per-dataset.
Otherwise, it is per-image.  This notion of dataset-dependency comes
in to play later when determine whether or not a module's results can
be reused.

=cut

sub calculateDependences {
    my $self = shift;
    my $chain = $self->{chain};
    my $factory = OME::Session->instance()->Factory();

    my %dependences;
    my @nodes_to_check = @{OME::Tasks::ChainManager->getRootNodes($chain)};
    my $any_dataset_dependences = 0;

  NODE:
    while (my $node = shift(@nodes_to_check)) {
        next NODE if defined $dependences{$node->id()};

        # Go ahead and add this node's successors to the list.
        push @nodes_to_check,
          @{OME::Tasks::ChainManager->getNodeSuccessors($node)};

        # Check if the node is globally-dependent by seeing if it
        # creates any global outputs.  If so, it cannot have any
        # non-global inputs.

        if ($factory->
            objectExists("OME::Module::FormalOutput",
                         {
                          module => $node->module(),
                          'semantic_type.granularity' => 'G',
                         })) {
            $dependences{$node->id()} = 'G';

            if ($factory->
                objectExists("OME::Module::FormalInput",
                             {
                              module => $node->module(),
                              'semantic_type.granularity' =>
                              ['<>','G'],
                             })) {
                die "Node ".$node->id()." illegally generates global outputs";
            }

            next NODE;
        }

        # Check if the node is trivially dataset-dependent, by seeing if
        # if has any dataset inputs or outputs.

        if ($factory->
            objectExists("OME::Module::FormalInput",
                         {
                          module => $node->module(),
                          'semantic_type.granularity' => 'D',
                         })) {
            $any_dataset_dependences = 1;
            $dependences{$node->id()} = 'D';
            next NODE;
        }

        if ($factory->
            objectExists("OME::Module::FormalOutput",
                         {
                          module => $node->module(),
                          'semantic_type.granularity' => 'D',
                         })) {
            $any_dataset_dependences = 1;
            $dependences{$node->id()} = 'D';
            next NODE;
        }

        # The node has only image inputs and outputs.  We must check its
        # predecessors to determine its dependence.  If there are any
        # dataset dependent predecessors, this node is also dataset-
        # dependent.  If there are any predecessors whose dependence we
        # haven't yet calculated, we have to add this node back to the
        # end of the list so that we can re-check later.

        my @inputs = $node->module()->inputs();
        my $unknown_predecessor = 0;
        foreach my $formal_input (@inputs) {
            if (defined $self->{user_inputs}->{$formal_input->id()}) {
                my $input_mexes = $self->{user_inputs}->{$formal_input->id()};
                foreach my $input_mex (@$input_mexes) {
                    if ($input_mex->dependence() eq 'D') {
                        $any_dataset_dependences = 1;
                        $dependences{$node->id()} = 'D';
                        next NODE;
                    }
                }
            } else {
                my $link = $factory->
                  findObject('OME::AnalysisChain::Link',
                             {
                              to_node  => $node,
                              to_input => $formal_input,
                             });

                my $from_node = $link->from_node();
                if (!defined $dependences{$from_node->id()}) {
                    $unknown_predecessor = 1;
                } elsif ($dependences{$from_node->id()} eq 'D') {
                    $any_dataset_dependences = 1;
                    $dependences{$node->id()} = 'D';
                    next NODE;
                }
            }
        }

        # We found no dataset-dependent predecessors.  If we found any
        # unknown predecessors, add this node back to the list and
        # check later (by which time we will have hopefully determined
        # the dependence of all of the predecessors).  Otherwise, the
        # node is image-dependent.

        if ($unknown_predecessor) {
            push @nodes_to_check, $node;
            next NODE;
        } else {
            $dependences{$node->id()} = 'I';
            next NODE;
        }
    }

    $self->{dependences} = \%dependences;
    $self->{any_dataset_dependences} = $any_dataset_dependences;
}

=head2 getPredecessorMEX

	my $mex = $self->getPredecessorMEX($node,$formal_input,$target);

Returns the MEX that should be used to satisfy the given formal input
of the given node for the given target.  This target should match the
dependence of the node.  The method first checks to see if there is a
universal execution for that works; if it doesn't, it then looks for a
node execution in the current chain execution that works.  If the link
is between an image-dependent MEX and a dataset-dependent MEX, then
there will be more than one MEX which satisfies (one per image in the
dataset).  In this case, the method will return an array of MEX's.
Otherwise, it will return a single MEX object.

=cut

sub getPredecessorMEX {
    my $self = shift;
    my ($to_node,$to_input,$to_target) = @_;
    my $factory = OME::Session->instance()->Factory();

    if (defined $self->{user_inputs}->{$to_input->id()}) {
        __debug "  getPredecessorMEX(",$to_input->name(),")\n";

        my $granularity = $to_input->semantic_type()->granularity();
        my $to_dependence = ($granularity eq 'F')? 'I': $granularity;

        my $input_mexes = $self->{user_inputs}->{$to_input->id()};
        my @target_mexes;
        foreach my $input_mex (@$input_mexes) {
            __debug "    Checking MEX ",$input_mex->id(),"\n";
            __debug "      $to_dependence ",$input_mex->dependence(),"\n";
            next unless ($input_mex->dependence() eq $to_dependence);

            __debug "      **GOOD!\n"
              if ($to_dependence eq 'G')
              || ($to_dependence eq 'D' &&
                  $input_mex->dataset()->id() == $to_target->id())
              || ($to_dependence eq 'I' &&
                  $input_mex->image()->id() == $to_target->id());

            push @target_mexes, $input_mex
              if ($to_dependence eq 'G')
              || ($to_dependence eq 'D' &&
                  $input_mex->dataset()->id() == $to_target->id())
              || ($to_dependence eq 'I' &&
                  $input_mex->image()->id() == $to_target->id());
        }

        return \@target_mexes;
    }

    my $link = $factory->
      findObject('OME::AnalysisChain::Link',
                 {
                  to_node  => $to_node,
                  to_input => $to_input,
                 });
    my $to_dependence = $self->{dependences}->{$to_node->id()};
    my $from_node = $link->from_node();
    my $from_dependence = $self->{dependences}->{$from_node->id()};
    my $idLink = ($from_dependence eq 'I' && $to_dependence eq 'D');
    my @from_targets;
    my %mexes;

    # Determine the "from target" based on the current node's target and
    # the dependences of the link.

    my $target_column;

    __debug "  getPredecessorMEX(",$link->id(),")\n";

    __debug "    from $from_dependence ",$from_node->id()," ",$from_node->module()->name(),"\n";
    __debug "    to $to_dependence ",$to_node->id()," ",$to_node->module()->name(),"\n";

    if ($from_dependence eq 'G') {
        push @from_targets, undef;
        $target_column = "module_execution.dataset";
    } elsif ($from_dependence eq 'D') {
        push @from_targets, $self->{dataset};
        $target_column = "module_execution.dataset";
    } elsif ($from_dependence eq 'I') {
        $target_column = "module_execution.image";
        if ($to_dependence eq 'I') {
            push @from_targets, $to_target;
        } else {
            @from_targets = $to_target->images();
        }
    }

  TARGET:
    foreach my $target (@from_targets) {
        my $target_id = (defined $target)? $target->id(): 0;

        # Look for a universal execution first.
        my $universal = $factory->
          findObject("OME::AnalysisChainExecution::NodeExecution",
                     {
                      "module_execution.module" => $from_node->module(),
                      $target_column            => $target,
                      analysis_chain_execution  => undef,
                      analysis_chain_node       => undef,
                     });

        if (defined $universal) {
            $mexes{$target_id} = $universal->module_execution();
            next TARGET;
        }

        # We didn't find one, so look for a regular node execution.
        my $chex = $self->{chain_execution};

        my $regular = $factory->
          findObject("OME::AnalysisChainExecution::NodeExecution",
                     {
                      $target_column            => $target,
                      analysis_chain_execution  => $chex,
                      analysis_chain_node       => $from_node,
                     });

        if (defined $regular) {
            $mexes{$target_id} = $regular->module_execution();
            next TARGET;
        }

        # We could not find a MEX that satisfied this link for at least
        # one of the targets.
        return undef;
    }

    # We should have more than MEX only in the case of an I->D link.  If
    # so, return the MEX hash we created in the previous loop.
    # Otherwise, assume that there's only one entry in the hash, and
    # return its value.
    my @mexes = values %mexes;
    return ($idLink)? \@mexes: $mexes[0];
}

=head2 getUniversalExecution

	my $nex = $self->getUniversalExecution($node,$target);

Tries to find a universal execution for the specified node and target.
The target should match the dependence of the node.

=cut

sub getUniversalExecution {
    my $self = shift;
    my ($node,$target) = @_;
    my $target_id = (defined $target)? $target->id(): 0;
    my $factory = OME::Session->instance()->Factory();

    __debug("  getUniversalExecution(",$node->module->name(),",$target_id)");

    my %criteria = (
                    "module_execution.module" => $node->module(),
                    analysis_chain_execution  => undef,
                    analysis_chain_node       => undef,
                   );

    $criteria{"module_execution.dataset"} = $target
      if ($self->{dependences}->{$node->id()} eq 'D');
    $criteria{"module_execution.image"} = $target
      if ($self->{dependences}->{$node->id()} eq 'I');

    my $universal = $factory->
      findObject("OME::AnalysisChainExecution::NodeExecution",
                 \%criteria);

    return $universal;
}

=head2 executeNodeWithTarget

	$self->executeNodeWithTarget($node,$target);

Executes a node against one of its targets.  The target should match
the dependence of the node.  If this dependence is global or dataset,
this method will be called once per module execution, with either the
target being undefined or the dataset, respectively.  If the
dependence is image, this method will be called per image in the
dataset.

This method performs attribute reuse checks, assuming that the
ReuseResults flag was set in the call to executeChain().

=cut

sub executeNodeWithTarget {
    my $self = shift;
    my ($node,$target) = @_;
    my $target_id = (defined $target)? $target->id(): 0;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    __debug("  executeNodeWithTarget(",$node->module->name(),",$target_id)");

    # First see if there is a universal execution for this node.  If
    # there is, then we have nothing to do for this node.

    return if defined $self->getUniversalExecution($node,$target);

    my $module = $node->module();
    my $dependence = $self->{dependences}->{$node->id()};

    # Create a new MEX for this execution.

    my $mex = OME::Tasks::ModuleExecutionManager->
      createMEX($module,$dependence,$target,
                $node->iterator_tag(),$node->new_feature_tag());

    # Create all of the appropriate ACTUAL_INPUTS for this MEX.

    my @inputs = $node->module()->inputs();
    foreach my $formal_input (@inputs) {
        my $input_mex = $self->getPredecessorMEX($node,$formal_input,$target);
        my @input_mexes;

        die "Couldn't find an input MEX!"
          unless defined $input_mex;

        if (ref($input_mex) eq 'ARRAY') {
            OME::Tasks::ModuleExecutionManager->
                addActualInput($_,$mex,$formal_input)
                foreach @$input_mex;
        } else {
            OME::Tasks::ModuleExecutionManager->
                addActualInput($input_mex,$mex,$formal_input);
        }
    }

    # Calculate the new MEX's input tag.

    my $input_tag = OME::Tasks::ModuleExecutionManager->
      getInputTag($mex);
    $mex->input_tag($input_tag);
    $mex->storeObject();

    # Look for an existing MEX with the same input tag.  If we find one,
    # then we've found a MEX which is eligible for attribute reuse.

    if ($self->{flags}->{ReuseResults}) {
        __debug("  Looking for $input_tag");
        my $past_mex = $factory->
          findObject("OME::ModuleExecution",
                     {
                      module    => $module,
                      input_tag => $input_tag,
                      status    => 'FINISHED',
                     });
        if (defined $past_mex) {
            # Reuse the results
            __debug("  Match! ",$past_mex->id()," ",$past_mex->module()->name());

            # Delete the newly created MEX (by rolling back the
            # transaction)
            $session->rollbackTransaction();

            # Create a node execution for this node and the matching MEX
            my $nex = OME::Tasks::ModuleExecutionManager->
              createNEX($past_mex,$self->{chain_execution},$node);
            $session->commitTransaction();

            return;
        }
    }

    # Create a node execution for this node and the new MEX
    my $nex = OME::Tasks::ModuleExecutionManager->
      createNEX($mex,$self->{chain_execution},$node);
    $session->commitTransaction();

    # Execute the module
    my $executor = $self->{executor};
    __debug("  Executing!");
    $executor->executeModule($mex,$dependence,$target);

    return;
}

=head2 isNodeReady

	my $ready = $self->isNodeReady($node,$target);

Checks whether a node is ready to be executed against the specified
target.

=cut

sub isNodeReady {
    my $self = shift;
    my ($node,$target) = @_;
    my $target_id = (defined $target)? $target->id(): 0;

    __debug("  isNodeReady(",$node->module->name(),",$target_id)");

  INPUT:
    foreach my $formal_input ($node->module()->inputs()) {
        my $input_mexes = $self->getPredecessorMEX($node,$formal_input,$target);
        return 0 unless defined $input_mexes;

        $input_mexes = [$input_mexes]
          unless ref($input_mexes) eq 'ARRAY';

      MEX:
        foreach my $mex (@$input_mexes) {
            my $status = $mex->status();

            # If we already know it's finished (successfully or not),
            # don't bother re-reading from the database

            next MEX if $status eq 'FINISHED';

            return 0 if ($status eq 'ERROR');

            # Otherwise, we think the module is still running.  Once
            # it's done, its Executor will set the STATUS field of the
            # appropriate module execution to FINISHED or ERROR, but
            # we'll have to refresh the module execution from the
            # database to see any changes.

            $mex->refresh();
            $status = $mex->status();

            # If the predecessor has not finished successfully (i.e.,
            # it's still running, or it finished with an error), then
            # the current node cannot execute.

            return 0 if ($status ne 'FINISHED');
        }
    }

    return 1;
}

=head2 executeChain

	my $chain_execution = OME::Analysis::Engine->executeChain($chain,$dataset,$user_inputs,
	                                    [ReuseResults => 1]);

The $user_inputs parameter must be a hash, with formal input ID's for
keys and MEX objects for values.

=cut

sub executeChain {
    my $class = shift;
    my ($chain,$dataset,$user_inputs,%flags) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    # ReuseResults flag has a default value
    $flags{ReuseResults} = 1
      unless exists $flags{ReuseResults};

    my $self = {
                chain         => $chain,
                flags         => \%flags,
                dataset       => $dataset,
                user_inputs   => $user_inputs,
                started_nodes => {},
               };
    bless $self, $class;

    # Validate the chain
    $self->checkInputs();

    # Load in the appropriate executor
    my $executor = OME::Analysis::Engine::Executor->
      getDefaultExecutor();
    $self->{executor} = $executor;

    # Build the data paths.  Since data paths are now associated
    # with analysis chains, we only need to calculate them once.
    # Since the view is only locked when it is executed, we assume
    # that an unlocked view has not had paths calculated, whereas
    # a locked one has.
    if (!$chain->locked()) {
        __debug("  Chain has not been locked yet");

        OME::Analysis::Engine::DataPaths->createDataPaths($chain);

        __debug("  Locking the chain");
        $chain->locked('true');
        $chain->storeObject();
    }

    $self->calculateDependences();

    # If there are any modules which have dataset dependence, then we
    # need to lock the dataset.  (So that the dataset outputs remain
    # valid.)  If there are not any dataset-dependent MEX's in this
    # chain, we don't need to lock the dataset.

    if ($self->{any_dataset_dependences}) {
        # Lock the dataset
        $dataset->locked('true');
        $dataset->storeObject();
    }

    my $chex = $factory->
      newObject("OME::AnalysisChainExecution",
                {
                 analysis_chain  => $chain,
                 dataset         => $dataset,
                 experimenter_id => $session->User(),
                });
    $self->{chain_execution} = $chex;

    $session->commitTransaction();

    my $continue = 1;
    my $round = 0;
    my @nodes = $chain->nodes();

  ROUND:
    while ($continue) {
        $continue = 0;
        $round++;
        __debug("Round $round...");

      NODE:
        foreach my $node (@nodes) {
            my $dependence = $self->{dependences}->{$node->id()};
            my @targets;

            if ($dependence eq 'G') {
                push @targets, undef;
            } elsif ($dependence eq 'D') {
                push @targets, $dataset;
            } elsif ($dependence eq 'I') {
                push @targets, ($dataset->images());
            }

          TARGET:
            foreach my $target (@targets) {
                my $target_id = (defined $target)? $target->id(): 0;

                # Node has already started executing
                next TARGET
                  if $self->{started_nodes}->{$node->id()}->{$target_id};

                # Node isn't ready
                next TARGET
                  unless $self->isNodeReady($node,$target);

                # Node's ready, let's execute
                $self->executeNodeWithTarget($node,$target);

                # Mark some state and keep going
                $session->commitTransaction();
                $self->{started_nodes}->{$node->id()}->{$target_id} = 1;
                $continue = 1;
            }
        }

        # Wait for at least one module to finish (we might be using a
        # multi-threaded or otherwise non-blocking executor) before
        # progressing to the next round.

        $executor->waitForAnyModules();

        if (!$continue) {
            # No modules were executed this round, but if we're
            # using a multi-threaded Executor, there might be
            # modules that are still executing.  If so, we should
            # keep looping until all of the modules are done,
            # since their completing might make further nodes
            # eligible for execution.

            $continue = $executor->modulesExecuting();
        }
    }
    return $self->{chain_execution};
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


