# OME/ImportExport/ChainExport.pm

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::ImportExport::ChainExport;

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Session;
use OME::Tasks::ChainManager;

use Carp;
use Log::Agent;
use XML::LibXML;

our $NAMESPACE = 'http://www.openmicroscopy.org/XMLschemas/AnalysisModule/IR3/AnalysisChain.xsd';
our $XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';

our $SCHEMA_LOCATION = $NAMESPACE;

sub new {
    my ($proto, %params) = @_;
    my $class = ref($proto) || $proto;

    my @fieldsILike = qw(_parser);

    my $self;

    @$self{@fieldsILike} = @params{@fieldsILike};

	if (!defined $self->{_doc}) {
		my $doc = XML::LibXML::Document->new();
		die "Cannot create XML document"
		  unless defined $doc;
		$self->{_doc} = $doc;
	}

	if (!defined $self->{_ChainManager}) {
		$self->{_ChainManager} = OME::Tasks::ChainManager->new()
			or die "Cannot create Chain manager"
	}

    return bless $self, $class;
}


sub exportFile {
	my ($self, $filename, %flags) = @_;
	my $doc = $self->doc();
	$flags{ compression } = 7 
		unless exists $flags{ compression } and defined $flags{ compression };
	logdie ref ($self)."->exportFile:  Need a filename parameter to export a file."
		unless defined $filename;
	$doc->setCompression($flags{ compression });
	logdie ref ($self)."->exportFile:  File could not be written."
		unless $doc->toFile($filename, 1); 
}

sub exportXML {
	my ($self, %flags) = @_;
	return ($self->doc()->toString(1));
}

sub doc {
	my $self = shift;
	return ($self->{_doc});
}

sub ChainManager {
	my $self = shift;
	return ($self->{_ChainManager});
}

sub buildDOM {
	my ($self, $objects, %flags) = @_;
	logdie ref ($self)."->buildDOM:	 Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';
	
	# Get the AnalysisChains element
	$self->{_ACSelement} = $self->ACSelement();

	# Export objects that inherit from OME::AnalysisChain.
	foreach my $object (@$objects) {
		$self->exportChain ($object,%flags)
			if UNIVERSAL::isa($object,"OME::AnalysisChain");
	}
}


sub ACSelement {
	my $self = shift;
	my $doc = $self->doc();
	my $ACSelement = $self->{_ACSelement};
	if (not defined $ACSelement) {
		my $root = $doc->documentElement();
		if (not defined $root) {
# FIXME:  This should be created in a proper namespace
#			$ACSelement = $root = $doc->createElementNS ($NAMESPACE, "AnalysisChains" );
# FIXME:  Not like this:
			$ACSelement = $root = $doc->createElement ("AnalysisChains" );
			$doc->setDocumentElement($ACSelement);

			$ACSelement->setNamespace($XSI_NAMESPACE, 'xsi' ,0);
# FIXME:  This should be created in a proper namespace
#			$ACSelement->setAttribute('xsi:schemaLocation' ,"$NAMESPACE $SCHEMA_LOCATION");
#				$ACSelement->setAttributeNS($XSI_NAMESPACE, "noNamespaceSchemaLocation" ,"$SCHEMA_LOCATION");
# FIXME:  Not like this:
			$ACSelement->setAttributeNS($XSI_NAMESPACE, "noNamespaceSchemaLocation" ,"$SCHEMA_LOCATION");
		} else {
			$ACSelement = $root->getElementsByTagNameNS($NAMESPACE,'AnalysisChains')->[0]; 
			if (not defined $ACSelement) {
				$ACSelement = $doc->createElementNS ($NAMESPACE, "AnalysisChains" );
				$root->appendChild( $ACSelement );

				my $xsi_prefix = $ACSelement->lookupNamespacePrefix( $XSI_NAMESPACE );
				if (not defined $xsi_prefix) {
					$ACSelement->setNamespace($XSI_NAMESPACE, 'xsi' ,0);
					$xsi_prefix = 'xsi';
				}
				my %schemaLocations = split (/\s/,$ACSelement->findvalue('../@'.$xsi_prefix.':schemaLocation'));
				$ACSelement->setAttributeNS($XSI_NAMESPACE, "schemaLocation" ,"$NAMESPACE $SCHEMA_LOCATION")
					unless exists $schemaLocations{$NAMESPACE};

			}
		}
	}
	return $ACSelement;
}

sub exportNode {
	my ($self,$node,$AC_nodes,$AC_links) = @_;
	my $nodeID = $node->id();

	return if exists $self->{_NodeIDs}->{$nodeID};
	$self->{_NodeIDs}->{$nodeID} = undef;

	my $DOM = $self->doc();

	# Get a unique name for this node
	my $nodeName = $self->getNodeName ($node);
	my $nodeElement = $DOM->createElement('Node');
	$nodeElement->setAttribute('NodeID', $nodeName );
	$nodeElement->setAttribute('ProgramName', $node->module()->name());
	$nodeElement->setAttribute('IteratorTag', $node->iterator_tag()) if $node->iterator_tag();
	$nodeElement->setAttribute('NewFeatureTag', $node->new_feature_tag()) if $node->new_feature_tag();

	# Attach the Node element to the Nodes element
	$AC_nodes->appendChild( $nodeElement );

	my $links = $node->output_links();
	while (my $link = $links->next()) {
		my $linkElement = $DOM->createElement('Link');
		$linkElement->setAttribute('FromNodeID', $nodeName );
		$linkElement->setAttribute('FromOutputName', $link->from_output()->name());
		$linkElement->setAttribute('ToNodeID', $self->getNodeName ($link->to_node()) );
		$linkElement->setAttribute('ToInputName', $link->to_input()->name());
	
		# Attach the Link element to the Links element
		$AC_links->appendChild( $linkElement );
	}

	# Export the successors
	my $childNodes = $self->ChainManager()->getNodeSuccessors($node);
	foreach my $childNode (@$childNodes) {
		$self->exportNode ($childNode,$AC_nodes,$AC_links);
	}
	
	$self->{_NodeIDs}->{$nodeID} = 1;
	
}

sub exportChain {
    my ($self, $chain, %flags) = @_;
    my $chainManager = $self->ChainManager();
    my $chainName = $chain->name();
	logdbg "debug", ref ($self)."->exportChain:  Exporting Chain $chainName";

	# Does the Chain already exist?
	if (not exists $self->{_Chains}->{$chainName} or not defined $self->{_Chains}->{$chainName}) {
		logdbg "debug", ref ($self)."->exportChain:  Adding Chain $chainName to DOM";
		$self->{_Chains}->{$chainName} = undef;

		# get the STD element and the DOM
		my $ACSelement = $self->ACSelement();
		my $DOM = $self->doc();

		# Make the AnalysisChain element
		my $AC = $DOM->createElement('AnalysisChain');
		$AC->setAttribute( 'Name', $chainName );
		$AC->setAttribute( 'Locked', $chain->locked() ? 'true' : 'false' );
		
		my $AC_nodes = $DOM->createElement('Nodes');
		my $AC_links = $DOM->createElement('Links');
		
		# Attach the Nodes and Links elements to the ACS element
		$AC->appendChild( $AC_nodes );
		$AC->appendChild( $AC_links );

		# Get root nodes for the chain
		my $rootNodes = $chainManager->getRootNodes($chain);
		foreach my $node (@$rootNodes) {
			$self->exportNode ($node,$AC_nodes,$AC_links);
		}
		
		# Attach the Chain element to the AnalysisChains element
		$ACSelement->appendChild( $AC );
		$self->{_Chains}->{$chainName} = $chainName;
	} else {
		logdbg "debug", ref ($self)."->exportChain:  Chain $chainName already in DOM";
	}
	
	logdbg "debug", ref ($self)."->exportST:  Finished with Chain $chainName\n";
	
}


sub getNodeName {
	my ($self,$node) = @_;
	my $module = $node->module();
	my $nodeID = $node->id();
	my $moduleID = $module->id();
	my $nodeName = $module->name();
	
	return $self->{_NodeNames}->{$nodeID}
		if exists $self->{_NodeNames}->{$nodeID};

#	$nodeName =~ s/\s([a-z])/\u$1/g if $nodeName =~ /\s([a-z])/;
#	$nodeName =~ s/\s->\s/To/g if $nodeName =~ /\s->\s/;
#	$nodeName =~ s/[()]/_/g if $nodeName =~ /[()]/;
#	$nodeName =~ s/[_]$//g if $nodeName =~ /[_]$/;
#	$nodeName =~ s/[>]/Gt/g if $nodeName =~ /[>]/;
#	$nodeName =~ s/[<]/Lt/g if $nodeName =~ /[<]/;
#	$nodeName =~ s/[=]/Eq/g if $nodeName =~ /[=]/;
#	$nodeName =~ s/['"\s]//g if $nodeName =~ /['"\s]/;

	if (exists $self->{_ModuleIDs}->{$nodeName}) {
		my $i=1;
		$i++ while exists $self->{_ModuleIDs}->{$nodeName." $i"};
		$nodeName .= " $i";
	}
	$self->{_ModuleIDs}->{$nodeName} = $moduleID;
	$self->{_NodeNames}->{$nodeID} = $nodeName;
	return $nodeName;
}


1;
