# OME/ImportExport/SemanticTypeImport.pm

# Copyright (C) 2003 Open Microscopy Environment, MIT
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


package OME::ImportExport::SemanticTypeExport;

use strict;
our $VERSION = '1.0';
our $NAMESPACE = 'http://www.openmicroscopy.org/XMLschemas/STD/RC2/STD.xsd';
our $XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';

our $SCHEMA_LOCATION = $NAMESPACE;


use Carp;
use Log::Agent;
use XML::LibXML;


sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session _doc debug _STDelement);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	logdie "I need a session"
	  unless exists $self->{session} &&
			 UNIVERSAL::isa($self->{session},'OME::Session');

	if (!defined $self->{_doc}) {
		my $doc = XML::LibXML::Document->new();
		die "Cannot create XML document"
		  unless defined $doc;
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
	logdie ref ($self)."->buildDOM:	 Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';

	my $debug	= $self->{debug};
	my $session = $self->{session};
	my $factory = $session->Factory();
	
	# Go through the list of objects and export STDs for the ones that inherit from OME::SemanticType::Superclass.
	foreach (@$objects) {
		$self->exportST ($_) if UNIVERSAL::isa($_,"OME::SemanticType::Superclass");
	}
}

# This method will return the DOM's STD element and create a new one if its not there.
# If there is no root element, root will be set to the STD element
# If there is a root element, the STD element will be inserted as the last child.
# Namespaces and schema locations will be re-used if the root element declared them.
# This method should only be called if there are STDs to export.
sub STDelement {
	my $self = shift;
	my $doc = $self->doc();
	my $STDelement = $self->{_STDelement};
	if (not defined $STDelement) {
		my $root = $doc->documentElement();
		if (not defined $root) {
			$STDelement = $root = $doc->createElementNS ($NAMESPACE, "SemanticTypeDefinitions" );
			$doc->setDocumentElement($STDelement);

			$STDelement->setNamespace($XSI_NAMESPACE, 'xsi' ,0);
			$STDelement->setAttribute('xsi:schemaLocation' ,"$NAMESPACE $SCHEMA_LOCATION");
		} else {
			$STDelement = $root->getElementsByTagNameNS($NAMESPACE,'SemanticTypeDefinitions')->[0]; 
			if (not defined $STDelement) {
				$STDelement = $doc->createElementNS ($NAMESPACE, "SemanticTypeDefinitions" );
				$root->appendChild( $STDelement );

				my $xsi_prefix = $STDelement->lookupNamespacePrefix( $XSI_NAMESPACE );
				if (not defined $xsi_prefix) {
					$STDelement->setNamespace($XSI_NAMESPACE, 'xsi' ,0);
					$xsi_prefix = 'xsi';
				}
				my %schemaLocations = split (/\s/,$STDelement->findvalue('../@'.$xsi_prefix.':schemaLocation'));
				$STDelement->setAttributeNS($XSI_NAMESPACE, "schemaLocation" ,"$NAMESPACE $SCHEMA_LOCATION")
					unless exists $schemaLocations{$NAMESPACE};

			}
		}
#		$self->{_STDelement} = $STDelement;		
	}
	return $STDelement;
}

# Export the ST declaration for an OME::SemanticType::Superclass object.
sub exportST {
	my ($self, $object) = @_;
	my $semantic_type = $object->semantic_type();
	my $attribute_name = $semantic_type->name();

	logdbg "debug", ref ($self)."->exportST:  Exporting STD $attribute_name";
	
	# Does the STD already exist?
	if (not exists $self->{_STDs}->{$attribute_name} or not defined $self->{_STDs}->{$attribute_name}) {
		logdbg "debug", ref ($self)."->exportST:  Adding STD $attribute_name to DOM";
		$self->{_STDs}->{$attribute_name} = undef;

		# get the STD element and the DOM
		my $STDelement = $self->STDelement();
		my $DOM = $self->doc();
		my $semantic_elements = $semantic_type->semantic_elements();

		# Make the ST element
		my $ST = $DOM->createElement('SemanticType');
		$ST->setAttribute( 'Name', $attribute_name );
		$ST->setAttribute( 'AppliesTo', $semantic_type->granularity() );
		$ST->setAttribute( 'Description', $semantic_type->description() );
		
		# Make ST's Element elements
		while (my $semantic_element = $semantic_elements->next()) {
	        my $data_column = $semantic_element->data_column();
			my $DBLocation = $data_column->data_table()->table_name().'.'.$data_column->column_name();
			my $SEName = $semantic_element->name();

			my $element = $DOM->createElement('Element');
			$element->setAttribute( 'Name', $SEName);
			$element->setAttribute( 'DBLocation', $DBLocation);
			$element->setAttribute( 'DataType', $data_column->sql_type());
			
			if ($data_column->sql_type() eq 'reference') {
				my $referenceTo = $data_column->reference_type();
				$element->setAttribute( 'RefersTo', $referenceTo);
			}
			# Attach the Element element to the ST
			$ST->appendChild ($element);
		}
		
		# Attach the ST element to the STD element
		$STDelement->appendChild( $ST );
		$self->{_STDs}->{$attribute_name} = $semantic_type;
	} else {
		logdbg "debug", ref ($self)."->exportST:  STD $attribute_name already in DOM";
	}
	
	logdbg "debug", ref ($self)."->exportST:  Finished with STD $attribute_name\n";
}


1;
