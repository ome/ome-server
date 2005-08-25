# OME/Util/Annotate/SpreadsheetReader.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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
# Written by:    Arpun Nagaraja <arpun@mit.edu>
#
#                Tom Macura <tmacura@nih.gov>
#                - Code tidying. Refactored outputing so there is command line and HTML
#                  output. Wrote HTML output. ++ descriptions to all produced objects
#                  ++ support for Projects and Dataset annotations. ++ error checking. 
#                  ++ the ability to "comment-out" columns by prepending the pound
#                  character '#'
#
#-------------------------------------------------------------------------------

package OME::Util::Annotate::SpreadsheetReader;

=pod

=head1 NAME

OME::Util::Annotate::SpreadsheetReader - Imports annotations into OME.

=head1 DESCRIPTION

A package to import CG and/or ST annotations from an Excel Spreadsheet or tab-delimited text 
file into OME.

=head1 METHODS

=cut

use strict;
use Carp 'cluck';
use vars qw($VERSION);
use Term::ANSIColor qw(:constants);
use Spreadsheet::ParseExcel;

use OME::Session;
use OME::SessionManager;

use OME::Tasks::ImageManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;
use OME::Tasks::DatasetManager;
use OME::Tasks::ProjectManager;

use base qw(OME::Web);

# Type of file
use constant EXCEL => "excel";
use constant TAB => "tab";

=head2 processFile

	my $message = OME::Web::SpreadsheetImporter->processFile( $fileToParse );

$fileToParse is a tab-delimited text file or Excel Spreadsheet in a specified format.
The format can be found at http://www.openmicroscopy.org/custom-annotations/spreadsheet_importer.html

=cut

sub processFile {
 	my ($self, $fileToParse) = @_;
 	my $session= $self->Session();
    my $factory = $session->Factory();
    my $ERRORoutput;
	
	# Get the appropriate modules and mexes
	my $global_module = $factory->findObject( 'OME::Module', name => 'Spreadsheet Global import' )
			or die "couldn't load Spreadsheet Global import module";
	my $global_mex = OME::Tasks::ModuleExecutionManager->createMEX($global_module,'G' )
		or die "Couldn't get mex for Spreadsheet Global import";

    # examine file to determine if it is an EXCEL document
	my $excel = new Spreadsheet::ParseExcel;
	my $workbook = $excel->Parse( $fileToParse );
	my $type = TAB; # Default type is tab
	$type = EXCEL if $workbook;
	my $sheet = $workbook->{ Worksheet }[0] if ($type eq EXCEL); # first sheet from the workbook
	
	# Get the column headings - different process for excel and tab
	my @columnHeadings;
	my $maxRow;
	my $maxCol;
	
	if ( $type eq EXCEL ) {
		$maxRow = $sheet->{ MaxRow };
		$maxCol = $sheet->{ MaxCol };
	
		for (my $col = 0; $col <= $maxCol; $col++) {
			 my $cell = $sheet->{Cells}[0][$col];
			 my $contents = $cell->Value if ($cell);
			 push ( @columnHeadings, $contents ) if $contents;
		}
	} else {
		open (FILE, "< $fileToParse") or die "Couldn't open $fileToParse for reading: $!";		
		my $text = <FILE>;
		chomp($text);
		
		@columnHeadings = split (/\t/,$text);
		$maxCol = scalar(@columnHeadings);
		
		1 while <FILE>;
		$maxRow = $. - 1;
		close FILE;
	}
	
	# Figure out which columns are image identifiers (Image.Name or Image.id),
	# Dataset, Project, Category Group (CG) or Semantic Type (ST)
	my $imgCol;
    my $projCol;
	my %DatasetCols;
    my %STCols;
	my %CGCols;

	my $colCounter = 0;
	foreach my $colHead (@columnHeadings) {
		if ($colHead eq "" or $colHead =~ m/#.*/) {
			# skip columns without a heading or use the # character to comment-things out
 		} elsif ($colHead eq 'Image.Name' or $colHead eq 'Image.id') {
 			$ERRORoutput .= "Only one image identifier (Image.Name or Image.id) column per spreadsheet is permitted."
 				and return $ERRORoutput if $imgCol;
 			$imgCol = $colCounter;
		} elsif ($colHead eq 'Project') {
			$ERRORoutput .= "Only one Project column per spreadsheet is permitted." 
				and return $ERRORoutput if $projCol;
			$projCol = $colCounter;
		} elsif ($colHead eq 'Dataset') {
			$DatasetCols{ $colCounter } = 1;
		} elsif ($colHead =~ m/(\w+)\.(\w+)/) {
		#	my $attribute = $factory->findObject('@' $1, { SEName => $2 });
			my $attribute = 1;
#			$ERRORoutput .= "The ST $STName is undefined or does not contain SE $SE\n" and return
#					unless $attribute;
 			$STCols{ $colCounter } = 1;
 		} else { 
			$CGCols{ $colCounter } = 1; 
		}	
 		$colCounter++;
	}
	# Use the TimeStamp to make sane Object descriptions
	my $timestamp = time;
	my $timestr = localtime $timestamp; 
	
	# If a category group referenced in the column headers isn't already in the database
	# make a new category group with that name 
	my @newCGs;
	
	my %CategoryGroups; # need this later when making new categories in order to be able to associate categories with CGs
	foreach my $index (keys(%CGCols)) {
		my $CGName = $columnHeadings[$index];
		my $CG = $factory->findObject ('@CategoryGroup', { Name => $CGName });
		if (not $CG) {
			$CG = $factory->newAttribute( 'CategoryGroup', undef, $global_mex, {
					Name => $CGName,
					Description => "Created on $timestr from file $fileToParse by the bulk annotation spreadsheet importer."
				  }) or die "could not make new CG attribute $CGName";
			push (@newCGs, $CG); # record the creation of new CG to generate HTML/command-line output later
		}
		$CategoryGroups{ $CGName } = $CG;
	}
	$session->commitTransaction();

	if ($type ne EXCEL) {
		open (FILE, "< $fileToParse");
		<FILE>; # skip the first line (column headings)
	}
	
	# Process the file row by row.
	my $newCategories;
	my $newGlobalSTSE;
	my @newDatasets;
	my @newProjs;
	my $newProjDataset;
	my %images;
	
	for (my $row = 1; $row <= $maxRow; $row++) {
		my $imageIdentifier;
		my $projName;
		my @datasetNames;
		my @cats;
		my @seVals;
		
		if ($type eq EXCEL) {
			for (my $col = 0; $col <= $maxCol; $col++) {
				my $cell = $sheet->{Cells}[$row][$col];
				my $content = $cell->Value if $cell;
				
				$imageIdentifier = $content if ( defined $imgCol and $imgCol == $col );
				$projName = $content        if ( defined $projCol and $projCol == $col);
				push ( @datasetNames, $content ) if ( $DatasetCols { $col } );
				push ( @cats, $content )         if ( $CGCols{ $col } );
				push ( @seVals, $content )       if ( $STCols{ $col } );
			}
		} else { # TAB
			my $text = <FILE>;
			chomp($text);
			my @entries = split(/\t/, $text);
			
			my $col = 0;
			foreach my $entry (@entries) {
				$imageIdentifier = $entry if ( defined $imgCol and $imgCol == $col );
				$projName = $entry        if ( defined $projCol and $projCol == $col);
				push ( @datasetNames, $entry ) if ( $DatasetCols { $col } );
				push ( @cats, $entry )         if ( $CGCols{ $col } );
				push ( @seVals, $entry )       if ( $STCols{ $col } );
				$col++;
			}
		}

		# Get the image from the database if it exists and the user wants it
		my $image;
		if ($imageIdentifier) {
			if ( not $images{$imageIdentifier} ) {
				my @objects;
				@objects = $factory->findObjects ( 'OME::Image', { name => "$imageIdentifier" } )
										if ($columnHeadings[$imgCol] eq 'Image.Name');
				@objects = $factory->findObjects ( 'OME::Image', { id => "$imageIdentifier" } )
										if ($columnHeadings[$imgCol] eq 'Image.id');

				die "There are two images in the database with that name $imageIdentifier. ".
					"Try using IDs instead to ensure uniqueness.\n" if (scalar(@objects) > 1);
				
				$ERRORoutput .= "Image with identifier $imageIdentifier doesn't exist. Skipping Row."
					and next if (scalar @objects != 1);

				$images{$imageIdentifier} = {Image => $objects[0]};
			}
			$image = $images{$imageIdentifier};
		}

		# Process the CG Columns in order to create new Categories, as appropriate
		foreach my $index (sort keys %CGCols) {
			my $CGName = $columnHeadings[$index] or
				die "ColumnHeading for column $index is undefined\n";
			my $categoryName = shift(@cats);
			my $CG = $CategoryGroups{$CGName};
			
			my $category = $factory->findObject ('@Category', { Name => $categoryName, CategoryGroup => $CG });
			if (not $category) {
				$category = $factory->newAttribute ('Category', undef, $global_mex, {
								Name => $categoryName,
								CategoryGroup => $CG,
								Description => "Created by bulk annotation spreadsheet importer from file $fileToParse on $timestr."
							}) or die "could not make new Category $categoryName";

				$newCategories->{$CGName}->{$categoryName} = 1; # record the creation of new category to generate HTML/command-line output later
			}
			OME::Tasks::CategoryManager->classifyImage($image->{Image}, $category);
			
			# record the new image classification for later
			$image->{ $CGName } = $category;
		}
		
		# Process the ST Columns in order
		foreach my $index ( sort keys %STCols ) {
			my $STSE = $columnHeadings[$index] or 
				die "ColumnHeading for column $index is undefined\n";
				
			$STSE =~ m/(\w+)\.(\w+)/;
			my $STName = $1;
			my $SEName = $2;
			
			my $granularity = $factory->findObject('OME::SemanticType', { name => $STName })->granularity;
			my $SEValue = shift(@seVals);

			# There's an Image ST but there's no image to annotate!
			if ( $granularity eq 'I' and not exists $image->{ Image }) {
				$ERRORoutput .= "You must specify an image for $STSE because it's an
							Image SemanticType.  Did not annotate.";
				next;
			}
			
			# Granularity is Image, so do image annotation
			elsif ($granularity eq 'I') {
				$factory->newAttribute ($STName, $image->{ Image }, $global_mex, {
										$SEName => $SEValue
										}) or die "could not make new (I) $STName:$SEName -> $SEValue";
				$image->{"ST:".$STName}->{$SEName} = $SEValue;
			}
			
			# Granularity is Global, so do global
			elsif ( $granularity eq 'G' ) {
				$factory->newAttribute ($STName, undef, $global_mex, {
										$SEName => $SEValue
										}) or die "could not make new (G) $STName:$SEName -> $SEValue";
				$newGlobalSTSE->{$STName}->{$SEName} = $SEValue;
			}
		}
		
		# Process Datasets
		my @datasets; # @datasets is at this scope so it can be passed to projects
		foreach my $index (sort keys %DatasetCols) {
			# $columnHeadings[$index] is 'Dataset'
			my $datasetManager = new OME::Tasks::DatasetManager;
			my $datasetName = shift (@datasetNames);
			
			my $dataset = $factory->findObject ('OME::Dataset', { name => $datasetName });			
			if (not $dataset) {
				$dataset = $datasetManager->newDataset ($datasetName, "Created on $timestr from".
					" file $fileToParse by the bulk annotation spreadsheet importer.") or
				die "could not create new dataset $datasetName";
				push (@newDatasets, $dataset);
			}
			
			$datasetManager->addToDataset($dataset, $image->{ Image });
			# record the new image classification for output purposes
			$image->{'Dataset'} = $dataset;
			push (@datasets, $dataset); # pass it to projects
		}
		
		# Process Projects
		if ($projCol) {
			my $projectManager = new OME::Tasks::ProjectManager;
			my $project = $factory->findObject ('OME::Project', { name => $projName });
			if (not $project) {
				$projectManager->create( {
					name => "$projName",
					description => "Created on $timestr from file $fileToParse by the bulk annotation spreadsheet importer.",
				}) or die "could not create new project $projName";
				
				# projectManger create() returns 1 or 0. useless
				$project = $factory->findObject ('OME::Project', { name => $projName });
				push (@newProjs, $project);
			}
			
			$projectManager->addDatasets(\@datasets, $project->project_id());
			
			# record which datasets are associated with which projects
			foreach (@datasets) {
				$newProjDataset->{$projName}->{$_->name()} =1;
			}
		}
		$session->commitTransaction();
	}
	close FILE unless $type eq EXCEL;
	$session->commitTransaction();
	
	# package up outputs and return
	# some one-else will be create some human understandable output
	my $Results;
	$Results->{ERRORoutput}   = $ERRORoutput;
	$Results->{newProjs}      = \@newProjs;
	$Results->{newDatasets}   = \@newDatasets;
	$Results->{newProjDatast} = $newProjDataset;
	$Results->{newCGs}        = \@newCGs;
	$Results->{newCategories} = $newCategories;
	$Results->{newGlobalSTSE} = $newGlobalSTSE;
	$Results->{images}        = \%images;
	return $Results;
}

# prints a "Results Hash" in a command-line readable format.
sub printSpreadsheetAnnotationResultsCL {
	my ($self, $Results) = @_;
	my $session = $self->Session();	
	my $factory = $session->Factory();
	
	die "second input to printResultsHTML is expected to be a hash"	if (ref $Results ne "HASH");	
	my $ERRORoutput    = $Results->{ERRORoutput};
	my @newProjs       = @{$Results->{newProjs}};
	my @newDatasets    = @{$Results->{newDatasets}};
	my $newProjDataset = $Results->{newProjDatast};
	my @newCGs         = @{$Results->{newCGs}};
	my $newCategories  = $Results->{newCategories};
	my $newGlobalSTSE  = $Results->{newGlobalSTSE};
	my $images         = $Results->{images};

	my $output = "";
	if (defined $ERRORoutput and $ERRORoutput ne '') {
		$output .= "$ERRORoutput\n\n";
	}	
	if (scalar @newProjs) {
		$output .= "New Projects:\n";
		$output .= "    '".$_->name()."'\n" foreach (sort @newProjs);
		$output .= "\n"; # spacing
	}
	if (scalar (@newDatasets)) {
		$output .= "New Datasets:\n";
		$output .= "    '".$_->name()."'\n" foreach (sort @newDatasets);
		$output .= "\n"; # spacing
	}
	if (scalar keys %$newProjDataset) {
		$output .= "New Dataset/Project Associations: \n";
		foreach my $pn (sort keys %$newProjDataset) {
			$output .= "    '".$pn."'\n";
			foreach my $dn (sort keys %{$newProjDataset->{$pn}}) {
				$output .= "        \\_ '".$dn."'\n";
			}
		}
		$output .= "\n"; # spacing
	}
	if (scalar @newCGs) {
		$output .= "New Category Groups:\n";
		$output .= "    '".$_->Name()."'\n" foreach (sort @newCGs);
		$output .= "\n"; # spacing
	}
	if (scalar keys %$newCategories) {
		$output .= "New Categories:\n";
		foreach my $CGName (sort keys %$newCategories) {
			my $CG = $factory->findObject ('@CategoryGroup', { Name => $CGName });
			$output .= "    '".$CGName."'\n";
			foreach my $categoryName (sort keys %{$newCategories->{$CGName}}) {
				my $category = $factory->findObject ('@Category', { Name => $categoryName, CategoryGroup => $CG });
				$output .= "        \\_'".$categoryName."'\n";
			}
		}
		$output .= "\n"; # spacing
	}
	if (scalar keys %$newGlobalSTSE) {
		$output .= "New Global Attributes:\n";
		foreach my $STName (sort keys %$newGlobalSTSE) {
			foreach my $SEName (sort keys %{$newGlobalSTSE->{$STName}}) {
				$output .= "&nbsp&nbsp $STName:$SEName -> `".$newGlobalSTSE->{$STName}->{$SEName}."`\n";
			}
		}
		$output .= "\n"; # spacing
	}
	if (scalar keys %$images) {
		foreach my $imageIdentifier (sort keys %$images) {
			my $image = $images->{$imageIdentifier};
			$output .= "Spreadsheet Identifier: '". $imageIdentifier."'\n";
			$output .= "    Image ID: ".$image->{"Image"}->ID()."\n";
			delete $image->{"Image"};

			# specialised Rendering for Dataset association
			if (exists $image->{"Dataset"}) {
				$output .= "    Dataset: '".$image->{"Dataset"}->name()."'\n";
				delete $image->{"Dataset"};
			}
			
			# generic rendering e.g. for Category Group/Cateogrizations
			if (scalar keys %$image) {
				$output .= "    Classifications:\n";
				foreach my $key (sort keys %$image) {
					my $CG = $factory->findObject ('@CategoryGroup', { Name => $key });
					$output .= "        \\_ '".$key."' : '".$image->{$key}->Name()."'\n";
				}
			}
			$output .= "\n"; # spacing
		}
	}

	return $output;
}

=head1 Author

Arpun Nagaraja <arpun@mit.edu>
Tom Macura <tmacura@nih.gov>

=cut

1;