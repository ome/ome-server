package OME::Tasks::HierarchyImport;

use strict;
use XML::LibXML;
use OME::Tasks::AttributeImport;

sub new {
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my %params = @_;
	my $debug = $params{debug} || 0;
	
	print STDERR $proto . "->new called with parameters:\n\t" . join( "\n\t", map { $_."=>".$params{$_} } keys %params ) ."\n" 
		if $debug > 1;
	
	my @requiredParams = ('session','semanticTypes','semanticColumns');
	
	foreach (@requiredParams) {
		die ref ($class) . "->new called without required parameter '$_'"
			unless exists $params{$_}
	}

	my $self = {
		session         => $params{session},
		debug           => $params{debug} || 0,
		semanticTypes   => $params{semanticTypes},
		semanticColumns => $params{semanticColumns},
		_parser         => $params{_parser},
	};
	
	if (!defined $self->{_parser}) {
		my $parser = XML::LibXML->new();
		die "Cannot create XML parser"
		  unless defined $parser;
		
		$parser->validation(exists $params{ValidateXML}?
							$params{ValidateXML}: 0);
		$self->{_parser} = $parser;
	}

	$self->{references} = {};

	# this is for development only! to be replaced w/ id's from db after linkage happens!
	$self->{idSeq} = 0;

	bless($self,$class);
	print STDERR ref ($self) . "->new returning successfully\n" 
		if $debug > 1;
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
	my $debug   = $self->{debug};
	
	###########################################################################
	#
	# Since all commits should wait till the end, I'm storing reference info
	# in this here hash. It's keyed by [element name].[element xml id] so keys
	# are guaranteed to be unique. It's valued by DBID. 
	# Data is imported from top down, which means we when it's time to resolve
	# a reference, if it's not in this hash, then something's wrong. We can 
	# work out something more clever when we start working with document groups
	# and partial imports.
	#
	my %references;
	#
	###########################################################################

	my $attributeImporter = OME::Tasks::AttributeImport->
      new(session         => $self->{session},
          _parser         => $self->{_parser},
          semanticTypes   => $self->{semanticTypes},
          semanticColumns => $self->{semanticColumns},
          debug           => $self->{debug},
          references      => \%references
          );


	###########################################################################
	# process global custom attributes
	#
	$attributeImporter->processDOM($root, 'G');
	#
	###########################################################################


	###########################################################################
	#
	# process projects
	#
	print STDERR "Processing Projects\n"
		if $debug;
	foreach my $projectXML ( @{ $root->getElementsByLocalName('Project') } ) {

		my $groupXML = $projectXML->getElementsByLocalName('GroupRef')->[0];
		my $group = $references{ 'Group'.$groupXML->getAttribute('GroupID') };
		my $experimenterXML = $projectXML->getElementsByLocalName('ExperimenterRef')->[0];
		my $owner = $references{ 'Experimenter'.$groupXML->getAttribute('ExperimenterID') };
		
		my $projectData = {
			name        => $projectXML->getAttribute( 'Name' ),
			description => $projectXML->getAttribute( 'Description' ),
			owner_id    => $owner,
			group_id    => $group
		};
		
		# Actually make a new project here.

		# Record project ID.
		my $projectID = $attributeImporter->{idSeq}++;
		$references{ 'Project'.$projectXML->getAttribute('ID') } = $projectID;
		
		# show what we've got
		print STDERR "Project: ".$projectID."\n\t".join( "\n\t",
			map( $_." => ".$projectData->{$_}, keys %$projectData ) )."\n"
			if $debug;
	}
	#
	###########################################################################
	

	###########################################################################
	#
	# process datasets
	#
	print STDERR "Processing Datasets\n"
		if $debug;
	foreach my $datasetXML ( @{ $root->getElementsByLocalName('Dataset') } ) {

		my $groupXML = $datasetXML->getElementsByLocalName('GroupRef')->[0];
		my $group = $references{ 'Group'.$groupXML->getAttribute('GroupID') };
		my $experimenterXML = $datasetXML->getElementsByLocalName('ExperimenterRef')->[0];
		my $owner = $references{ 'Experimenter'.$groupXML->getAttribute('ExperimenterID') };
		
		my $datasetData = {
			name        => $datasetXML->getAttribute( 'Name' ),
			description => $datasetXML->getAttribute( 'Description' ),
			owner_id    => $owner,
			group_id    => $group,
# locked may need to be cast into boolean
			locked      => $datasetXML->getAttribute( 'Locked' )
		};
		
		# Actually make a new dataset here.

		# Record dataset ID.
		my $datasetID = $attributeImporter->{idSeq}++;
		$references{ 'Dataset'.$datasetXML->getAttribute('ID') } = $datasetID;

		# link this dataset to projects it belongs to
		my $projectRefsXML = $datasetXML->getElementsByLocalName( 'ProjectRef' );
		my @projectIDs = map( $references{ 'Project'. $_->getAttribute('ProjectID')}, @$projectRefsXML );
	
		
		# show what we've got
		print STDERR "Dataset: ".$datasetID."\n\t".join( "\n\t",
			map( $_." => ".$datasetData->{$_}, keys %$datasetData ) )."\n"
			if $debug;
		print STDERR "\tBelongs to projects: ".join( ',', @projectIDs ). "\n"
			if $debug;

		# process custom attributes in the dataset
			$attributeImporter->processDOM($datasetXML, 'D', $references{ 'Dataset'.$datasetXML->getAttribute('ID') });
	}
	#
	###########################################################################


	###########################################################################
	#
	# process images
	#
	print STDERR "Processing Images\n"
		if $debug;
	foreach my $imageXML ( @{ $root->getElementsByLocalName('Image') } ) {

		my $imageData = {
			name        => $imageXML->getAttribute( 'Name' ),
			description => $imageXML->getAttribute( 'Description' ),
			image_guid  => $imageXML->getAttribute( 'ID' ),
# might need to do type conversion on CreationDate
			created     => $imageXML->getAttribute( 'CreationDate' )
		};
		
		# Actually make a new image here.

		# Record image ID.
		my $imageID = $attributeImporter->{idSeq}++;
		$references{ 'Image'.$imageXML->getAttribute('ID') } = $imageID;

		# link this image to datasets it belongs to
		my $datasetRefsXML = $imageXML->getElementsByLocalName( 'DatasetRef' );
		my @datasetIDs = map( $references{ 'Dataset'. $_->getAttribute('DatasetID')}, @$datasetRefsXML );
	
		
		# show what we've got
		print STDERR "Image: ".$imageID."\n\t".join( "\n\t",
			map( $_." => ".$imageData->{$_}, keys %$imageData ) )."\n"
			if $debug;
		print STDERR "\tBelongs to datasets: ".join( ',', @datasetIDs ). "\n"
			if $debug;

		# process custom attributes in the image
			$attributeImporter->processDOM($imageXML, 'I', $references{ 'Image'.$imageXML->getAttribute('ID') });
		
		# process features
		foreach my $featureXML (@ {$imageXML->getElementsByLocalName('Feature') }) {
			$self->processFeature( $featureXML );
		}
	}
	#
	###########################################################################

	
} 
#
# END sub processDOM
#
###############################################################################

sub processFeature {
	my $self = shift;
	
	my $debug = $self->{debug};
	print STDERR "Pretending to Process a feature.\n"
			if $debug;
	# do feature processing. also process custom attributes for that feature
	# recursively call this function for sub features.
}


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=cut


1;
