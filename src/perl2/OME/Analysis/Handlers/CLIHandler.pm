# OME/Analysis/CLIHandler.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Analysis::CLIHandler;

use strict;
our $VERSION = '1.0';

use IO::File;

use OME::Analysis::Handler;
use XML::LibXML;
use base qw(OME::Analysis::Handler);

use fields qw(_outputHandle);

sub new {
    my ($proto,$location,$session,$program,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$program,$node);

    bless $self,$class;
    return $self;
}


sub precalculateDataset {
    my ($self) = @_;

	my $program                  = $self->{_program};
	my $executionInstructions    = $program->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'precalculateDataset' ) {
		my @formalInputs          = $program->inputs();
		my %inputs                = map { $_->name() => $self->getDatasetInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub precalculateImage {
    my ($self) = @_;

	my $program                  = $self->{_program};
	my $executionInstructions    = $program->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'precalculateImage' ) {
		my @formalInputs          = $program->inputs();
		my %inputs                = map { $_->name() => $self->getImageInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub calculateFeature {
    my ($self) = @_;

	my $program                  = $self->{_program};
	my $executionInstructions    = $program->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'calculateFeature' ) {
		my @formalInputs          = $program->inputs();
		my %inputs                = map { $_->name() => $self->getFeatureInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}


sub postcalculateImage {
    my ($self) = @_;

	my $program                  = $self->{_program};
	my $executionInstructions    = $program->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'postcalculateImage' ) {
		my @formalInputs          = $program->inputs();
		my %inputs                = map { $_->name() => $self->getImageInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub postcalculateDataset {
    my ($self) = @_;

	my $program                  = $self->{_program};
	my $executionInstructions    = $program->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'postcalculateDataset' ) {
		my @formalInputs          = $program->inputs();
		my %inputs                = map { $_->name() => $self->getDatasetInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub _execute {
	my $self   = shift;
	my $i      = shift;
	my %inputs = %{ $i };

    my $image  = $self->getCurrentImage();
    my $dims   = $image->Dimensions();

	my $program               = $self->{_program};
	my %outputs;
	my $executionInstructions = $program->execution_instructions();
	my $debug                 = 0;
	my $session               = $self->Session();
	my $imagePix;
	my %dims = ( 'x'   => $image->Dimensions()->size_x(),
				 'y'   => $image->Dimensions()->size_y(),
				 'z'   => $image->Dimensions()->size_z(),
				 'w'   => $image->Dimensions()->num_waves(),
				 't'   => $image->Dimensions()->num_times(),
				 'BytesPerPixel' => $image->Dimensions()->bits_per_pixel()/8,
				 'BitsPerPixel' => $image->Dimensions()->bits_per_pixel(),
				 );
	
	my $parser = XML::LibXML->new();
	my $tree = $parser->parse_string( $executionInstructions );
	my $root = $tree->getDocumentElement();
	
	
	#####################################################################
	#
	# What needs to be done to generalize plane interating from just XY to YZ, XZ, etc.
	#
	#	change contents of planeIndexTypes
	#	change method of plane generation
	#
	#
	#####################################################################
	
	
	#####################################################################
	#
	# set up Plane Indexes
	#
	# Notes:
	# 	the import process normalized planeID's - it gives every plane a unique ID and updates all references
	# 	autoIterators is hash reference. hash is keyed by planeID. values are references to hashes keyed by theZ, theW, & theT. these values are references to scalars.
	# 		The reason for this is each plane needs a set of plane indexes {theZ, theW, theT}, but sometimes a component of these will overlap.
	# 		For example, the cross correlation program needs two planes synced on theZ and theT with differing constant wavenumbers.
	# 		Since theZ theW and theT are references, it is a simple matter to sync any of these.
	#
	my $planeIndexes;
	my @planes = $root->getElementsByTagName( "XYPlane" );
	if(scalar(@planes) > 0 ) {
		my $imagePix = $image->GetPix()
			or die "Could not load image->Pix, image_ID = ".$image->id();
	}
	# planeIndexTypes is hard coded now because we only deal w/ XY planes. 
	my @planeIndexTypes   = ( 'theZ', 'theT', 'theW' );
	
		#####################################################################
		#
		# First run through planes to generate plane indexes
		#
		print STDERR "\n" if $debug eq 2;
		print STDERR "----------------------------------------------\n" if $debug eq 2;
		print STDERR "First plane run - generating indexes\n" if $debug eq 2;
		print STDERR "----------------------------------------------\n" if $debug eq 2;
		foreach my $plane(@planes) {
			my $planeID   = $plane->getAttribute( "XYPlaneID" );
			my %indexSize = ( theZ => $dims{'z'}, theT => $dims{'t'}, theW => $dims{'w'}, theX => $dims{'x'}, theY => $dims{'y'} );
			print STDERR "Processing plane ".$planeID."\n" if $debug eq 2;
			
			#################################################################
			#
			#	Process indexes with non referential methods.
			#
			foreach my $index (@planeIndexTypes) {
				my $indexXML    = $plane->getElementsByTagName( $index )->[0];
				print STDERR "\tProcessing index: ".$index."\n" if $debug eq 2;
				#############################################################
				#
				# AutoIterate
				#
				if ( $indexXML->getElementsByTagName( 'AutoIterate' ) ) {
					print STDERR "\t\tUses method: AutoIterate\n" if $debug eq 2;
					$planeIndexes->{ $planeID }->{$index} = 
						newScalarRef( 0 );
					$planeIndexes->{ $planeID }->{IterateStart}->{$index} = 
						0;
					$planeIndexes->{ $planeID }->{IterateEnd}->{$index} = 
						$indexSize{ $index }-1;
					$planeIndexes->{ $planeID }->{Output}->{$index} = 
						$indexXML->getElementsByTagName( 'AutoIterate')->[0];
				#
				#
				#############################################################
				#
				# UseValue
				#
				} elsif ( $indexXML->getElementsByTagName( 'UseValue' ) ) {
					my $indexMethod = $indexXML->getElementsByTagName( 'UseValue' )->[0];
					print STDERR "\t\tUses method: UseValue\n" if $debug eq 2;
					$planeIndexes->{ $planeID }->{$index} = 
						newScalarRef (
							$inputs{ 
								$indexMethod->getAttribute( "FormalInputName" )
							}->[0]->{
								$indexMethod->getAttribute( "FormalInputColumnName" )
							} );
				#
				#
				#############################################################
				#
				# IterateRange
				#
				} elsif ( $indexXML->getElementsByTagName( 'IterateRange' ) ) {
					print STDERR "\t\tUses method: IterateRange\n" if $debug eq 2;
					my $indexMethod = $indexXML->getElementsByTagName( 'IterateRange' )->[0];
					$planeIndexes->{ $planeID }->{$index} = 
						newScalarRef (
							$inputs{ 
								$indexMethod->getElementsByTagName( "Start" )->[0]->getAttribute( "FormalInputName" )
							}->[0]->{
								$indexMethod->getElementsByTagName( "Start" )->[0]->getAttribute( "FormalInputColumnName" )
							} 
						);
					$planeIndexes->{ $planeID }->{IterateStart}->{$index} = 
						$inputs{ 
							$indexMethod->getElementsByTagName( "Start" )->[0]->getAttribute( "FormalInputName" )
						}->[0]->{
							$indexMethod->getElementsByTagName( "Start" )->[0]->getAttribute( "FormalInputColumnName" )
						};
					$planeIndexes->{ $planeID }->{IterateEnd}->{$index} = 
						$inputs{ 
							$indexMethod->getElementsByTagName( "End" )->[0]->getAttribute( "FormalInputName" )
						}->[0]->{
							$indexMethod->getElementsByTagName( "End" )->[0]->getAttribute( "FormalInputColumnName" )
						};
					$planeIndexes->{ $planeID }->{Output}->{$index} = 
						$indexXML->getElementsByTagName( 'IterateRange')->[0];
				}
				#
				#############################################################
				
				print STDERR "\t\tCurrent Value: ". ${ $planeIndexes->{ $planeID }->{$index} } . "\n" if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{$index};
				print STDERR "\t\tIterateStart Value: ". $planeIndexes->{ $planeID }->{IterateStart}->{$index}. "\n" if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateStart}->{$index};
				print STDERR "\t\tIterateEnd Value: ". $planeIndexes->{ $planeID }->{IterateEnd}->{$index}. "\n" if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateEnd}->{$index};
			}
			#
			#	END "Process indexes with non referential methods."
			#
			#################################################################
			
		
			#################################################################
			#
			# helper function - makes a new scalar and returns its reference
			#
			sub newScalarRef { 
				my $tmp = shift;
				return \$tmp;
			}
			#
			#################################################################
			
		}
		#
		# End "First run through planes to generate plane indexes"
		#
		#####################################################################
		
		
		#####################################################################
		#
		# Second run through planes to link references
		#
		print STDERR "\n" if $debug eq 2;
		print STDERR "----------------------------------------------\n" if $debug eq 2;
		print STDERR "Second plane run - processing index references\n" if $debug eq 2;
		print STDERR "----------------------------------------------\n" if $debug eq 2;
		foreach my $plane(@planes) {
			my $planeID     = $plane->getAttribute( "XYPlaneID" );
			print STDERR "Processing plane ".$planeID."\n" if $debug eq 2;
			foreach my $index (@planeIndexTypes) {
				my $indexXML    = $plane->getElementsByTagName( $index )->[0];
				print STDERR "\tProcessing index: ".$index."\n" if $debug eq 2;
				if ( $indexXML->getElementsByTagName( 'Match' ) ) {
					my $indexMethod = $indexXML->getElementsByTagName( 'Match' )->[0];
					$planeIndexes->{ $planeID }->{$index} = 
						$planeIndexes->{
							$indexMethod->getAttribute( "XYPlaneID" )
						}->{$index}
						or die "Plane number $planeID.$index references plane number ".$indexMethod->getAttribute( "XYPlaneID" ).".$index but the latter plane's index is not defined. This could be caused by a circular reference.";
					print STDERR "\t\tProcessed reference to plane: ".$indexMethod->getAttribute( "XYPlaneID" )."\n" if $debug eq 2;
				}
				print STDERR "\t\tCurrent Value: ". ${ $planeIndexes->{ $planeID }->{$index} } . "\n" if $debug eq 2;
				print STDERR "\t\tIterateStart Value: ". $planeIndexes->{ $planeID }->{IterateStart}->{$index}. "\n" if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateStart}->{$index};
				print STDERR "\t\tIterateEnd Value: ". $planeIndexes->{ $planeID }->{IterateEnd}->{$index}. "\n" if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateEnd}->{$index};
			}
		}
		#
		#
		#####################################################################
		
	#
	# END "Set up Plane Indexes"
	#
	#####################################################################
	
	
	
	
	#####################################################################
	#
	# Execute the program
	#
	my $runAgain;
	my $cmdXML      = $root->getElementsByTagName( "CommandLine" )->[0];
	my @cmdElements = $cmdXML->getElementsByTagName( "InputSubString" );
	print STDERR "\n" if $debug eq 2;
	print STDERR "----------------------\n" if $debug eq 2;
	print STDERR "      Executing\n" if $debug eq 2;
	print STDERR "----------------------\n" if $debug eq 2;
	do { # loop is needed for plane iteration.
		$runAgain         = undef;
		my $cmdLineString = ' ';
		if ($debug) {
			print STDERR "Inputs:";
			foreach my $fi (keys %inputs) {
				print STDERR "\n\t$fi (". scalar @{$inputs{$fi}} .")";
				foreach my $inst ( @{$inputs{$fi}}) {
					foreach my $col ( keys %$inst ) {
						print STDERR "\n\t\t$col => ".$inst->{$col};
					}
					print STDERR "\n";
				}
			}
		}
	
		#################################################################
		#
		# Construct Command Line String
		#
		print STDERR "Constructing Command Line String\n" if $debug eq 2;
		foreach my $subString(@cmdElements) {
	
			#############################################################
			#
			# plain text - no processing required
			#		
			if( $subString->getElementsByTagName( 'RawText' ) ) {
				print STDERR "\tProcessing sub node of type RawText\n" if $debug eq 2;
				$cmdLineString .= $subString->getElementsByTagName( 'RawText' )->[0]->getFirstChild->getData;
			#
			#############################################################
			#
			# Variable substitutions
			#
			} elsif ($subString->getElementsByTagName( 'RawImageFilePath' ) ) {
				print STDERR "\tProcessing sub node of type RawImageFilePath\n" if $debug eq 2;
				$cmdLineString .= $image->getFullPath();
			} elsif ($subString->getElementsByTagName( 'sizeT' ) ) {
				print STDERR "\tProcessing sub node of type sizeT\n" if $debug eq 2;
				$cmdLineString .= $dims{'t'};
			} elsif ($subString->getElementsByTagName( 'sizeW' ) ) {
				print STDERR "\tProcessing sub node of type sizeW\n" if $debug eq 2;
				$cmdLineString .= $dims{'w'};
			} elsif ($subString->getElementsByTagName( 'sizeZ' ) ) {
				print STDERR "\tProcessing sub node of type sizeZ\n" if $debug eq 2;
				$cmdLineString .= $dims{'z'};
			} elsif ($subString->getElementsByTagName( 'sizeX' ) ) {
				print STDERR "\tProcessing sub node of type sizeX\n" if $debug eq 2;
				$cmdLineString .= $dims{'x'};
			} elsif ($subString->getElementsByTagName( 'sizeY' ) ) {
				print STDERR "\tProcessing sub node of type sizeY\n" if $debug eq 2;
				$cmdLineString .= $dims{'y'};
			} elsif ($subString->getElementsByTagName( 'BitsPerPixel' ) ) {
				print STDERR "\tProcessing sub node of type BitsPerPixel\n" if $debug eq 2;
				$cmdLineString .= $dims{'BitsPerPixel'};
			} elsif ($subString->getElementsByTagName( 'BytesPerPixel' ) ) {
				print STDERR "\tProcessing sub node of type BytesPerPixel\n" if $debug eq 2;
				$cmdLineString .= $dims{'BytesPerPixel'};
			#
			#############################################################
			#
			# Input request
			#
			} elsif ($subString->getElementsByTagName( 'Input' ) ) {
				print STDERR "\tProcessing sub node of type Input\n" if $debug eq 2;
				$cmdLineString .= 
					$inputs{
						$subString->getElementsByTagName( 'Input' )->[0]->getAttribute('FormalInputName')
					}->[0]->{
						$subString->getElementsByTagName( 'Input' )->[0]->getAttribute('FormalInputColumnName')
					};
			#
			#############################################################
			#
			# Generate a plane - currently only TIFFs are supported
			#		
			} elsif ($subString->getElementsByTagName( 'XYPlane' ) ) {
				print STDERR "\tProcessing sub node of type XYPlane\n" if $debug eq 2;
				my $planeXML = $subString->getElementsByTagName( 'XYPlane' )->[0];
				my $planeID = $planeXML->getAttribute( 'XYPlaneID' );
				my $planePath = $session->getTemporaryFilename('ome_cccp','TIFF')
					or die "Could not get temporary file to write image plane.";
				my $planeInfo = 'format='.$planeXML->getAttribute( 'Format' ).
					' theZ = '.${ $planeIndexes->{ $planeID }->{theZ} }.
					' theW = '.${ $planeIndexes->{ $planeID }->{theW} }.
					' theT = '.${ $planeIndexes->{ $planeID }->{theT} }.
					' Path = '.$planePath;
				print STDERR "\tPlane info is:\n$planeInfo" if $debug eq 2;
				my $pixelsWritten;
				if( $planeXML->getAttribute( 'BPP' ) eq 8 ) {
					print STDERR " BPP = 8" if $debug eq 2;
					$pixelsWritten = $imagePix->Plane2TIFF8( 
						${ $planeIndexes->{ $planeID }->{theZ} },
						${ $planeIndexes->{ $planeID }->{theW} },
						${ $planeIndexes->{ $planeID }->{theT} },
						$planePath,
						1, # scale
						0  # offset
					);
				} else {
					$pixelsWritten = $imagePix->Plane2TIFF( 
						${ $planeIndexes->{ $planeID }->{theZ} },
						${ $planeIndexes->{ $planeID }->{theW} },
						${ $planeIndexes->{ $planeID }->{theT} },
						$planePath );
				}
				print STDERR "\n\n" if $debug eq 2;
				my $nPix = $dims{'x'}*$dims{'y'};
				die "Wrong number of pixels written to file. $pixelsWritten of $nPix pixels written"
					unless ( $pixelsWritten == $nPix);
				$cmdLineString .= $planePath;
			#
			#
			#############################################################
			}
		}
		my $executeString = $program->location() . $cmdLineString;
		print STDERR "Execution string is:\n$executeString\n" if $debug;
		#
		#
		#################################################################
		
	#####################################################################
	#   
	# Actually execute
	#
		my $_STDOUT = new IO::File;
		open $_STDOUT, "$executeString |" or
			die "Cannot open analysis program";
		my $outputStream='';
		while( <$_STDOUT> ) {
			$outputStream .= $_;
		}
		close ( $_STDOUT );
	#
	#####################################################################
		
	
		#################################################################
		#
		# Iterate plane indexes and write iterated indexes as output
		# 	For a given plane, it's indexes will be iterated like they
		#	were in 3 nested for loops
		#		for(theW...) {
		#			for(theT...) {
		#				for(theZ...) {
		#	Except I'm using an array to hold the indexes so theZ
		#	is $planeIndexTypes[0] and so forth.
		# 
		print STDERR "\tDoing plane iteration and index storage.\n" if $debug eq 2;
		foreach my $plane($cmdXML->getElementsByTagName('XYPlane')) {
			my $planeID = $plane->getAttribute( 'XYPlaneID' );
			print STDERR "\t\tInspecting plane " . $planeID . "\n" if $debug eq 2;
			#########################################################
			#
			# Store indexes that need storing
			#
			foreach my $index (@planeIndexTypes) {
				my $indexXML = $plane->getElementsByTagName( $index )->[0];
				if( defined $indexXML->getAttribute('FormalOutputName') ) {
				# then store the index
					$outputs{
						$indexXML->getAttribute( 'FormalOutputName' )
					}->{
						$indexXML->getAttribute( 'FormalOutputColumnName' )
					} =
						${ $planeIndexes->{ $planeID }->{ $index } };
					print STDERR "\tStored index $index, value ".$outputs{
						$indexXML->getAttribute( 'FormalOutputName' )
					}->{
						$indexXML->getAttribute( 'FormalOutputColumnName' )
					}." to ".$indexXML->getAttribute( 'FormalOutputName' ).'.'.$indexXML->getAttribute( 'FormalOutputColumnName' )."\n"
						if $debug eq 2;
				}
			}
			#
			#########################################################
	
	
			#########################################################
			#
			# Iterate the first index - typically theZ
			#
			if( ${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[0] } } < $planeIndexes->{ $planeID }->{IterateEnd}->{ $planeIndexTypes[0] } ) {
				$runAgain = 1;
				${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[0] } }++;
				print STDERR "\t\t\tIterated $planeIndexTypes[0]\n" if $debug eq 2;
			#
			#
			#########################################################
			#
			# Iterate the second index - typically theT
			# Also reset theZ if it could use it
			# 	Do this only If theZ didn't need iterating
			#
			} elsif( ${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[1] } } < $planeIndexes->{ $planeID }->{IterateEnd}->{ $planeIndexTypes[1] } ) {
				$runAgain = 1;
				${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[1] } }++;
				print STDERR "\t\t\tIterated $planeIndexTypes[1]\n" if $debug eq 2;
				${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[0] } } = $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] }
					if defined $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] };
				print STDERR "\t\t\tReset $planeIndexTypes[0] to ".$planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] }."\n" 
					if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] };
			#
			#
			#########################################################
			#
			# Iterate the third index - typically theW
			# Also reset theT and theZ if they could use it
			# 	Do this only If theZ and theT both didn't need iterating
			#
			} elsif( ${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[2] } } < $planeIndexes->{ $planeID }->{IterateEnd}->{ $planeIndexTypes[2] } ) {
				$runAgain = 1;
				${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[2] } }++;
				print STDERR "\t\t\tIterated $planeIndexTypes[2]\n" if $debug eq 2;
				${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[0] } } = $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] }
					if defined $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] };
				print STDERR "\t\t\tReset $planeIndexTypes[0] to ".$planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] }."\n" 
					if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[0] };
				${ $planeIndexes->{ $planeID }->{ $planeIndexTypes[1] } } = $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[1] }
					if defined $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[1] };
				print STDERR "\t\t\tReset $planeIndexTypes[1] to ".$planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[1]}."\n"
					if ($debug eq 2) and defined $planeIndexes->{ $planeID }->{IterateStart}->{ $planeIndexTypes[1] };
			}
			#
			#
			#########################################################
		}
		#
		# END "Iterate plane indexes"
		#
		#################################################################
	
	
		#################################################################
		#   
		# Process output from STDOUT
		#
		my $stdout = $root->getElementsByTagName( "STDOUT" )->[0];
		my @outputRecords = $stdout->getElementsByTagName( "OutputRecord" );
		print STDERR "Collecting output from STDOUT\n" if $debug and $stdout;
		foreach my $outputRecord( @outputRecords) {
			my $repeatCount = $outputRecord->getAttribute( "RepeatCount" );
			my $terminateAt = $outputRecord->getAttribute( "TerminateAt" );
			my $pat = $outputRecord->getElementsByTagName( "pat" )->[0]->getFirstChild->getData();
			my @outputs = $outputRecord->getElementsByTagName( "Output" );

			while( keepGoing($repeatCount, $terminateAt, $outputStream) and ($outputStream =~ s/$pat// )) {
				$repeatCount-- if defined $repeatCount;
				my @outputRecord;
				foreach my $output(@outputs) {
					foreach my $outputTo ($output->getElementsByTagName( "OutputTo" ) ) {
						# This use of eval is not a security hole. ExecutionInstructions has been validated against XML schema.
						# XML schema dictates AccessBy attribute must be an integer.
						# ...but I'm paranoid, so I'm going to check anyway
						my $accessBy               = $output->getAttribute( "AccessBy" );
						die "Attribute AccessBy is not an integer! Execution Instructions in module ".$self->{_program}->name()." are corrupted. Alert system admin!" 
							if( $accessBy =~ m/\D/ );
						my $formalOutputColumnName = $outputTo->getAttribute( "FormalOutputColumnName" );
						my $formalOutputName       = $outputTo->getAttribute( "FormalOutputName" );
						my $cmd                    = '$outputs{ $formalOutputName }->{$formalOutputColumnName} = $' . $accessBy . ';';
						eval $cmd;
					}
				}

				#########################################################
				#   
				# Write output record
				#
				$self->newAttributes(%outputs);
				if($debug) {
					print STDERR "Outputs:";
					foreach my $outputName( keys %outputs) {
						print STDERR "\n\t$outputName:";
							foreach my $outputCol ( keys %{$outputs{$outputName}}) {
								print STDERR "\n\t\t$outputCol: ".$outputs{$outputName}->{$outputCol};
							}
					}
					print STDERR "\n";
				}
				#
				#########################################################

			}
			print STDERR "\n" if $debug eq 2;
			
			#############################################################
			#
			# Helper function
			#	returns undef if loop needs to exit, else returns 1
			#
			sub keepGoing {
				my ($r, $t, $str) = @_;
				return undef if length($str) == 0;
				if( defined $r) {
					return undef if( $r<=0 );
				}
				if(defined $t) {
					return undef if $str =~ m/^$t/;
				}
				return 1;
			}
			#
			#############################################################
		}
		#
		#################################################################
	
	
	
	
	} while($runAgain);
	#
	# END "Execute the program"
	#
	#####################################################################

}

1;
