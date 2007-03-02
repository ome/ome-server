# OME/Tasks/ChainManager.pm

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


package OME::Tasks::ChainManager;

=head1 NAME

OME::Tasks::ChainManager - Workflow methods for handling analysis chains

=head1 SYNOPSIS

	use OME::Tasks::ChainManager;
	my $manager = new OME::Tasks::ChainManager($session);

=head1 DESCRIPTION

Here is a description.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Module;
use OME::AnalysisChain;

=head1 METHODS

NOTE: Several of these methods create new database objects.  None of
them commit any transactions.

=head2 new

	my $manager = OME::Tasks::ChainManager->new();

Creates a new chain manager for the current session.  Previously, this
method required a session parameter.  It is still allowed, but is
ignored.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session) = @_;

    my $self = {};

    return bless $self, $class;
}

sub Session { return OME::Session->instance(); }

=head2 createChain

	my $chain = $manager->createChain($name,$description,[$owner]);

Creates a new analysis chain with the given name and description.  If
$owner is specified, it must be an Experimenter attribute.  This
Experimenter will own the created chain.  If $owner is not specified,
the chain will be owned by the user running the session.

=cut

sub createChain {
    my ($self,$name,$description,$owner) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    $owner = $session->User() unless defined $owner;
    $owner->verifyType("Experimenter");

    my $chain = $factory->
      newObject("OME::AnalysisChain",
                {
                 name        => $name,
                 owner_id    => $owner->id(),
                 locked      => 'f',
                 description => $description,
                });

    return $chain;
}

=head2 cloneChain

	my $newChain = $manager->cloneChain($oldChain,[$owner]);

Creates a new analysis chain which is a clone of $oldChain.  If $owner
is specified, it must be an Experimenter attribute.  This Experimenter
will own the created chain.  If $owner is not specified, the chain
will be owned by the user running the session.  The new chain will be
unlocked, even if the old chain was locked.

=cut

sub cloneChain {
    my ($self,$old_chain,$owner,$returnNodeMapping) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "cloneChain needs an analysis chain!"
      unless
        defined $old_chain &&
        UNIVERSAL::isa($old_chain,"OME::AnalysisChain");

    $owner = $session->User() unless defined $owner;
    $owner->verifyType("Experimenter");

    my $new_chain = $factory->
      newObject("OME::AnalysisChain",
                {
                 name        => $old_chain->name(),
                 owner_id    => $owner->id(),
                 locked      => 'f',
                 description => $old_chain->description(),
                });

    my %new_nodes;
    foreach my $node ($old_chain->nodes()) {
        my $new_node = $factory->
          newObject("OME::AnalysisChain::Node",
                    {
                     analysis_chain_id => $new_chain->id(),
                     module_id         => $node->module()->id(),
                     iterator_tag      => $node->iterator_tag(),
                     new_feature_tag   => $node->new_feature_tag(),
                    });
        $new_nodes{$node->id()} = $new_node;
    }

    foreach my $link ($old_chain->links()) {
        my $from_node = $new_nodes{$link->from_node()->id()};
        my $to_node = $new_nodes{$link->to_node()->id()};

        my $new_link = $factory->
          newObject("OME::AnalysisChain::Link",
                    {
                     analysis_chain_id => $new_chain->id(),
                     from_node         => $from_node->id(),
                     from_output       => $link->from_output()->id(),
                     to_node           => $to_node->id(),
                     to_input          => $link->to_input()->id(),
                    });
    }

	return ($new_chain, \%new_nodes) if $returnNodeMapping;
    return $new_chain;
}

=head2 findModule

	my $module = $manager->findModule($name);

Basically just a wrapper for Factory->findObject.  Returns the module
in the system with the given name.  If there is more than one module
with that name, one of them will be returned.  Which one is undefined.

=cut

sub findModule {
    my ($self, $name) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    return $factory->findObject("OME::Module",name => $name);
}


=head2 addNode

	my $node = $manager->addNode($chain,$module,
	                             [$iterator_tag],[$new_feature_tag]);

Adds a node to the specified chain corresponding to $module.  Throws
an error if the chain is locked.  The $iterator_tag and
$new_feature_tag parameters are optional; if they are not given, they
will take their values from the $module.

=cut

sub addNode {
    my ($self,$chain,$module,$iterator_tag,$new_feature_tag) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "addNode needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "addNode: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    die "addNode needs a module!"
      unless
        defined $module
        && UNIVERSAL::isa($module,"OME::Module");

    $iterator_tag = $module->default_iterator()
      unless defined $iterator_tag;
    $new_feature_tag = $module->new_feature_tag()
      unless defined $new_feature_tag;

    my $node = $factory->
      newObject("OME::AnalysisChain::Node",
                {
                 analysis_chain_id => $chain->id(),
                 module_id       => $module->id(),
                 iterator_tag     => $iterator_tag,
                 new_feature_tag  => $new_feature_tag,
                });

    return $node;
}

=head2 removeNode

	$manager->removeNode($chain,$node);

Remove the given node and all of its incident links from $chain.
Throws an error if $chain is locked.

=cut

sub removeNode {
    my ($self, $chain, $node) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "removeNode needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "removeNode: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    die "removeNode needs a node!"
      unless
        defined $node
        && UNIVERSAL::isa($node,"OME::AnalysisChain::Node");

    die "removeNode: Node '".$node->module()->name().
      "' does not belong to chain!"
      if $node->analysis_chain()->id() ne $chain->id();

    # Delete all of the links associated with this node
    my @input_links = $factory->
      findObjects("OME::AnalysisChain::Link",
                  analysis_chain_id => $chain->id(),
                  to_node          => $node->id());

    my @output_links = $factory->
      findObjects("OME::AnalysisChain::Link",
                  analysis_chain_id => $chain->id(),
                  from_node        => $node->id());

    # This is a horrible hack which must be removed ASAP.
    $_->Class::DBI::delete() foreach (@input_links,@output_links);

    $node->Class::DBI::delete();

    return;
}

=head2 getChain

	my $chain = $manager->getChain($name);

Returns a chain with the given name.

=cut

sub getChain {
    my ($self,$name) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "getChain needs a chain name!"
      unless
        defined $name
        && !ref($name);

    return $factory->findObject("OME::AnalysisChain",{ name  => $name });
}

=head2 getNode

	my $node = $manager->getNode($chain,$name);

Returns the node representing the module of the given name in the
specified analysis chain.

=cut

sub getNode {
    my ($self,$chain,$name) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "getNode needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "getNode needs a module name!"
      unless
        defined $name
        && !ref($name);

    return $factory->findObject("OME::AnalysisChain::Node",
                                {
                                 analysis_chain => $chain,
                                 'module.name'  => $name,
                                });
}

=head2 getFormalInput

	my $input = $manager->getFormalInput($chain,$node,$input_name);

Returns the formal input of the specified name in the node of the
specified analysis chain.

=cut

sub getFormalInput {
    my ($self,$chain,$node,$input_name) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "getFormalInput needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "getFormalInput needs a node!"
      unless
        defined $node
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "getFormalInput needs an input name!"
      unless
        defined $input_name
        && !ref($input_name);

    die "getFormalInput: node does not belong to chain!"
      unless
       #$node->analysis_chain()->id() ne $chain->analysis_chain_id();
	  $node->analysis_chain()->id() eq $chain->id();
	  

    my $module = $node->module();
    return $factory->
      findObject('OME::Module::FormalInput',
                 module_id => $module->id(),
                 name       => $input_name);
}

=head2 addLink

	my $link = $manager->addLink($chain,
	                             $from_node,$from_output,
	                             $to_node,$to_input);

Adds a link to the specified chain, connecting $from_node and
$to_node.  The chain must be unlocked.  Both nodes must belong to
$chain.  $from_output must belong to the module represented by
$from_node, and $to_input must belong to the module represented by
$to_node.  There cannot already be a link pointing to $to_input on
$to_node.  If any of these conditions are not met, an error is thrown.

The $from_output and $to_input parameters can be specified either as
an instance of OME::Module::FormalOutput (or ::FormalInput), or as
the name if the output (or input).  If specified as a name, an error
is thrown if no output (or input) exists of that name.

=cut

sub addLink {
    my ($self,$chain,$from_node,$from_output,$to_node,$to_input) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "addLink needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "addLink: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    die "addLink needs a 'from' node!"
      unless
        defined $from_node
        && UNIVERSAL::isa($from_node,"OME::AnalysisChain::Node");

    die "addLink: Node '".$from_node->module()->name().
      "' does not belong to chain!"
      if $from_node->analysis_chain()->id() ne $chain->id();

    die "addLink needs a 'to' node!"
      unless
        defined $to_node
        && UNIVERSAL::isa($to_node,"OME::AnalysisChain::Node");

    die "addLink: Node '".$to_node->module()->name().
      "' does not belong to chain!"
      if $to_node->analysis_chain()->id() ne $chain->id();

    die "addLink needs a 'from' output!"
      unless
        defined $from_output;

    if (ref($from_output)) {
        # $from_output is an object
        die "addLink needs a 'from' output!"
          unless
            UNIVERSAL::isa($from_output,"OME::Module::FormalOutput");
    } else {
        # $from_output is a name
        my $name = $from_output;
        $from_output = $factory->
          findObject("OME::Module::FormalOutput",
                     module_id => $from_node->module()->id(),
                     name       => $name);
        die "addLink:  Cannot find output named '$name'"
          unless defined $from_output;
    }

    if (ref($to_input)) {
        # $to_input is an object
        die "addLink needs a 'to' input!"
          unless
            UNIVERSAL::isa($to_input,"OME::Module::FormalInput");
    } else {
        # $to_input is a name
        my $name = $to_input;
        $to_input = $factory->
          findObject("OME::Module::FormalInput",
                     module_id => $to_node->module()->id(),
                     name       => $name);
        die "addLink:  Cannot find input named '$name'"
          unless defined $to_input;
    }

    my $link_exists = $factory->
      objectExists("OME::AnalysisChain::Link",
                   analysis_chain_id => $chain->id(),
                   to_node          => $to_node->id(),
                   to_input         => $to_input->id());

    die "addLink: '".$to_input->name()."' already has an incoming link"
      if $link_exists;

    my $link = $factory->
      newObject("OME::AnalysisChain::Link",
                {
                 analysis_chain_id => $chain->id(),
                 from_node        => $from_node->id(),
                 from_output      => $from_output->id(),
                 to_node          => $to_node->id(),
                 to_input         => $to_input->id(),
                });

    return $link;
}

=head2 removeLink

	$manager->removeLink($chain,
	                     $from_node,$from_output,
	                     $to_node,$to_input);
	$manager->removeLink($chain,$link);

Removes a link from the specified chain.  The link can either be
passed in directly, or specifed using the same syntax as the addLink
method.  The chain must be unlocked.

=cut

sub removeLink {
    my ($self,$chain,$link,$from_node,$from_output,$to_node,$to_input);
    $self = shift;
    $chain = shift;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "removeLink needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    die "removeLink: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    if (scalar(@_) == 1) {
        $link = shift;

        die "removeLink needs a link!"
          unless
            defined $link
            && UNIVERSAL::isa($link,"OME::AnalysisChain::Link");
    } else {
        ($from_node,$from_output,$to_node,$to_input) = @_;

        die "removeLink needs a 'from' node!"
          unless
            defined $from_node
              && UNIVERSAL::isa($from_node,"OME::AnalysisChain::Node");

        die "removeLink: Node '".$from_node->module()->name().
          "' does not belong to chain!"
            if $from_node->analysis_chain()->id() ne $chain->id();

        die "removeLink needs a 'to' node!"
          unless
            defined $to_node
              && UNIVERSAL::isa($to_node,"OME::AnalysisChain::Node");

        die "removeLink: Node '".$to_node->module()->name().
          "' does not belong to chain!"
            if $to_node->analysis_chain()->id() ne $chain->id();

        die "removeLink needs a 'from' output!"
          unless
            defined $from_output;

        if (ref($from_output)) {
            # $from_output is an object
            die "removeLink needs a 'from' output!"
              unless
                UNIVERSAL::isa($from_output,"OME::Module::FormalOutput");
        } else {
            # $from_output is a name
            my $name = $from_output;
            $from_output = $factory->
              findObject("OME::Module::FormalOutput",
                         module_id => $from_node->module()->id(),
                         name       => $name);
            die "removeLink:  Cannot find output named '$name'"
              unless defined $from_output;
        }

        if (ref($to_input)) {
            # $to_input is an object
            die "removeLink needs a 'to' input!"
              unless
                UNIVERSAL::isa($to_input,"OME::Module::FormalInput");
        } else {
            # $to_input is a name
            my $name = $to_input;
            $to_input = $factory->
              findObject("OME::Module::FormalInput",
                         module_id => $to_node->module()->id(),
                         name       => $name);
            die "removeLink:  Cannot find input named '$name'"
              unless defined $to_input;
        }

        $link = $factory->
          findObject("OME::AnalysisChain::Link",
                     analysis_chain_id => $chain->id(),
                     from_node        => $from_node->id(),
                     from_output      => $from_output->id(),
                     to_node          => $to_node->id(),
                     to_input         => $to_input->id());

        die "removeLink:  Cannot find specified link!"
          unless defined $link;
    }

    # Another horrible, horrible hack
    $link->Class::DBI::delete();

    return;
}

=head2 getUserInputs

	my $inputs = $manager->getUserInputs($chain);

Returns all of the formal inputs in the chain which do not have input
links.  This list corresponds to those formal inputs which the user
must provide a value for.

The return value will be an array reference.  Each element of the
array will have the following form:

	[$node, $module, $formal_input, $semantic_type]

The output array will be grouped by $node.

=cut

sub getUserInputs {
    my ($self,$chain) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "getUserInputs needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisChain");

    my @inputs;
    my %input_links;

    # Sort the links in the chain by "to node" and "to input".
    $input_links{$_->to_node()->id()}->{$_->to_input()->id()} = $_
      foreach $chain->links();

    foreach my $node ($chain->nodes()) {
        my $module = $node->module();
        foreach my $input ($module->inputs()) {
            my $input_link = $input_links{$node->id()}->{$input->id()};
            # If there was an input link for this input, skip it.
            next if defined $input_link;

            my $element = [$node,$module,$input,$input->semantic_type()];
            push @inputs,$element;
        }
    }

    return \@inputs;
}

=head2 getRootNodes

	my $nodes = $manager->getRootNodes($chain);

Returns an array reference of the root nodes of an analysis chain.

=cut

sub getRootNodes {
    my $self = shift;
    my ($chain) = @_;
    my $factory = OME::Session->instance()->Factory();

    my @nodes = $factory->
      findObjects("OME::AnalysisChain::Node",
                  { analysis_chain => $chain });

    # scalar((foo)) forces to foo to be evaluated in list context, then
    # coerced into scalar context.  Net result -- number of input links
    # for a node

    my @roots;
    foreach my $node (@nodes) {
        my @links = $node->input_links();
        push @roots, $node
          if scalar(@links) == 0;
    }

    return \@roots;
}

=head2 getNodeSuccessors

	my $nodes = $manager->getNodeSuccessors($node);

Returns the list of nodes which are successors of the given node as an
array reference.

=cut

sub getNodeSuccessors {
    my $self = shift;
    my ($node) = @_;
    my $factory = OME::Session->instance()->Factory();

    my @links = $factory->
      findObjects("OME::AnalysisChain::Link",
                  { from_node => $node });
    my %to_nodes;
    $to_nodes{$_->to_node()->id()} = $_->to_node()
      foreach @links;
    my @to_nodes = values %to_nodes;
    return \@to_nodes;
}

=head2 findLeaves

	my @leaves = $manager->findLeaves( $chain );

Returns list of a chain's leaf nodes.

=cut

sub findLeaves {
	my ($self, $chain) = @_;
	my @nodes = $chain->nodes();
	my @leaf_nodes;
	foreach my $node( @nodes ) {
		my @links = $node->output_links() ;
		push @leaf_nodes, $node
			if scalar( @links ) eq 0;
	}
	return @leaf_nodes;
}

=head2 findPath

	my @path = $manager->findPath( $rootNode, $targetNode );

Returns all nodes in the path between $rootNode and $targetNode (inclusive).
If no such path exists the returned array is empty. 

=cut

sub findPath {
	my ($self, $rootNode, $targetNode) = @_;
	my @path;

	# base case, rootNode is targetNode
	if ($rootNode->id == $targetNode->id) {
		push @path, $rootNode;
		return @path;
	}
	
	# recursion case
	my @nodes = @{$self->getNodeSuccessors($rootNode)};
	foreach (@nodes) {
		my @local_path = $self->findPath($_, $targetNode);

		if ( scalar @local_path ) {
			push @path, $rootNode, @local_path;
			return @path;
		}
	}
	return @path; # return an empty path;
}
=head2 topologicalSort

	my @chain_elevations = $manager->topologicalSort( $chain );

Returns a list of elevations. Each elevation is a list of nodes that
can be executed concurrently.

By Josiah Johnston. Originally in OME/Util/Dev/Lint.pm

=cut

sub topologicalSort {
	my ($self, $chain) = @_;
	
	my @nodes = $chain->nodes();
	my @chain_elevations;
	my %used_nodes;

	# Build a list of elevations. Each elvation is a list of nodes that can
	# be executed concurrently. Continue until all nodes are placed.
	while( @nodes ne keys %used_nodes ) {
		my @elevation;
		# collect nodes for this elevation
		foreach my $node ( @nodes ) {
			next if exists $used_nodes{ $node->id };
			my @input_links = $node->input_links();
			# if all of a node's inputs are in used_nodes
			if( grep( exists $used_nodes{ $_->from_node_id } , @input_links ) eq scalar( @input_links ) ) {
				# then add it to @elevation
				push( @elevation, $node );
			}
		}
		# mark this node as used.
		$used_nodes{ $_->id } = undef
			foreach @elevation;
		# store this elevation
		push( @chain_elevations, \@elevation );
	}
	
	# el fin
	return @chain_elevations;
}

sub printChainElevations {
	my ($self, @chain_elevations) = @_;
	for ( my ( $i, $elevation ) = ( 0, $chain_elevations[ 0 ] );
		  $i < scalar (@chain_elevations);
		  $i++, $elevation = $chain_elevations[ $i ] ) {
		print 
			"Elevation $i:\n\t".
			join( ", ", map( $_->module->name.'('.$_->id.')', @$elevation ) ).
			"\n";
	}
}

#
# NodeTags are strings that describe 
#
sub createNodeTags {
	my ($self, @nodes) = @_;
	my @node_tags;
	
	my $chain = $nodes[0]->analysis_chain();
	my @root_nodes = @{$self->getRootNodes( $chain )};
	my $root_node = $root_nodes[0];
	
	foreach my $node (@nodes) {
		# create a FI Name based on the Path of Modules.
		my @node_path = $self->findPath($root_node, $node);
		my $node_name = "im";
		
		foreach (@node_path) {
			# ignore modules based on their categories
			next unless (defined $_->module->category); # ignore no category modules
			my $cat_path = OME::Tasks::ModuleTasks::returnPathToLeafCategory ($_->module->category);
			next if ($cat_path =~ m/.*Slicers.*/);  # ignore slicer modules 
			next if ($cat_path =~ m/.*Typecasts.*/); # ignore typecaster modules 

			if (defined $_->module->location) {
				$node_name = $_->module->location."($node_name)"
			} else {
				$node_name = $_->module->name."($node_name)"
			}
		}
		push @node_tags, $node_name;
	}
	
	# make sure that $nodes are all unique strings. If there are multiple
	# exact same strings, we shall enumerate them.
	my %unique_node_tags_count;
	my %unique_node_tags_ptr; # points to the first redundent string. This way
	                           # we can retroactively add a _1 suffix

	for (my $i=0; $i<scalar @node_tags; $i++) {
		my $node_name = $node_tags[$i];
		
		if (not exists $unique_node_tags_count{$node_name}) {
			$unique_node_tags_count{$node_name} = 1;
			$unique_node_tags_ptr{$node_name} = $i;			
			next;
		}
		
		# retroactively add a _1 suffix to the first redundent string
		if ($unique_node_tags_count{$node_name} == 1) {
#			print "was ".$node_tags[$unique_node_tags_ptr{$node_name}]."\n";
			$node_tags[$unique_node_tags_ptr{$node_name}] = 
				$node_tags[$unique_node_tags_ptr{$node_name}]."_1";
#			print "now ".$node_tags[$unique_node_tags_ptr{$node_name}]."\n";
		}
#		print "was ".$node_tags[$i]."\n";
		$unique_node_tags_count{$node_name} = $unique_node_tags_count{$node_name} + 1;
		$node_tags[$i] = 
				$node_tags[$i]."_".$unique_node_tags_count{$node_name};
#		print "now ".$node_tags[$i]."\n";
	}
	
	return @node_tags;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
