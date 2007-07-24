#!/usr/bin/perl

use strict;
use OME::SessionManager;
use OME::Tasks::ModuleExecutionManager;


my $session = OME::SessionManager->TTYlogin();
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
# Image.Name	Clone ID	Gene Symbol	Gene Description	TF	Log Intensity	Fold	Oligo ID	Stage	Type

# Set up a global MEX & an image MEX
my $global_module = $factory->findObject( 'OME::Module', name => 'Spreadsheet Global import' )
		or die "couldn't load Spreadsheet Global import module";
my $globalMEX = OME::Tasks::ModuleExecutionManager->createMEX($global_module,'G' )
	or die "Couldn't get mex for Spreadsheet Global import";


# Create a template
my $extLinkTemplate =  $factory->maybeNewAttribute('ExternalLinkTemplate',undef,$globalMEX, {
	Name     => "NIA Gene Index",
	Template =>  "http://lgsun.grc.nia.nih.gov/geneindex5/bin/giU.cgi?search_term=~ID~"
});

# Create the embryo stages
my $stage;
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => 'Unfertilized Egg',
	Description => 'Unfertilized Egg'
});
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => '1-Cell',
	Description => 'Single Cell'
});
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => '2-Cell',
	Description => 'Pair of  Cells'
});
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => '4-Cell',
	Description => 'Quartet of  Cells'
});
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => '8-Cell',
	Description => 'Octet of  Cells'
});
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => 'Morula',
	Description => 'Morula'
});
$stage =  $factory->maybeNewAttribute('EmbryoStage',undef,$globalMEX, {
	Name        => 'Blastocyst',
	Description => 'Blastocyst'
});

# If localization data is available, prepare to categorize based on it.
my ($localizationCategoryGroup, $ICM_Category, $TE_Category);
if( exists( $data[0]->{ 'ICM' } ) ) {
	# Find or make a category group for localization
	$localizationCategoryGroup = $factory->maybeNewAttribute( 'CategoryGroup', undef, $globalMEX, {
		Name => 'Localization',
	} );
	# Find or make categories for localization's entries: ICM and TE
	$ICM_Category = $factory->maybeNewAttribute( 'Category', undef, $globalMEX, {
		CategoryGroup => $localizationCategoryGroup,
		Name          => 'ICM',
	} );
	$TE_Category = $factory->maybeNewAttribute( 'Category', undef, $globalMEX, {
		CategoryGroup => $localizationCategoryGroup,
		Name          => 'TE',
	} );
}

my @fieldsToGoInDescription = sort( grep( $_ ne 'Image.Name', @colHeaders ) );
foreach my $record ( @data ) {
	# Find or make a probe
	my $probeType = $factory->maybeNewAttribute( 'ProbeType', Name => $record->{ 'Type' } );
	my $probeName = $record->{ 'Clone ID' }.( ( $record->{ 'Type' } =~ m/Sense/o ) ? '-SE' : '-AS'  );
	my $probe = $factory->maybeNewAttribute( 'Probe', undef, $globalMEX, {
		Name => $probeName,
		Type => $probeType
	} );
	
	# Find or make a gene
	my $gene = $factory->maybeNewAttribute( 'Gene', undef, $globalMEX, {
		Name => $record->{ 'Gene Symbol' }
	} );
	# Link the gene to MGI
	my $externalLink = $factory->maybeNewAttribute( 'ExternalLink', undef, $globalMEX, {
		URL        => 'http://lgsun.grc.nia.nih.gov/geneindex/mm8/bin/giU.cgi?search_term='.$record->{ 'Gene Symbol' } ,
		Template   => $extLinkTemplate,
		ExternalId => $record->{ 'Gene Symbol' }, 
		Description => "NIA Gene Index",
		
	});
	my $geneExternalLink = $factory->maybeNewAttribute( 'GeneExternalLink', undef, $globalMEX, {
		ExternalLink => $externalLink,
		Gene         => $gene
	} );
	# Link the gene to the probe
	my $probeGene = $factory->maybeNewAttribute( 'ProbeGene', undef, $globalMEX, {
		Probe => $probe,
		Gene  => $gene,
	});
	
	# Find or make the appropriate embryo stage
	my $embryoStage = $factory->maybeNewAttribute( 'EmbryoStage', undef, $globalMEX, {
		Name => $record->{ 'Stage' },
	});
	
	# Load the image, update its description, link it to the probe & embryostage,
	# and set its publication status to true
	my $imageSpec;
	my @originalFiles;
	my @objects;
	if (exists $record->{ 'Image.id' }) {
		$imageSpec = $record->{ 'Image.id' };
		@objects = $factory->findObjects ( 'OME::Image', { id => $imageSpec } );
	} elsif (exists $record->{ 'Image.FileSHA1' }) {
		$imageSpec = $record->{ 'Image.FileSHA1' };
		@originalFiles = $factory->findAttributes("OriginalFile", {SHA1 => $imageSpec});
	} elsif (exists $record->{ 'Image.FilePath' }) {
		$imageSpec = $record->{ 'Image.FilePath' };
		@originalFiles = $factory->findAttributes("OriginalFile", {Path => $imageSpec});
	} elsif (exists $record->{ 'Image.Name' }) {
		$imageSpec = $record->{ 'Image.Name' };
		@objects = $factory->findObjects 
			( 'OME::Image', { name => $imageSpec } );
	}
	
	# Get the unique Image IDs associated with the OriginalFIles
	if (scalar (@originalFiles)) {
		my %image_id_hash;
		foreach (@originalFiles) {
			my $img = OME::Tasks::ImageManager->getImageByOriginalFile($_);
			%image_id_hash->{$img->ID()} = $img if $img;
		}
		@objects = values %image_id_hash;
	}

	if (scalar(@objects) > 1) {
		print STDERR "Warning, found duplicate images for: $imageSpec\n";
		next;
	}
	if (scalar(@objects) < 1) {
		print STDERR "Warning, could not find image named: $imageSpec\n";
		next;
	}
	my $image = $objects[0];
	print STDERR "Found image: '$imageSpec'\n";

	
	my $imageProbe = $factory->maybeNewAttribute( 'ImageProbe', undef, $globalMEX, {
		image => $image,
		Probe => $probe,
	});
	my $imageEmbryoStage = $factory->maybeNewAttribute( 'ImageEmbryoStage', undef, $globalMEX, {
		image       => $image,
		EmbryoStage => $embryoStage,
	});
	my $imageEmbryoStage = $factory->maybeNewAttribute( 'PublicationStatus', undef, $globalMEX, {
		image       => $image,
		Publishable => 1,
	});
	if( exists( $record->{ 'ICM' } ) ) {
		my $category;
		if( $record->{ 'ICM' } =~ m/yes/io ) {
			$category = $ICM_Category;
		} else {
			$category = $TE_Category;
		}
		my $localizationCategory = $factory->maybeNewAttribute( 'Classification', undef, $globalMEX, {
			image       => $image,
			Category    => $category,
			Valid       => 1,
		});
	}
	my $description = '';
	$description .= $_.": ".$record->{ $_ }."\n"
		foreach( @fieldsToGoInDescription );
	$image->description( $description );
	$image->storeObject();

}

$globalMEX->status( 'FINISHED' );
$globalMEX->storeObject();
$session->commitTransaction();
