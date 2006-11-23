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
#                Tom Macura <tmacura@nih.gov>
#                    re-wrote executeChain() and executeNodeWithTarget() to use
#                    topological sort based scheduling algorithm resulting in
#                    about 20% speed-up of chain executions
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
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ChainManager;
use OME::Tasks::NotificationManager;

use Time::HiRes qw(gettimeofday tv_interval);
use Log::Agent;

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
            if ( ( defined $user_input ) and
                 # Check for empty Array. Empty arrays should be treated the same as undefined values.
                 ( ref($user_input) ne 'ARRAY' || scalar( @$user_input ) > 0 ) 
               ) {
                if (ref($user_input) ne 'ARRAY') {
                    $user_input = [$user_input];
                    $self->{user_inputs}->{$inputID} = $user_input;
                }

				die "User inputs must be MEXes"
					if( grep( (not UNIVERSAL::isa($_,'OME::ModuleExecution') ), @$user_input ) );

				# determine dependence & verify all MEXes have the same dependence
				my $dependence;
				foreach my $input_mex (@$user_input) {
					if( defined $dependence ) {						
						die "MEXes given to satisfy formal input ".$formal_input->name.
							"' (id=$inputID) of module '".$module->name()."' (id=".$module->id.
							") have differing dependences. Some have dependence of $dependence, and at least one has a dependence of ".
							$input_mex->dependence().". They all need to have the same dependence."
							if( $dependence ne $input_mex->dependence() )
					} else {
						$dependence = $input_mex->dependence();
					}
				}

				# non-image dependence
				die scalar( @$user_input )." MEXes with dependence '$dependence' were given to satisfy formal input '".$formal_input->name.
					"'. Multiple MEXes are allowed iff they all have Image dependence."
					if( $dependence ne 'I' && scalar( @$user_input ) > 1 );
				
				# dataset dependence
				if( $dependence eq 'D' ) {
					# this should be a die. However, since the AE still doesn't allow global
					# outputs based on non-global inputs, I'm making the classifier dataset granularity.
					# This means a dataset attribute will have to be passed out of one dataset and into another.
					logdbg "debug", "WARNING! A user entered input for formal input '".$formal_input->name.
						"' (id=$inputID) was generated by a different dataset then is currently being executed against.\n".
						"Input mex id=".$user_input->[0]->id.". Current dataset id=".$self->{dataset}->id
						if( $user_input->[0]->dataset_id ne $self->{dataset}->id);
				}

				# image dependence
				if( $dependence eq 'I' ) {
					my %image_ids = map{ $_->image_id => undef } @$user_input;
					die "Multiple MEXes given for a single image in user inputs."
						if( scalar( keys %image_ids ) < scalar( @$user_input ) );
					die "Some images given in the list of user input for ".$formal_input->name." do not belong to the dataset being executed against."
						if( scalar( @$user_input ) > $factory->
							countObjects( 'OME::Image::DatasetMap', {
								dataset_id => $self->{dataset}->id,
								image_id   => [ 'IN', [ keys %image_ids ] ]
							} )
						);
                }
            } else {
                # Non-specified user inputs are now allowed.  They are
                # just treated as null arrays.
                $self->{user_inputs}->{$inputID} = [];
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

Returns the MEX that should be used to satisfy the given formal input of
the given node for the given target.  This target should match the
dependence of the node.  The method first looks for a match in user
inputs. Then it checks to see if there is a universal execution for that
works; if it doesn't, it then looks for a node execution in the current
chain execution that works.  If the link is between an image-dependent
MEX and a dataset-dependent MEX, then there will be more than one MEX
which satisfies (one per image in the dataset).  In this case, the
method will return an array of MEX's. Otherwise, it will return a single
MEX object.

=cut

sub getPredecessorMEX {
    my $self = shift;
    my ($to_node,$to_input,$to_target) = @_;
    my $factory = OME::Session->instance()->Factory();

	# There should be exactly one input mex unless they are coming in as image-dependent
	# In that case, they should be merged if they are going into a dataset-dependent node
	# Or, if going into an image-dependent node, filtered to the current target (which will be an image)
	# checkInputs should have already verified mex counts and checked target validities
    if (defined $self->{user_inputs}->{$to_input->id()}) {
        logdbg "debug", "  getPredecessorMEX(".$to_input->name().") from user inputs";
        my $input_mexes = $self->{user_inputs}->{$to_input->id()};
		return $input_mexes->[0]
			if scalar( @$input_mexes ) eq 1;
		return []
			if scalar( @$input_mexes ) eq 0;

        my $to_dependence = $self->{dependences}->{$to_node->id()};
        return $input_mexes
        	unless $to_dependence eq 'I';
        my @filtered_input_mexes = grep( 
        	( $_->image->id eq $to_target->id() ), 
        	@$input_mexes );
        return \@filtered_input_mexes;
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

    logdbg "debug", "  getPredecessorMEX(".$link->id().")";

    logdbg "debug", "    from $from_dependence ".$from_node->id()." ".$from_node->module()->name();
    logdbg "debug", "    to $to_dependence ".$to_node->id()." ".$to_node->module()->name();

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

    logdbg ("debug", "  getUniversalExecution(",$node->module->name(),",$target_id)");

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
    
    logdbg ("debug", "  executeNodeWithTarget(".$node->module->name().",$target_id)");

    # First see if there is a universal execution for this node.  If
    # there is, then we have nothing to do for this node.
	my $nex = $self->getUniversalExecution($node,$target);
    return $nex if defined $nex;

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

		logdbg ("debug", "  PredecessorMEX not ready. Not executing MEX.")
			and return unless defined $input_mex;
          
        # check input_mexes to verify that the node is ready
     	my $input_mexes = $input_mex;
     	$input_mexes = [$input_mexes]
          unless ref($input_mexes) eq 'ARRAY';
        
		# use input_mexes to load module's actual inputs
		foreach my $in_mex (@$input_mexes) {
		
			# These checks were refactored from the method isNodeReady() RIP
			if ($in_mex->status() ne 'FINISHED') {
			
				# Otherwise, we think the module is still running.  Once
				# it's done, its Executor will set the STATUS field of the
				# appropriate module execution to FINISHED or ERROR, but
				# we'll have to refresh the module execution from the
				# database to see any changes.
				
				$in_mex->refresh();
				
				# If the predecessor has not finished successfully (i.e.,
				# it's still running, or it finished with an error), then
				# the current node cannot execute.

				logdbg ("debug", "  PredecessorMEX not ready. Not executing MEX.")
					and return if ($in_mex->status() ne 'FINISHED');		
			}
			
			OME::Tasks::ModuleExecutionManager->
				addActualInput($in_mex,$mex,$formal_input);
		}                
    }

    # Calculate the new MEX's input tag.
    my $input_tag = OME::Tasks::ModuleExecutionManager->getInputTag($mex);
    $mex->input_tag($input_tag);
    $mex->storeObject();

    # Look for an existing MEX with the same input tag.  If we find one,
    # then we've found a MEX which is eligible for attribute reuse.

    if ($self->{flags}->{ReuseResults}) {
        logdbg ("debug", "  Looking for $input_tag");
        my $past_mex = $factory->
          findObject("OME::ModuleExecution",
                     {
                      module    => $module,
                      input_tag => $input_tag,
                      status    => 'FINISHED',
                     });
        if (defined $past_mex) {
            # Reuse the results
            logdbg ("debug", "  Match! ",$past_mex->id()," ",$past_mex->module()->name());

            # Delete the newly created MEX (by rolling back the
            # transaction)
            $session->rollbackTransaction();

            # Create a node execution for this node and the matching MEX
            $nex = OME::Tasks::ModuleExecutionManager->
              createNEX($past_mex,$self->{chain_execution},$node);

            return $nex;
        }
    }

    # Create a node execution for this node and the new MEX
    $nex = OME::Tasks::ModuleExecutionManager->
      createNEX($mex,$self->{chain_execution},$node);
    $session->commitTransaction();

    # Execute the module
    my $executor = $self->{executor};
    logdbg ("debug", "  Executing!");
    $executor->executeModule($mex,$dependence,$target);
	$mex->storeObject();
    return $nex;
}

=head2 executeChain

	my $chain_execution = OME::Analysis::Engine->executeChain($chain,$dataset,$user_inputs, $task
	                                    [ReuseResults => 1]);

The $user_inputs parameter must be a hash, with formal input ID's for
keys and MEX objects for values. Values may also be arrays of MEX
objects. The format of $user_inputs is known to be problematic (See Bug
391: http://bugs.openmicroscopy.org.uk/show_bug.cgi?id=391 ) and will be
modified in the future, from:
{ 
	$formal_inputA_id => [ $mex_objectA, $mex_objectB, $mex_objectC ],
	$formal_inputB_id => $mex_objectD,
	...
}
perhaps to:
{
	$nodeA_id => [ 
		{ $formal_inputA_id => [ $mex_objectA, $mex_objectB, $mex_objectC ] },
		{ $formal_inputB_id => $mex_objectD },
	],
	$nodeB_id => {
		$formal_inputA_id => [ $mex_objectE, $mex_objectF, $mex_objectG ],
	},
	...
}
Notice the arrays are optional when they would contain only one element.

=cut

sub executeChain {
    my $class = shift;
    my ($chain,$dataset,$user_inputs,$task,%flags) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

	my $start_time = [gettimeofday()];

    # ReuseResults flag has a default value
    $flags{ReuseResults} = 1
      unless exists $flags{ReuseResults};

    my $self = {
                chain         => $chain,
                flags         => \%flags,
                dataset       => $dataset,
                user_inputs   => $user_inputs,
               };
    bless $self, $class;

    # Validate the chain
    $self->checkInputs();

    # Load in the appropriate executor
    my $executor = OME::Analysis::Engine::Executor->
      getDefaultExecutor();
    $self->{executor} = $executor;

    # If there are any modules which have dataset dependence, then we need to
    # lock the dataset.  (So that the dataset outputs remain valid.)  If there
    # are not any dataset-dependent MEX's in this chain, we don't need to
    # lock the dataset.
    $self->calculateDependences();

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


	my @nodes = $chain->nodes();
		
	# predict how many steps executing the analysis chain will require
	my $count_steps = 0;
	foreach my $node (@nodes) {
		my $dependence = $self->{dependences}->{$node->id()};
		
		if ($dependence eq 'G') {
			$count_steps += 1;
		} elsif ($dependence eq 'D') {
			$count_steps += 1;
		} elsif ($dependence eq 'I') {
			my @imgs = $dataset->images();
			$count_steps += scalar(@imgs);
		}
	}
    
    # the notfication manager task could have been created somewhere else
    # e.g. by the chain execution command line tool
    unless ($task) {
		$task = OME::Tasks::NotificationManager->
			new("Executing `".$chain->name()."`", $count_steps);
		$task->setMessage('Start Execution of Analysis Chain');
	}
	$task->n_steps($count_steps); # always set the number of steps because the
	                              # AE knows best
	
    $SIG{INT} = sub { $task->died('User Interrupt');CORE::exit; };

	# get a topological sorted list of nodes
	my @chain_elevations = OME::Tasks::ChainManager->topologicalSort($chain);

	# follow the node list and execute
	for (my $i = 0; $i < scalar (@chain_elevations); $i++) {
		my @nodes = @{$chain_elevations[$i]};
		
		foreach my $node (@nodes) {

			my @targets;
			my $dependence = $self->{dependences}->{$node->id()};
			if ($dependence eq 'G') {
				push @targets, undef;
			} elsif ($dependence eq 'D') {
				push @targets, $dataset;
			} elsif ($dependence eq 'I') {
				push @targets, ($dataset->images());
			}

			foreach my $target (@targets) {
				$task->step();
				$task->setMessage('Executing `'.$node->module->name()."`");
				$self->executeNodeWithTarget($node,$target);
				$session->commitTransaction();
			}
		}

		# wait for all modules to finish, then start executing the next set of nodes
		$executor->waitForAllModulesToFinish();
	}
	
    $task->setMessage("");
    $task->finish();

    $chex->total_time(tv_interval($start_time));
	$chex->storeObject();
    $session->commitTransaction();
    return $self->{chain_execution};
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Tom Macura <tmacura@nih.gov>

Open Microscopy Environment, MIT, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


