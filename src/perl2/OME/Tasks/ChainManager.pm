# OME/Tasks/ChainManager.pm

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
our $VERSION = '1.0';

use OME::Session;
use OME::Program;
use OME::AnalysisView;

use fields qw(session);

=head1 METHODS

NOTE: Several of these methods create new database objects.  None of
them commit any transactions.

=head2 new

	my $manager = OME::Tasks::ChainManager->new($session);

Creates a new chain manager for the given session.  The $session
parameter is required.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session) = @_;

    die "ChainManager->new needs a session!"
      unless
        defined $session &&
        UNIVERSAL::isa($session,"OME::Session");

    my $self = {
                session => $session,
               };

    return bless $self, $class;
}

sub Session { return shift->{session}; }

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
      newObject("OME::AnalysisView",
                {
                 name        => $name,
                 owner       => $owner->id(),
                 locked      => 'f',
                 description => $description,
                });

    return $chain;
}

=head2

	my $newChain = $manager->cloneChain($oldChain,[$owner]);

Creates a new analysis chain which is a clone of $oldChain.  If $owner
is specified, it must be an Experimenter attribute.  This Experimenter
will own the created chain.  If $owner is not specified, the chain
will be owned by the user running the session.  The new chain will be
unlocked, even if the old chain was locked.

=cut

sub cloneChain {
    my ($self,$old_chain,$owner) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "cloneChain needs an analysis chain!"
      unless
        defined $old_chain &&
        UNIVERSAL::isa($old_chain,"OME::AnalysisView");

    $owner = $session->User() unless defined $owner;
    $owner->verifyType("Experimenter");

    my $new_chain = $factory->
      newObject("OME::AnalysisView",
                {
                 name        => $old_chain->name(),
                 owner       => $owner->id(),
                 locked      => 'f',
                 description => $old_chain->description(),
                });

    my %new_nodes;
    foreach my $node ($old_chain->nodes()) {
        my $new_node = $factory->
          newObject("OME::AnalysisView::Node",
                    {
                     analysis_view_id => $new_chain->id(),
                     program_id       => $node->program()->id(),
                     iterator_tag     => $node->iterator_tag(),
                     new_feature_tag  => $node->new_feature_tag(),
                    });
        $new_nodes{$node->id()} = $new_node;
    }

    foreach my $link ($old_chain->links()) {
        my $from_node = $new_nodes{$link->from_node()->id()};
        my $to_node = $new_nodes{$link->to_node()->id()};

        my $new_link = $factory->
          newObject("OME::AnalysisView::Link",
                    {
                     analysis_view_id => $new_chain->id(),
                     from_node        => $from_node->id(),
                     from_output      => $link->from_output()->id(),
                     to_node          => $to_node->id(),
                     to_input         => $link->to_input()->id(),
                    });
    }

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

    return $factory->findObject("OME::Program",program_name => $name);
}


=head2 addNode

	my $node = $manager->addNode($chain,$program,
	                             [$iterator_tag],[$new_feature_tag]);

Adds a node to the specified chain corresponding to $program.  Throws
an error if the chain is locked.  The $iterator_tag and
$new_feature_tag parameters are optional; if they are not given, they
will take their values from the $program.

=cut

sub addNode {
    my ($self,$chain,$program,$iterator_tag,$new_feature_tag) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "addNode needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "addNode: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    die "addNode needs a program!"
      unless
        defined $program
        && UNIVERSAL::isa($program,"OME::Program");

    $iterator_tag = $program->default_iterator()
      unless defined $iterator_tag;
    $new_feature_tag = $program->new_feature_tag()
      unless defined $new_feature_tag;

    my $node = $factory->
      newObject("OME::AnalysisView::Node",
                {
                 analysis_view_id => $chain->id(),
                 program_id       => $program->id(),
                 iterator_tag     => $iterator_tag,
                 new_feature_tag  => $new_feature_tag,
                });

    return $node;
}

=head2 removeNode

	$manager->removeNode($chain,$node);

Remove the given node from $chain.  Throws an error if $chain is
locked.

=cut

sub removeNode {
    my ($self, $chain, $node) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "removeNode needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "removeNode: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    die "removeNode needs a node!"
      unless
        defined $node
        && UNIVERSAL::isa($node,"OME::AnalysisView::Node");

    die "removeNode: Node '".$node->program()->program_name().
      "' does not belong to chain!"
      if $node->analysis_view()->id() ne $chain->id();

    # Delete all of the links associated with this node
    my @input_links = $factory->
      findObjects("OME::AnalysisView::Link",
                  analysis_view_id => $chain->id(),
                  to_node          => $node->id());

    my @output_links = $factory->
      findObjects("OME::AnalysisView::Link",
                  analysis_view_id => $chain->id(),
                  from_node        => $node->id());

    # This is a horrible hack which must be removed ASAP.
    $_->Class::DBI::delete() foreach (@input_links,@output_links);

    $node->Class::DBI::delete();

    return;
}

=head2 getNode

	my $node = $manager->getNode($chain,$program_name);

Returns the node representing the module of the given name in the
specified analysis chain.

=cut

sub getNode {
    my ($self,$chain,$program_name) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "getNode needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "getNode needs a program name!"
      unless
        defined $program_name
        && !ref($program_name);

    # Man, we should have a better method for searching for things...
    my @nodes = $chain->nodes();

    foreach my $node (@nodes) {
        my $program = $node->program();
        return $node if $program->program_name() eq $program_name;
    }

    return undef;
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
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "getFormalInput needs a node!"
      unless
        defined $node
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "getFormalInput needs an input name!"
      unless
        defined $input_name
        && !ref($input_name);

    die "getFormalInput: node does not belong to chain!"
      unless
       #$node->analysis_view()->id() ne $chain->analysis_view_id();
	  $node->analysis_view()->id() eq $chain->id();
	  

    my $program = $node->program();
    return $factory->
      findObject('OME::Program::FormalInput',
                 program_id => $program->id(),
                 name       => $input_name);
}

=head2 addLink

	my $link = $manager->addLink($chain,
	                             $from_node,$from_output,
	                             $to_node,$to_input);

Adds a link to the specified chain, connecting $from_node and
$to_node.  The chain must be unlocked.  Both nodes must belong to
$chain.  $from_output must belong to the program represented by
$from_node, and $to_input must belong to the program represented by
$to_node.  There cannot already be a link pointing to $to_input on
$to_node.  If any of these conditions are not met, an error is thrown.

The $from_output and $to_input parameters can be specified either as
an instance of OME::Program::FormalOutput (or ::FormalInput), or as
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
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "addLink: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    die "addLink needs a 'from' node!"
      unless
        defined $from_node
        && UNIVERSAL::isa($from_node,"OME::AnalysisView::Node");

    die "addLink: Node '".$from_node->program()->program_name().
      "' does not belong to chain!"
      if $from_node->analysis_view()->id() ne $chain->id();

    die "addLink needs a 'to' node!"
      unless
        defined $to_node
        && UNIVERSAL::isa($to_node,"OME::AnalysisView::Node");

    die "addLink: Node '".$to_node->program()->program_name().
      "' does not belong to chain!"
      if $to_node->analysis_view()->id() ne $chain->id();

    die "addLink needs a 'from' output!"
      unless
        defined $from_output;

    if (ref($from_output)) {
        # $from_output is an object
        die "addLink needs a 'from' output!"
          unless
            UNIVERSAL::isa($from_output,"OME::Program::FormalOutput");
    } else {
        # $from_output is a name
        my $name = $from_output;
        $from_output = $factory->
          findObject("OME::Program::FormalOutput",
                     program_id => $from_node->program()->id(),
                     name       => $name);
        die "addLink:  Cannot find output named '$name'"
          unless defined $from_output;
    }

    if (ref($to_input)) {
        # $to_input is an object
        die "addLink needs a 'to' input!"
          unless
            UNIVERSAL::isa($to_input,"OME::Program::FormalInput");
    } else {
        # $to_input is a name
        my $name = $to_input;
        $to_input = $factory->
          findObject("OME::Program::FormalInput",
                     program_id => $to_node->program()->id(),
                     name       => $name);
        die "addLink:  Cannot find input named '$name'"
          unless defined $to_input;
    }

    my $link_exists = $factory->
      objectExists("OME::AnalysisView::Link",
                   analysis_view_id => $chain->id(),
                   to_node          => $to_node->id(),
                   to_input         => $to_input->id());

    die "addLink: '".$to_input->name()."' already has an incoming link"
      if $link_exists;

    my $link = $factory->
      newObject("OME::AnalysisView::Link",
                {
                 analysis_view_id => $chain->id(),
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
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    die "removeLink: Chain '".$chain->name()."' is locked!"
      if $chain->locked();

    if (scalar(@_) == 1) {
        $link = shift;

        die "removeLink needs a link!"
          unless
            defined $link
            && UNIVERSAL::isa($link,"OME::AnalysisView::Link");
    } else {
        ($from_node,$from_output,$to_node,$to_input) = @_;

        die "removeLink needs a 'from' node!"
          unless
            defined $from_node
              && UNIVERSAL::isa($from_node,"OME::AnalysisView::Node");

        die "removeLink: Node '".$from_node->program()->program_name().
          "' does not belong to chain!"
            if $from_node->analysis_view()->id() ne $chain->id();

        die "removeLink needs a 'to' node!"
          unless
            defined $to_node
              && UNIVERSAL::isa($to_node,"OME::AnalysisView::Node");

        die "removeLink: Node '".$to_node->program()->program_name().
          "' does not belong to chain!"
            if $to_node->analysis_view()->id() ne $chain->id();

        die "removeLink needs a 'from' output!"
          unless
            defined $from_output;

        if (ref($from_output)) {
            # $from_output is an object
            die "removeLink needs a 'from' output!"
              unless
                UNIVERSAL::isa($from_output,"OME::Program::FormalOutput");
        } else {
            # $from_output is a name
            my $name = $from_output;
            $from_output = $factory->
              findObject("OME::Program::FormalOutput",
                         program_id => $from_node->program()->id(),
                         name       => $name);
            die "removeLink:  Cannot find output named '$name'"
              unless defined $from_output;
        }

        if (ref($to_input)) {
            # $to_input is an object
            die "removeLink needs a 'to' input!"
              unless
                UNIVERSAL::isa($to_input,"OME::Program::FormalInput");
        } else {
            # $to_input is a name
            my $name = $to_input;
            $to_input = $factory->
              findObject("OME::Program::FormalInput",
                         program_id => $to_node->program()->id(),
                         name       => $name);
            die "removeLink:  Cannot find input named '$name'"
              unless defined $to_input;
        }

        $link = $factory->
          findObject("OME::AnalysisView::Link",
                     analysis_view_id => $chain->id(),
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

	[$node, $program, $formal_input, $attribute_type]

The output array will be grouped by $node.

=cut

sub getUserInputs {
    my ($self,$chain) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();

    die "getUserInputs needs a chain!"
      unless
        defined $chain
        && UNIVERSAL::isa($chain,"OME::AnalysisView");

    my @inputs;
    my %input_links;

    # Sort the links in the chain by "to node" and "to input".
    $input_links{$_->to_node()->id()}->{$_->to_input()->id()} = $_
      foreach $chain->links();

    foreach my $node ($chain->nodes()) {
        my $program = $node->program();
        foreach my $input ($program->inputs()) {
            my $input_link = $input_links{$node->id()}->{$input->id()};
            # If there was an input link for this input, skip it.
            next if defined $input_link;

            my $element = [$node,$program,$input,$input->attribute_type()];
            push @inputs,$element;
        }
    }

    return \@inputs;
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
