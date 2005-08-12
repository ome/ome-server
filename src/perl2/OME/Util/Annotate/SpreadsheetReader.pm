# OME/Web/SpreadsheetImporter/SpreadsheetImporter.pm

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
#
# Written by:    Arpun Nagaraja <arpun@mit.edu>
#
#-------------------------------------------------------------------------------

package OME::Web::SpreadsheetImporter::SpreadsheetImporter;

=pod

=head1 NAME

OME::Web::SpreadsheetImporter - Imports annotations into OME.

=head1 DESCRIPTION

A package to import CG and/or ST annotations from an Excel Spreadsheet or tab-delimited text 
file into OME.

=head1 METHODS

=cut

use strict;
use Carp 'cluck';
use vars qw($VERSION);
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;
use Spreadsheet::ParseExcel;

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
    
	my $type = TAB; # Default type is tab
	my $maxRow;
	my $maxCol;
    my @columnHeadings;
    
    # Stuff for category group info
    my %CGCols;
    my %CategoryGroups;
    my %categories;
    
    # Stuff for semantic type info
    my %STCols;
    my %semanticElements;
    my %images;
    
	my @globalAnnotations;
	my @imageAnnotations;
	my $output;
    
    # Change type to EXCEL if it's actually excel.
	my $excel = new Spreadsheet::ParseExcel;
	my $workbook = $excel->Parse( $fileToParse );
	$type = EXCEL if $workbook;
	
	# first sheet from the workbook
	my $sheet = $workbook->{ Worksheet }[0];
	$maxRow = $sheet->{ MaxRow };
	$maxCol = $sheet->{ MaxCol };
	
	# Get the appropriate modules and mexes
	my $global_module = $factory->findObject( 'OME::Module', name => 'Spreadsheet Global import' )
			or die "couldn't load Spreadsheet Global import module";
	my $global_mex = OME::Tasks::ModuleExecutionManager->createMEX($global_module,'G' )
		or die "Couldn't get mex for Spreadsheet Global import";
	my @objs;
	
	# Get the column headings - different process for excel and tab
	if ( $type eq EXCEL ) {
		for (my $col = 0; $col <= $maxCol; $col++) {
				 my $cell = $sheet->{Cells}[0][$col];
				 my $contents = $cell->Value if ($cell);
				 push ( @columnHeadings, $contents ) if $contents;
		}
	}
	else {
		open (FILE, "< $fileToParse") or die "Couldn't open $fileToParse for reading: $!<br>";		
		my $text = <FILE>;
		chomp($text);
		
		@columnHeadings = split (/\t/,$text);
		$maxCol = scalar(@columnHeadings);
		
		1 while <FILE>;
		$maxRow = $. - 1;
	}
	close FILE;
	
	
	# Figure out which cols are CG and which are ST	
	my $colCounter = 0;
	foreach my $colHead (@columnHeadings) {
		my $STName;
		my $SEName;
		if ($colHead =~ m/(\w+)\.(\w+)/) {
			$STName = $1;
			$SEName = $2;
		}

		# First col could be Image.Name or Image.id, or it might not be
 		if ($colHead eq 'Image.Name' or $colHead eq 'Image.id') {
			# ignore it for now (it's neither ST nor CG)
		} elsif ($STName && $SEName) {
 			$STCols{ $colCounter } = 1;
 		} else { 
			$CGCols{ $colCounter } = 1; 
		}
		
 		$colCounter++;
	}
	
	# If there's a category group that isn't in the database, push it onto
	# @globalAnnotations
	foreach my $index (keys(%CGCols)) {
		my $CGName = $columnHeadings[$index];
		my $CG = $factory->findObject ('@CategoryGroup', { Name => $CGName });
		$CategoryGroups{ $CGName } = $CG if $CG;
		next if $CG;
		push (@globalAnnotations,('CategoryGroup',{
			Name => $CGName,
			Description => undef
			}));
	}
	
 	# If there are CG's that need to be created, create them		
	$output .= "New Category Groups:<br>" if (scalar (@globalAnnotations));
	for (my $i=0; $i < scalar(@globalAnnotations); $i+=2) {
		$output .= "Name =".$globalAnnotations[$i+1]->{Name}."<br>";
		my $obj = $factory->newAttribute( $globalAnnotations[$i], undef,
										   $global_mex, $globalAnnotations[$i+1]);
		$CategoryGroups{$obj->Name()} = $obj;
	}
	@globalAnnotations = (); # Clear the array
	$session->commitTransaction();

	open (FILE, "< $fileToParse");
	<FILE>; # Don't need the first line (column headings) anymore
	
	# Process the file row by row.
	$output .= "<br>New Attributes:<br>";
	for (my $row = 1; $row <= $maxRow; $row++) {
		my @cats;
		my @seVals;
		my @imgNames;
		my $imageIdentifier;
		
		# Excel
		if ($type eq EXCEL) {
			for (my $col = 0; $col <= $maxCol; $col++) {
					my $cell = $sheet->{Cells}[$row][$col];
					my $content = $cell->Value if $cell;
					
					# If there's a column named Image.Name or Image.id, push that entry
					# onto @imgNames - we'll need it to find the image that
					# needs to be annotated
					push ( @imgNames, $content ) if ($columnHeadings[$col] eq 'Image.Name' ||
													 $columnHeadings[$col] eq 'Image.id');
					push ( @cats, $content ) if ( $CGCols{ $col } );
					push (@seVals, $content) if ( $STCols{ $col } );
			}
		}
		
		# Tab
		else {
			my $text = <FILE>;
			chomp($text);
			my @entries = split(/\t/, $text);
			my $col = 0;
			foreach my $entry (@entries) {
				push ( @imgNames, $entry ) if ($columnHeadings[$col] eq 'Image.Name' ||
											   $columnHeadings[$col] eq 'Image.id');
				push ( @cats, $entry ) if ( $CGCols{ $col } );
				push (@seVals, $entry) if ( $STCols{ $col } );
				$col++;
			}
		}
		
		# Get the image from the database if it exists and the user wants it
		$imageIdentifier = shift ( @imgNames );
		my $image;
		if ($imageIdentifier) {
			my @objects = $factory->findObjects ( 'OME::Image', { name => $imageIdentifier } )
									if ($columnHeadings[0] eq 'Image.Name');
			@objects = $factory->findObjects ( 'OME::Image', { id => $imageIdentifier } )
									if ($columnHeadings[0] eq 'Image.id');
			die "There are two images in the database with that name $imageIdentifier.
Try using IDs instead, to ensure uniqueness\n" if (scalar(@objects) > 1);
			$images { $imageIdentifier } = {
				Image => $objects[0],
			} unless exists $images{$imageIdentifier};
			$image = $images{ $imageIdentifier };
		}
		
		# Process the CG Columns in order
		my @cgkeys = sort ( keys %CGCols );
		foreach my $index ( @cgkeys ) {
			my $CGName = $columnHeadings[$index];
			die "CGName is undefined\n" unless $CGName;
			my $categoryName = shift(@cats);
			my $category;
			my $CG = $CategoryGroups{$CGName};
			next unless $categoryName;
			
			$category = $factory->findObject ('@Category',{ Name => $categoryName, CategoryGroup => $CG });
			# If the category doesn't exist in this CG, put it onto globalAnnotations for creation
			push ( @globalAnnotations, ('Category',{
				Name => $categoryName,
				CategoryGroup => $CG,
				Description => undef
				})) unless ($category or exists $categories{ "$CGName:$categoryName" });
			
			$categories{"$CGName:$categoryName"} = $category;
			$image->{ $CGName } = $categoryName;
		}
		
		# Process the ST Columns in order
		my @stkeys = sort ( keys %STCols );
		foreach my $index ( @stkeys ) {
			my $STSE = $columnHeadings[$index];
			die "Column heading is undefined\n" unless $STSE;
			my $SEValue = shift(@seVals);

			$STSE =~ m/(\w+)\.(\w+)/;
			my $STName = $1;
			my $SEName = $2;

			my $attribute = $factory->findObject('@'.$STName, { $SEName => $SEValue });
			
			# This is strictly to get the granularity of the ST
			my $ST = $factory->findObject('OME::SemanticType', { name => $STName });
			my $granularity = $ST->granularity;
			
			# There's an Image ST but there's no image to annotate!
			if ( $granularity eq 'I' && not($image->{ Image })) {
				$output .= "You must specify an image for $STSE because it's an
							Image SemanticType.  Did not annotate.<br>";
				next;
			}
			
			# Granularity is Image, so do image annotation
			elsif ( exists($image->{ Image }) && $granularity eq 'I') {
				unless ($attribute or exists $semanticElements{ "$STName:$SEName:$SEValue" }) {
					push ( @imageAnnotations, ($STName,{
						$SEName => $SEValue
						}));
					$output .= "$STSE -> $SEValue<br>";
				}
			}
			
			# Granularity is Global, so do global
			elsif ( $granularity eq 'G' ) {
				unless ($attribute or exists $semanticElements{ "$STName:$SEName:$SEValue" }) {
					push ( @globalAnnotations, ($STName,{
						$SEName => $SEValue
						}));
					$output .= "$STSE -> $SEValue<br>";
				}
			}
			
			$semanticElements{"$STName:$SEName:$SEValue"} = $SEValue;
		}
		
		# Annotate for this particular image, if there were ST image annotations to be done
		for (my $i = 0; $i < scalar(@imageAnnotations); $i+=2) {
			$factory->newAttribute( $imageAnnotations[$i], $image->{ Image },
										   $global_mex, $imageAnnotations[$i+1]);
		}
		$session->commitTransaction();
	}
	close FILE;
	
	# If there are Categories or ST global annotations that need to be added to the
	# database, add them.
	$output .= "<br>New Categories:<br>" if scalar(@globalAnnotations);
	for (my $i = 0; $i < scalar(@globalAnnotations); $i+=2) {
		my $object = $factory->newAttribute( $globalAnnotations[$i], undef,
										   $global_mex, $globalAnnotations[$i+1]);
		my $type = ref($object);
		if ($type eq 'OME::SemanticType::__Category') {
			my $catName = $object->Name();
			$categories{$object->CategoryGroup()->Name().':'.$catName} = $object;
			$output .= "Name = $catName<br>";
		}
	}
	$session->commitTransaction();
	@globalAnnotations = ();
	
	# Apply the CategoryGroup annotations to the images
	my @lostImages;
	if (scalar(keys %images) > 0) {
		$output .= "<br>-- CategoryGroup Annotation Output --<br>";
		foreach my $imageIdentifier (keys %images) {
			my $image = $images{ $imageIdentifier };
			my $imageName = $imageIdentifier;
			$imageName = $image->{Image}->name if $image->{Image};
			$output .= "<br>Classifying $imageName<br>";
			
			$output .= "$imageName does not exist in the DB<br>" and push (@lostImages,$imageIdentifier) and next unless $image->{ Image };
			foreach my $CGName (@columnHeadings) {
				next if ($CGName eq 'Image.Name' || $CGName eq 'Image.id');
				my $categoryName = $image->{ $CGName };
				next unless $categoryName;
				my $category = $categories{"$CGName:$categoryName"};
				next unless $category;
				OME::Tasks::CategoryManager->classifyImage($image->{Image}, $category);
				$output .= "&nbsp&nbsp&nbsp&nbsp $CGName -> $categoryName<br>";
			}
		}
		$session->commitTransaction();
		
		$output .= "<br>Images in description file missing from DB:<br>" if scalar (@lostImages > 0);
		$output .= join ("<br>",@lostImages)."<br>";
	}
	
	return $output;
}

=head1 Author

Arpun Nagaraja <arpun@mit.edu>

=cut

1;