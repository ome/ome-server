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
# Written by:  Tom Macura <tmacura@nih.gov> re-wrote Doug Creager and Ilya Goldberg's
#             earlier incarnations of the AE and distributed AE
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
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ChainManager;
use OME::Tasks::NotificationManager;
use OME::Util::Data::Delete;

use Date::Parse qw(str2time);
use Time::HiRes qw(gettimeofday tv_interval);
use Log::Agent;
use base qw(Class::Accessor Class::Data::Inheritable);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();
    
    return $self;
}

=head2 checkInputs

	$self->checkInputs($chain,$dataset,$user_inputs);

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
	my $chain = shift;
	my $dataset = shift;
	my $user_inputs = shift;
    my $factory = OME::Session->instance()->Factory();

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
                  if defined $user_inputs->{$inputID};

                next INPUT;
            }

            my $user_input = $user_inputs->{$inputID};
            if ( ( defined $user_input ) and
                 # Check for empty Array. Empty arrays should be treated the same as undefined values.
                 ( ref($user_input) ne 'ARRAY' || scalar( @$user_input ) > 0 ) 
               ) {
                if (ref($user_input) ne 'ARRAY') {
                    $user_input = [$user_input];
                    $user_inputs->{$inputID} = $user_input;
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
						"Input mex id=".$user_input->[0]->id.". Current dataset id=".$dataset->id
						if( $user_input->[0]->dataset_id ne $dataset->id);
				}

				# image dependence
				if( $dependence eq 'I' ) {
					my %image_ids = map{ $_->image_id => undef } @$user_input;
					die "Multiple MEXes given for a single image in user inputs."
						if( scalar( keys %image_ids ) < scalar( @$user_input ) );
					die "Some images given in the list of user input for ".$formal_input->name." do not belong to the dataset being executed against."
						if( scalar( @$user_input ) > $factory->
							countObjects( 'OME::Image::DatasetMap', {
								dataset_id => $dataset->id,
								image_id   => [ 'IN', [ keys %image_ids ] ]
							} )
						);
                }
            } else {
                # Non-specified user inputs are now allowed.  They are
                # just treated as null arrays.
                $user_inputs->{$inputID} = [];
            }
        }
    }
}

=head2 calculateDependences

	$any_dataset_dependences = $self->calculateDependences($chain, $user_inputs);

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
    my $chain = shift;
    my $user_inputs = shift;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my @nodes_to_check = @{OME::Tasks::ChainManager->getRootNodes($chain)};
    my $any_dataset_dependences = 0;

  NODE:
    while (my $node = shift(@nodes_to_check)) {
        next NODE if (defined $node->dependence() and 
							  $node->dependence() ne  "");

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
            $node->dependence('G');
			$node->storeObject();

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
			$node->dependence('D');
			$node->storeObject();
            next NODE;
        }

        if ($factory->
            objectExists("OME::Module::FormalOutput",
                         {
                          module => $node->module(),
                          'semantic_type.granularity' => 'D',
                         })) {
            $any_dataset_dependences = 1;
			$node->dependence('D');
			$node->storeObject();
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
            if (defined $user_inputs->{$formal_input->id()}) {
                my $input_mexes = $user_inputs->{$formal_input->id()};
                foreach my $input_mex (@$input_mexes) {
                    if ($input_mex->dependence() eq 'D') {
                        $any_dataset_dependences = 1;
                        $node->dependence('D');
                        $node->storeObject();
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
                if (! defined $from_node->dependence()) {
                    $unknown_predecessor = 1;
                } elsif ($from_node->dependence() eq 'D') {
                    $any_dataset_dependences = 1;
					$node->dependence('D');
					$node->storeObject();
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
			$node->dependence('I');
			$node->storeObject();        
            next NODE;
        }
    }

	$session->commitTransaction();
	return $any_dataset_dependences;
}

=head2 getPredecessorMEX

	my $mex = $self->getPredecessorMEX($chex,$node,$formal_input,$target);

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
    my ($chex,$to_node,$to_input,$to_target) = @_;
    my $factory = OME::Session->instance()->Factory();

	# There should be exactly one input mex unless they are coming in as image-dependent
	# In that case, they should be merged if they are going into a dataset-dependent node
	# Or, if going into an image-dependent node, filtered to the current target (which will be an image)
	# checkInputs should have already verified mex counts and checked target validities
	
    my @input_objects = $factory->findObjects('OME::AnalysisChainExecutionUserInputs',
								{
								 formal_input => $to_input,
								});
	my @input_mexes = map {$_->module_execution()} @input_objects;
    if (scalar @input_mexes) {
        logdbg "debug", "  getPredecessorMEX(".$to_input->name().") from user inputs";
		return $input_mexes[0]
			if scalar( @input_mexes ) eq 1;

        my $to_dependence = $to_node->dependence();
        return \@input_mexes
        	unless $to_dependence eq 'I';
        my @filtered_input_mexes = grep( 
        	( $_->image->id eq $to_target->id() ), 
        	@input_mexes );
        return \@filtered_input_mexes;
    }

    my $link = $factory->
      findObject('OME::AnalysisChain::Link',
                 {
                  to_node  => $to_node,
                  to_input => $to_input,
                 });
	return undef
		unless (defined $link); # no FormalInput link -> there can't be a predecessorMEX
		
    my $to_dependence = $to_node->dependence();
    my $from_node = $link->from_node();
    my $from_dependence = $from_node->dependence();
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
        push @from_targets, $chex->dataset();
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
                      "module_execution.status" => 'FINISHED',
                      $target_column            => $target,
                      analysis_chain_execution  => undef,
                      analysis_chain_node       => undef,
                     });

        if (defined $universal) {
            $mexes{$target_id} = $universal->module_execution();
            next TARGET;
        }

        # We didn't find one, so look for a regular node execution.
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
    my $factory = OME::Session->instance()->Factory();

	my $target_name = "-";
	$target_name = $target->name() if (defined $target);
    logdbg ("debug", "  getUniversalExecution(".$node->module->name().", $target_name)");

    my %criteria = (
                    "module_execution.module" => $node->module(),
                    "module_execution.status" => 'FINISHED',
                    analysis_chain_execution  => undef,
                    analysis_chain_node       => undef,
                   );

    $criteria{"module_execution.dataset"} = $target
      if ($node->dependence() eq 'D');
    $criteria{"module_execution.image"} = $target
      if ($node->dependence() eq 'I');

    my $universal = $factory->
      findObject("OME::AnalysisChainExecution::NodeExecution",
                 \%criteria);

    return $universal;
}

=head2 recordUserInputs

   	$self->recordUserInputs($chex,$user_inputs);

Writes the user inputs to data-base tables

=cut

sub recordUserInputs {
	my $self = shift;
	my ($chex, $user_inputs) = @_;
	
    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    
    foreach my $fo_input (keys %$user_inputs) {
		my @mexs = @{$user_inputs->{$fo_input}};
		foreach my $mex (@mexs) {
			$factory->newObject('OME::AnalysisChainExecutionUserInputs',
								{
								 analysis_chain_execution => $chex,
								 formal_input => $fo_input,
								 module_execution => $mex,
								});
		}    
    }
    $session->commitTransaction();
}

=head2 newJob

	$self->newJob($chex,$node,$target);

This method is called when a node is to be executed against one of its targets.
The method's main function is add a job description describing the exeuciton
to the AE's job queue.

Executes a node against one of its targets.  The target should match
the dependence of the node.  If this dependence is global or dataset,
this method will be called once per module execution, with either the
target being undefined or the dataset, respectively.  If the
dependence is image, this method will be called per image in the
dataset.

This method performs attribute reuse checks, assuming that the
ReuseResults flag was set in the call to executeChain().

=cut

sub newJob {
    my $self = shift;
    my ($chex,$node,$target) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    
	my $target_name = "-";
	$target_name = $target->name() if (defined $target);
    logdbg ("debug", "newJob(".$node->module->name().", $target_name)");

    # First see if there is a universal execution for this node.
	my $nex = $self->getUniversalExecution($node,$target);
    # if there is, then we have nothing to do for this node.
	if (defined $nex) {
		$chex->task->refresh();
		$chex->task->step();
		$chex->task->setMessage('Executing `'.$node->module->name()."`");
		$self->finishedJob($chex,$nex,$node,$target);
		return;
	}

    my $module = $node->module();
    # Create a new MEX for this execution.
    my $mex = OME::Tasks::ModuleExecutionManager->
      createMEX($module,$node->dependence(),$target,
                $node->iterator_tag(),$node->new_feature_tag());

    # Create all of the appropriate ACTUAL_INPUTS for this MEX.
    my @inputs = $node->module()->inputs();
    foreach my $formal_input (@inputs) {
        my $input_mex = $self->getPredecessorMEX($chex,$node,$formal_input,$target);
        
        if (not defined $input_mex) {        
			if ($formal_input->optional()) {
				next;
			} else {
				logdbg ("debug", " Formal input required and PredecessorMEX unready.".
						" Not creating NewJob. (Condition A)");
				$session->rollbackTransaction();
				return;
			}
		}
		
        # check input_mexes to verify that the node is ready
     	my $input_mexes = $input_mex;
     	$input_mexes = [$input_mexes]
          unless (ref($input_mexes) eq 'ARRAY');
        
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
				unless ($in_mex->status() eq 'FINISHED') {
					logdbg ("debug", "  PredecessorMEX not ready. Not creating NewJob. (Condition B)");
					$session->rollbackTransaction();
					return;
				}
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
    if ($chex->results_reuse() ) {
        logdbg ("debug", "  ResultsReuse is looking for $input_tag");
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

            # Delete the newly created MEX (by rolling back the transaction)
            $session->rollbackTransaction();

            # Create a node execution for this node and the matching MEX
            $nex = OME::Tasks::ModuleExecutionManager->
              createNEX($past_mex,$chex,$node);
			
			$chex->task->refresh();
			$chex->task->step();
			$chex->task->setMessage('Executing `'.$node->module->name()."`");
			$session->commitTransaction();
			$self->finishedJob($chex,$nex,$node,$target);
			return;
        }
    }

    # Create a node execution for this node and the new MEX
    $nex = OME::Tasks::ModuleExecutionManager->
      createNEX($mex,$chex,$node);
      
	# finally, add NEX to analysis Engine's Job Queue
	logdbg ("debug", "  Adding NEX to Analysis Engine's Job Queue");
    my $job = $factory->newObject ('OME::Analysis::Engine::Job',
								  {
								   NEX => $nex->id(),
								   status => 'READY',
								  });
	croak (" Could not record job in the AE's job queue")
		unless defined $job;
		
	$job->storeObject();
	$session->commitTransaction(); # on commit new jobs become visible to other transactions
	return;
}

=head2 getJob

	$nex = $self->getJob($worker_id);

Get's the worker (specified by worker_id) a job.

=cut

sub getJob {
	my $self = shift;
	my $worker_id = shift;
	
	my $session = OME::Session->instance();
    my $factory = $session->Factory();

    logdbg ("debug", "getJob($worker_id)");

	## LOCK the jobs TABLE !!
    logdbg ("debug", "trying for lock");
	$factory->lockTable("OME::Analysis::Engine::Job");
    logdbg ("debug", "got it!");
    
	my $job = $factory->findObject ('OME::Analysis::Engine::Job',
								{
								status => 'READY',
								});
	my $worker = $factory->findObject ('OME::Analysis::Engine::Worker',
								{
								id => $worker_id,
								});
	my $nex;
	if ( defined ($job) ) {
		$nex = $job->NEX();
		logdbg ("debug", "  got NEX: ".$nex->id());
		
		$job->status('BUSY');
		$job->executing_worker($worker_id);
		$job->storeObject;
		
		$worker->status('BUSY');
		$worker->executing_mex($nex->module_execution());
		$worker->storeObject;

		my $task = $nex->analysis_chain_execution()->task();
		$task->refresh();
		$task->step();
		$task->setMessage('Executing `'.$ nex->analysis_chain_node->module->name()."`");
	}
	
	## commit unlocks the jobs TABLE !!
	$session->commitTransaction();
	return $nex;
}

=head2 finishedJob

	$self->finishedJob($chex,$nex,$node,$target);

A job processing $nex just finished. This method checks if the nex finished
successfully and if so, what are the successor nexs that can be added to the
AE's job queue.
=cut

sub finishedJob {
	my $self = shift;

	# N.B. usually you can get the node from the nex using
 	#	$nex->analysis_chain_node();
 	# and the chex from the nex using
 	#	$nex->analysis_chain_execution();
 	# but if it's a universal execution that's not possible
	
	my $chex = shift;
	my $nex = shift;
	my $node = shift; 
	my $target = shift; 

	my $session = OME::Session->instance();
    my $factory = $session->Factory();

	my $target_name = "-";
	$target_name = $target->name() if (defined $target);

    logdbg ("debug", "finishedJob(".$node->module->name().", ". $target_name.")");

    my $mex = $nex->module_execution;
    $mex->refresh(); # update to referesh the module execution from DB to see any changes
	if ($mex->status() eq "FINISHED") {
		# if yes --> find succesor jobs and thus figure out
		# if the chain execution is complete
		my @next_nodes = @{OME::Tasks::ChainManager->getNodeSuccessors($node)};
		if (scalar (@next_nodes)) {
			foreach my $next_node (@next_nodes) {
				if ($next_node->dependence() eq 'G') {
					$self->newJob ($chex, $next_node, undef);
				} elsif ($next_node->dependence() eq 'D') {
					$self->newJob ($chex, $next_node, $chex->dataset());
				} elsif ($next_node->dependence() eq 'I' and
						 $node->dependence() eq 'I') {
					$self->newJob ($chex, $next_node, $target);
				} elsif ($next_node->dependence() eq 'I' and
						 $node->dependence() ne 'I') {

					# additional_jobs signals that there are more jobs in memory that
					# need to be written into the DB
					my @imgs = $chex->dataset()->images();
					$chex->additional_jobs(1);
					for (my $i=1; $i<scalar(@imgs); $i++) {
						$self->newJob ($chex, $next_node, $imgs[$i]);
					}
					$chex->additional_jobs(0);
					$self->newJob ($chex, $next_node, $imgs[0]);
					
				} else {
					croak ("current node dependence is ".$node->dependence()." and ".
						   "next node dependence is ".$next_node->dependence());
				}
			}
		} else {
			logdbg ("debug", $node->module->name()." is a leaf node ");
			# no successor nodes implies we're a leaf node
			# are there any remaining CHEX jobs ?
			if ( not $chex->additional_jobs() ) {
				my @CHEX_jobs = $factory->findObjects ('OME::Analysis::Engine::Job',
							  {
							   'NEX.analysis_chain_execution' => $chex,
							  });
							  
				if (scalar @CHEX_jobs == 0 ) {
					logdbg ("debug", "Chain (CHEX=".$chex->id().") has finished executing");
					
					# timing info
					$chex->refresh(); # makes sure that $chex->timestamp() is valid
					my $s = str2time($chex->timestamp());
					my $usec = 0;
					$chex->total_time(sprintf("%0.1f",tv_interval([$s,$usec])));
					
					# chex status
					if ($chex->count_node_executions('module_execution.status' => 'ERROR')) {
						$chex->status('ERROR');
					} else {
						$chex->status('FINISHED');
					}
					
					# update the task
					$chex->task->refresh();
					$chex->task->step();
					$chex->task->finish();
					$chex->task->message("");
					$chex->storeObject();
				}
			}
		}
	} else {
		logdbg ("debug", "MEX status was not FINISHED");
	}
	$session->commitTransaction();
	return;
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
    my $self = shift;
    my ($chain,$dataset,$user_inputs,$task,%flags) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

	my $start_time = [gettimeofday()];

    $flags{ReuseResults} = 1
      unless exists $flags{ReuseResults};
      
    # Validate the chain
    $self->checkInputs($chain,$dataset,$user_inputs);

    # If there are any modules which have dataset dependence, then we need to
    # lock the dataset.  (So that the dataset outputs remain valid.)  If there
    # are not any dataset-dependent MEX's in this chain, we don't need to
    # lock the dataset.
    if ($self->calculateDependences($chain,$user_inputs)) {
        # Lock the dataset
        $dataset->locked('true');
        $dataset->storeObject();
    }
    
	# predict how many steps executing the analysis chain will require
	my @nodes = $chain->nodes();
	my $count_steps = 1;
	foreach my $node (@nodes) {
		my $dependence = $node->dependence();
		
		if ($dependence eq 'G') {
			$count_steps += 1;
		} elsif ($dependence eq 'D') {
			$count_steps += 1;
		} elsif ($dependence eq 'I') {
			my @imgs = $dataset->images();
			$count_steps += scalar(@imgs);
		}
	}
	
	# create the notfication manager task if it hasn't been created elsewhere
    if (!$task) {
		$task = OME::Tasks::NotificationManager->
			new_remote_task("Executing `".$chain->name()."`", $count_steps);
		$task->setMessage('Start Execution of Analysis Chain');
	}
	$task->setnSteps($count_steps); # always set the number of steps because the.
	                              # AE knows best
	                              
    my $chex = $factory->
      newObject("OME::AnalysisChainExecution",
                {
                 analysis_chain  => $chain,
                 dataset         => $dataset,
                 experimenter_id => $session->User(),
                 status          => 'UNFINISHED',
                 task            => $task,
                 results_reuse   => $flags{ReuseResults},
                });
   	# write the user_inputs to the database linked to the CHEX
   	$self->recordUserInputs($chex,$user_inputs);

    # create jobs for all the CHEX's root nodes
	my @root_nodes = @{OME::Tasks::ChainManager->getRootNodes($chain)};
	foreach my $node (@root_nodes) {
			my @targets;
			my $dependence = $node->dependence();
			if ($dependence eq 'G') {
				push @targets, undef;
			} elsif ($dependence eq 'D') {
				push @targets, $dataset;
			} elsif ($dependence eq 'I') {
				push @targets, ($dataset->images());
			}
			# additional_jobs signals that there are more jobs in memory that
			# need to be written into the DB
			$chex->additional_jobs(1);
			for (my $i=1; $i<scalar(@targets); $i++) {
				$self->newJob ($chex, $node, $targets[$i]);
			}
			$chex->additional_jobs(0);
			$self->newJob ($chex, $node, $targets[0]);
	}

    $session->commitTransaction();
    return $chex;
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Ilya Goldberg <igg@nih.gov>
Douglas Creager <dcreager@alum.mit.edu>,

Open Microscopy Environment, MIT, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

