# OME/ImportExport/HierarchyImport.pm
# This module is used for importing a list of objects from XML governed by the OME-CA schema.

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
# Written by:  
#    Josiah Johnston <siah@nih.gov>
#    Ilya G. Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::ImportExport::HierarchyImport;

=head1 NAME

OME::ImportExport::HierarchyImport - Import a list of objects from an OME XML.

=head1 SYNOPSIS

	# Should really have OMEImporter make the calls for you:
	my $importer = new OME::Tasks::OMEImport (session => $session);
	$importer->importFile ($filename);

	# Or, if you insist on doing it yourself:
    my $parser = new XML::LibXML ();
    my $hierarchyImporter = new OME::ImportExport::HierarchyImport->(session => $session);
    my $doc = $parser->parse_string($xml);
    my $objectList = $hierarchyImporter->processDOM($doc->getDocumentElement());

=head1 DESCRIPTION

This class is responsible for importing the OME hierarchy from an XML file, DOM or string.  The OME hierarchy
consists of the Project, Dataset, Image, and Feature elements as specified in the OME-CA schema.  Each level of the
hierarchy has an optional CustomAttributes element which may containn one or more CustomAttributes (instances of
a Semantic Type).

Currently, it also executes the Import Analysis Chain against the imported images and/or datasets.

=cut


use strict;

use Carp;
use Log::Agent;

use XML::LibXML;

use OME::LSID;
use OME::Analysis::AnalysisEngine;
use OME::Tasks::DatasetManager;
use OME::Tasks::ProjectManager;

=head1 METHODS

=head2 new

	my $importer = new OME::ImportExport::HierarchyImport (session => $session, _lsidResolver => $lsidRslvr);

This makes a new hierarchy importer.  The session parameter is required, and the _lsidResolver parameter is optional.
The _lsidResolver is an L<OME::LSID|OME::LSID> object used for resolving LSIDs to local DB IDs.  If one is not passed
as a parameter a new resolver for this instance will be generated with this method call.

=cut

sub new {
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my %params = @_;
	
	logdbg "debug", $proto . "->new called with parameters:\n\t" .
		join( "\n\t", map { $_."=>".$params{$_} } keys %params );
	
	my @requiredParams = ('session');
	
	foreach (@requiredParams) {
		die ref ($class) . "->new called without required parameter '$_'"
			unless exists $params{$_}
	}

	my $self = {
		session         => $params{session},
		_lsidResolver   => $params{_lsidResolver},
		_docIDs         => {},
		_docRefs		=> {},
		_DBObjects      => [],
		_nullAnalysisSTs=> {
			'Thumbnail'      => undef,
			'DisplayChannel' => undef,
			'DisplayOptions' => undef,
			'DisplayROI'     => undef, 
			},
			
	};

	if (!defined $self->{_lsidResolver}) {
		$self->{_lsidResolver} = new OME::LSID (session => $self->{session});
	}

	$self->{factory} = $self->{session}->Factory()
		or die "Could not obtain a Factory object for this session.";

	

	bless($self,$class);
	logdbg "debug", ref ($self) . "->new returning successfully";
	return $self;
}


=head2 processDOM

	my $objects = $exporter->processDOM ($root);

This will read the XML sub-tree under the $root element, creating objects in the DB.  A reference to the list
of objects in the sub-tree will be returned.
The objects will be written to the DB at the end of the import, and the Session's database handle committed.
All images will be imported into a dummy dataset and the standard analysis chain will be executed on them.
N.B.:  In the present implementation, if the LSIDs in XML are resolved to objects in the DB, 
the object is not re-imported - but only for components of the hierarchy above <Image>.  The <Image> elements 
and everything below them in the hierarchy are always re-imported.  In a subsequent release, we will be able to 
merge attributes for all objects.

=cut

###############################################################################
#
# Process DOM
# parameters:
#	$root element (DOM model)
#
sub processDOM {
	my $self    = shift;
	my $root    = shift;

	my $session = $self->{session};
	my $factory = $self->{factory};
	my $lsid = $self->{_lsidResolver};
	my $datasetManager = new OME::Tasks::DatasetManager($session);
	my $projectManager = new OME::Tasks::ProjectManager($session);
	
	# Turn on row guessing if its off - make the factory figure out how to put attributes together into DB rows.
	my $oldRowGuessing = OME::SemanticType->GuessRows();
	OME::SemanticType->GuessRows(1);

	
	###########################################################################
	# These hashes store the IDs we've found so far in the document
	# The first is keyed by LSID, where the value is the corresponding Database ID.
	# docIDs->{$LSID} => $DBID # IDs for objects in the document
	# The second stores unresolved references.  The key is also the LSID of the reference.
	# The LSID points to an array of objects and fields in those objects that made the reference.
	# docRefs->{$refLSID} => [{Object=>$object, Field=>$field}]    # IDs for references in the document
	#

	my $docIDs = $self->{_docIDs};
	my $docRefs = $self->{_docRefs};
	my ($node,$refNode,$object,$objectID,$refObject,$refObjectID,$refID);


	# process global custom attributes
	my @CAs;
	my ($CA,$CAnode);
	$CAnode = $root->getChildrenByTagName('CustomAttributes')->[0];
	@CAs = $CAnode ? grep{ $_->nodeType == 1 } $CAnode->childNodes() : () ;
	foreach $CA ( @CAs ) {
		$self->importObject ($CA,'G',undef,undef);
	}

	# process projects
	logdbg "debug", ref ($self)."->processDOM: Processing Projects";
	foreach $node ( @{ $root->getChildrenByTagName('Project') } ) {
		$self->importObject ($node,undef,undef,undef);
	}	

	# process datasets
	logdbg "debug", ref ($self)."->processDOM: Processing Datasets";
	foreach $node ( @{ $root->getChildrenByTagName('Dataset') } ) {
		$object = $self->importObject ($node,undef,undef,undef);
		$objectID = $object->id();

		# make connections between datasets and projects
		logdbg "debug", ref ($self)."->processDOM: Connecting Datasets to Projects";
		foreach $refNode ( @{ $node->getChildrenByTagName('ProjectRef') } ) {
			$refID = $refNode->getAttribute('ID');
			if (exists $docIDs->{$refID}) {
				$refObjectID = $docIDs->{$refID};
			}
			else {
				$refObject = $lsid->getLocalObject ($refID);
				$refObjectID = $refObject ? $refObject->id() : undef
			}
			logdie ref ($self) . "->processDOM: Could not resolve Project ID '$refID'"
				unless defined $refObjectID;
			$projectManager->addToProject ($objectID, $refObjectID);
		}
		
		# Import Dataset CAs
		$CAnode = $node->getChildrenByTagName('CustomAttributes')->[0];
		@CAs = $CAnode ? grep{ $_->nodeType eq 1 } $CAnode->childNodes() : () ;
		foreach $CA ( @CAs ) {
			$self->importObject ($CA,'D',$objectID,undef);
		}
	}	

	# process images
	logdbg "debug", ref ($self)."->processDOM: Processing Images";
	my ($importDataset,$importAnalysis);
	foreach my $node ( @{ $root->getChildrenByTagName('Image') } ) {
	
		$object = $self->importObject ($node,undef,undef,undef);
		$objectID = $object->id();

		# make connections between images and datasets
		logdbg "debug", ref ($self)."->processDOM: Connecting Images to Datasets";
		foreach $refNode ( @{ $node->getChildrenByTagName('DatasetRef') } ) {
			$refID = $refNode->getAttribute('ID');
			if (exists $docIDs->{$refID}) {
				$refObjectID = $docIDs->{$refID};
			}
			else {
				$refObject = $lsid->getLocalObject ($refID);
				$refObjectID = $refObject ? $refObject->id() : undef
			}
			logdie ref ($self) . "->processDOM: Could not resolve Dataset ID '$refID'"
				unless defined $refObjectID;
			$datasetManager->addImages ([$objectID], $refObjectID);
		}

		# These get imported into an import dataset
		$importDataset = $self->dataset()
			or die "Could not make an import dataset! ";
		$self->addObject ($factory->maybeNewObject('OME::Image::DatasetMap',
			{image_id => $objectID, dataset_id => $importDataset->id()}
		));

		# We need an module_execution for these.  This will return the one stored in the object or make a new one.
		$importAnalysis = $self->module_execution();

		# Import Image CAs
		$CAnode = $node->getChildrenByTagName('CustomAttributes')->[0];
		@CAs = $CAnode ? grep{ $_->nodeType eq 1 } $CAnode->childNodes() : () ;
		foreach $CA ( @CAs ) {
			my $imgAttr = $self->importObject ($CA,'I',$objectID,$importAnalysis);
# This is a hack to rename the pixels repository file to the standard naming convention
# added by josiah Friday 13, June, 2003
# Modified by IGG 06/27/03 to also assign the proper repository ID to the pixels.
# Modified DC 08/12/2003 to only normalize the "name" portion of the
# filename, not the id or punctuation.  (It was turned 5-abc.ori into
# 5_abc_ori -- not ideal.)
			if( $CA->tagName() eq 'Pixels' ) {
				# Get the Repository object from the LSID
				my $repository = $lsid->getLocalObject ($CA->getAttribute('Repository'))
					or die "A repository was not assigned for Pixels ID: '".$CA->getAttribute('ID')."'!\n";
				# Assign the pixels to the proper repository
				$imgAttr->Repository ($repository);
                                my $normalized_name = $object->name();
				$normalized_name =~ s/[^a-zA-Z0-9]/_/g;
				my $newPath = $imgAttr->id().'-'.$normalized_name.'.ori';
				my $cmd = 'mv '.$object->getFullPath($imgAttr).' '.$imgAttr->Repository()->Path().'/'.$newPath;
				system( $cmd ) eq 0 or die "Could not rename a repository file!\ncommand was '$cmd'\n";
				$imgAttr->Path( $newPath );
			}
		}
# end of hack

		my $image = $object;
		my $imageID = $image->id();
		# Import Features
		$self->importFeatures ($imageID, undef, $importAnalysis, $node);
	}
	
	# Turn row gessing back to what it was before.
	OME::SemanticType->GuessRows($oldRowGuessing);

	# Commit everything we've got so far.
	logdbg "debug", ref ($self)."->processDOM: Committing DBObjects";
	$self->commitObjects ();

	# Run the engine on the dataset.
    my $view = $factory->
		findObject("OME::AnalysisChain",name => 'Image import analyses');
	
	if (!defined $view or !defined $importAnalysis) {
		logcarp "The image import analysis chain is not defined.  Skipping predefined analyses..."
			if !defined $view;
		return $self->{_DBObjects};
	}
	logdbg "debug", ref ($self)."->processDOM: Running module_execution tasks";
	my $engine = OME::Analysis::AnalysisEngine->new();

#	eval {
		$engine->executeAnalysisView($session,$view,{},$importDataset);
#	};
	
#	logcarp "$@" if $@;
	return $self->{_DBObjects};
}


sub importFeatures ($$$) {
my ($self, $imageID, $parentFeature, $importAnalysis, $node) = @_;

		logdbg "debug", ref ($self)."->importFeatures: Processing Features";

		foreach my $feature (@{$node->getChildrenByTagName('Feature' )}) {
			my $object = $self->importObject ($feature,undef,$imageID,$parentFeature);
			$object->parent_feature ($parentFeature) if defined $parentFeature;
			my $objectID = $object->id();

			# Import Feature CAs
			my $CAnode = $feature->getChildrenByTagName('CustomAttributes')->[0];
			my @CAs = $CAnode ? grep{ $_->nodeType eq 1 } $CAnode->childNodes() : () ;
			foreach my $CA ( @CAs ) {
				$self->importObject ($CA,'F',$objectID,$importAnalysis);
			}
			$self->importFeatures ($imageID, $object, $importAnalysis, $feature);
		}
}

sub module_execution () {
	my $self = shift;

	return $self->{_module_execution} if exists $self->{_module_execution} and defined $self->{_module_execution};
	my $session = $self->{session};

    my $config =  $self->{factory}->loadObject("OME::Configuration", 1);

    my $module_execution = $self->{factory}->
		newObject("OME::ModuleExecution", {
			dependence => 'I',
			dataset_id => $self->dataset()->id(),
			timestamp  => 'now',
			status     => 'FINISHED',
			module_id => $config->import_module()->id(),
		});

    $self->{_module_execution} = $module_execution;
    $self->addObject ($module_execution);
    return ($module_execution);
}


sub dataset () {
	my $self = shift;

	return $self->{_dataset} if exists $self->{_dataset} and defined $self->{_dataset};
	my $session = $self->{session};

    my $dataset = $self->{factory}->
		newObject("OME::Dataset", {
			name => 'Dummy XML import dataset',
			description => '',
			locked => 'true',
			owner_id => $session->User()->id(),
			group_id => undef
		});
    $self->{_dataset} = $dataset;
    $self->addObject ($dataset);
    return ($dataset);
}


sub commitObjects () {
	my $self = shift;
	
	logdbg "debug", ref ($self)."->commitObjects: committing ".scalar (@{ $self->{_DBObjects} })." objects.";
    $_->storeObject() foreach @{ $self->{_DBObjects} };
    $self->{_DBObjects} = [];
}

sub addObject ($) {
	my ($self,$object) = @_;
	push (@{ $self->{_DBObjects} }, $object) if defined $object;
	logdbg "debug", ref ($self)."->addObject: added object #".scalar (@{ $self->{_DBObjects} })." '".ref($object).
		"' ID = ".$object->id()." for later commit.";
}


sub importObject ($$$$) {
	my ($self, $node, $granularity, $parentDBID, $module_execution) = @_;
	return undef unless defined $node;

	my $docIDs     = $self->{_docIDs};
	my $docRefs    = $self->{_docRefs};

	logdbg "debug", ref ($self)."->importObject: Importing node ".$node->nodeName ()." type ".$node->nodeType ();
	
	my $theObject;
	my $lsid = $self->{_lsidResolver};
	my $LSID = $node->getAttribute('ID');
	logdbg "debug", ref ($self)."->importObject: Trying to resolve '$LSID' locally";
	$theObject = $lsid->getLocalObject ($LSID);
	$parentDBID = undef if $granularity eq 'G';
	$module_execution = undef if $granularity eq 'G' or $granularity eq 'D';
	$module_execution = undef if exists $self->{_nullAnalysisSTs}->{$node->nodeName()};

#
# FIXME (IGG):  Only allow previously seen objects to be resolved if there is
# no module_execution associated with the object.
# This is because we have no way of merging attributes from different module executions.
	$theObject = undef if $module_execution;
# Images get re-imported even though they have no module_execution.
	$theObject = undef if $node->nodeName() eq 'Image';

	if (defined $theObject) {
		$docIDs->{$LSID} = $theObject->id();
		logdbg "debug", ref ($self)."->importObject: Object ID '$LSID' exists in DB!";
		return $theObject;
	}

	logdbg "debug", ref ($self)."->importObject:   Building new Object $LSID.";

	my $session	   = $self->{session};
	my $factory	   = $self->{factory};

	# It is fatal for an object ID to be non-unique
	logdie ref ($self) . "->importObject: Attempt to import an attribute with duplicate ID '$LSID'"
		if exists $docIDs->{$LSID};
	$docIDs->{$LSID} = undef;

	my ($objectType,$isAttribute,$objectData,$refCols) = $self->getObjectTypeInfo($node,$parentDBID);
	logdbg "debug", ref ($self)."->importObject:   Got info - object type $objectType.";

	# Process references in this object.
	# If the reference was to an object already read from the document, resolve it.
	# If not, check if its already in the DB
	# If not, store the object for later resolution in a local hash.
	my %unresolvedRefs;
	my ($objField,$theRef,$refObject);
	while ( ($objField,$theRef) = each %$refCols ) {
		if (exists $docIDs->{$theRef}) {
			$objectData->{$objField} = $docIDs->{$theRef};
			logdbg "debug", ref ($self)."->importObject:     Field $objField -> $theRef resolved to ".
				$objectData->{$objField}." in document.";
		} else {
			$refObject = $lsid->getLocalObject ($theRef);
			# FIXME (IGG): references to pixels within Image objects do not get resolved because they will be re-made each time.
			$refObject = undef if $objField eq 'pixels_id' and $objectType eq 'OME::Image';
			if ($refObject) {
				$objectData->{$objField} = $refObject->id();
				logdbg "debug", ref ($self)."->importObject:     Field $objField -> $theRef resolved to ".
					$objectData->{$objField}." in DB.";
			} else {
				$objectData->{$objField} = undef;
				$unresolvedRefs{$objField} = $theRef;
				logdbg "debug", ref ($self)."->importObject:     Field $objField -> $theRef NOT resolved.";
			}
		}
	}
	
	$theObject = undef;

	# Make the object.
	if ($isAttribute) {
		logdbg "debug", ref ($self)."->importObject:   Calling newAttribute.\n\t".
			join( "\n\t", map { $_."=>".$objectData->{$_} } keys %$objectData );
		$theObject = $factory->newAttribute($objectType,$parentDBID,$module_execution,$objectData);
	} else {
		logdbg "debug", ref ($self)."->importObject:   Calling newObject.".
			join( "\n\t", map { $_."=>".$objectData->{$_} } keys %$objectData );
		$theObject = $factory->newObject($objectType,$objectData);
	}

	# Set the Object's DBID in the global docID hash
	my $objID = $theObject->id();
	$docIDs->{$LSID} = $objID;

	# Add the unresolved references for this object from the local unresolvedRefs hash to the global docRefs hash
	while ( ($objField, $theRef) = each %unresolvedRefs ) {
		push (@{ $docRefs->{$theRef} }, {Object=>$theObject, Field=>$objField});
	}

	# If this object resolves some references, resolve them.
	if (exists $docRefs->{$LSID}) {
		foreach (@{ $docRefs->{$LSID} }) {
			$objField = $_->{Field};
			$_->{Object}->$objField ($objID);
		}
		delete $docRefs->{$LSID};
	}

    $self->addObject ($theObject);
	return ($theObject);
}




sub getObjectTypeInfo ($$) {
	my ($self,$node,$parentID) = @_;
	return undef unless defined $node;

	my ($objectType,$isAttribute,$objectData,$refCols) = ('',0,{},{});

	$objectType = $node->nodeName();

	if ($objectType eq 'Project') {
		$objectType = 'OME::Project';
		$objectData = {
			name        => $node->getAttribute( 'Name' ),
			description => $node->getAttribute( 'Description' ),
			owner_id    => $node->getAttribute( 'Experimenter' ),
			group_id    => $node->getAttribute( 'Group' )
		};
		$refCols = {
			owner_id => $objectData->{owner_id},
			group_id => $objectData->{group_id}
		};

	} elsif ($objectType eq 'Dataset') {
		$objectType = 'OME::Dataset';
		$objectData = {
			name        => $node->getAttribute( 'Name' ),
			description => $node->getAttribute( 'Description' ),
			owner_id    => $node->getAttribute( 'Experimenter' ),
			group_id    => $node->getAttribute( 'Group' ),
# locked may need to be cast into boolean
			locked      => lc ($node->getAttribute( 'Locked' )) eq 'true' ? '1':'0'
		};
		$refCols = {
			owner_id => $objectData->{owner_id},
			group_id => $objectData->{group_id}
		};

	} elsif ($objectType eq 'Image') {
		$objectType = 'OME::Image';
		$objectData = {
			name            => $node->getAttribute( 'Name' ),
			description     => $node->getAttribute( 'Description' ),
			created         => $node->getAttribute( 'CreationDate' ),
			inserted        => 'NOW',
			experimenter_id => $node->getAttribute( 'Experimenter' ),
			group_id        => $node->getAttribute( 'Group' ),
			pixels_id       => $node->getAttribute( 'DefaultPixels' )
		};
		$refCols = {
			experimenter_id => $objectData->{experimenter_id},
			group_id        => $objectData->{group_id},
			pixels_id       => $objectData->{pixels_id}
			};

	} elsif ($objectType eq 'Feature') {
		$objectType = 'OME::Feature';
		$objectData = {
			name        => $node->getAttribute( 'Name' ),
			tag         => $node->getAttribute( 'Tag' ),
			image_id    => $parentID
		};
		$refCols = {};

	} else {
		my $factory	   = $self->{factory};
		my $ST = $factory->findObject("OME::SemanticType",name => $objectType)
			|| logdie ref ($self) . "->getObjectTypeInfo: Attempt to import an undefined attribute type: $objectType";
		my @attrColumns = $ST->semantic_elements();
		my ($attrCol,$attrColName);
		foreach $attrCol (@attrColumns) {
			$attrColName = $attrCol->name();
			$objectData->{$attrColName} = $node->getAttribute($attrColName);
			my $sql_type = $attrCol->data_column()->sql_type();
			if ($sql_type eq 'reference') {
				$refCols->{$attrColName} = $objectData->{$attrColName};
			} elsif ($sql_type eq 'boolean') {
				$objectData->{$attrColName} = $objectData->{$attrColName} eq 'true' ? '1' : '0';
			}
			logdbg "debug", ref ($self)."->getObjectTypeInfo:   $attrColName = ".$objectData->{$attrColName};
		}

                # (Modified DC - 08/12/2003)  We do not need to set the
                # target field (dataset_id, image_id, or feature_id), as
                # this will be set appropriately by the call to
                # $factory->newAttribute().

		$isAttribute = 1;
	}
	return ($objectType,$isAttribute,$objectData,$refCols);
}



=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov), Ilya Goldberg (igg@nih.gov)

=head1 SEE ALSO

L<OME::Tasks::OMEImport|OME::Tasks::OMEImport>

=cut


1;
