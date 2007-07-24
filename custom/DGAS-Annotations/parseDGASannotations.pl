#!/usr/bin/perl

use strict;
use Carp qw(cluck croak confess carp);
use Sys::Hostname;

use OME::SessionManager;
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ImageTasks;
use OME::Tasks::ImageManager;

my $DATASET_NAME = 'Automated Import';
my $DATASET_DESCRIPTION = 'Images imported by nightly background task';
my $PROJECT_NAME = 'ES Bank';
my $PROJECT_DESCRIPTION = 'Genetic Manipulation of Embryonic Stem Cells';

# my $session = OME::SessionManager->TTYlogin();
my $session = su_session();
my $factory = $session->Factory();

my ($filename) = @ARGV;
open( INFILE, "< $filename" ) or die "Couldn't open $filename";

my $line = <INFILE>;
chomp $line;
my @colHeaders = split( m/ *\t/o, $line );
my @data;
while( $line = <INFILE> ) {
	chomp $line;
	my @record = split( m/ *\t/o, $line );
	my %data_hash;
	foreach my $i( 0..scalar( @colHeaders )-1 ) {
		my $field = $colHeaders[ $i ];
		$data_hash{ $field } = $record[ $i ];
	}
	push( @data, \%data_hash );
}
close( INFILE );

# Known fields: 
# ImagePath	UserName	Cell Line	Task ES Cell Type	Gene Symbol	Clone_No	Probe/Antibody/Staining Type	Culture Condition	Magnification

# First pass:
# Segregate the records by user
# Identify new images to import and sort them by user.
my ($new_imgs,$user_records);
my @objects;
foreach my $record (@data) {

	# Segregate the records by user
	push ( @{ $user_records->{ $record->{ 'UserName' } }}, $record );

	# See if the image exists
	my $path = $record->{ 'ImagePath' };
	# Make a sha1 digest
	my $sha1 = `openssl sha1 '$path'`;
	$sha1 = $1 if $sha1 =~ m/^.+= +([a-fA-F0-9]*)$/;
	print "$path: $sha1\n";
	# Store the SHA1 if we need it later (to re-find newly imported images)
	$record->{'Image.SHA1'} = $sha1;
	# Find OriginalFiles with this sha1
	@objects = $factory->findAttributes("OriginalFile", {SHA1 => $sha1});
	# If there's one or more, find the associated image(s)
	my @images;
	if (scalar (@objects)) {
		my %image_id_hash;
		foreach (@objects) {
			my $img = OME::Tasks::ImageManager->getImageByOriginalFile($_);
			%image_id_hash->{$img->ID()} = $img if $img;
		}
		@images = values %image_id_hash;
	}

	if (scalar(@images) > 1) {
		print "Warning, found duplicate images for: $path\n";
		next;
	} elsif (scalar(@images) < 1) {
		print "adding $path to import list\n";
		push ( @{ $new_imgs->{ $record->{ 'UserName' } }}, $path );
	} elsif (scalar(@images) == 1) {
		print "Found $path in DB\n";
		$record->{'ImageObject'} = $images[0];
	}
}

# Import any new files as the appropriate user
my ($username,$files);
while ( ($username,$files) = each %$new_imgs) {
	# Make a sudo_session
	$session = sudo_session ($session,$username);
	die "Could not make session for $username" unless $session;

	# Make a project and dataset if necessary
	my $dataset = $factory->findObject( "OME::Dataset", {
		name  => $DATASET_NAME,
		owner => $session->User()
	});
	if (not defined $dataset) {
		print "Creating dataset $DATASET_NAME\n";
		$dataset = $factory->newObject( "OME::Dataset", {
			name        => $DATASET_NAME,
			owner       => $session->User(),
			group       => $session->User()->Group()->id(),
			description => $DATASET_DESCRIPTION,
			locked      => 'false'
		});
		my $project = $factory->findObject ('OME::Project', {
			name  => $PROJECT_NAME,
			owner => $session->User()
		});
		if (not defined $project) {
			$project = $factory->newObject( "OME::Project", {
				name        => $PROJECT_NAME,
				owner       => $session->User(),
				group       => $session->User()->Group()->id(),
				description => $PROJECT_DESCRIPTION,
			});
		}
		$factory->maybeNewObject("OME::Project::DatasetMap", {
			project_id => $project->ID(),
			dataset_id => $dataset->ID(),
		});
		
	}

	print "Importing images by $username\n";
	print join ("\n",@$files)."\n";
	# and import the files
	OME::Tasks::ImageTasks::importFiles ($dataset, $files);
	print "Finished import\n";
	$session->commitTransaction();
}




# Second pass (by user):
# All images are pre-existing or freshly imported.
# Find corresponding image objects for freshly imported images
my $records;
while ( ($username,$records) = each %$user_records ) {

# Get a global MEX for this user.  If this MEX doesn't produce anything, we'll delete it at the end.
	# Make a sudo_session
	$session = sudo_session ($session,$username);
	die "Could not make session for $username" unless $session;
	
	# Set up a global MEX
	my $global_module = $factory->findObject( 'OME::Module', name => 'Spreadsheet Global import' )
			or die "couldn't load Spreadsheet Global import module";
	my $globalMEX = OME::Tasks::ModuleExecutionManager->createMEX($global_module,'G',
		undef, undef, undef, # These don't apply to global MEXes
		$session->User(), undef             # These make the MEX public, but owned by the specified owner
		) or die "Couldn't get mex for Spreadsheet Global import";


	# Create a Magnification CategoryGroup
	my $magnificationCategoryGroup = $factory->maybeNewAttribute( 'CategoryGroup', undef, $globalMEX, {
		Name => 'Magnification',
	} );

	print "set up global MEX for $username\n";
	foreach my $record (@$records) {
		# There won't be an ImageObject record for newly imported images, so we should make one
		if (not exists $record->{'ImageObject'}) {
			my $path = $record->{ 'ImagePath' };
			my @objects = $factory->findAttributes("OriginalFile", {SHA1 => $record->{'Image.SHA1'}});
			# If there's one or more, find the associated image(s)
			print "Getting image object for $path\n";
			my @images;
			if (scalar (@objects)) {
				my %image_id_hash;
				foreach (@objects) {
					my $img = OME::Tasks::ImageManager->getImageByOriginalFile($_);
					%image_id_hash->{$img->ID()} = $img if $img;
				}
				@images = values %image_id_hash;
			}
			if (scalar(@images) > 1) {
				print "Warning, found duplicate images for: $path\n";
				next;
			} elsif (scalar(@images) < 1) {
				print "Warning, $path was not successfully imported!!!\n";
				next;
			} elsif (scalar(@images) == 1) {
				print "Found image object for $path\n";
				$record->{'ImageObject'} = $images[0];
			}
		}

		# Do Gene first (column 'Gene Symbol'), since many things link to Gene	
		# Find or make a gene
		my $gene = make_gene ($factory,$globalMEX,$record->{ 'Gene Symbol' });


		# Get a MEX for this image (and clean it out later if we don't make anything)
		my $image = $record->{'ImageObject'};

		my $image_module = $factory->findObject( 'OME::Module', name => 'Spreadsheet Image import' )
			or die "couldn't load Spreadsheet Image import module";
		my $imageMEX = OME::Tasks::ModuleExecutionManager->createMEX($image_module,'I',$image)
			or die "Couldn't get mex for Spreadsheet Image import";
		print "Got an image MEX for Image ID ".$image->ID()."\n";

		# Do Experiment and ImageExperiment based on 'Task'
		my $experiment = $factory->maybeNewAttribute( 'Experiment', undef, $globalMEX, {
			Type                => $record->{ 'Task' }
		} );
		my $expImage = $factory->maybeNewAttribute( 'ImageExperiment', $image, $imageMEX, {
			image               => $image,
			Experiment          => $experiment,
		} );
		print "Annotated Experiment type\n";

		# The 'Probe/AntiBody/Staining Type' column has different interpretations depending on
		# the Task:
		# Task = Live
		#   Nothing more to add
		# Task = In_situ
		#   Probe/AntiBody/Staining Type contains the gene used as a probe
		#   Create a Probe (Name='???'), ProbeGene, and Gene annotation for the probe
		#   Create an ExperimentProbe to bind the Probe to the Experiment
		# Task = Immunochemistry
		#   Probe/AntiBody/Staining Type contains the gene used as an antibody probe
		#   Create a Probe (Name='???'), ProbeGene, and Gene annotation for the probe
		#   Create an ExperimentProbe to bind the Probe to the Experiment
		# Task = Staining
		#   Probe/AntiBody/Staining Type contains the name of the stain
		#   Create a Probe (Name=stain) 
		#   Create an ExperimentProbe to bind the Probe to the Experiment

		my ($prGene,$probe,$probeType,$prGeneMap,$experimentProbe);
		# First make sure we have a ProbeType
		if ($record->{ 'Task' } eq 'In_situ') {
			$probeType = $factory->maybeNewAttribute( 'ProbeType', undef, $globalMEX, {
				Name                => 'anti-sense',
			} );
		} elsif ($record->{ 'Task' } eq 'Immunochemistry') {
			$probeType = $factory->maybeNewAttribute( 'ProbeType', undef, $globalMEX, {
				Name                => 'antibody',
			} );
		} elsif ($record->{ 'Task' } eq 'Staining') {
			$probeType = $factory->maybeNewAttribute( 'ProbeType', undef, $globalMEX, {
				Name                => 'direct stain',
			} );
		}

		# Make a Gene, a Probe and a ProbeGene for antibodies and in-situs
		if ( (
			$record->{ 'Task' } eq 'In_situ') or (
			$record->{ 'Task' } eq 'Immunochemistry') ) {
			# Make a Gene, Probe, and ProbeGene
			$prGene = make_gene ($factory,$globalMEX,$record->{ 'Probe/AntiBody/Staining Type' });
			$probe = find_or_make_attribute ($factory,'Probe',$globalMEX,{
				Name                => '???', # To be filled in later
				Type                => $probeType,
				'ProbeGeneList.Gene.Name' => $prGene->Name()
			});				
			$prGeneMap = $factory->maybeNewAttribute( 'ProbeGene', undef, $globalMEX, {
				Probe               => $probe,
				Gene                => $prGene,
			} );
		} elsif ($record->{ 'Task' } eq 'Staining') {
		# Make a Probe without a Gene
			$probe = $factory->maybeNewAttribute( 'Probe', undef, $globalMEX, {
				Name                => $record->{ 'Probe/AntiBody/Staining Type' },
				Type                => $probeType,
			});				
		}

		# Create an ExperimentProbe to bind the Probe to the Experiment
		if (
			($record->{ 'Task' } eq 'In_situ') or
			($record->{ 'Task' } eq 'Staining') or
			($record->{ 'Task' } eq 'Immunochemistry') ) {
			$experimentProbe = $factory->maybeNewAttribute( 'ExperimentProbe', undef, $globalMEX, {
				Probe               => $probe,
				Experiment          => $experiment,
			} );
		}

		# Do GeneticManipulation, and ImageGeneticManipulation based on 'ES Cell Type'
		my $geneticManipulation = $factory->maybeNewAttribute( 'GeneticManipulation', undef, $globalMEX, {
			Type                => $record->{ 'ES Cell Type' },
			Gene                => $gene,
		} );
		my $gmImage = $factory->maybeNewAttribute( 'ImageGeneticManipulation', $image, $imageMEX, {
			image               => $image,
			GeneticManipulation => $geneticManipulation,
		} );
		print "Annotated GeneticManipulation as '".$geneticManipulation->Type()."'\n";
		
		# Do Clone, CloneGene and ImageClone based on 'Clone_No'
		# Here, we have to search for a clone.Name/Gene.Name combination because Clone Names are not unique.
		my $clone =  find_or_make_attribute($factory,'Clone',$globalMEX,{
			Name                => $record->{ 'Clone_No' },
			'CloneGeneList.Gene.Name' => $gene->Name()
		});
		my $clGene = $factory->maybeNewAttribute( 'CloneGene', undef, $globalMEX, {
			Clone               => $clone,
			Gene                => $gene
		} );
		my $clImage = $factory->maybeNewAttribute( 'ImageClone', $image, $imageMEX, {
			image               => $image,
			Clone               => $clone,
		} );
		print "Annotated Clone\n";

		# Do CultureCondition and ImageCultureCondition based on 'Culture Condition'
		my $cultureCondition = $factory->maybeNewAttribute( 'CultureCondition', undef, $globalMEX, {
			Name                => $record->{ 'Culture Condition' }
		} );
		my $ccImage = $factory->maybeNewAttribute( 'ImageCultureCondition', $image, $imageMEX, {
			image               => $image,
			CultureCondition    => $cultureCondition,
		} );
		print "Annotated CultureCondition\n";

		# Do ExpressionState and ImageExpressionState based on GeneticManipulation and CultureCondition
		#   Overexpression:  Dox+ == Baseline, Dox- == Altered
		#   Repression:		 Dox+ == Altered, Dox- == Baseline
		# If we don't have one of these four conditions, then ExpressionState is not made
		my $expressionStateName;
		print "GeneticManipulation:'".$geneticManipulation->Type()."'\n";
		print "CultureCondition:'".$cultureCondition->Name()."'\n";
		if (
			($geneticManipulation->Type() eq 'Overexpression' and $cultureCondition->Name() eq 'Dox+') or
			($geneticManipulation->Type() eq 'Repression'     and $cultureCondition->Name() eq 'Dox-')
		) {$expressionStateName = 'Baseline'}
		elsif (
			($geneticManipulation->Type() eq 'Overexpression' and $cultureCondition->Name() eq 'Dox-') or
			($geneticManipulation->Type() eq 'Repression'     and $cultureCondition->Name() eq 'Dox+')
		) {$expressionStateName = 'Altered'};
		if ($expressionStateName) {
			my $expressionState = $factory->maybeNewAttribute( 'ExpressionState', undef, $globalMEX, {
				Name                => $expressionStateName
			} );
			my $esImage = $factory->maybeNewAttribute( 'ImageExpressionState', $image, $imageMEX, {
				image               => $image,
				ExpressionState     => $expressionState,
			} );
			print "Annotated ExpressionState\n";
		}		

		# Do CellLine and ImageCellLine based on 'Cell Line'
		my $cellLine = $factory->maybeNewAttribute( 'CellLine', undef, $globalMEX, {
			Name                => $record->{ 'Cell Line' }
		} );
		my $clImage = $factory->maybeNewAttribute( 'ImageCellLine', $image, $imageMEX, {
			image               => $image,
			CellLine            => $cellLine,
		} );
		print "Annotated CellLine\n";

		# Do Magnification as a CategryGroup
		# Find or make categories for localization's entries: ICM and TE
		my $category = $factory->maybeNewAttribute( 'Category', undef, $globalMEX, {
			CategoryGroup => $magnificationCategoryGroup,
			Name          => $record->{ 'Magnification' }.'x',
		} );
		my $magnificationCategory = $factory->maybeNewAttribute( 'Classification', undef, $imageMEX, {
			image       => $image,
			Category    => $category,
			Valid       => 1,
		});
		print "Annotated Magnification\n";


		# Delete the image MEX if nothing was added with the maybeNewAttribute calls	
		my @untyped_outputs = $imageMEX->untypedOutputs();
		if (scalar (@untyped_outputs)) {
			print "Storing Image MEX\n";
			$imageMEX->status( 'FINISHED' );
		# Uncomment to make the annotations (i.e. the image annotation MEX) public:
#			OME::Tasks::ModuleExecutionManager->chownMEX ($imageMEX, group_id => undef);
			$imageMEX->storeObject();
		} else {
			print "Deleting Image MEX\n";
			$imageMEX->deleteObject();
		}
		
		# The following makes the image public:
#		OME::Tasks::ImageManager->chownImage($image,group => undef);
		
		# A complete image annotation leaves the DB in a valid state.
		$session->commitTransaction();
	}

	# All the outputs are untyped for this MEX, so see if we have any and delete the MEX if not.
	my @untyped_outputs = $globalMEX->untypedOutputs();
	if (scalar (@untyped_outputs)) {
		print "Storing global MEX\n";
		$globalMEX->status( 'FINISHED' );
		$globalMEX->storeObject();
	} else {
		print "deleting global MEX\n";
		$globalMEX->deleteObject();
	}

	$session->commitTransaction();

}

sub make_gene {
my ($factory,$MEX,$symbol) = @_;

	# Create a template
	my $extLinkTemplate =  $factory->maybeNewAttribute('ExternalLinkTemplate',undef,$MEX, {
		Name     => "NIA Gene Index",
		Template =>  "http://lgsun.grc.nia.nih.gov/geneindex5/bin/giU.cgi?search_term=~ID~"
	});

	my $gene = $factory->maybeNewAttribute( 'Gene', undef, $MEX, {
		Name => $symbol
	} );
	# Link the gene to MGI
	my $externalLink = $factory->maybeNewAttribute( 'ExternalLink', undef, $MEX, {
		URL        => "http://lgsun.grc.nia.nih.gov/geneindex/mm8/bin/giU.cgi?search_term=$symbol" ,
		Template   => $extLinkTemplate,
		ExternalId => $symbol, 
		Description => "NIA Gene Index",
		
	});
	my $geneExternalLink = $factory->maybeNewAttribute( 'GeneExternalLink', undef, $MEX, {
		ExternalLink => $externalLink,
		Gene         => $gene
	} );
	
	return $gene;
}


sub find_or_make_attribute {
my ($factory,$type,$MEX,$criteria) = @_;

	my $object = $factory->findObject('@'.$type,$criteria);
	return $object if $object;
	# copy the criteria to a new hash, eliminating any 'dotted' criteria
	my %Fields;
	while (my ($key,$value) = each %$criteria) {
		$Fields{$key} = $value unless $key =~ /\./;
	}
	$object = $factory->newAttribute ($type, undef, $MEX, \%Fields);
	return $object;
}






sub su_session {
#	croak "You must be root to create an OME superuser session" unless $< == 0;
#	my $DSN = OME::Database::Delegate->getDefaultDelegate()->getDSN();
#	croak "You can only create an OME superuser session on a local database" if $DSN =~ /host/;
	
    my $factory = OME::Factory->new();
    croak "Couldn't create a new factory" unless $factory;
    
	my $var = $factory->findObject('OME::Configuration::Variable',
			configuration_id => 1, name => 'super_user');
    my $experimenterID = $var->value();
    
   
	croak "The super_user Expreimenter is not defined in the configuration table.\n"
		unless $experimenterID;
	my $userState = OME::SessionManager->makeOrGetUserState ($factory, experimenter_id => $experimenterID);

    print "  \\__ Getting session for user state ID=".$userState->id()."\n";
    # N.B.: In this case, we are not specifying the visible groups and users - they are all visible.
    my $session = OME::Session->instance($userState, $factory);

    croak "Could not create session from userState.  Something is probably very very wrong" unless defined $session;

    $userState->storeObject();
    $session->commitTransaction();

    return $session;
}

sub sudo_session {
	my $session = shift;
	my $username = shift;
	my $factory = $session->Factory();
#	croak "You can only call sudo_session on a super_user session"
#		unless $factory->Configuration()->super_user() == $session->experimenter_id();

	my $userState = OME::SessionManager->makeOrGetUserState ($factory, OMEName => $username);
	croak "Could not get user state for $username" unless $userState;

	# N.B.:  This disables ACL on the sudo session
	return ( OME::Session->instance($userState, $factory,undef) );
	
}
