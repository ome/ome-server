# OME/Tasks/HierarchyExport.pm
# This module is used for exporting a list of objects to an XML hierarchy governed by the OME-CA schema.

# Copyright (C) 2003 Open Microscopy Environment
# Author:  Ilya G. Goldberg <igg@nih.gov>
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
package OME::Tasks::HierarchyExport;


=head1 NAME

OME::Tasks::HierarchyExport - Export a list of objects as an OME XML hierarchy

=head1 SYNOPSIS

	# Make a new Hierarchy exporter and a new XML document
	my $exporter = new OME::Tasks::HierarchyExport(session => $session);

	# Or - make a new Hierarchy exporter for an existing XML document
	my $exporter = new OME::Tasks::OMEExporter (session => $session);
	my $doc = $exporter->doc();
	my $exportH = new OME::Tasks::HierarchyExport(session => $session, _doc => $doc);

	# Build a DOM from a list of objects.
	$exportH->buildDOM (@OMEobjects);
	
	# Write an XML file, get the XML as a string, or get the XML document (XML::LibXML), 
	$exportH->exportFile ();
	my $xml = $exportH->exportXML ();
	my $doc = $exportH->doc();

=head1 DESCRIPTION

This class is responsible for exporting the hierarchy of OME elements as described in the OME-CA Schema.
This is a simplified version of the regular OME schema which contains the Project, Dataset, Image, Feature hierarchy
and CustomAttributes elements within the main OME element (global attributes), and the Dataset, Image and Feature elements.
The elements to be exported are specified as a list of objects that are passed to C<buildDom()>.
Since some objects in the XML document are nested within others (e.g.  Features within Image), parent objects not in the list
are sutomatically created as needed to make a properly structured XML document with an <OME> root element.

=cut

use strict;
use Carp;
use Log::Agent;
use XML::LibXML;
use OME::Tasks::OMEExport;
use OME::LSID;

=head1 METHODS

=head2 new

	my $exporter = new OME::Tasks::HierarchyExport (session => $session, _doc => $XMLdoc);

This makes a new hierarchy exporter.  The session parameter is required, and the _doc parameter is optional.
The _doc parameter is an XML document object as returned by XML::LibXML::Document->new();.
It can also be any of the document objects returned by the OME Exporters' doc() method (i.e. L<OME::Tasks::OMEExport|OME::Tasks::OMEExport>).
If the _doc parameter is not given, a new DOM will be created - the other methods in this class operate on this cumulative DOM.

=cut

sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session _doc _lsidResolver);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	logdie "I need a session"
	  unless exists $self->{session} &&
			 UNIVERSAL::isa($self->{session},'OME::Session');

	# Unfortunately only OMEExport knows how to make the 'OME' root element.
	if (!defined $self->{_doc}) {
		my $OMEExporter = OME::Tasks::OMEExport->new( session => $self->{session});
		$self->{_doc} = $OMEExporter->doc();
	}
	
	if (!defined $self->{_lsidResolver}) {
		$self->{_lsidResolver} = new OME::LSID (session => $self->{session});
	}

	$self->{_GlobalCAs} = {};
	$self->{_Projects} = {};
	$self->{_Datasets} = {};
	$self->{_Images} = {};
	$self->{_Features} = {};

	return bless $self, $class;
}




=head2 buildDOM

	$exporter->buildDOM ($objects);

This will build a DOM out of a list of OME objects.  The required parameter is a reference to a list of OME objects.
Since objects are nested in XML, this will create any container objects necessary to make a document with an <OME> root element.
The document generated with this call obeys the OME-CA Schema.  This method is E<not> re-entrant.  If you can call it repeatedly to build up
the DOM, any pre-existing children of root will be unbound.  They will stay in the DOM but be in limbo without parents or children.

=cut

sub buildDOM {
	my ($self, $objects, %flags) = @_;
	logdie ref ($self)."->buildDOM:	 Need a reference to an array of objects."
		unless ref($objects) eq 'ARRAY';

	my $session = $self->{session};

	my $GlobalCAs = $self->{_GlobalCAs};
	my $Projects = $self->{_Projects};
	my $Datasets = $self->{_Datasets};
	my $Images = $self->{_Images};
	my $Features = $self->{_Features};

	# sort the objects by building trees out of hashes that mimick the XML structure.
	# N.B.:  Without caching, and when the objects aren't sorted by depth, this code isn't very efficient in terms of memory or speed.
	my ($object,$ref,$id,$granularity);
	my ($target,$targetID);
	
	foreach $object (@$objects) {
		$ref = ref ($object);
		$id = $object->id();

		# Process the various kinds of attributes.
		# While we're at it, build the CA's parents.
		if (UNIVERSAL::isa($object,"OME::AttributeType::Superclass") ) {
			$granularity = $object->attribute_type()->granularity();
			if ($granularity eq 'G')  {
				if ( not exists $GlobalCAs->{$id} ) {
					$GlobalCAs->{$id}->{node} = $self->Attribute2doc ($object);
					$GlobalCAs->{$id}->{object} = $object;
				}
			} elsif ($granularity eq 'D')  {
				$target = $object->dataset();
				$targetID = $target->id();
				if (not exists $Datasets->{$targetID}) {
					$Datasets->{$targetID}->{node} = $self->Dataset2doc($target);
					$Datasets->{$targetID}->{object} = $target;
				}
				if (not exists $Datasets->{$targetID}->{CAs}) {
					$Datasets->{$targetID}->{CAs}->{node} = $self->newCAnode ($Datasets->{$targetID}->{node});
				}
				if (not exists $Datasets->{$targetID}->{CAs}->{$id}) {
					my $newNode = $self->Attribute2doc ($object,$Datasets->{$targetID}->{CAs}->{node});
					$Datasets->{$targetID}->{CAs}->{$id}->{node} = $newNode;
					$Datasets->{$targetID}->{CAs}->{$id}->{object} = $object;
				}

			} elsif ($granularity eq 'I')  {
				$target = $object->image();
				$targetID = $target->id();
				if (not exists $Images->{$targetID}) {
					$Images->{$targetID}->{node} = $self->Image2doc($target);
					$Images->{$targetID}->{object} = $target;
				}
				if (not exists $Images->{$targetID}->{CAs}) {
					$Images->{$targetID}->{CAs}->{node} = $self->newCAnode ($Images->{$targetID}->{node});
				}
				if (not exists $Images->{$targetID}->{CAs}->{$id}) {
					my $newNode = $self->Attribute2doc ($object,$Images->{$targetID}->{CAs}->{node});
					$Images->{$targetID}->{CAs}->{$id}->{node} = $newNode;
					$Images->{$targetID}->{CAs}->{$id}->{object} = $object;
				}

			} elsif ($granularity eq 'F')  {
				my ($feature, $featureID);
				$feature = $object->feature();
				$featureID = $feature->id();
				$self->Feature2doc($feature) or logdie ref ($self)."->buildDOM:  Couldn't create a Feature element.";
				if (not exists $Features->{$featureID}->{CAs}) {
					$Features->{$featureID}->{CAs}->{node} = $self->newCAnode ($Features->{$featureID}->{node});
				}
				if (not exists $Features->{$featureID}->{CAs}->{$id}) {
					my $newNode = $self->Attribute2doc ($object,$Features->{$featureID}->{CAs}->{node});
					$Features->{$featureID}->{CAs}->{$id}->{node} = $newNode;
					$Features->{$featureID}->{CAs}->{$id}->{object} = $object;
				}
			}

		# Process the hierarchy objects
		} elsif ($ref eq 'OME::Project' and not exists $Projects->{$id}) {
			$Projects->{$id}->{node} = $self->Project2doc ($object);
			$Projects->{$id}->{object} = $object;
		} elsif ($ref eq 'OME::Dataset' and not exists $Datasets->{$id}) {
			$Datasets->{$id}->{node} = $self->Dataset2doc ($object);
			$Datasets->{$id}->{object} = $object;
		} elsif ($ref eq 'OME::Image' and not exists $Images->{$id}) {
			$Images->{$id}->{node} = $self->Image2doc ($object);
			$Images->{$id}->{object} = $object;
		} elsif ($ref eq 'OME::Feature' and not exists $Features->{$id}) {
			$Features->{$id}->{node} = $self->Feature2doc ($object);
			$Features->{$id}->{object} = $object;
		}
	}
	# End first run through objects array.
	
	# In the second pass, we'll go through the hierarchy, adding it to the OME element.
	my $doc = $self->doc();
	my $root = $doc->documentElement();
	
	# Unbind every last child of the root node.
	# These will still be attached to the document, but without parents or children.
	while ($root->lastChild()) {
		logdbg "debug", ref ($self)."->buildDOM:  removing last child.";
		$root->lastChild()->unbindNode();
	}
	
	
	my $element;

	# Add the Projects
	foreach (values %$Projects) {
		$root->appendChild ($_->{node});
	}
	
	# Add the Datasets and their CustomAttributes
	foreach my $dataset (values %$Datasets) {
		$root->appendChild ($dataset->{node});
		my %datasetProjects = map {$_->id() => $_} $dataset->{object}->projects();

		# Only add the projects in the $objects list.
		foreach (values %datasetProjects) {
			$self->addRefNode ($_, 'ProjectRef', $dataset->{node})
				if exists $Projects->{$_->id()};
		}
	}

	# Add the Images, Features and their CustomAttributes
	foreach my $image (values %$Images) {
		$root->appendChild ($image->{node});
		my %imageDatasets = map {$_->id() => $_} $image->{object}->datasets();

		# Only add the datasets in the $objects list.
		foreach (values %imageDatasets) {
			$self->addRefNode ($_, 'DatasetRef', $image->{node})
				if exists $Datasets->{$_->id()};
		}

		# Add the features
		foreach my $feature (values %{ $image->{features} }) {
			$image->{node}->appendChild ($feature->{node});
		}

	}
	
	# Add the Global CustomAttributes
	my @CAs = values (%$GlobalCAs);
	if (@CAs > 0) {
		my $CAnode = $self->newCAnode ($root);
		foreach ( @CAs ) {
			$CAnode->appendChild ($_->{node});
		}
	}



} 



=head2 exportFile

	$exporter->exportFile (filename => $fileName);

This will write a new gzip-compressed XML file containing the DOM presently in $exporter.  Call C<buildDOM()> to build a DOM out of OME objects.

=cut

sub exportFile {
	my ($self, $filename, %flags) = @_;
	my $doc = $self->doc();
	logdie ref ($self)."->exportFile:  Need a filename parameter to export a file."
		unless defined $filename;
	$doc->setCompression(7);
	logdie ref ($self)."->exportFile:  File could not be written."
		unless $doc->toFile($filename, 1); 
}



=head2 exportXML

	my $XMLstring = $exporter->exportXML ();

This will return a formatted XML string containing the DOM presently in $exporter.  Call C<buildDOM()> to build a DOM out of OME objects.

=cut

sub exportXML {
	my ($self, %flags) = @_;
	return ($self->doc()->toString(1)); 
}


=head2 doc

	my $document = $exporter->doc ();

This will return the DOM presently in $exporter.  Call C<buildDOM()> to build a DOM out of OME objects.

=cut


sub doc {
	my $self = shift;
	return ($self->{_doc});
}


# Project2doc
# Parameters: Project object
# Returns: Project element
sub Project2doc {
my ($self, $project) = @_;

	return undef unless defined $project;
	my $Projects = $self->{_Projects};
	my $projectID = $project->id();
	if (exists $Projects->{$projectID}) {
		return $Projects->{$projectID}->{node};
	}

	my $DOM = $self->doc();
	my $lsid = $self->lsidResolver();
	my $element = $DOM->createElement('Project');
#  <Project ID="123.456.1.123.123" Name="Stress Response Pathway" Description="" Experimenter="lsid" Group="lsid">
	$element->setAttribute( 'ID' , $lsid->getLSID ($project) );
	$element->setAttribute( 'Name' , $project->name() );
	$element->setAttribute( 'Description' , $project->description() );
	$element->setAttribute( 'Experimenter' , $lsid->getLSID ($project->owner()) );
	$element->setAttribute( 'Group' , $lsid->getLSID ($project->group()) );
	logdbg "debug", ref ($self)."->Project2doc:  Adding Project element.";
	
	$Projects->{$projectID}->{node} = $element;
	$Projects->{$projectID}->{object} = $project;

	return $element;
	
}


# Dataset2doc
# Parameters: Dataset object
# Returns: Dataset element
sub Dataset2doc {
my ($self, $dataset) = @_;

	return undef unless defined $dataset;
	my $Datasets = $self->{_Datasets};
	my $datasetID = $dataset->id();
	if (exists $Datasets->{$datasetID}) {
		return $Datasets->{$datasetID}->{node};
	}

	my $DOM = $self->doc();
	my $lsid = $self->lsidResolver();
	my $element = $DOM->createElement('Dataset');
#  <Dataset ID="123.456.2.123.123" Name="Controls" Description="" Locked="true">
#    <Ref Name="Experimenter" ID="123.456.71.123.123"/>
#    <Ref Name="Group" ID="123.456.73.123.123"/>
#    <Ref Name="Project" ID="123.456.1.123.123"/>
#  </Dataset>
	$element->setAttribute( 'ID' , $lsid->getLSID ($dataset) );
	$element->setAttribute( 'Name' , $dataset->name() );
	$element->setAttribute( 'Description' , $dataset->description() );
	$element->setAttribute( 'Locked' , $dataset->locked() ? 'true' : 'false' );
	$element->setAttribute( 'Experimenter' , $lsid->getLSID ($dataset->owner()) );
	$element->setAttribute( 'Group' , $lsid->getLSID ($dataset->group()) );
# N.B.:  This element has optional multiple Project elements as 'Ref' child elements.
# These children should be added by calling $self->addRefNode ($object, 'Project', $parent) with this node as $parent
	logdbg "debug", ref ($self)."->Dataset2doc:  Adding Dataset element.";

	$Datasets->{$datasetID}->{node} = $element;
	$Datasets->{$datasetID}->{object} = $dataset;

	return $element;
}


# Image2doc
# Parameters: Image object
# Returns: Image element
sub Image2doc {
my ($self, $image) = @_;

	return undef unless defined $image;
	my $Images = $self->{_Images};
	my $imageID = $image->id();
	if (exists $Images->{$imageID}) {
		return $Images->{$imageID}->{node};
	}

	my $DOM = $self->doc();
	my $lsid = $self->lsidResolver();
	my $element = $DOM->createElement('Image');

	$element->setAttribute( 'ID' , $lsid->getLSID ($image) );
	$element->setAttribute( 'Name' , $image->name() );
	$element->setAttribute( 'CreationDate' , $image->created() );
	$element->setAttribute( 'Description' , $image->description() );
	$element->setAttribute( 'Experimenter' , $lsid->getLSID ($image->experimenter()) );
	$element->setAttribute( 'Group' , $lsid->getLSID ($image->group()) );
# N.B.:  This element has optional multiple Dataset elements as 'Ref' child elements.
# These children should be added by calling $self->addRefNode ($object, 'Dataset', $parent) with this node as $parent
	logdbg "debug", ref ($self)."->Image2doc:  Adding Image element.";

	$Images->{$imageID}->{node} = $element;
	$Images->{$imageID}->{object} = $image;


	return $element;

}


# Feature2doc
# Parameters: Feature object
# Returns: Feature element
sub Feature2doc ($) {
my ($self, $feature) = @_;

	return undef unless defined $feature;

	my $Features = $self->{_Features};
	my $featureID = $feature->id();
	if (exists $Features->{$featureID}) {
		return $Features->{$featureID}->{node};
	}

	my $DOM = $self->doc();
	my $lsid = $self->lsidResolver();
	my $element = $DOM->createElement('Feature');
	my $Images = $self->{_Images};

	$element->setAttribute( 'ID' , $lsid->getLSID ($feature) );
	$element->setAttribute( 'Name' , $feature->name() );
	$element->setAttribute( 'Tag' , $feature->tag() );
	logdbg "debug", ref ($self)."->Feature2doc:  Adding Feature element.";

	$Features->{$featureID}->{node} = $element;
	$Features->{$featureID}->{object} = $feature;
	
	if ( $feature->parent_feature() ) {
		my $parent = $self->Feature2doc ($feature->parent_feature());
		$parent->appendChild ($element);
	} else {
		# The ultimate parent of a feature is an Image, so we have to make that too.
		my $image = $feature->image();
		my $imageID = $image->id();
		if (not exists $Images->{$imageID}) {
			$Images->{$imageID}->{node} = $self->Image2doc ($image);
			$Images->{$imageID}->{object} = $image;
		}
		# Add the top-most feature to the image.
		$Images->{$imageID}->{features}->{$featureID} = $Features->{$featureID};
	}

	return $element;
}

# newCAnode
# Parameters:  parent node.
# Returns: CustomAttributes element
sub newCAnode {
my ($self, $parent) = @_;
	logdbg "debug", ref ($self)."->newCAnode:  Adding CustomAttributes element.";

	my $DOM = $self->doc();
	my $element = $DOM->createElement('CustomAttributes');
	if (defined $parent) {
		$parent->appendChild ($element);
	}
	return ($element);
}

# Attribute2doc
# Parameters: object, parent node (optional)
# Returns: a CA element
sub Attribute2doc {
my ($self, $object, $parent) = @_;

	my $DOM = $self->doc();
	my $lsid = $self->lsidResolver();
	my $attribute_type = $object->attribute_type();
	my $attribute_name = $attribute_type->name();
	my $attribute_columns = $attribute_type->attribute_columns();
	my $element = $DOM->createElement($attribute_name);
	$element->setAttribute( 'ID' , $lsid->getLSID ($object) );
	logdbg "debug", ref ($self)."->Attribute2doc:  Exporting Attribute '$attribute_name'";
	while (my $attribute_column = $attribute_columns->next()) {
		my $SEName = $attribute_column->name();
		my $type = $attribute_column->data_column->sql_type();
		if ($type eq 'reference') {
			$element->setAttribute( $SEName, $lsid->getLSID($object->$SEName()));
		} else {
			$element->setAttribute( $SEName, $object->$SEName() );
		}
	}
	
	if (defined $parent) {
		$parent->appendChild ($element);
	}
	
	return ($element);
}

sub addRefNode {
my ($self, $object, $name, $parent) = @_;
	logdbg "debug", ref ($self)."->addRefNode:  Adding $name reference.";

	my $DOM = $self->doc();
	my $lsid = $self->lsidResolver();
	my $element = $DOM->createElement($name);
	$element->setAttribute( 'ID' , $lsid->getLSID($object));
	if (defined $parent) {
		$parent->appendChild ($element);
	}
	return ($element);
}

sub lsidResolver() {
	return shift->{_lsidResolver}
}

=pod

=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=head1 SEE ALSO

L<OME::Tasks::OMEExport|OME::Tasks::OMEExport>

=cut


1;
