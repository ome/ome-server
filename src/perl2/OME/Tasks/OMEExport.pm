# OME/Tasks/OMEExport.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  Ilya Goldberg <igg@nih.gov>
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Tasks::OMEExport;

use strict;
our $VERSION = '1.0';
our $NAMESPACE = 'http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd';
our $SCHEMA_LOCATION = $NAMESPACE;
our $XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';

use Carp;
use Log::Agent;
use XML::LibXML;

use OME::Tasks::SemanticTypeExport;
#use OME::Tasks::ProgramExport;
#use OME::Tasks::ChainExport;
use OME::Tasks::HierarchyExport;

sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session _doc);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	die "I need a session"
	  unless exists $self->{session} &&
			 UNIVERSAL::isa($self->{session},'OME::Session');

	if (!defined $self->{_doc}) {
		my $doc = XML::LibXML::Document->new();
		die "Cannot create XML document"
		  unless defined $doc;
		my $root = $doc->createElementNS($NAMESPACE,'OME');
		$root->setNamespace($XSI_NAMESPACE, 'xsi',0);
		$root->setAttributeNS($XSI_NAMESPACE,'schemaLocation',"$NAMESPACE $SCHEMA_LOCATION");
		$doc->setDocumentElement($root);
		$self->{_doc} = $doc;
	}

	return bless $self, $class;
}


sub exportFile {
	my ($self, $filename, %flags) = @_;
	my $doc = $self->doc();
	logdie ref ($self)."->exportFile:  Need a filename parameter to export a file."
		unless defined $filename;
	$doc->setCompression(7);
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


sub buildDOM {
	my ($self, $objects, %flags) = @_;
	my $doc = $self->doc();
	logdie ref ($self)."->buildDOM:  Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';

	if ($flags{ResolveAllRefs}) {
		$self->resolveAllRefs ($objects);
	}

	# Export the hierarchy and custom attributes
	logdbg "debug", ref ($self).'->buildDOM:  Getting a Hierarchy Exporter';
	my $hierarchyExporter = new OME::Tasks::HierarchyExport (session  => $self->{session}, _doc => $doc);
	logdbg "debug", ref ($self).'->buildDOM:  Exporting Hierarchy to DOM';
	$hierarchyExporter->buildDOM($objects,%flags);

	# Export semantic type definitions only if ExportSTDs is set
	if ($flags{ExportSTDs}) {
		logdbg "debug", ref ($self).'->buildDOM:  Getting a STD Exporter';
		my $typeExporter = new OME::Tasks::SemanticTypeExport (session => $self->{session}, _doc => $doc);
		logdbg "debug", ref ($self).'->buildDOM:  Exporting STDs to DOM';
		$typeExporter->buildDOM($objects,%flags);
	}
	
	
	# Export modules
#	my $moduleExporter = OME::Tasks::ProgramExport->
#	  new(session		  => $self->{session},
#			  _doc => $doc);

#	$moduleExporter->buildDOM($objects,%flags);

	# Export the chains
#	my $chainExporter = OME::Tasks::ChainExport->
#	  new(session => $self->{session},
#			  _doc => $doc);

#	$chainExporter->buildDOM($objects,%flags);


}


# FIXME:  This could stand a bit of implementation
sub resolveAllRefs {
	return undef;
}
1;
