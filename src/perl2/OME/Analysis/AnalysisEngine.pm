# OME/Tasks/AnalysisEngine.pm

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


package OME::Analysis::AnalysisEngine;

=head1 NAME

OME::Analysis::AnalysisEngine - OME module_execution subsystem

=head1 SYNOPSIS

	use OME::Analysis::AnalysisEngine;
	my $engine = new OME::Analysis::AnalysisEngine();

	# login to OME, load/create an module_execution view and dataset
	$engine->executeAnalysisView($session,$view,$free_inputs,$dataset);

	# Voila, you're done.

=head1 DESCRIPTION

OME::Analysis::AnalysisEngine is implements the execution algorithm of
the OME module_execution subsystem.  Given an module_execution chain, which is a
directed acylic graph of module_execution nodes, and a dataset, which is a
collection of OME images, the engine will execute each node in the
chain against the dataset, recording the results and all of the
appropriate metadata into the OME database.

=cut

use strict;
our $VERSION = 2.000_000;

use Carp;
use Log::Agent;
use OME::Factory;
use OME::DBObject;
use OME::Dataset;
use OME::Image;
use OME::Module;
use OME::ModuleExecution;
use OME::AnalysisChain;
use OME::AnalysisPath;
use OME::AnalysisChainExecution;
use OME::SessionManager;
use OME::DBConnection;
use Ima::DBI;

use Benchmark qw(timediff timesum timestr);

use base qw(Ima::DBI);

__PACKAGE__->set_db('Main',
                  OME::DBConnection->DataSource(),
                  OME::DBConnection->DBUser(),
                  OME::DBConnection->DBPassword(), 
                  { RaiseError => 1 });

use fields qw(_flags);

=head1 SQL Statements

Very little internal state is maintained during the execution
algorithm, for two reasons.  First, all of this information is
recorded in the database as part of module execution, so recording
internal state would cause unnecessary duplication.  Second, in the
case of large datasets (on the order of 10,000 images), the internal
state would become an incredible memory overhead, and cause the
algorithm to be horribly slow, if it worked at all.

The following SQL statements are used throughout the execution
algorithm to retrieve the information that would otherwise have been
stored internally in Perl variables.

=head2 sql_get_root_nodes

	$sth = $self->sql_get_root_node();
	$sth->execute($viewID);

Returns the node ID's of all of the root nodes in an module_execution view.

=cut

__PACKAGE__->set_sql('get_root_nodes',<<'SQL;','Main');
SELECT avn.analysis_chain_node_id
  FROM analysis_chain_nodes avn
 WHERE avn.analysis_chain_id = ?
   AND NOT EXISTS
       (SELECT avl.analysis_chain_link_id
          FROM analysis_chain_links avl
         WHERE avl.to_node = avn.analysis_chain_node_id)
SQL;

=head2 sql_get_predecessors

	$sth = $self->sql_get_predecessors();
	$sth->execute($nodeID>);

Returns the node ID's of all of the predecessors of a node.

=cut

__PACKAGE__->set_sql('get_predecessors',<<'SQL;','Main');
SELECT DISTINCT avl.from_node
  FROM analysis_chain_links avl
 WHERE avl.to_node = ?
SQL;

=head2 sql_get_successors

	$sth = $self->sql_get_successors();
	$sth->execute($nodeID>);

Returns the node ID's of all of the successors of a node.

=cut

__PACKAGE__->set_sql('get_successors',<<'SQL;','Main');
SELECT DISTINCT avl.to_node
  FROM analysis_chain_links avl
 WHERE avl.from_node = ?
SQL;

=head2 sql_get_input_attributes

	$sth = $self->sql_get_input_attributes($attribute_table_name);
	$sth->execute($analysisID);

Returns the ID's of the attributes created as outputs from a specific
analysis.

=cut

__PACKAGE__->set_sql('get_input_attributes',<<'SQL;','Main');
  SELECT dt.attribute_id
    FROM %s dt
   WHERE dt.module_execution_id = ?
ORDER BY dt.attribute_id
SQL;

=head2 sql_get_input_image_attributes

	$sth = $self->sql_get_input_image_attributes($attribute_table_name);
	$sth->execute($analysisID,$imageID);

Returns the ID's of the attributes created as outputs from a specific
analysis.  Assumes that the attribute type has image-level
granularity, and limits the attributes returned to those keyed to a
specific image.

=cut

__PACKAGE__->set_sql('get_input_image_attributes',<<'SQL;','Main');
  SELECT dt.attribute_id
    FROM %s dt
   WHERE dt.module_execution_id = ?
     AND dt.image_id = ?
ORDER BY dt.attribute_id
SQL;

=head2 sql_get_input_feature_attributes

	$sth = $self->sql_get_input_feature_attributes($attribute_table_name);
	$sth->execute($analysisID,$imageID);

Returns the ID's of the attributes created as outputs from a specific
analysis.  Assumes that the attribute type has feature-level
granularity, and limits the attributes returned to those keyed to a
specific image.  (Does not take into account which features each
attribute belongs to.)

=cut

__PACKAGE__->set_sql('get_input_feature_attributes',<<'SQL;','Main');
  SELECT dt.attribute_id
    FROM %s dt, features f
   WHERE dt.module_execution_id = ?
     AND dt.feature_id = f.feature_id
     AND f.image_id = ?
ORDER BY dt.attribute_id
SQL;

=head2 sql_get_input_feature_attributes_by_feature

	$sth = $self->sql_get_input_feature_attributes_by_feature($attribute_table_name,$feature_IDs);
	$sth->execute($analysisID);

Returns the ID's of the attributes created as outputs from a specific
analysis.  Assumes that the attribute type has feature-level
granularity, and limits the attributes returned to those keyed to a
specific image.  (Does not take into account which features each
attribute belongs to.)

=cut

__PACKAGE__->set_sql('get_input_feature_attributes_by_feature',<<'SQL;','Main');
  SELECT dt.attribute_id
    FROM %s dt
   WHERE dt.module_execution_id = ?
     AND dt.feature_id in %s
ORDER BY dt.attribute_id
SQL;

=head2 sql_get_input_feature_tags

	$sth = $self->sql_get_input_feature_tags($attribute_table_name);
	$sth->execute($analysisID,$imageID);

Returns the feature tags of the attributes created as outputs from a
specific module_execution.  Assumes that the attribute type has feature-level
granularity, and limits the attributes returned to those keyed to a
specific image.

=cut

__PACKAGE__->set_sql('get_input_feature_tags',<<'SQL;','Main');
  SELECT DISTINCT f.tag
    FROM %s dt, features f
   WHERE dt.module_execution_id = ?
     AND f.image_id = ?
     AND dt.feature_id = f.feature_id
SQL;

=head2 sql_get_input_features

	$sth = $self->sql_get_input_features($attribute_table_name);
	$sth->execute($analysisID,$imageID);

Returns the feature ID's and tags of the attributes created as outputs
from a specific module_execution.  Assumes that the attribute type has
feature-level granularity, and limits the attributes returned to those
keyed to a specific image.

=cut

__PACKAGE__->set_sql('get_input_features',<<'SQL;','Main');
  SELECT DISTINCT f.feature_id, f.tag
    FROM %s dt, features f
   WHERE dt.module_execution_id = ?
     AND f.image_id = ?
     AND dt.feature_id = f.feature_id
SQL;

=head2 sql_get_input_link

	$sth = $self->sql_get_input_link();
	$sth->execute($nodeID,$formal_inputID);

Returns the data link providing input to a formal input of an module_execution
node.

=cut

__PACKAGE__->set_sql('get_input_link',<<'SQL;','Main');
SELECT avl.analysis_chain_link_id
  FROM analysis_chain_links avl
 WHERE avl.to_node = ?
   AND avl.to_input = ?
SQL;

=head2 sql_get_actual_output_from_input

	$sth = $self->sql_get_actual_output_from_input();
	$sth->execute($analysisID,$formal_inputID);

Returns the module_execution providing input to a formal input of an module_execution
node.

=cut

__PACKAGE__->set_sql('get_analysis_from_input',<<'SQL;','Main');
  SELECT ai.input_module_execution_id
    FROM actual_inputs ai
   WHERE ai.module_execution_id = ?
     AND ai.formal_input_id = ?
SQL;

=head2 sql_get_formal_inputs_by_node

	$sth = $self->sql_get_formal_inputs_by_node();
	$sth->execute($nodeID,$granularity);

Returns all of the formal inputs of a given granularity for a node.

=cut

__PACKAGE__->set_sql('get_formal_inputs_by_node',<<'SQL;','Main');
  SELECT fi.formal_input_id
    FROM analysis_chain_nodes avn,
         formal_inputs fi, semantic_types at
   WHERE avn.analysis_chain_node_id = ?
     AND at.granularity = ?
     AND avn.module_id = fi.module_id
     AND fi.semantic_type_id = at.semantic_type_id
ORDER BY fi.formal_input_id
SQL;

=head2 sql_get_formal_inputs_by_not_node

	$sth = $self->sql_get_formal_inputs_by_not_node();
	$sth->execute($nodeID,$granularity);

Returns all of the formal inputs not of a given granularity for a
node.

=cut

__PACKAGE__->set_sql('get_formal_inputs_by_not_node',<<'SQL;','Main');
  SELECT fi.formal_input_id
    FROM analysis_chain_nodes avn,
         formal_inputs fi, semantic_types at
   WHERE avn.analysis_chain_node_id = ?
     AND at.granularity != ?
     AND avn.module_id = fi.module_id
     AND fi.semantic_type_id = at.semantic_type_id
ORDER BY fi.formal_input_id
SQL;

=head2 sql_get_formal_outputs_by_node

	$sth = $self->sql_get_formal_outputs_by_node();
	$sth->execute($nodeID,$granularity);

Returns all of the formal outputs of a given granularity for a node.

=cut

__PACKAGE__->set_sql('get_formal_outputs_by_node',<<'SQL;','Main');
  SELECT fo.formal_output_id
    FROM analysis_chain_nodes avn,
         formal_outputs fo, semantic_types at
   WHERE avn.analysis_chain_node_id = ?
     AND at.granularity = ?
     AND avn.module_id = fo.module_id
     AND fo.semantic_type_id = at.semantic_type_id
ORDER BY fo.formal_output_id
SQL;

=head2 sql_get_formal_inputs_by_analysis

	$sth = $self->sql_get_formal_inputs_by_analysis();
	$sth->execute($analysisID,$granularity);

Returns all of the formal inputs of a given granularity for a node
execution.

=cut

__PACKAGE__->set_sql('get_formal_inputs_by_analysis',<<'SQL;','Main');
  SELECT fi.formal_input_id
    FROM module_executions a,
         formal_inputs fi, semantic_types at
   WHERE a.module_execution_id = ?
     AND at.granularity = ?
     AND a.module_id = fi.module_id
     AND fi.semantic_type_id = at.semantic_type_id
ORDER BY fi.formal_input_id
SQL;

=head2 sql_get_input_links_by_node

	$sth = $self->sql_get_input_links_by_node();
	$sth->execute($nodeID,$granularity);

Returns all of the data links of a given granularity for a node.

=cut

__PACKAGE__->set_sql('get_input_links_by_node',<<'SQL;','Main');
  SELECT avl.analysis_chain_link_id
    FROM analysis_chain_links avl,
         semantic_types at, formal_inputs fi
   WHERE avl.to_node = ?
     AND at.granularity = ?
     AND avl.to_input = fi.formal_input_id
     AND fi.semantic_type_id = at.semantic_type_id
ORDER BY fi.formal_input_id
SQL;


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {
                _flags => {
                           ReuseResults => 1,
                           DebugDefault => 1,
                           DebugTiming  => 1
                          },
               };
    return bless $self, $class;
}


sub Flag {
    my ($self,$flag,$value) = @_;

    return (defined $value)? 
        $self->{_flags}->{$flag} = $value:
        $self->{_flags}->{$flag};
}



# For now assume the module type is the Perl class of the
# module handler.

sub findModuleHandler {
    return shift;
}

{
    # We'll need several shared variables for these internal
    # functions.  They are defined here.

    # The instance of this class.
    my $self;

    # The user's database session.
    my $session;

    # The database factory used to create new database objects and to
    # find existing ones.
    my $factory;

    # The analysis chain being executed.
    my $analysis_chain;

    # The hash of the user-specified input parameters.
    my $input_parameters;

    # The hash of the analyses providing each set of user-specified
    # inputs.
    my %user_input_analyses;
    my %node_inputs;

    # The dataset the chain is being executed against.
    my $dataset;

    # A list of nodes in the analysis chain.
    my @nodes;

    # A hash of nodes keyed by node ID.
    my %nodes;

    # The instantiated modules for each analyis node.
    my %node_modules;

    # The current state of each node.
    use constant INPUT_STATE    => 1;
    use constant FINISHED_STATE => 2;
    my %node_states;

    # The input and output links for each node.
    # $input_links{$nodeID}->{$granularity} = $analysis_link
    # $output_links{$nodeID}->{$granularity} = $analysis_link
    #my %input_links;
    #my %output_links;

    # The analysis_chain_execution entry for this chain execution.
    my $analysis_chain_execution;

    # The dataset-dependence of each node.
    # $dependence{$nodeID} = [D,I]
    my %dependence;

    # The ANALYSES for each node.
    # $global_analysis{$nodeID} = $module_execution
    # $perdataset_analysis{$nodeID} = $module_execution
    # $perimage_analysis{$nodeID}->{$imageID} = $module_execution
    my (%global_analysis, %perdataset_analysis,%perimage_analysis);

    # The outputs generated by each node
    # $dataset_outputs{$nodeID}->
    #   {$formal_outputID} = $attribute
    # $image_outputs{$nodeID}->{$formal_outputID}->
    #   {$imageID} = $attribute
    # $feature_outputs{$nodeID}->{$formal_outputID}->
    #   {$imageID}->{$featureID} = $attribute
    #my (%dataset_outputs,%image_outputs,%feature_outputs);

    # Whether or not we need another round in the fixed-point loop.
    my $continue;

    # Which of those rounds we are in.
    my $round;

    # The node which was most recently executed.
    my $last_node;

    # The following variables are only valid within the per-node loop.
    # They refer to the module currently being examined/executed.
    my ($curr_node,$curr_nodeID,@curr_predecessorIDs);
    my ($curr_module,$curr_inputs,$curr_outputs);
    my (@curr_global_inputs,@curr_dataset_inputs,
        @curr_image_inputs,@curr_feature_inputs);
    my (@curr_global_outputs,@curr_dataset_outputs,
        @curr_image_outputs,@curr_feature_outputs);
    my ($curr_image,$curr_imageID);
    my ($curr_feature,$curr_featureID);

    # The list of data paths found.
    my @data_paths;

    # The data paths to which each node belongs.
    my %data_paths;

    # Timing benchmarks
    my $start_time;
    my $end_time;

    sub __clearEverything {
        $factory = undef;
        %user_input_analyses = ();
        %node_inputs = ();
        @nodes = ();
        %nodes = ();
        %node_modules = ();
        %node_states = ();
        $analysis_chain_execution = undef;
        %dependence = ();
        %global_analysis = ();
        %perdataset_analysis = ();
        %perimage_analysis = ();
        $continue = undef;
        $round = undef;
        $last_node = undef;
        $curr_node = undef;
        $curr_nodeID = undef;
        @curr_predecessorIDs = ();
        $curr_module = undef;
        $curr_inputs = undef;
        $curr_outputs = undef;
        @curr_global_inputs = ();
        @curr_dataset_inputs = ();
        @curr_image_inputs = ();
        @curr_feature_inputs = ();
        @curr_global_outputs = ();
        @curr_dataset_outputs = ();
        @curr_image_outputs = ();
        @curr_feature_outputs = ();
        @data_paths = ();
        %data_paths = ();
        $start_time = undef;
        $end_time = undef;
    }

    # A debug routine
    sub __debug {
        my ($message,$group) = @_;
        $group = defined $group? $group: "Default";

        logtrc "notice", "$message" if $self->Flag("Debug$group");
    }

    # Some helpful database routines

    # Returns the first column of the first row of an executed DBI
    # statement handle.
    sub __fetchone {
        my ($sth) = @_;

        if (my $row = $sth->fetch()) {
            $sth->finish();
            return $row->[0];
        } else {
            return undef;
        }
    }

    # Returns the same as __fetchone, but assumes that the value is a
    # primary key for the specified class.  Instantiates the object
    # and returns it.
    sub __fetchobj {
        my ($class,$sth) = @_;

        if (my $row = $sth->fetch()) {
            $sth->finish();
            return $factory->loadObject($class,$row->[0]);
        } else {
            return undef;
        }
    }

    # Returns an array of the values in the first column of an
    # executed DBI statement handle.
    sub __fetchall {
        my ($sth) = @_;
        my (@results,$row);

        push @results, $row->[0]
          while ($row = $sth->fetch());
        return \@results;
    }

    # Returns the same of __fetchall, but assumes that the value is a
    # primary key for the specified class.  Instantiates an object for
    # each row.
    sub __fetchobjs {
        my ($class,$sth) = @_;
        my (@results,$row);

        push @results, $factory->loadObject($class,$row->[0])
          while ($row = $sth->fetch());
        return \@results;
    }

    # This routine prepares the all of the internal variables for each
    # node in the chain.  It loads in the appropriate module handler,
    # and initializes it with the module's location, and sets up the
    # [dataset,image,feature]_[inputs,outputs] hashes with the input
    # and output links of the module.  Currently, all outputs are
    # added to the hashes, regardless of whether or not they are
    # linked to anything.  However, only those inputs which are
    # connected are pushed into their hashes.
    sub __initializeNode {
        my $module = $curr_node->module();
        my $module_type = $module->module_type();
        my $location = $module->location();

        $nodes{$curr_nodeID} = $curr_node;

        __debug("  ".$module->name());

        __debug("    Loading module $location via handler $module_type");
        my $handler = findModuleHandler($module_type);
        logcroak "Malformed class name $handler"
          unless $handler =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;
        eval "require $handler";
        my $module_instance = $handler->new($location,$session,$module,$curr_node);
        $node_modules{$curr_nodeID} = $module_instance;

        $node_states{$curr_nodeID} = INPUT_STATE;
    }

    # Returns a list of successor nodes to a node.
    sub __successors {
        my ($nodeID) = @_;

        my $sth = $self->sql_get_successors();
        $sth->execute($nodeID);
        return __fetchall($sth);
    }

    # Verifies that every formal input has zero or one links feeding
    # it.  It a formal input has zero links feeding it, verifies that
    # the user input provided for the input (defaulting to null) is
    # valid, according to the input's optional and list specification.
    # Also verifies that each link is well-formed; i.e., that the
    # "from output" belongs to the "from node", the "to input" belongs
    # to the "to node", and that the types of the "from output" and
    # "to input" match.
    sub __checkInputs {
        __debug("    Sorting and checking links");
        foreach my $link ($analysis_chain->links()) {
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

        # Contains the number of distinct user inputs of each
        # semantic type.
        my %input_types;
        my %input_analyses;
        my $max_input_analyses = 0;

        __debug("    Checking nodes");
        foreach my $node (@nodes) {
            __debug("      ".$node->module()->name());
            my @inputs = $node->module()->inputs();
            foreach my $input (@inputs) {
                # Okay if there's a link feeding this input
                my $nodeID = $node->id();
                my $inputID = $input->id();
                next if exists $node_inputs{$nodeID}->{$inputID};

                # Keep a count of the number of user inputs of this type
                my $semantic_type = $input->semantic_type();
                my $semantic_typeID = $semantic_type->id();
                $input_types{$semantic_typeID}++;

                # ...and keep track of the maximum of that count
                my $this_max = $input_types{$semantic_typeID};
                $input_analyses{$nodeID}->{$inputID} = $this_max;
                $max_input_analyses = $this_max
                  if $this_max > $max_input_analyses;

                # See if the user provided inputs
                my $user;
                if (exists $input_parameters->{$nodeID}->{$inputID}) {
                    $user = $input_parameters->{$nodeID}->{$inputID};
                    if (UNIVERSAL::isa($user,"OME::SemanticType::Superclass")) {
                        # If the user provided a single input, wrap it
                        # in an array ref
                        $user = [$user];
                    } elsif (ref($user) ne 'ARRAY') {
                        # Otherwise only accept the input if its an
                        # array ref
                        die
                          $node->module()->name().".".
                          $input->name().
                          ": User input must be an attribute ".
                          "or array of attributes";
                    }
                } else {
                    # User did not provide input, so treat this input
                    # as receiving an empty array
                    $user = [];
                }
                $input_parameters->{$nodeID}->{$inputID} = $user;

                # Check those inputs against the spec
                die "Input is not optional"
                  if (!$input->optional()) && (scalar(@$user) == 0);
                die "Input cannot accept a list"
                  if (!$input->list()) && (scalar(@$user) > 1);
            }
        }

        __debug("    Creating $max_input_analyses user input analyses");
        my @analyses;
        $analyses[$_] = $factory->
          newObject("OME::ModuleExecution",
                    {
                     module_id => undef,
                     dependence => 'D',
                     dataset_id => $dataset->id(),
                     timestamp  => 'now',
                     status     => 'FINISHED',
                    })
          foreach 0..$max_input_analyses-1;

        #print join("\n",@analyses),"\n";

        # Create a hash, recording which module_execution we will associate each
        # user input with.  We won't actually clone the user inputs
        # until it's time to execute the module.  (This prevents extra
        # user inputs from cluttering everything in case the chain
        # doesn't execute completely.)

        foreach my $nodeID (keys %input_analyses) {
            foreach my $inputID (keys %{$input_analyses{$nodeID}}) {
                my $index = $input_analyses{$nodeID}->{$inputID};
                __debug("      ${nodeID}.${inputID} = $index");
                $user_input_analyses{$nodeID}->{$inputID} =
                  $analyses[$index-1];
            }
        }
    }

    # Clones the user inputs for the current node.  The cloned
    # attributes are associated with the module_execution created by the
    # __checkInputs method.

    sub __cloneUserInputs {
        #print "      CLONE $curr_nodeID\n";
        foreach my $inputID (keys %{$user_input_analyses{$curr_nodeID}}) {
            my $inputs = $input_parameters->{$curr_nodeID}->{$inputID};
            my $module_execution = $user_input_analyses{$curr_nodeID}->{$inputID};
            #print "         $inputID - ",$module_execution->id(),"\n";

            foreach my $attribute (@$inputs) {
                my $type = $attribute->semantic_type();
                my $target = $attribute->target();
                my $hash = $attribute->getDataHash();

                my $clone = $factory->
                  newAttribute($type,$target,$module_execution,$hash);
                $session->commitTransaction();
                #print "          $clone\n";
            }
        }
    }

    # Builds the data paths for an module_execution chain.  Simultaneous
    # verifies that the graph is acyclic.
    sub __buildDataPaths {
        __debug("  Building data paths");

        # A data path is represented by a list of node ID's, starting
        # with a root node and ending with a leaf node.

        my $sth;

        # First, we create paths for each root node in the chain
        $sth = $self->sql_get_root_nodes();
        $sth->execute($analysis_chain->id());
        while (my $row = $sth->fetch) {
            __debug("    Found root node ".$row->[0]);
            my $path = [$row->[0]];
            push @data_paths, $path;
        }

        # Then, we iteratively extend each path until it reaches a
        # leaf node.  If at any point, it branches, we create
        # duplicates so that there is one path per branch-point.
        my $continue = 1;
        while ($continue) {
            $continue = 0;
            my @new_paths;
            while (my $data_path = shift(@data_paths)) {
                my $end_nodeID = $data_path->[$#$data_path];
                my $successors = __successors($end_nodeID);
                my $num_successors = scalar(@$successors);

                if ($num_successors == 0) {
                    push @new_paths,$data_path;
                } elsif ($num_successors == 1) {
                    # Check for a cycle
                    foreach (@$data_path) {
                        die
                          "Cycle! ".join(':',@$data_path,$successors->[0])
                            if $_ eq $successors->[0];
                    }

                    __debug("    Extending ".
                      join(':',@$data_path)." with ".
                        $successors->[0]);
                    push @$data_path, $successors->[0];
                    push @new_paths,$data_path;
                    $continue = 1;
                } else {
                    foreach my $successor (@$successors) {
                        # Check for a cycle
                        foreach (@$data_path) {
                            die
                              "Cycle! ".join(':',@$data_path,$successors->[0])
                                if $_ eq $successors->[0];
                        }

                        # make a copy
                        my $new_path = [@$data_path];
                        __debug("    Extending ".
                          join(':',@$new_path)." with ".
                            $successor);
                        push @$new_path, $successor;
                        push @new_paths, $new_path;
                    }
                    $continue = 1;
                }
            }

            @data_paths = @new_paths;
        }

        foreach my $data_path_list (@data_paths) {
            my $data_path = $factory->
              newObject("OME::AnalysisPath",
                        {
                         path_length   => scalar(@$data_path_list),
                         analysis_chain => $analysis_chain
                        });
            my $data_pathID = $data_path->id();

            my $order = 0;
            foreach my $nodeID (@$data_path_list) {
                my $path_entry =
                  {
                   path               => $data_path,
                   path_order         => $order,
                   analysis_chain_node => $nodeID
                  };
                my $db_path_entry = $factory->
                  newObject("OME::AnalysisPath::Map",
                            $path_entry);
                push @{$data_paths{$nodeID}}, $db_path_entry;
                $order++;
            }
        }
    }

    # Loads the data paths for an analysis chain which has already had
    # them built.
    sub __loadDataPaths {
        __debug("  Loading data paths");

        my @db_paths = $analysis_chain->paths();
        foreach my $db_path (@db_paths) {
            my @db_path_entries = $db_path->path_nodes();
            foreach my $db_path_entry (@db_path_entries) {
                push
                  @{$data_paths{$db_path_entry->analysis_chain_node()->id()}},
                  $db_path_entry;
            }
        }
    }

    # Returns the correct module_execution entry for the given node.  Takes
    # into account the dataset-dependence of the node; if it is a
    # per-image node, it finds the module_execution entry for the current
    # image.
    sub __getAnalysis {
        my ($nodeID) = @_;

        if ($dependence{$nodeID} eq 'G') {
            return $global_analysis{$nodeID};
        } elsif ($dependence{$nodeID} eq 'D') {
            return $perdataset_analysis{$nodeID};
        } else {
            return $perimage_analysis{$nodeID}->{$curr_imageID};
        }
    }

    # If any of the predecessors has not finished, then this
    # node is not ready to run.
    sub __testModulePredecessors {
        my $ready = 1;

      TEST_PRED:
        foreach my $predID (@curr_predecessorIDs) {
            if ($node_states{$predID} < FINISHED_STATE) {
                $ready = 0;
                last TEST_PRED;
            }
        }

        return $ready;
    }

    # Determines whether the current node is a global, per-dataset or
    # per-image module.  If a module outputs any global attributes
    # (which is only allowed if all of its inputs are global
    # attributes), then the module is global.  If a module takes in
    # any dataset inputs, or outputs any dataset outputs, or if any of
    # its immediate predecessors nodes are per-dataset, then it as
    # per-dataset.  Otherwise, it is per-image.  This notion of
    # dataset-dependency comes in to play later when determine whether
    # or not a module's results can be reused.
    sub __determineDependence {
        my $sth;

        $sth = $self->sql_get_formal_outputs_by_node();
        $sth->execute($curr_nodeID,'G');
        if ($sth->fetch()) {
            $dependence{$curr_nodeID} = 'G';
            $sth->finish();

            $sth = $self->sql_get_formal_inputs_by_not_node();
            $sth->execute($curr_nodeID,'G');
            if ($sth->fetch()) {
                $sth->finish();
                die "Node $curr_nodeID illegally generates global outputs";
            }

            return;
        }

        $sth = $self->sql_get_formal_inputs_by_node();
        $sth->execute($curr_nodeID,'D');
        if ($sth->fetch()) {
            $dependence{$curr_nodeID} = 'D';
            $sth->finish();
            return;
        }

        $sth = $self->sql_get_formal_outputs_by_node();
        $sth->execute($curr_nodeID,'D');
        if ($sth->fetch()) {
            $dependence{$curr_nodeID} = 'D';
            $sth->finish();
            return;
        }

        foreach my $predID (@curr_predecessorIDs) {
            if ($dependence{$predID} eq 'D') {
                $dependence{$curr_nodeID} = 'D';
                return;
            }
        }

        $dependence{$curr_nodeID} = 'I';
    }

    sub __getDataTables {
        my ($formal_input) = @_;

        my $attr_type = $formal_input->semantic_type();

        my %data_tables;
        foreach my $sem_elem ($attr_type->semantic_elements()) {
            my $data_column = $sem_elem->data_column();
            my $data_table = $data_column->data_table();
            my $table_name = $data_table->table_name();
            $data_tables{$table_name} = $data_table;
        }

        return keys %data_tables;
    }

    # The following routines are used to check to see if we need to
    # execute the current module, or if it can be reused.
    #
    # We allow results to be reused if the "input tag" of the current
    # module's state is equal to the input tag of a previous execution
    # of the same module.  The input tag is a string that captures the
    # essence of a module's input.  It records: whether the module was
    # run in a per-dataset manner, or a per-image manner; which
    # dataset or image (respectively) it was run against; and the
    # attribute ID's presented to the module as input.

    # This routine calculates the input tag of the current module.
    # This routine will not get called unless a module is ready to be
    # executed, which means that the results of the predecessor
    # modules are available.  It is the attribute ID's of these
    # results that are encoded into the input tag.
    sub __calculateCurrentInputTag {
        my ($paramString,$sth);

        if ($dependence{$curr_nodeID} eq 'G') {
            $paramString = "G ";
        } elsif ($dependence{$curr_nodeID} eq 'D') {
            $paramString = "D ".$dataset->id()." ";
        } else {
            $paramString = "I ".$curr_imageID." ";
        }

        $paramString .= "g ";
        #$sth = $self->sql_get_formal_inputs_by_node();
        #$sth->execute($curr_nodeID,'G');
        #my $formal_inputIDs = __fetchall($sth);

        foreach my $formal_input (@curr_global_inputs) {
            my $formal_inputID = $formal_input->id();
            $paramString .= $formal_inputID."(";

            $sth = $self->sql_get_input_link();
            $sth->execute($curr_nodeID,$formal_inputID);
            my $input_link = __fetchobj("OME::AnalysisChain::Link",$sth);
            my ($pred_node,$pred_analysis);

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            #print "   $pred_analysisID\n";

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                #print "   $table_name\n";
                $sth = $self->sql_get_input_attributes($table_name);
                $sth->execute($pred_analysisID);

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $paramString .= ") ";
        }

        $paramString .= "d ";
        $sth = $self->sql_get_formal_inputs_by_node();
        $sth->execute($curr_nodeID,'D');
        my $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $paramString .= $formal_inputID."(";

            $sth = $self->sql_get_input_link();
            $sth->execute($curr_nodeID,$formal_inputID);
            my $input_link = __fetchobj("OME::AnalysisChain::Link",$sth); 
            my ($pred_node,$pred_analysis);

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->
              loadObject("OME::Module::FormalInput",
                         $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                $sth = $self->sql_get_input_attributes($table_name);
                $sth->execute($pred_analysisID);

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $paramString .= ") ";
        }

        $paramString .= "i ";
        $sth = $self->sql_get_formal_inputs_by_node();
        $sth->execute($curr_nodeID,'I');
        $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $paramString .= $formal_inputID."(";

            $sth = $self->sql_get_input_link();
            $sth->execute($curr_nodeID,$formal_inputID);
            my $input_link = __fetchobj("OME::AnalysisChain::Link",$sth);
            my ($pred_node,$pred_analysis);

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->
              loadObject("OME::Module::FormalInput",
                         $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                if ($dependence{$curr_nodeID} eq 'D') {
                    $sth = $self->sql_get_input_attributes($table_name);
                    $sth->execute($pred_analysisID);
                } else {
                    $sth = $self->sql_get_input_image_attributes($table_name);
                    $sth->execute($pred_analysisID,
                                  $curr_imageID);
                }

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $paramString .= ") ";
        }

        $paramString .= "f ";
        $sth = $self->sql_get_formal_inputs_by_node();
        $sth->execute($curr_nodeID,'F');
        $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $paramString .= $formal_inputID."(";

            $sth = $self->sql_get_input_link();
            $sth->execute($curr_nodeID,$formal_inputID);
            my $input_link = __fetchobj("OME::AnalysisChain::Link",$sth);
            my ($pred_node,$pred_analysis);

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->loadObject("OME::Module::FormalInput",
                                                    $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                my $pred_node = $input_link->from_node();

                if ($dependence{$curr_nodeID} eq 'D') {
                    $sth = $self->sql_get_input_attributes($table_name);
                    $sth->execute($pred_analysisID);
                } else {
                    $sth = $self->sql_get_input_feature_attributes($table_name);
                    $sth->execute($pred_analysisID,
                                  $curr_imageID);
                }

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $paramString .= ") ";
        }

        return $paramString;
    }

    # This routine calculates the input tag of a previous module_execution.
    # All of the appropriate elements of the tag can be retrieved from
    # the ANALYSES and ACTUAL_INPUTS tables.
    sub __calculatePastInputTag {
        my ($past_analysis) = @_;
        my $past_analysisID = $past_analysis->id();
        my ($past_paramString,$sth);

        if ($past_analysis->dependence() eq 'G') {
            $past_paramString = "G ";
        } elsif ($past_analysis->dependence() eq 'D') {
            $past_paramString = "D ".$past_analysis->dataset()->id()." ";
        } else {
            $past_paramString = "I ".$curr_imageID." ";
        }

        $past_paramString .= "g ";
        $sth = $self->sql_get_formal_inputs_by_analysis();
        $sth->execute($past_analysisID,'G');
        my $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $past_paramString .= $formal_inputID."(";

            $sth = $self->sql_get_analysis_from_input();
            $sth->execute($past_analysisID,$formal_inputID);
            my $input_module_execution = __fetchobj("OME::ModuleExecution",$sth);
            my ($pred_node,$pred_analysis);
            my $input_link = $node_inputs{$curr_nodeID}->{$formal_inputID};

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->
              loadObject("OME::Module::FormalInput",
                         $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                $sth = $self->sql_get_input_attributes($table_name);
                $sth->execute($input_module_execution->id());

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $past_paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $past_paramString .= ") ";
        }

        $past_paramString .= "d ";
        $sth = $self->sql_get_formal_inputs_by_analysis();
        $sth->execute($past_analysisID,'D');
        $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $past_paramString .= $formal_inputID."(";

            $sth = $self->sql_get_analysis_from_input();
            $sth->execute($past_analysisID,$formal_inputID);
            my $input_module_execution = __fetchobj("OME::ModuleExecution",$sth);
            my ($pred_node,$pred_analysis);
            my $input_link = $node_inputs{$curr_nodeID}->{$formal_inputID};

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->
              loadObject("OME::Module::FormalInput",
                         $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                $sth = $self->sql_get_input_attributes($table_name);
                $sth->execute($input_module_execution->id());

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $past_paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $past_paramString .= ") ";
        }

        $past_paramString .= "i ";
        $sth = $self->sql_get_formal_inputs_by_analysis();
        $sth->execute($past_analysisID,'I');
        $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $past_paramString .= $formal_inputID."(";

            $sth = $self->sql_get_analysis_from_input();
            $sth->execute($past_analysisID,$formal_inputID);
            my $input_module_execution = __fetchobj("OME::ModuleExecution",$sth);
            my ($pred_node,$pred_analysis);
            my $input_link = $node_inputs{$curr_nodeID}->{$formal_inputID};

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->
              loadObject("OME::Module::FormalInput",
                         $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                if ($dependence{$curr_nodeID} eq 'D') {
                    $sth = $self->sql_get_input_attributes($table_name);
                    $sth->execute($input_module_execution->id());
                } else {
                    $sth = $self->sql_get_input_image_attributes($table_name);
                    $sth->execute($input_module_execution->id(),
                                  $curr_imageID);
                }

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $past_paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $past_paramString .= ") ";
        }

        $past_paramString .= "f ";
        $sth = $self->sql_get_formal_inputs_by_analysis();
        $sth->execute($past_analysisID,'F');
        $formal_inputIDs = __fetchall($sth);

        foreach my $formal_inputID (@$formal_inputIDs) {
            $past_paramString .= $formal_inputID."(";

            $sth = $self->sql_get_analysis_from_input();
            $sth->execute($past_analysisID,$formal_inputID);
            my $input_module_execution = __fetchobj("OME::ModuleExecution",$sth);
            my ($pred_node,$pred_analysis);
            my $input_link = $node_inputs{$curr_nodeID}->{$formal_inputID};

            if (!defined $input_link) {
                $pred_analysis =
                  $user_input_analyses{$curr_nodeID}->{$formal_inputID};
            } else {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            }

            my $pred_analysisID = $pred_analysis->id();
            my $formal_input = $factory->loadObject("OME::Module::FormalInput",
                                                    $formal_inputID);

            my %attributes;
            foreach my $table_name (__getDataTables($formal_input)) {
                if ($dependence{$curr_nodeID} eq 'D') {
                    $sth = $self->sql_get_input_attributes($table_name);
                    $sth->execute($input_module_execution->id());
                } else {
                    $sth = $self->sql_get_input_feature_attributes($table_name);
                    $sth->execute($input_module_execution->id(),
                                  $curr_imageID);
                }

                $attributes{$_} = $_
                    foreach @{__fetchall($sth)};
            }

            $past_paramString .= "$_ "
                foreach sort {$a <=> $b} keys %attributes;
            $past_paramString .= ") ";
        }

        return $past_paramString;
    }

    sub __createAnalysis {
        my ($data) = @_;
        my $module_execution = $factory->
          newObject("OME::ModuleExecution",
                    $data);
        __addAnalysisToPaths($module_execution);

        return $module_execution;
    }

    sub __createActualInputs {
        my ($node) = @_;
        my $nodeID = $node->id();
        my $module_execution = __getAnalysis($nodeID);

        my %actual_inputs;

        #__debug("**** actual inputs");
        my $module = $module_execution->module();

        foreach my $formal_input ($module->inputs()) {
            my $inputID = $formal_input->id();
            my $input_link = $node_inputs{$nodeID}->{$inputID};

            #__debug("****   ".$formal_input->name());

            my ($pred_node,$pred_analysis);

            if (defined $input_link) {
                $pred_node = $input_link->from_node();
                $pred_analysis = __getAnalysis($pred_node->id());
            } else {
                $pred_analysis =
                  $user_input_analyses{$nodeID}->{$inputID};
            }

            #__debug("****   ".$pred_node->id());

            #__debug("****     $actual_outputID");

            my $actual_input = $factory->
              newObject("OME::ModuleExecution::ActualInput",
                        {
                         module_execution          => $module_execution->id(),
                         formal_input_id           => $inputID,
                         input_module_execution_id => $pred_analysis->id()
                        });

            #__debug("****     ".$actual_input->id());
        }
    }

    sub __addAnalysisToPaths {
        my ($module_execution) = @_;
        foreach my $db_data_path_entry (@{$data_paths{$curr_nodeID}}) {
            my $node_execution = $factory->
              newObject("OME::AnalysisChainExecution::NodeExecution",
                        {
                         analysis_chain_execution => $analysis_chain_execution,
                         analysis_chain_node      => $curr_nodeID,
                         module_execution         => $module_execution,
                        });
        }
    }

    # Updates the hash of module_execution entries.  Takes into account the
    # dataset-dependency of the current module.
    sub __assignAnalysis {
        my ($module_execution,$reused) = @_;

        if ($dependence{$curr_nodeID} eq 'G') {
            $global_analysis{$curr_nodeID} = $module_execution;
        } elsif ($dependence{$curr_nodeID} eq 'D') {
            $perdataset_analysis{$curr_nodeID} = $module_execution;
        } else {
            $perimage_analysis{$curr_nodeID}->{$curr_imageID} = $module_execution;
        }
        #$module_execution{$curr_nodeID} = $module_execution unless $reused;
    }

    # This routine performs the check that determines whether results
    # can be reused, using the methods described above.
    sub __checkPastResults {
        # Allow the user to skip module_execution reuse.  This should really
        # only be used for testing.
        return 0 if (!$self->Flag('ReuseResults')
                     && $curr_node->module()->name() ne "Importer");

        my $paramString = __calculateCurrentInputTag();
        my $space = ($dependence{$curr_nodeID} eq 'I')? '  ': '';
        __debug("$space  Param $paramString");

        my $match = 0;
        my $matched_analysis;
        my @past_analyses = $factory->
          findObjects("OME::ModuleExecution",
                      module_id => $curr_node->module()->id());
        my $this_analysis = __getAnalysis($curr_nodeID);
        my $this_analysisID;
        $this_analysisID = $this_analysis->id() if (defined $this_analysis);

      FIND_MATCH:
        foreach my $past_analysis (@past_analyses) {
            __debug("$space    Checking module_execution ".$past_analysis->id()."...");
            if ($past_analysis->status() ne 'FINISHED') {
                __debug("$space      unfinished.");
                next FIND_MATCH;
            }
            if (defined $this_analysisID &&
                $past_analysis->id() eq $this_analysisID) {
                __debug("$space      current module_execution.");
                next FIND_MATCH;
            }
            my $image_map = $factory->
                findObject("OME::Image::DatasetMap",
                           image_id   => $curr_imageID,
                           dataset_id => $past_analysis->dataset()->id());
            if (!defined $image_map) {
                __debug("$space      didn't execute against this image.");
                next FIND_MATCH;
            }

            my $past_paramString = __calculatePastInputTag($past_analysis);
            __debug("$space    Found $past_paramString ");

            if ($past_paramString eq $paramString) {
                $match = 1;
                $matched_analysis = $past_analysis;
                __debug("$space      match!");
                last FIND_MATCH;
            }

            __debug("$space      mismatch.");
        }

        if ($match) {
            __debug("$space    Found reusable module_execution ".$matched_analysis->id());
            __addAnalysisToPaths($matched_analysis);
            __assignAnalysis($matched_analysis,1);
        }

        return $match;
    }

    # $hierarchy_children{$tag} = [ tags ]
    # $hierarchy_parent{$tag} = [ parent tag ]
    # @hierarchy_roots = [ tags who have no parent features ]

    my (%hierarchy_children,%hierarchy_parent,%hierarchy_roots);

    sub __printHierarchy {
        my ($prefix) = @_;

        my %tags_found;

        my $print_tag;
        $print_tag = sub {
            my ($prefix,$tag) = @_;

            if (exists $tags_found{$tag}) {
                __debug("${prefix}ERROR!  '$tag' found twice!");
                croak "$tag found twice in feature hierarchy";
            }

            __debug("${prefix}'${tag}'");
            $tags_found{$tag} = 1;

            foreach (keys %{$hierarchy_children{$tag}}) {
                &$print_tag("$prefix  ",$_) if defined $_;
            }
        };

        __debug("$prefix<Image>");
        &$print_tag("$prefix  ",$_) foreach keys %hierarchy_roots;
    }

    # Builds the feature hierarchy for a given node.  This changes
    # from node to node.

    sub __calculateHierarchy {
        %hierarchy_children = ();
        %hierarchy_parent = ();
        %hierarchy_roots = ();

        my %nodes_to_examine;
        my %nodes_examined;

        $nodes_to_examine{$curr_nodeID} = 1;

        # For every node left to examine:
        #   Find its tags' parents, mark this in the hierarchy.
        #   Add its predecessor nodes to the list of nodes to examine.
        my $continue = 1;
        while ($continue) {
            $continue = 0;
            foreach my $this_nodeID (keys %nodes_to_examine) {
                next if (exists $nodes_examined{$this_nodeID});

                my %this_tags;

                my $sth = $self->sql_get_input_links_by_node();
                $sth->execute($this_nodeID,'F');
                foreach my $input_link (@{__fetchobjs("OME::AnalysisChain::Link",$sth)}) {
                    my $formal_input = $input_link->to_input();
                    #my $attr_table = $formal_input->datatype()->table_name();

                    my %tags;
                    my $formal_output = $input_link->from_output();
                    my $pred_node = $input_link->from_node();
                    my $pred_nodeID = $pred_node->id();
                    my $pred_iterator = $pred_node->iterator_tag();

                    foreach my $attr_table (__getDataTables($formal_input)) {
                        $sth = $self->sql_get_input_feature_tags($attr_table);
                        $sth->execute(__getAnalysis($pred_nodeID)->id(),
                                      $curr_imageID);
                        $tags{$_} = 1
                            foreach @{__fetchall($sth)};
                    }

                    $pred_iterator = '[Image]' unless (defined $pred_iterator);

                    foreach my $tag (keys %tags) {
                        # Each of the tags that were found must either
                        # a) match the iterator tag of the predecessor
                        # node, or b) must be a child of the
                        # predecessor iterator.

                        #__debug("          Found tag $tag");

                        if ($pred_iterator eq '[Image]') {
                            #__debug("            $tag is a child of <Image>");
                            $hierarchy_parent{$tag} = undef;
                            $hierarchy_roots{$tag} = 1;
                        } elsif ($tag eq $pred_iterator) {
                            #__debug("            $tag is propagating");
                            # No more parents can be determined at
                            # this point.
                        } else {
                            #__debug("            $tag is a parent of $pred_iterator");
                            $hierarchy_parent{$tag} = $pred_iterator;
                            $hierarchy_children{$pred_iterator}->{$tag} = 1;
                        }
                    }

                    $nodes_to_examine{$pred_nodeID} = 1;
                }


                $continue = 1;
                $nodes_examined{$this_nodeID} = 1;
            }
        }
    }

    my %sqls_defined;

    sub __buildIteratorSQL {
        my ($iterator,$tag) = @_;

        # Tries to build an SQL statement that finds the iterator
        # features that correspond to a given tag feature.

        #__debug("Building SQL for iterator $iterator and tag $tag");


        # Quickly handle the trivial case.

        if ($iterator eq $tag) {
            my $filter_method = "iterator_features_0";

            if (!$sqls_defined{$filter_method}) {
                # Yes, this is a silly query.  But we need some query here.
                my $sql = "SELECT FEATURE_ID FROM FEATURES WHERE FEATURE_ID %s";

                __PACKAGE__->set_sql($filter_method,$sql,'Main');
                $sqls_defined{$filter_method} = 1;

                #__debug("$sql");
            }

            return "sql_${filter_method}";
        }

        # Search up the tree.
        my @path = ($tag);

        while ($path[0] ne $iterator) {
            my $parent = $hierarchy_parent{$path[0]};
            if (defined $parent) {
                unshift @path, $parent;
            } else {
                last;
            }
        }

        my $forwards = 1;

        # Did we find one?
        if ($path[0] ne $iterator) {
            # No, so, search down the tree.  Or in other words, search up
            # the tree from the opposite end.

            @path = ($iterator);

            while ($path[0] ne $tag) {
                my $parent = $hierarchy_parent{$path[0]};
                if (defined $parent) {
                    unshift @path, $parent;
                } else {
                    last;
                }
            }

            $forwards = 0;

            # Did we find one?
            if ($path[0] ne $tag) {
                croak "No path in the feature hierarchy between $tag and $iterator";
            }
        }

        my $num_levels = scalar(@path);
        my $filter_method = "iterator_features_${num_levels}_${forwards}";

        if (!$sqls_defined{$filter_method}) {
            my @tables = ();
            my @joins = ();
            foreach (0..$num_levels-1) {
                push @tables, "FEATURES F".$_;
                push @joins, "F".$_.".FEATURE_ID = F".($_ + 1).".PARENT_FEATURE_ID"
                  if $_ < $num_levels-1;
            }

            my $select_table = $forwards? 'F0': 'F'.($num_levels-1);
            my $filter_table = $forwards? 'F'.($num_levels-1): 'F0';
            push @joins, "${filter_table}.FEATURE_ID %s";

            my $sql =
              "SELECT ${select_table}.FEATURE_ID FROM ".
                join(", ",@tables)." WHERE ".
                  join(" AND ",@joins);

            __debug("$sql");

            __PACKAGE__->set_sql($filter_method,$sql,'Main');
            $sqls_defined{$filter_method} = 1;
        }

        return "sql_${filter_method}";
    }

    sub __findIteratorFeatures {
        # keyed by tag
        my %input_features;

        foreach my $formal_input (@curr_feature_inputs) {
            #my $formal_input = $input_link->to_input();
            #my $attr_table = $formal_input->datatype()->table_name();

            my $input_link = $node_inputs{$curr_nodeID}->{$formal_input->id()};
            next unless defined $input_link;

            my $formal_output = $input_link->from_output();
            my $pred_node = $input_link->from_node();

            foreach my $attr_table (__getDataTables($formal_input)) {
                my $sth = $self->sql_get_input_features($attr_table);
                $sth->execute(__getAnalysis($pred_node->id())->id(),
                              $curr_imageID);

                while (my $row = $sth->fetch) {
                    my ($featureID,$tag) = @$row;
                    #__debug("--- $featureID $tag");
                    $input_features{$tag}->{$featureID} = 1;
                }
            }
        }

        my $iterator = $curr_node->iterator_tag();
        my %iterator_features;

        foreach my $tag (keys %input_features) {
            my $features = $input_features{$tag};
            my @features = keys %$features;

            if (scalar(@features) > 0) {
                # Build up the SQL statement to find the iterator tags.
                my $sql = __buildIteratorSQL($iterator,$tag);

                my $sth = $self->$sql("in (".join(",",@features).")");
                $sth->execute();
                my $features = __fetchall($sth);

                foreach (@$features) {
                    #__debug("$_ !");
                    $iterator_features{$_} = 1;
                }
            }
        }

        my @feature_IDs = keys %iterator_features;
        #__debug(join(',',@feature_IDs));
        return \@feature_IDs;
    }

    sub __findFeatureAttributes {
        my ($formal_input) = @_;

        my $iterator = $curr_node->iterator_tag();

        # the curr_feature is the iterator feature
        #my $formal_input = $input_link->to_input();
        #my $attr_table = $formal_input->datatype()->table_name();

        my $input_link = $node_inputs{$curr_nodeID}->{$formal_input->id()};

        if (!defined $input_link) {
            # If this input is user-specified, then we don't need to do
            # anything fancy to find the inputs.
            return __findInputAttributes($formal_input,
                                         "         ",
                                         "sql_get_input_feature_attributes",
                                         $curr_imageID);
        }

        my $formal_output = $input_link->from_output();
        my $pred_node = $input_link->from_node();

        my %tags;
        my $sth;

        foreach my $attr_table (__getDataTables($formal_input)) {
            my $sth = $self->sql_get_input_feature_tags($attr_table);
            $sth->execute(__getAnalysis($pred_node->id())->id(),
                          $curr_imageID);

            $tags{$_} = 1
                foreach @{__fetchall($sth)};
        }

        my %input_features;

        foreach my $tag (keys %tags) {
            #__debug("$tag!!!!!");
            my $sql = __buildIteratorSQL($tag,$iterator);
            #__debug("  $sql");
            my $snippet = "= $curr_featureID";
            #__debug("  '$snippet'");
            $sth = $self->$sql($snippet);

            #print "****** '$curr_featureID'";
            $sth->execute();

            $input_features{$_} = 1 foreach @{__fetchall($sth)};
        }

        my @feature_IDs = keys %input_features;
        my $feature_IDs = join(",",keys %input_features);
        #__debug(" $feature_IDs");

        my %attributes;

        foreach my $attr_table (__getDataTables($formal_input)) {
            $sth = $self->
                sql_get_input_feature_attributes_by_feature($attr_table,
                                                            "($feature_IDs)");
            $sth->execute(__getAnalysis($pred_node->id())->id());

            $attributes{$_} = 1
                foreach @{__fetchall($sth)};
        }
        my @result = keys %attributes;

        return \@result;
    }

    sub __processAllFeatures {
        $curr_module->startFeature(undef);

        __debug("      Feature inputs");
        my %feature_hash;
        foreach my $input (@curr_feature_inputs) {
            $feature_hash{$input->name()} =
                __findInputAttributes($input,
                                      "         ",
                                      "sql_get_input_feature_attributes",
                                      $curr_imageID);
        }
        $curr_module->featureInputs(\%feature_hash);

        __debug("      Calculate feature");
        $curr_module->calculateFeature();

        $curr_module->finishFeature();
    }

    sub __processOneFeature {
        #__debug("        startFeature ".$curr_featureID);
        $curr_module->startFeature($curr_feature);

        #__debug("          Feature inputs");
        my %feature_hash;

        foreach my $formal_input (@curr_feature_inputs) {
            #__debug("  Link ".$input_link." ".$formal_input->name());
            my $attr_type_name = $formal_input->semantic_type()->name();
            my @attributes = @{__findFeatureAttributes($formal_input)};

            # Turn the attribute ID's into attribute objects.
            $_ = $factory->loadAttribute($attr_type_name,$_)
                foreach (@attributes);

            #__debug("            ".$formal_input->name()." (".
            #  scalar(@attributes).")");

            $feature_hash{$formal_input->name()} = \@attributes;
        }

        $curr_module->featureInputs(\%feature_hash);

        #__debug("          Calculate feature");
        $curr_module->calculateFeature();

        $curr_module->finishFeature();
    }

    sub __findInputAttributes {
        my ($formal_input,$prefix,$sql_method,$extra_input,$no_load) = @_;

        #my $formal_input = $input_link->to_input();
        my $inputID = $formal_input->id();
        my $input_link = $node_inputs{$curr_nodeID}->{$inputID};
        my $attr_type = $formal_input->semantic_type();
        my $attr_type_name = $attr_type->name();

        my $pred_analysis;

        if (defined $input_link) {
            my $pred_node = $input_link->from_node();
            $pred_analysis = __getAnalysis($pred_node->id());
        } else {
            $pred_analysis = $user_input_analyses{$curr_nodeID}->{$inputID};
            #print "        ${curr_nodeID}.${inputID} = $pred_analysis\n";
        }

        my $sth;
        my %attribute_ids;

        foreach my $attr_table (__getDataTables($formal_input)) {
            $sth = $self->$sql_method($attr_table);
            if (defined $extra_input) {
                $sth->execute($pred_analysis->id(),
                              $extra_input);
            } else {
                $sth->execute($pred_analysis->id());
            }
            $attribute_ids{$_} = $_
              foreach @{__fetchall($sth)};
        }


        my @attribute_ids = values %attribute_ids;
        return \@attribute_ids if ($no_load);

        my %attribute_list;
        $attribute_list{$_} =
          $factory->loadAttribute($attr_type,$_)
          foreach @attribute_ids;

        my @attribute_list = values %attribute_list;

        __debug($prefix.$formal_input->name()." (".
          scalar(@attribute_list).")");


        return \@attribute_list;
    }

    # The main body of the analysis engine.  Its purpose is to execute
    # a prebuilt analysis chain against a dataset, reusing results if
    # possible.
    sub executeAnalysisView {
        ($self, $session, $analysis_chain, $input_parameters, $dataset) = @_;

        __clearEverything();
        $factory = $session->Factory();

        $start_time = new Benchmark;

        # all nodes
        @nodes = $analysis_chain->nodes();

        __debug("Setup");

        __debug("  Validating chain");
        __checkInputs();

        __debug("  Locking the dataset");
        $dataset->locked('true');
        $dataset->storeObject();

        # Build the data paths.  Since data paths are now associated
        # with analysis chains, we only need to calculate them once.
        # Since the view is only locked when it is executed, we assume
        # that an unlocked view has not had paths calculated, whereas
        # a locked one has.
        if (!$analysis_chain->locked()) {
            __debug("  Chain has not been locked yet");

            __buildDataPaths();

            __debug("  Locking the chain");
            $analysis_chain->locked('true');
            $analysis_chain->storeObject();
        } else {
            __debug("  Chain has already been locked");

            __loadDataPaths();
        }

        __debug("  Creating ANALYSIS_CHAIN_EXECUTION table entry");

        $analysis_chain_execution = $factory->
          newObject("OME::AnalysisChainExecution",
                    {
                     analysis_chain => $analysis_chain,
                     dataset       => $dataset,
                     experimenter_id  => $session->User()->id()
                    });

        # initialize all of the nodes
        foreach my $node (@nodes) {
            $curr_node = $node;
            $curr_nodeID = $curr_node->id();
            __initializeNode();
        }

        $continue = 1;
        $round = 0;

        my $sth;

        $session->commitTransaction();

        while ($continue) {
            $continue = 0;
            $round++;
            __debug("Round $round...");

            # Look for input_nodes that are ready to run (i.e., whose
            # predecessor nodes have been completed).
          ANALYSIS_LOOP:
            foreach my $node (@nodes) {
                $curr_node = $node;
                $curr_nodeID = $curr_node->id();

                # Go ahead and skip if we've completed this module.
                if ($node_states{$curr_nodeID} > INPUT_STATE) {
                    __debug("  ".$curr_node->module()->
                      name()." already completed");
                    next ANALYSIS_LOOP;
                }

                $sth = $self->sql_get_predecessors();
                $sth->execute($curr_nodeID);
                @curr_predecessorIDs = @{__fetchall($sth)};


                if (!__testModulePredecessors()) {
                    __debug("  Skipping ".$curr_node->module()->
                      name());
                    next ANALYSIS_LOOP;
                }

                $curr_module = $node_modules{$curr_nodeID};

                my $debug = 1;

                $sth = $self->sql_get_formal_inputs_by_node();
                $sth->execute($curr_nodeID,'G');
                @curr_global_inputs = 
                  @{__fetchobjs("OME::Module::FormalInput",$sth)};

                $sth = $self->sql_get_formal_inputs_by_node();
                $sth->execute($curr_nodeID,'D');
                @curr_dataset_inputs = 
                  @{__fetchobjs("OME::Module::FormalInput",$sth)};

                $sth = $self->sql_get_formal_inputs_by_node();
                $sth->execute($curr_nodeID,'I');
                @curr_image_inputs = 
                  @{__fetchobjs("OME::Module::FormalInput",$sth)};

                $sth = $self->sql_get_formal_inputs_by_node();
                $sth->execute($curr_nodeID,'F');
                @curr_feature_inputs = 
                  @{__fetchobjs("OME::Module::FormalInput",$sth)};

                $sth = $self->sql_get_formal_outputs_by_node();
                $sth->execute($curr_nodeID,'G');
                @curr_global_outputs =
                  @{__fetchobjs("OME::Module::FormalOutput",$sth)};

                $sth = $self->sql_get_formal_outputs_by_node();
                $sth->execute($curr_nodeID,'D');
                @curr_dataset_outputs =
                  @{__fetchobjs("OME::Module::FormalOutput",$sth)};

                $sth = $self->sql_get_formal_outputs_by_node();
                $sth->execute($curr_nodeID,'I');
                @curr_image_outputs =
                  @{__fetchobjs("OME::Module::FormalOutput",$sth)};

                $sth = $self->sql_get_formal_outputs_by_node();
                $sth->execute($curr_nodeID,'F');
                @curr_feature_outputs =
                  @{__fetchobjs("OME::Module::FormalOutput",$sth)};

                $last_node = $curr_node;

                __determineDependence();

                if ($dependence{$curr_nodeID} ne 'I') {
                    if (__checkPastResults()) {
                        __debug("    Marking state");
                        $node_states{$curr_nodeID} = FINISHED_STATE;
                        $continue = 1;
                        next ANALYSIS_LOOP;
                    }
                }

                my $new_analysis;

                __debug("  Executing ".$curr_node->module()->
                  name()." (".$dependence{$curr_nodeID}.")");

                __cloneUserInputs();

                # Execute away.
                if ($dependence{$curr_nodeID} ne 'I') {
                    __debug("    Creating MODULE_EXECUTION entry");
                    $new_analysis = 
                      __createAnalysis({
                                        module    => $curr_node->module(),
                                        dependence => $dependence{$curr_nodeID},
                                        dataset    => $dataset,
                                        timestamp  => 'now',
                                        status     => 'RUNNING'
                                       });
                    __assignAnalysis($new_analysis,0);
                    #__debug(" (".$new_analysis->id().")");
                    __createActualInputs($curr_node);
                    #my $actual_outputs = __createActualOutputs($new_analysis);
                    $curr_module->startAnalysis($new_analysis);
                }

                # Collect and present the global inputs

                __debug("    Global inputs");
                my %global_hash;
                foreach my $input (@curr_global_inputs) {
                    $global_hash{$input->name()} =
                        __findInputAttributes($input,
                                              "      ",
                                              "sql_get_input_attributes");
                }
                $curr_module->globalInputs(\%global_hash);

                __debug("    Precalculate global");
                $curr_module->precalculateGlobal();

                __debug("    startDataset");
                $curr_module->startDataset($dataset);

                # Collect and present the dataset inputs

                __debug("    Dataset inputs");
                my %dataset_hash;
                foreach my $input (@curr_dataset_inputs) {
                    $dataset_hash{$input->name()} =
                        __findInputAttributes($input,
                                              "      ",
                                              "sql_get_input_attributes");
                }
                $curr_module->datasetInputs(\%dataset_hash);

                __debug("    Precalculate dataset");
                $curr_module->precalculateDataset();

                my $image_maps = $dataset->image_links();
              IMAGE_LOOP:
                while (my $image_map = $image_maps->next()) {
                    # Collect and present the image inputs
                    $curr_image = $image_map->image();
                    $curr_imageID = $curr_image->id();

                    __debug("    Image ".$curr_image->name());

                    if ($dependence{$curr_nodeID} eq 'I') {
                        if (__checkPastResults()) {
                            next IMAGE_LOOP;
                        } elsif (!defined $new_analysis) {
                            __debug("    Creating MODULE_EXECUTION entry");
                            $new_analysis =
                              __createAnalysis({
                                                module     => $curr_node->module(),
                                                dependence => $dependence{$curr_nodeID},
                                                dataset    => $dataset,
                                                timestamp  => 'now',
                                                status     => 'RUNNING'
                                               });
                            __assignAnalysis($new_analysis,0);
                            #__debug(" (".$new_analysis->id().")");
                            __createActualInputs($curr_node);
                            #my $actual_outputs = __createActualOutputs($new_analysis);
                            $curr_module->startAnalysis($new_analysis);
                        } else {
                            __assignAnalysis($new_analysis,0);
                        }
                    }

                    __debug("    startImage");
                    $curr_module->startImage($curr_image);

                    __debug("    Image inputs");
                    my %image_hash;
                    foreach my $input (@curr_image_inputs) {
                        $image_hash{$input->name()} =
                            __findInputAttributes($input,
                                                  "      ",
                                                  "sql_get_input_image_attributes",
                                                  $curr_imageID);
                    }
                    $curr_module->imageInputs(\%image_hash);

                    __debug("    Precalculate image");
                    $curr_module->precalculateImage();

                    __debug("      Calculating feature hierarchy");
                    __calculateHierarchy();
                    __printHierarchy("        ");

                    # Collect and present the feature inputs.

                    if (defined $curr_node->iterator_tag()) {
                        # We have a feature iterator, so we should
                        # present the feature inputs grouped by
                        # iterator feature.

                        __debug("      Iterating over ".$curr_node->iterator_tag()." tag");

                        my $iterator_features = __findIteratorFeatures();

                        foreach my $cf (@$iterator_features) {
                            $curr_featureID = $cf;
                            $curr_feature = $factory->
                              loadObject("OME::Feature",$curr_featureID);
                            __processOneFeature();
                        }
                    } else {
                        # No iterator feature; present all of the
                        # feature inputs for the image at once.

                        __processAllFeatures();
                    }

                    # Collect and process the image outputs
                    __debug("    Postcalculate image");
                    $curr_module->postcalculateImage();

                    __debug("    Checking feature outputs");
                    $curr_module->collectFeatureOutputs();

                    $curr_module->finishImage($curr_image);
                }               # foreach $curr_image

                # Collect and process the dataset outputs
                __debug("    Postcalculate dataset");
                $curr_module->postcalculateDataset();

                __debug("    Checking image outputs");
                $curr_module->collectImageOutputs();

                $curr_module->finishDataset($dataset);

                # Collect and process the global outputs
                __debug("    Postcalculate global");
                $curr_module->postcalculateGlobal();

                __debug("    Checking dataset outputs");
                $curr_module->collectDatasetOutputs();

                __debug("    Checking global outputs");
                $curr_module->collectGlobalOutputs();

                __debug("    Finishing module_execution");
                $curr_module->finishAnalysis();

                # Mark this node as finished, and flag that we need
                # another fixed point iteration.

                if (defined $new_analysis) {
                    __debug("    Marking database state");
                    $new_analysis->status('FINISHED');
                    $new_analysis->storeObject();
                }

                $session->commitTransaction();

                __debug("    Marking FSM state");
                $node_states{$curr_nodeID} = FINISHED_STATE;
                $continue = 1;
            }                   # ANALYSIS_LOOP - foreach $curr_node
        }                       # while ($continue)

        $session->commitTransaction();

        $end_time = new Benchmark;

        my $total_time = timediff($end_time,$start_time);

        __debug("Timing - Total: ".timestr($total_time),'Timing');

    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

