package OME::Tasks::HierarchyImport;

use strict;

use Carp;
use Log::Agent;

use XML::LibXML;

use OME::LSID;
use OME::Tasks::AnalysisEngine;

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
		_parser         => $params{_parser},
		_docIDs         => {},
		_docRefs		=> {},
	};
	
	if (!defined $self->{_parser}) {
		my $parser = XML::LibXML->new();
		die "Cannot create XML parser"
		  unless defined $parser;
		
		$parser->validation(exists $params{ValidateXML}?
							$params{ValidateXML}: 0);
		$self->{_parser} = $parser;
	}

	if (!defined $self->{_lsidResolver}) {
		$self->{_lsidResolver} = new OME::LSID (session => $self->{session});
	}


	bless($self,$class);
	logdbg "debug", ref ($self) . "->new returning successfully";
	return $self;
}


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
	my $factory = $session->Factory();
	my $lsid = $self->{_lsidResolver};
	
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
	my ($node,$refNode,$object,$objectID,$refObject,$refID);


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
				$refObject = $docIDs->{$refID};
			} else {
				$refObject = $lsid->getLocalObject ($refID);
			}
			logdie ref ($self) . "->processDOM: Could not resolve Project ID '$refID'"
				unless defined $refObject;
			$factory->maybeNewObject('OME::Project::DatasetMap',
				{dataset_id => $objectID, project_id => $refObject->id()}
			);
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
				$refObject = $docIDs->{$refID};
			} else {
				$refObject = $lsid->getLocalObject ($refID);
			}
			logdie ref ($self) . "->processDOM: Could not resolve Dataset ID '$refID'"
				unless defined $refObject;
			$factory->maybeNewObject('OME::Image::DatasetMap',
				{image_id => $objectID, dataset_id => $refObject->id()}
			);
		}

		# These get imported into an import dataset
		$importDataset = $self->dataset();
		$factory->maybeNewObject('OME::Image::DatasetMap',
			{image_id => $objectID, dataset_id => $importDataset->id()}
		);

		# We need an analysis for these.  This will return the one stored in the object or make a new one.
		$importAnalysis = $self->analysis();

		# Import Image CAs
		$CAnode = $node->getChildrenByTagName('CustomAttributes')->[0];
		@CAs = $CAnode ? grep{ $_->nodeType eq 1 } $CAnode->childNodes() : () ;
		foreach $CA ( @CAs ) {
			$self->importObject ($CA,'I',$objectID,$importAnalysis);
		}

		my $image = $object;
		my $imageID = $image->id();
		# Import Features
		# This does a breadth-first traversal of the features sub-tree - non-recursively.
		logdbg "debug", ref ($self)."->processDOM: Processing Features";
		my $feature = $node->getChildrenByTagName('Feature' )->[0];
		my ($parentFeature, $firstFeature);
		$firstFeature = $feature;
		while ($feature) {
			$object = $self->importObject ($feature,undef,$imageID,undef);
			$object->image($image);
			$object->parent_feature($parentFeature) if defined $parentFeature;

			$objectID = $object->id();

			# Import Feature CAs
			$CAnode = $feature->getChildrenByTagName('CustomAttributes')->[0];
			@CAs = $CAnode ? grep{ $_->nodeType eq 1 } $CAnode->childNodes() : () ;
			foreach $CA ( @CAs ) {
				$self->importObject ($CA,'I',$objectID,$importAnalysis);
			}
			# Go to the sibling.
			$feature = $feature->nextSibling ();
			while ($feature and not $feature->nodeName() eq 'Feature') {$feature = $feature->nextSibling ();}
			# If we're got all the siblings, set ourselves as the parent,
			# and go down a level from this level's first feature
			if (not defined $feature) {
				$parentFeature = $feature;
				$feature = $firstFeature->getChildrenByTagName('Feature' )->[0];
				$firstFeature = $feature;
			}
		}
	}
	
	# Commit everything we've got so far.
	logdbg "debug", ref ($self)."->processDOM: Committing DBObjects";
	$self->commitObjects ();

	# Run the engine on the dataset.
#    my $view = $factory->
#		findObject("OME::AnalysisView",name => 'Image import analyses');
#	if (!defined $view) {
#		logcarp "The image import analysis chain is not defined.  Skipping predefined analyses...";
#		return;
#	}
#	logdbg "debug", ref ($self)."->processDOM: Running Analysis tasks";
#	my $engine = OME::Tasks::AnalysisEngine->new();
#	eval {
#		$engine->executeAnalysisView($session,$view,{},$importDataset);
#	};
#	
#	logcarp "$@" if $@;
	return;
}

sub analysis () {
	my $self = shift;

	return $self->{_analysis} if exists $self->{_analysis} and defined $self->{_analysis};
	my $session = $self->{session};

    my $config = $session->Factory()->loadObject("OME::Configuration", 1);

    my $analysis = $session->Factory()->
		newObject("OME::Analysis", {
			dependence => 'I',
			dataset_id => $self->dataset()->id(),
			timestamp  => 'now',
			status     => 'FINISHED',
			program_id => $config->import_module()->id(),
		});

    $self->{_analysis} = $analysis;
    $self->addObject ($analysis);
    return ($analysis);
}


sub dataset () {
	my $self = shift;

	return $self->{_dataset} if exists $self->{_dataset} and defined $self->{_dataset};
	my $session = $self->{session};

    my $dataset = $session->Factory()->
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
	
    $_->writeObject() foreach @{ $self->{_DBObjects} };
    $self->{_DBObjects} = [];

    $self->{session}->DBH()->commit();
}

sub addObject ($) {
	my ($self,$object) = shift;
	push (@{ $self->{_DBObjects} }, $object) if defined $object;
}


sub importObject ($$$$) {
	my ($self, $node, $granularity, $parentDBID, $analysis) = @_;
	return undef unless defined $node;

	my $docIDs     = $self->{_docIDs};
	my $docRefs    = $self->{_docRefs};

	logdbg "debug", ref ($self)."->importObject:  Importing node ".$node->nodeName ()." type ".$node->nodeType ();
	
	my $lsid = $self->{_lsidResolver};
	my $LSID = $node->getAttribute('ID');
	my $theObject = $lsid->getLocalObject ($LSID);
	if (defined $theObject) {
		$docIDs->{$LSID} = $theObject->id();
		logdbg "debug", ref ($self)."->importObject:  Object ID '$LSID' exists in DB!";
		return $theObject;
	}

	logdbg "debug", ref ($self)."->importObject:  Building new Object ID.";
	$parentDBID = undef if $granularity eq 'G';
	$analysis = undef if $granularity eq 'G' or $granularity eq 'D';

	my $session	   = $self->{session};
	my $factory	   = $session->Factory();

	# It is fatal for an object ID to be non-unique
	logdie ref ($self) . "->importObject: Attempt to import an attribute with duplicate ID '$LSID'"
		if exists $docIDs->{$LSID};
	$docIDs->{$LSID} = undef;

	my ($objectType,$isAttribute,$objectData,$refCols) = $self->getObjectTypeInfo($node);

	# Process references in this object.
	# If the reference was to an object already read from the document, resolve it.
	# If not, check if its already in the DB
	# If not, store the object for later resolution in a local hash.
	my %unresolvedRefs;
	my $theObject;
	my ($objField,$theRef);
	while ( ($objField,$theRef) = each %$refCols ) {
		if (exists $docIDs->{$theRef}) {
			$objectData->{$objField} = $docIDs->{$theRef};
		} elsif ($theObject = $lsid->getLocalObject ($theRef)) {
			$objectData->{$objField} = $theObject->id();
		} else {
			$objectData->{$objField} = undef;
			$unresolvedRefs{$objField} = $theRef
		}
	}
	$theObject = undef;

	# Make the object.
	if ($isAttribute) {
		$theObject = $factory->newAttribute($objectType,$parentDBID,$analysis,$objectData);
	} else {
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




sub getObjectTypeInfo ($) {
	my ($self,$node) = @_;
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
			name        => $node->getAttribute( 'Name' ),
			description => $node->getAttribute( 'Description' ),
# might need to do type conversion on CreationDate
			created     => $node->getAttribute( 'CreationDate' )
		};
		$refCols = {};

	} elsif ($objectType eq 'Feature') {
		$objectType = 'OME::Feature';
		$objectData = {
			name        => $node->getAttribute( 'Name' ),
			description => $node->getAttribute( 'Tag' ),
		};
		$refCols = {};

	} else {
		my $session	   = $self->{session};
		my $factory	   = $session->Factory();
		my $attrType = $factory->findObject("OME::AttributeType",name => $objectType)
			|| logdie ref ($self) . "->getObjectTypeInfo: Attempt to import an undefined attribute type: $objectType";
		my @attrColumns = $attrType->attribute_columns();
		my ($attrCol,$attrColName);
		foreach $attrCol (@attrColumns) {
			$attrColName = $attrCol->name();
			$objectData->{$attrColName} => $node->getAttribute($attrColName);
			if ($attrCol->data_column()->sql_type() eq 'reference') {
				$refCols->{$attrColName} = $objectData->{$attrColName};
			}
		}
		$isAttribute = 1;
	}
	return ($objectType,$isAttribute,$objectData,$refCols);
}



=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=cut


1;
