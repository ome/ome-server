#/OME/Util/Annotate/SpreadsheetReader.pm

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
# Written by:     Tom Macura <tmacura@nih.gov> (Category/CategoryGroup, Project/Dataset/Image, HTML rendering)
#				  Josiah Johnston, Harry Hochheiser (Semantic Types)
#
# 			based on Arpun Nagaraja's code
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

	my $message = OME::Util::Annotate::SpreadsheetReader->processFile( $fileToParse );

$fileToParse is a tab-delimited text file or Excel Spreadsheet in a specified format.
The format can be found at http://www.openmicroscopy.org/custom-annotations/spreadsheet_importer.html

=cut

sub processFile {
 	my ($self, $fileToParse,$noop) = @_;
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
	my ($maxRow,$maxCol,$columnHeadings) = 
		$self->getColumnHeadings($type,$sheet,$fileToParse);
	
	
	# Figure out which columns are image identifiers
	# Dataset, Project, Category Group (CG) or Semantic Type (ST)
	my ($imgCol,$projCol,$DatasetCols,$STCols,$CGCols) =
	    $self->classifyColumnHeadings($columnHeadings,\@ERRORoutput);

	# Use the TimeStamp to make sane Object descriptions
	my $timestamp = time;
	my $timestr = localtime $timestamp; 
	
	
	# $newCGs:  If a category group referenced in the column headers isn't already
	# in the database make a new category group with that name 

	# $CGCols gets filled with CategoryGroups. Used later when making new categories in order to be
	# able to associate categories with CGs
	my ($newCGs) = $self->getCategoryGroups($columnHeadings,$CGCols,$fileToParse,$global_mex,
	                             $timestr,$noop);
	                             
	# $STCols gets filled with SEs. Used later when making new attributes
	$self->getSTs($columnHeadings,$STCols,$fileToParse);

	my $file;
	if ($type ne EXCEL) {
		open (FILE, "< $fileToParse");
		<FILE>; # skip the first line (column headings)
		$file = \*FILE;
	}
	
	# Process the file row by row.
	my $newCategories;
	my $newGlobalSTSE;
	my @newDatasets;
	my @newProjs;
	my $newProjDataset;
	my %images;
	
	# Image.Name or Image.id etc.
	my $imageIdentifier_type = $$columnHeadings[$imgCol];

	for (my $row = 1; $row <= $maxRow; $row++) {
		my $imageIdentifier;
		my $projName;
		my @datasetNames;
		my @cats;
		my @seVals;

		# Separate out the row from image,project,datasets
		# category groups and STs
		($imageIdentifier,$projName) = 
		    $self->parseRow($type,$row,$imgCol,$projCol,\@datasetNames,
				    \@cats,\@seVals,$DatasetCols,$CGCols,$STCols,
				    $maxCol,$sheet,$file);

		# Get the image from the database if it exists and the user wants it
		my $image;
		if ($imageIdentifier) {
		    $image =
			$self->loadImage($imageIdentifier,$imageIdentifier_type, \%images,
					 \@ERRORoutput);
		}

		# Process Category Groups
		$self->processCategoryGroups($image,$CGCols,\@cats,
					     $newCategories,$global_mex,
					     $fileToParse,$timestr,\@ERRORoutput,$noop);
		# Process Semantic Types
		$newGlobalSTSE = $self->processSTs($image,$STCols,\@seVals,
				  $newGlobalSTSE,$global_mex,\@ERRORoutput);

		# Process Datasets
		my @datasets; # @datasets is at this scope so it can be passed to projects
		$self->processDatasets(\@datasets,$DatasetCols,\@datasetNames,
				       $image,\@newDatasets,
				       $fileToParse,$timestr);

		# Process Projects
		$self->processProjects($projCol,$projName,\@datasets,\@newProjs,$newProjDataset,$fileToParse,$timestr);
	
		$session->commitTransaction() unless $noop;
	}
	close FILE unless $type eq EXCEL;
	$INPUT_RECORD_SEPARATOR = ''; # probably don't need to do
				# this, but let's be safe
	$global_mex->status('FINISHED');
	if (scalar @ERRORoutput) {
	    my $errorMsg = $self->getErrorMessage(\@ERRORoutput);
	    $global_mex->error_message($errorMsg); 
	}
	$global_mex->storeObject();
	if ($noop) {
		$session->rollbackTransaction();
	} else {
		$session->commitTransaction();
	}
	
	# package up outputs and return
	# some one-else will be create some human understandable output
	my $Results;
	$Results->{global_mex}    = $global_mex;
	$Results->{ERRORoutput}   = \@ERRORoutput;
	$Results->{newProjs}      = \@newProjs;
	$Results->{newDatasets}   = \@newDatasets;
	$Results->{newProjDatast} = $newProjDataset;
	$Results->{newCGs}        = $newCGs;
	$Results->{newCategories} = $newCategories;
	$Results->{newGlobalSTSE} = $newGlobalSTSE;
	$Results->{images}        = \%images;
	return $Results;
}

# get the column headings, etc.
sub getColumnHeadings {
	my $self = shift;
	my ($type,$sheet,$fileToParse) = @_;
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
	return ($maxRow,$maxCol,\@columnHeadings);

}

sub classifyColumnHeadings {
    my $self = shift;
    my ($columnHeadings,$ERRORoutput) = @_;

    my $colCounter = 0;
    my $imgCol;
    my $projCol;

    my %DatasetCols;
    my %STCols;
    my %CGCols;

    
    foreach my $colHead (@$columnHeadings) {
		if ($colHead eq "" or $colHead =~ m/#.*/) {
			# skip columns without a heading or use the # character to comment-things out
		} elsif ($colHead eq 'Image.FilePath' or
			$colHead eq 'Image.OriginalFile' or # Image.OriginalFile is deprecated, use Image.FilePath
			$colHead eq 'Image.FileSHA1' or
			$colHead eq 'Image.Name' or
			$colHead eq 'Image.id') {
				push (@$ERRORoutput, "Only one image identifier (Image.FilePath, Image.FileSHA1, Image.Name or Image.id) column per spreadsheet is permitted.")
					and return @$ERRORoutput if $imgCol;
			$imgCol = $colCounter;
		} elsif ($colHead eq 'Project') {
			push (@$ERRORoutput, "Only one Project column per spreadsheet is permitted.")
			and return @$ERRORoutput if $projCol;
			$projCol = $colCounter;
		} elsif ($colHead eq 'Dataset') {
			$DatasetCols{ $colCounter } = 1;
		} elsif ($colHead =~ m/^(\w+)\.(\w+)$/) {
			#	my $attribute = $factory->findObject('@' $1, { SEName => $2 });
			my $attribute = 1;
			$STCols{ $colCounter } = 1;
		} else { 
			$CGCols{ $colCounter } = 1; 
		}	
		$colCounter++;
    }
    
    die "This spreadsheet is lacking an image identifier column. The spreadsheet needs \n".
    	"either a Image.FilePath, Image.FileSHA1, Image.Name, or Image.id column." if (not defined $imgCol);
    	 
    return ($imgCol,$projCol,\%DatasetCols,\%STCols,\%CGCols);
}

sub getCategoryGroups {
    my $self= shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($columnHeadings,$CGCols,$fileToParse,$global_mex,$timestr,$noop) = @_;

    my @newCGs;

    foreach my $index (keys(%$CGCols)) {
		my $CGName = $$columnHeadings[$index];
		$CGName =~ s/^['"]([^'"]+)['"]$/$1/; # remove quotes if they are present.
		$$columnHeadings[$index] = $CGName;
		my $CG = $factory->findObject ('@CategoryGroup', { Name => $CGName });
		if (not $CG) {
			$CG = $factory->newAttribute( 'CategoryGroup', undef, $global_mex, {
			Name => $CGName,
			Description => "Created on $timestr from file $fileToParse by the bulk annotation spreadsheet importer."
						  }) or die "could not make new CG attribute $CGName";
			push (@newCGs, $CG); # record the creation of new CG to generate HTML/command-line output later
		}
		$CGCols->{$index} = $CG;
    }
    $session->commitTransaction() unless $noop;
    return (\@newCGs);
}

sub getSTs {
    my $self= shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($columnHeadings,$STCols,$fileToParse) = @_;

    foreach my $index (keys(%$STCols)) {
    
    my $columnHeader = $$columnHeadings[$index] or 
			die "ColumnHeading for column $index is undefined\n"; 
		$columnHeader =~ m/(\w+)\.(\w+)/
			or die "Could not parse column header: $columnHeader.";
		my $STName = $1; 
		my $SEName = $2; 
		my $ST = $factory->findObject('OME::SemanticType', { name => $STName })
			or die "Could not find a Semantic Type named $STName";

		my $SE = $factory->findObject('OME::SemanticType::Element', {name=> $SEName, semantic_type=> $ST} )
			or die "Could not find a Semantic Element named $SEName under the Semantic Type $STName";
			
		$STCols->{$index} = $SE;
    }
}

sub parseRow {
    my $self=shift;
    my ($type,$row,$imgCol,$projCol,$datasetNames,$cats,$seVals,
	$DatasetCols,$CGCols,$STCols,$maxCol,$sheet,$file) = @_;
    my $imageIdentifier;
    my $projName;

    if ($type eq EXCEL) {
		for (my $col = 0; $col <= $maxCol; $col++) {
			my $cell = $sheet->{Cells}[$row][$col];
			my $content = $cell->Value if $cell;
			
			$imageIdentifier = $content if ( defined $imgCol and $imgCol == $col );
			$projName = $content        if ( defined $projCol and $projCol == $col);
			push ( @$datasetNames, $content ) if ( $$DatasetCols{ $col } );
			push ( @$cats, $content )         if ( $$CGCols{ $col } );
			push ( @$seVals, $content )       if ( $$STCols{ $col } );
		}
    } else { # TAB
		my $text = <$file>;
		chomp($text);
		my @entries = split(/\t/, $text);
		
		my $col = 0;
		foreach my $entry (@entries) {
			$imageIdentifier = $entry if ( defined $imgCol and $imgCol == $col );
			$projName = $entry        if ( defined $projCol and $projCol == $col);
			push ( @$datasetNames, $entry ) if ( $$DatasetCols { $col } );
			push ( @$cats, $entry )         if ( $$CGCols{ $col } );
			push ( @$seVals, $entry )       if ( $$STCols{ $col } );
			$col++;
		}
    }
    return ($imageIdentifier,$projName);
}
    
sub loadImage {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($imageIdentifier,$imageIdentifier_type,$images,$ERRORoutput) = @_;

    if ( not $$images{$imageIdentifier} ) {
		my @objects;
		my @originalFiles;
		
		if ($imageIdentifier_type eq 'Image.Name') {
			@objects = $factory->findObjects 
				( 'OME::Image', { name => "$imageIdentifier" } );
		} elsif ($imageIdentifier_type eq 'Image.id') {
			@objects = $factory->findObjects
				( 'OME::Image', { id => "$imageIdentifier" } );
		# Image.OriginalFile is deprecated.  Please use Image.FilePath
		} elsif ($imageIdentifier_type eq 'Image.OriginalFile') {
			@originalFiles = $session->Factory->
				  findAttributes("OriginalFile", {Path => "$imageIdentifier"});
		} elsif ($imageIdentifier_type eq 'Image.FilePath') {
			@originalFiles = $session->Factory->
				  findAttributes("OriginalFile", {Path => "$imageIdentifier"});
		} elsif ($imageIdentifier_type eq 'Image.FileSHA1') {
			@originalFiles = $session->Factory->
				  findAttributes("OriginalFile", {SHA1 => "$imageIdentifier"});
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

		
		die "There are two images in the database with that name
		$imageIdentifier. ". 
		"Try using IDs instead to ensure uniqueness.\n" 
		if (scalar(@objects) > 1);
		
		push (@$ERRORoutput, "Image with identifier $imageIdentifier doesn't exist. Skipping Row.")
			and next if (scalar @objects != 1);
		
		$$images{$imageIdentifier} = {Image => $objects[0]};
    }
    return $$images{$imageIdentifier};
}

# Use @cats, along with $CGcols to make new classifications for $image
sub processCategoryGroups {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($image,$CGCols,$cats,$newCategories,$global_mex,$fileToParse,
    	$timestr,$ERRORoutput,$noop) = @_; 


    foreach my $index (sort {$a <=> $b} keys %$CGCols) { 
    	my $CG = $CGCols->{$index} or
			die "CategoryGroup for column $index is undefined \n";
		my $CGName = $CG->Name();
		my $categoryName = shift(@$cats);
		
		# skip 'Null' cells. i.e. cells that contain only white-space
		# characters
		next unless defined $categoryName and $categoryName =~ m/\S+/;
	
		my $category = $factory->findObject ('@Category', { Name =>
						$categoryName, CategoryGroup => $CG });
		if (not $category) { 
			$category = $factory->newAttribute ('Category', undef, 
				$global_mex, { Name => $categoryName, 
						   CategoryGroup => $CG, 
						   Description => "Created by bulk annotation spreadsheet importer from file $fileToParse on $timestr."  }) 		or die "could not make new Category $categoryName"; 
			
			$newCategories->{$CGName}->{$categoryName} = 1; 
			   # record the creation of new category to generate
		   # HTML/command-line output later
		}
		
		if (exists $image->{ Image }) {
			OME::Tasks::CategoryManager->classifyImage($image->{Image}, $category) unless $noop;
		} else {
			push(@$ERRORoutput, "You must specify an image for Category ".$CG->Name().".".$category->Name()." so did not annotate."); 
			next;
		}

		# record the new image classification for later
		$image->{ $CGName } = $category; 
    } 
}


sub processSTs {
    my $self = shift;
    my $session = $self->Session();	
    my $factory = $session->Factory();
    
    my ($image,$STCols,$seVals,$newGlobalSTSE,$global_mex,$ERRORoutput) = @_;

    my %ST_data_hash; 
    my %STs; 
    # Extract the Semantic type data in column order. Index it for attribute 
    # creation below  
    foreach my $index (sort {$a <=> $b} keys %$STCols)  { 

		my $SE = $STCols->{$index};
		my $ST = $SE->semantic_type();
		my $SEName = $SE->name();
		my $STName = $ST->name();
		my $granularity = $ST->granularity; 
		my $col = $SE->data_column();

		$STs{ $STName } = $ST;
		my $SEValue = shift(@$seVals); 
		if ($col->sql_type() eq 'reference') {
			# if it's a reference, then find what it refers to.
			eval {
				my $refType = $col->reference_semantic_type();
				# lookup value where the "name" is $SEValue.
				my $refObj = $factory->findObject($refType,
								  {Name=>$SEValue });
				if (defined $refObj) {
					#use it instead.
					$SEValue = $refObj;
				}
				# here we must do something where we try to 
				# create a new instance of type $refType where name is
				# $SEVAlue. 
				# if it works, set $sevalue to that new object.
				else {
					my $targ = undef;
		
					$targ = $image->{Image} if
					($refType->granularity() eq 'I') ;
					my $obj = $factory->maybeNewAttribute($refType,$targ,$global_mex,{Name=>$SEValue});
					if (defined $obj) {
						$SEValue = $obj;
					}
				}
			};
			# print $@ if $@; #uncomment for debugging info
		}
	
		# skip 'Null' cells. i.e. cells that contain only white-space 
		#characters  
		next unless defined $SEValue and $SEValue =~ m/\S+/; 
		$ST_data_hash{ $STName }->{ $SEName } = $SEValue; 
	
		# There's an Image ST but there's no image to annotate!  
		if ( $granularity eq 'I' and not exists $image->{ Image }) { 
			push(@$ERRORoutput, "You must specify an image for $STName.$SEName ($SEValue) because it's an image granularity SemanticType so did not annotate."); 
			next; 
		} 
    } 

    # Create attributes from the indexed, semantically typed data.  
    foreach my $ST ( values %STs ) { 
		my $STName = $ST->name; 
		my $data_hash = $ST_data_hash{ $STName }; 
		my $granularity = $ST->granularity; 
	
#debug	print "Image ".$image->{ Image }->name()."\n";
#		print "ST: ".$STName."\n";
#		print "values: ".join( "\n\t", map( $_." => ".$data_hash->{$_}, 
#						 keys %$data_hash ) )."\n\n\n";

		# Granularity is Image, so do image annotation  
		if ($granularity eq 'I' and exists $image->{ Image }) {
			$data_hash->{image_id} = $image->{ Image }->ID();
			my $attr = $factory->maybeNewAttribute ($STName, $image->{ Image }, 
						$global_mex, $data_hash) or 
				die "could not make new (I) $STName\n\t". 
					  join( "\n\t", map( $_." => ".$data_hash->{$_}, 
						 keys %$data_hash ) );
	
			$image->{"ST:".$STName} = $attr; 
		} elsif ($granularity eq 'I' and exists $image->{ Image }) {
		
			# can't make image annotation without specifying the image
			
		# Granularity is Global, so do global  
		} elsif ( $granularity eq 'G' ) { 
			my $attr = $factory->maybeNewAttribute ($STName, undef, $global_mex, $data_hash) or
				die "could not make new (G) $STName\n\t". 
					join( "\n\t", map( $_." => ".$data_hash->{$_}, 
					   keys %$data_hash ) ); 
			push( @{ $newGlobalSTSE->{$STName} },  $attr );
		} 
    }
    return $newGlobalSTSE;
}

sub processDatasets{ 
    my $self = shift;
    my $session = $self->Session();	
    my $factory = $session->Factory();

    my ($datasets,$DatasetCols,$datasetNames,$image,$newDatasets,$fileToParse,$timestr) = @_;

    foreach my $index (sort {$a <=> $b} keys %$DatasetCols) {
		# $columnHeadings[$index] is 'Dataset'
		my $datasetManager = new OME::Tasks::DatasetManager;
		my $datasetName = shift (@$datasetNames);
				
		# skip 'Null' cells. i.e. cells that contain only white-space characters
		next unless defined $datasetName and $datasetName =~ m/\S+/;
				
		my $dataset = $factory->findObject ('OME::Dataset', { name => $datasetName });			
		if (not $dataset) {
			$dataset = $datasetManager->newDataset ($datasetName, "Created on $timestr from".
								" file $fileToParse by the bulk annotation spreadsheet importer.") or
								die "could not create new dataset $datasetName";
			push (@$newDatasets, $dataset);
		}
				
		$datasetManager->addToDataset($dataset, $image->{ Image }) if exists $image->{ Image };
		# record the new image classification for output purposes
		$image->{'Dataset'} = $dataset;
		push (@$datasets, $dataset); # pass it to projects
    }
}

sub processProjects {
    my $self = shift;
    my $session = $self->Session();	
    my $factory = $session->Factory();
    my ($projCol,$projName,$datasets,$newProjs,$newProjDataset,$fileToParse,$timestr) =  @_;

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
			push (@$newProjs, $project);
		}
		
		$projectManager->addDatasets($datasets, $project->project_id());
		
		# record which datasets are associated with which projects
		foreach (@$datasets) {
			$newProjDataset->{$projName}->{$_->name()} =1;
		}
    }
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
	    $output .= $self->getErrorMessage(\@ERRORoutput);
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
			foreach my $attr ( @{ $newGlobalSTSE->{$STName} } ) {
				$output .= "		$STName: id: ".$attr->id()." ";
				my $data_hash = $attr->getDataHash();
				foreach my $seName ( sort keys %$data_hash )  {
					$output .= ", $seName: ".$data_hash->{ $seName };
				}
				$output .= "\n";
			}
		}
		$output .= "\n"; # spacing
	}
	if (scalar keys %$images) {
		foreach my $imageIdentifier (sort keys %$images) {
			my $image = $images->{$imageIdentifier};
			$output .= "Spreadsheet Identifier: '". $imageIdentifier."'\n";
			$output .= "	Image ID: ".$image->{"Image"}->ID()."\n";
			delete $image->{"Image"};

			# specialised Rendering for Dataset association
			if (exists $image->{"Dataset"}) {
				$output .= "	Dataset: '".$image->{"Dataset"}->name()."'\n";
				delete $image->{"Dataset"};
			}
			
			# render attributes
			if (scalar keys %$image) {
				my $attributesMsg .= "	Attributes:\n";
				my $haveAttributes = 0;
				foreach my $key (sort keys %$image) {
					if( $key =~ m/^ST:(.*)$/ ) {
						$haveAttributes = 1;
						$attributesMsg .= "		\\_ '".$1.": id:".$image->{$key}->id()."'\n";
					}
				}
				$output .= $attributesMsg if $haveAttributes;
			}
			
			# render Category Group/Cateogrizations
			if (scalar keys %$image) {
				my $classificationMsg .= "	Classifications:\n";
				my $haveClassifications = 0;
				foreach my $key (sort keys %$image) {
					unless( $key =~ m/^ST:(.*)$/ ) {
						$haveClassifications = 1;
						$classificationMsg .= "		\\_ '".$key."' : '".$image->{$key}->Name()."'\n";
					}
				}
				$output .= $classificationMsg if $haveClassifications;
			}
			$output .= "\n"; # spacing
		}
	}

	return $output;
}

sub getErrorMessage {
    my ($self,$ERRORoutput) = @_;
    my $output ="";
    foreach (@$ERRORoutput) {
	$output .="$_\n";
    }
    return $output;
}

=head1 Author

Arpun Nagaraja <arpun@mit.edu>
Tom Macura <tmacura@nih.gov>

=cut

1;
