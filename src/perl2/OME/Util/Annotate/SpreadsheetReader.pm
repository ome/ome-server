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
use English; # for $INPUT_RECORD_SEPARATOR
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
    my @ERRORoutput;
	
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
		# TSV formated spreadsheets use the tab character to separate columns.
		# But what do they use to separate rows? It depends. Most people use the
		# new-line character. Certainly that is how text tables produced with 
		# the OME WebUI and spreadsheet wizard tools are formated. Excel spreadsheets
		# exported in TSV format, on the other hand, uses the return character (\r).
		# So to support both CR and NL TSV formats we do a quick pass over the file
		# to see which character is used. Then we set the input record separator to
		# that character. The input record separator affects how end of line is parsed
		# by file I/O. TJM 25-10-2005
		open (FILE, "< $fileToParse") or die "Couldn't open $fileToParse for reading: $!";	
		my $text = <FILE>;
		$INPUT_RECORD_SEPARATOR = "\r" if $text =~ m/\r/;
		close FILE;
		
		open (FILE, "< $fileToParse") or die "Couldn't open $fileToParse for reading: $!";	
		$text = <FILE>;
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
 		 	push (@ERRORoutput, "Only one image identifier (Image.Name or Image.id) column per spreadsheet is permitted.")
 				and return @ERRORoutput if $imgCol;
 			$imgCol = $colCounter;
		} elsif ($colHead eq 'Project') {
			push (@ERRORoutput, "Only one Project column per spreadsheet is permitted.")
				and return @ERRORoutput if $projCol;
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
				
				push (@ERRORoutput, "Image with identifier $imageIdentifier doesn't exist. Skipping Row.")
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
			
			# skip 'Null' cells. i.e. cells that contain only white-space characters
			next unless defined $categoryName and $categoryName =~ m/\S+/;
			
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
		
		my %ST_data_hash;
		my %STs;
		# Extract the Semantic type data in column order. Index it for attribute
		# creation below
		foreach my $index ( sort keys %STCols ) {
			my $STSE = $columnHeadings[$index] or 
				die "ColumnHeading for column $index is undefined\n";
				
			$STSE =~ m/(\w+)\.(\w+)/;
			my $STName = $1;
			my $SEName = $2;
			
			my $ST = $factory->findObject('OME::SemanticType', { name => $STName });
			$STs{ $STName } = $ST;
			my $granularity = $ST->granularity;
			my $SEValue = shift(@seVals);
			
			# skip 'Null' cells. i.e. cells that contain only white-space characters
			next unless defined $SEValue and $SEValue =~ m/\S+/;
			
			$ST_data_hash{ $STName }->{ $SEName } = $SEValue;

			# There's an Image ST but there's no image to annotate!
			if ( $granularity eq 'I' and not exists $image->{ Image }) {
				push(@ERRORoutput, "You must specify an image for $STSE because it's an Image SemanticType.  Did not annotate.");
				next;
			}
		}
		# Create attributes from the indexed, semantically typed data.
		foreach my $ST ( values %STs ) {
			my $STName = $ST->name;
			my $data_hash = $ST_data_hash{ $STName };
			my $granularity = $ST->granularity;
			
			# Granularity is Image, so do image annotation
			if ($granularity eq 'I') {
				$factory->newAttribute ($STName, $image->{ Image }, $global_mex, $data_hash)
					or die "could not make new (I) $STName\n\t".
						join( "\n\t", map( $_." => ".$data_hash->{$_}, keys %$data_hash ) );
				$image->{"ST:".$STName} = $data_hash;
			}
			
			# Granularity is Global, so do global
			elsif ( $granularity eq 'G' ) {
				$factory->newAttribute ($STName, undef, $global_mex, $data_hash)
					or die "could not make new (G) $STName\n\t".
						join( "\n\t", map( $_." => ".$data_hash->{$_}, keys %$data_hash ) );
				$newGlobalSTSE->{$STName} = $data_hash;
			}
		}
		
		# Process Datasets
		my @datasets; # @datasets is at this scope so it can be passed to projects
		foreach my $index (sort keys %DatasetCols) {
			# $columnHeadings[$index] is 'Dataset'
			my $datasetManager = new OME::Tasks::DatasetManager;
			my $datasetName = shift (@datasetNames);
			
			# skip 'Null' cells. i.e. cells that contain only white-space characters
			next unless defined $datasetName and $datasetName =~ m/\S+/;
			
			my $dataset = $factory->findObject ('OME::Dataset', { name => $datasetName });			
			if (not $dataset) {
				$dataset = $datasetManager->newDataset ($datasetName, "Created on $timestr from".
					" file $fileToParse by the bulk annotation spreadsheet importer.") or
				die "could not create new dataset $datasetName";
				push (@newDatasets, $dataset);
			}
			
			$datasetManager->addToDataset($dataset, $image->{ Image }) if $imageIdentifier;
			# record the new image classification for output purposes
			$image->{'Dataset'} = $dataset;
			push (@datasets, $dataset); # pass it to projects
		}
		
		# Process Projects
		if (defined $projCol) {
			my $projectManager = new OME::Tasks::ProjectManager;

			# skip 'Null' cells. i.e. cells that contain only white-space characters
			next unless defined $projName and $projName =~ m/\S+/;
			
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
	$INPUT_RECORD_SEPARATOR = ''; # probably don't need to do this, but let's be safe
	$session->commitTransaction();
	
	# package up outputs and return
	# some one-else will be create some human understandable output
	my $Results;
	$Results->{ERRORoutput}   = \@ERRORoutput;
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
	my @ERRORoutput    = @{$Results->{ERRORoutput}};
	my @newProjs       = @{$Results->{newProjs}};
	my @newDatasets    = @{$Results->{newDatasets}};
	my $newProjDataset = $Results->{newProjDatast};
	my @newCGs         = @{$Results->{newCGs}};
	my $newCategories  = $Results->{newCategories};
	my $newGlobalSTSE  = $Results->{newGlobalSTSE};
	my $images         = $Results->{images};

	my $output = "";
	if (scalar @ERRORoutput) {
		foreach (@ERRORoutput) {
			$output .= "$_\n";
		}
	}	
	if (scalar @newProjs) {
		$output .= "New Projects:\n";
		$output .= "    '".$_->name()."'\n" foreach (sort {$a->name() cmp $b->name()} @newProjs);
		$output .= "\n"; # spacing
	}
	if (scalar (@newDatasets)) {
		$output .= "New Datasets:\n";
		$output .= "    '".$_->name()."'\n" foreach (sort {$a->name() cmp $b->name()} @newDatasets);
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
		$output .= "    '".$_->Name()."'\n" foreach (sort {$a->Name() cmp $b->Name()} @newCGs);
		$output .= "\n"; # spacing
	}
	if (scalar keys %$newCategories) {
		$output .= "New Categories:\n";
		foreach my $CGName (sort keys %$newCategories) {
			$output .= "    '".$CGName."'\n";
			foreach my $categoryName (sort keys %{$newCategories->{$CGName}}) {
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
					$output .= "        \\_ '".$key."' : '".$image->{$key}->Name()."'\n"
						if $CG;
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