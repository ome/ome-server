# OME/ImportExport/ChainImport.pm

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


package OME::ImportExport::ChainImport;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Log::Agent;
use XML::LibXML;


sub new {
    my ($proto, %params) = @_;
    my $class = ref($proto) || $proto;

    my @fieldsILike = qw(session _parser);

    my $self;

    @$self{@fieldsILike} = @params{@fieldsILike};

    die $class."->new needs a session"
      unless exists $self->{session} &&
             UNIVERSAL::isa($self->{session},'OME::Session');

    if (!defined $self->{_parser}) {
        my $parser = XML::LibXML->new();
        die "Cannot create XML parser"
          unless defined $parser;

        $parser->validation(exists $params{ValidateXML}?
                            $params{ValidateXML}: 0);
        $self->{_parser} = $parser;
    }

    return bless $self, $class;
}


sub importFile {
    my ($self, $filename, %flags) = @_;
    my $doc = $self->{_parser}->parse_file($filename)
      or die "Cannot parse file $filename";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub importXML {
    my ($self, $xml, %flags) = @_;
    my $doc = $self->{_parser}->parse_string($xml)
      or die "Cannot parse XML string";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}


sub processDOM {
    my ($self, $root, %flags) = @_;
    my $session = $self->{session};
    my $factory = $session->Factory();
    my $chains = $root->getElementsByTagName('AnalysisChain');

    my @chains;

    foreach my $chain (@$chains) {
        my (%nodes, @links);

        if ($flags{NoDuplicates}) {
            my $chainName = $chain->getAttribute('Name');
            my $oldChain = $factory->
              findObject("OME::AnalysisChain",
                         name => $chainName);
            if (defined $oldChain) {
            	print STDERR "Chain \"$chainName\" already exists\n";
            	next;
            }
        }

        my $nodesTag = $chain->getElementsByTagName('Nodes')->[0];
        my $linksTag = $chain->getElementsByTagName('Links')->[0];

        foreach my $node ($nodesTag->getElementsByTagName('Node')) {
            my $nodeID = $node->getAttribute('NodeID');
            my $programName = $node->getAttribute('ProgramName');
            my $module = $factory->
              findObject('OME::Module',
                         name => $programName);
            die "Cannot find module named \"$programName\""
              unless defined $module;

            my $hash = {
                        module         => $module,
                        iterator_tag    => $node->getAttribute('IteratorTag') ||
                                           $module->default_iterator(),
                        new_feature_tag => $node->getAttribute('NewFeatureTag') ||
                                           $module->new_feature_tag(),
                       };

            $nodes{$nodeID} = $hash;
        }

        foreach my $link ($linksTag->getElementsByTagName('Link')) {
            my $fromNodeID = $link->getAttribute('FromNodeID');
            my $fromOutputName = $link->getAttribute('FromOutputName');
            my $toNodeID = $link->getAttribute('ToNodeID');
            my $toInputName = $link->getAttribute('ToInputName');

            my $fromNode = $nodes{$fromNodeID};
            die "Cannot find node \"$fromNodeID\""
              unless defined $fromNode;

            my $output = $factory->
              findObject("OME::Module::FormalOutput",
                         module_id => $fromNode->{module}->id(),
                         name       => $fromOutputName);
            die "Cannot find output \"$fromOutputName\" from node \"$fromNodeID\""
              unless defined $output;

            my $toNode = $nodes{$toNodeID};
            die "Cannot find node \"$toNodeID\""
              unless defined $toNode;

            my $input = $factory->
              findObject("OME::Module::FormalInput",
                         module_id => $toNode->{module}->id(),
                         name       => $toInputName);
            die "Cannot find input \"$toInputName\" for link\"".$link->toString()."\""
              unless defined $input;

            my $hash = {
                        from_node   => $fromNodeID,
                        from_output => $output,
                        to_node     => $toNodeID,
                        to_input    => $input,
                       };
            push @links, $hash;
        }

        my $chainObject = $factory->
          newObject("OME::AnalysisChain",
                    {
                     owner_id => $session->User()->id(),
                     name     => $chain->getAttribute('Name'),
                     locked   => $chain->getAttribute('Locked') || 'f',
                    });

        foreach my $nodeID (keys %nodes) {
            my $node = $nodes{$nodeID};
            $node->{analysis_chain} = $chainObject;
            my $nodeObject = $factory->
              newObject("OME::AnalysisChain::Node",$node);
            $nodes{$nodeID} = $nodeObject;
        }

        foreach my $link (@links) {
            $link->{from_node} = $nodes{$link->{from_node}};
            $link->{to_node} = $nodes{$link->{to_node}};
            $link->{analysis_chain} = $chainObject;
            my $linkObject = $factory->
              newObject("OME::AnalysisChain::Link",$link);
        }

        $chainObject->storeObject();

        push @chains, $chainObject;
    }

    return \@chains;
}


1;
