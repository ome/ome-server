# OME/Analysis/CLIHandler.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Analysis::CLIHandler;

use strict;
our $VERSION = 2.000_000;

use IPC::Open2;

use OME::Analysis::Handler;
use XML::LibXML;
use base qw(OME::Analysis::Handler);

use fields qw(_outputHandle);

sub new {
    my ($proto,$location,$session,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$module,$node);

    bless $self,$class;
    return $self;
}


sub precalculateDataset {
    my ($self) = @_;

	my $module                  = $self->{_module};
	my $executionInstructions    = $module->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'precalculateDataset' ) {
		my @formalInputs          = $module->inputs();
		my %inputs                = map { $_->name() => $self->getDatasetInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub precalculateImage {
    my ($self) = @_;

	my $module                  = $self->{_module};
	my $executionInstructions    = $module->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'precalculateImage' ) {
		my @formalInputs          = $module->inputs();
		my %inputs                = map { $_->name() => $self->getImageInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub calculateFeature {
    my ($self) = @_;

	my $module                  = $self->{_module};
	my $executionInstructions    = $module->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'calculateFeature' ) {
		my @formalInputs          = $module->inputs();
		my %inputs                = map { $_->name() => $self->getFeatureInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}


sub postcalculateImage {
    my ($self) = @_;

	my $module                  = $self->{_module};
	my $executionInstructions    = $module->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'postcalculateImage' ) {
		my @formalInputs          = $module->inputs();
		my %inputs                = map { $_->name() => $self->getImageInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub postcalculateDataset {
    my ($self) = @_;

	my $module                  = $self->{_module};
	my $executionInstructions    = $module->execution_instructions();
	my $parser                   = XML::LibXML->new();
	
	my $tree                     = $parser->parse_string( $executionInstructions );
	my $root                     = $tree->getDocumentElement();
	my $ExecutionInstructionsXML = $root;#->getElementsByTagName( 'ExecutionInstructions' )->[0];

	if( $ExecutionInstructionsXML->getAttribute( 'ExecutionPoint' ) eq 'postcalculateDataset' ) {
		my @formalInputs          = $module->inputs();
		my %inputs                = map { $_->name() => $self->getDatasetInputs($_->name()) } @formalInputs;
		$self->_execute(\%inputs);
	}
}

sub _execute {
	my $self   = shift;
	my $i      = shift;
	my %inputs = %{ $i };

    my $image  = $self->getCurrentImage();

	my $module               = $self->{_module};
	my %outputs;
	my $executionInstructions = $module->execution_instructions();
	my $debug                 = 0;
	my $session               = $self->Session();
	my $imagePix;
	my $CLIns = 'http://www.openmicroscopy.org/XMLschemas/CLI/RC1/CLI.xsd';

my $Pixels =  $self->getImageInputs("Pixels")->[0];	
my %dims = ( 'x'   => $Pixels->SizeX(),
			 'y'   => $Pixels->SizeY(),
			 'z'   => $Pixels->SizeZ(),
			 'w'   => $Pixels->SizeC(),
			 't'   => $Pixels->SizeT(),
			 'BytesPerPixel' => $Pixels->BitsPerPixel()/8,
			 'BitsPerPixel' => $Pixels->BitsPerPixel(),
			 )
	if defined $Pixels;
	
	my $parser = XML::LibXML->new();
	my $tree = $parser->parse_string( $executionInstructions );
	my $root = $tree->getDocumentElement();
	
	
	#####################################################################
	#
	# What needs to be done to generalize plane interating from just XY to YZ & XZ
	#
	#	change contents of planeIndexTypes
	#	change method of plane generation
	#
	#
	#####################################################################
	
	
	#####################################################################
	#
	# set up Plane Generation
	#
	# Notes:
	# 	the import process normalized planeID's - it gives every plane a unique ID and updates all references
	# 	autoIterators is hash reference. hash is keyed by planeID. values are references to hashes keyed by theZ, theW, & theT. these values are references to scalars.
	# 		The reason for this is each plane needs a set of plane indexes {theZ, theW, theT}, but sometimes a component of these will overlap.
	# 		For example, the cross correlation module needs two planes synced on theZ and theT with differing constant wavenumbers.
	# 		Since theZ theW and theT are references, it is a simple matter to sync any of these.
	#
	my $planeIndexes;
	my @planes = $root->getElementsByTagNameNS( $CLIns, "XYPlane" );
	if(scalar(@planes) > 0 ) {
		my $imagePix = $image->GetPix($Pixels)
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
				my $indexXML    = $plane->getElementsByTagNameNS( $CLIns, $index )->[0];
				print STDERR "\tProcessing index: ".$index."\n" if $debug eq 2;
				#############################################################
				#
				# AutoIterate
				#
				if ( $indexXML->getElementsByTagNameNS( $CLIns, 'AutoIterate' ) ) {
					print STDERR "\t\tUses method: AutoIterate\n" if $debug eq 2;
					$planeIndexes->{ $planeID }->{$index} = 
						newScalarRef( 0 );
					$planeIndexes->{ $planeID }->{IterateStart}->{$index} = 
						0;
					$planeIndexes->{ $planeID }->{IterateEnd}->{$index} = 
						$indexSize{ $index }-1;
					$planeIndexes->{ $planeID }->{Output}->{$index} = 
						$indexXML->getElementsByTagNameNS( $CLIns, 'AutoIterate')->[0];
				#
				#
				#############################################################
				#
				# UseValue
				#
				} elsif ( $indexXML->getElementsByTagNameNS( $CLIns, 'UseValue' ) ) {
					my $indexMethod = $indexXML->getElementsByTagNameNS( $CLIns, 'UseValue' )->[0];
					print STDERR "\t\tUses method: UseValue\n" if $debug eq 2;
					$planeIndexes->{ $planeID }->{$index} = 
						newScalarRef (
							$inputs{ 
								$indexMethod->getAttribute( "FormalInputName" )
							}->[0]->{
								$indexMethod->getAttribute( "SemanticElementName" )
							} );
				#
				#
				#############################################################
				#
				# IterateRange
				#
				} elsif ( $indexXML->getElementsByTagNameNS( $CLIns, 'IterateRange' ) ) {
					print STDERR "\t\tUses method: IterateRange\n" if $debug eq 2;
					my $indexMethod = $indexXML->getElementsByTagNameNS( $CLIns, 'IterateRange' )->[0];
					$planeIndexes->{ $planeID }->{$index} = 
						newScalarRef (
							$inputs{ 
								$indexMethod->getElementsByTagNameNS( $CLIns, "Start" )->[0]->getAttribute( "FormalInputName" )
							}->[0]->{
								$indexMethod->getElementsByTagNameNS( $CLIns, "Start" )->[0]->getAttribute( "SemanticElementName" )
							} 
						);
					$planeIndexes->{ $planeID }->{IterateStart}->{$index} = 
						$inputs{ 
							$indexMethod->getElementsByTagNameNS( $CLIns, "Start" )->[0]->getAttribute( "FormalInputName" )
						}->[0]->{
							$indexMethod->getElementsByTagNameNS( $CLIns, "Start" )->[0]->getAttribute( "SemanticElementName" )
						};
					$planeIndexes->{ $planeID }->{IterateEnd}->{$index} = 
						$inputs{ 
							$indexMethod->getElementsByTagNameNS( $CLIns, "End" )->[0]->getAttribute( "FormalInputName" )
						}->[0]->{
							$indexMethod->getElementsByTagNameNS( $CLIns, "End" )->[0]->getAttribute( "SemanticElementName" )
						};
					$planeIndexes->{ $planeID }->{Output}->{$index} = 
						$indexXML->getElementsByTagNameNS( $CLIns, 'IterateRange')->[0];
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
				my $indexXML    = $plane->getElementsByTagNameNS( $CLIns, $index )->[0];
				print STDERR "\tProcessing index: ".$index."\n" if $debug eq 2;
				if ( $indexXML->getElementsByTagNameNS( $CLIns, 'Match' ) ) {
					my $indexMethod = $indexXML->getElementsByTagNameNS( $CLIns, 'Match' )->[0];
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
	# Execute the module
	#
	my $runAgain;
	my $cmdXML      = $root->getElementsByTagNameNS( $CLIns, "CommandLine" )->[0];
	my @cmdElements = $cmdXML->getElementsByTagNameNS( $CLIns, "InputSubString" )
		if defined $cmdXML;
	my @planes = $cmdXML->getElementsByTagNameNS( $CLIns, "XYPlane" )
		if defined $cmdXML;
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
			$cmdLineString .= resolveSubString( $subString );
		}
		my $executeString = $module->location() . $cmdLineString;
		print STDERR "Execution string is:\n$executeString\n" if $debug;
		#
		#
		#################################################################
			
		#####################################################################
		#   
		# Actually execute
		#
			open2(*OUT, *IN, $executeString);
			
			#################################################################
			#
			# Write to STDIN of program
			#
			print STDERR "Writing to Program's STDIN.\n" if $debug eq 2;
 			my @stdinXML = $root->getElementsByLocalName( "STDIN" ); 
			if( @stdinXML ) {
				my @inputRecordsXML = $stdinXML[0]->getElementsByLocalName( "InputRecord" );
				foreach my $inputRecordXML( @inputRecordsXML ) {
					#construct input record
					my $delimitedRecordXML = [$inputRecordXML->getElementsByLocalName("DelimitedRecord")]->[0];
					my @inputsXML = $delimitedRecordXML->getElementsByLocalName( "Input" );
					my @indexesXML = $inputRecordXML->getElementsByLocalName( "Index" );

					my %recordHash;
					my %knownFormalInputs;
					
					# process each formal input in the record block, & join them on indexes
					foreach my $inputXML( @inputsXML ) {
						my @indexLookup;
						my $FI = $inputXML->getAttribute('FormalInputName');
						
						# have we seen this formal input before?
						next if exists $knownFormalInputs{$FI};
						$knownFormalInputs{$FI} = undef;
						
						foreach my $indexXML (@indexesXML ) {
							my @matchingInput = grep( 
								$_->getAttribute('FormalInputName') eq $FI,
								$indexXML->getElementsByLocalName("Input"));
							push( @indexLookup, $matchingInput[0]->getAttribute( 'SemanticElementName' ) );
						}
						
						# make hash entry for each instance of this formal input
						foreach my $input ( @{$inputs{ $FI }} ) {
                            # This doesn't get used, and takes time to build
							#my $d = $input->getDataHash();
							my @keys = ();
							foreach my $se ( @indexLookup ) {
								# FIXME: implement dereferencing
								#$se =~ s/\./\(\)->/g;
								my $val = $input->$se();
								
								die "Could not find SE '$se' belonging to ST '".$input->semantic_type()->name()."'. The <InputRecord> this stuff was pulled from is\n".$inputRecordXML->toString()."\n"
									unless defined $val;
								push( @keys, $val );
							}
							my $key = join( '.', @keys );
							die "Duplicate entry for '$FI' found for index key '$key'\n"
								if exists $recordHash{$key}->{$FI};
							$recordHash{$key}->{$FI} = $input;
						}

					}

					#sort & print input record block
					my @recordBlock;
					foreach my $index( sort keys %recordHash ) {
						my @recordEntries;
						foreach my $inputXML( @inputsXML ) {
							my $FI = $inputXML->getAttribute('FormalInputName');
							my $se = $inputXML->getAttribute('SemanticElementName');
							# FIXME: implement dereferencing
							#$se =~ s/\./\(\)->/g;
							my $r = $recordHash{ $index }->{ $FI }->$se();
							die "_getField( $se ) returned undef. This was most likely caused by a misspelling of the semantic element '$se' in '".$inputXML->toString()."'.\n"
								unless defined $r;
							push( @recordEntries, $r );
						}
						my $record = join( $delimitedRecordXML->getAttribute( 'FieldDelimiter' ), @recordEntries );
						push( @recordBlock, $record );
					}
					my $recordDelimiter = $delimitedRecordXML->getAttribute( 'RecordDelimiter' ) || "\n";
					print IN join( $recordDelimiter, @recordBlock );
					print STDERR "Record block is:\n".join( $recordDelimiter, @recordBlock ) if $debug > 2;
				}
			}
			close(IN);
			#
			#
			#################################################################

			# collect output
			my $outputStream='';
			while( <OUT> ) {
				$outputStream .= $_;
			}
			close(OUT);
		#
		#####################################################################
			
	
	
	
		#####################################################################
		#   
		# resolveSubString
		#	a helper function
		#
		sub resolveSubString {
			my $subString = shift;
			
			#############################################################
			#
			# plain text - no processing required
			#		
			if( $subString->getElementsByTagNameNS( $CLIns, 'RawText' ) ) {
				return $subString->getElementsByTagNameNS( $CLIns, 'RawText' )->[0]->getFirstChild->getData;
			#
			#############################################################
			#
			# Input request
			#
			} elsif ($subString->getElementsByTagNameNS( $CLIns, 'Input' ) ) {
				my $se = $subString->getElementsByTagNameNS( $CLIns, 'Input' )->[0]->getAttribute('SemanticElementName');
				$se =~ s/\./\(\)->/g;
				my $str = '$inputs{'.
						$subString->getElementsByTagNameNS( $CLIns, 'Input' )->[0]->getAttribute('FormalInputName').
					'}->[0]->'.$se.'()';
				my $val;
				# FIXME: potential security hole - <Input>'s SemanticElementName needs better type checking at ProgramImport
				eval('$val ='. $str)
					or die "Could not resolve input call '$str'\n";
				
				$val /= $subString->getElementsByTagNameNS( $CLIns, 'Input' )->[0]->getAttribute('DivideBy')
					if defined $subString->getElementsByTagNameNS( $CLIns, 'Input' )->[0]->getAttribute('DivideBy');
				$val *= $subString->getElementsByTagNameNS( $CLIns, 'Input' )->[0]->getAttribute('MultiplyBy')
					if defined $subString->getElementsByTagNameNS( $CLIns, 'Input' )->[0]->getAttribute('MultiplyBy');
				return $val;
			#
			#############################################################
			#
			# Generate a plane - currently only TIFFs are supported
			#		
			} elsif ($subString->getElementsByTagNameNS( $CLIns, 'XYPlane' ) ) {
				my $planeXML = $subString->getElementsByTagNameNS( $CLIns, 'XYPlane' )->[0];
				my $planeID = $planeXML->getAttribute( 'XYPlaneID' );
				my $planePath = $session->getTemporaryFilename('ome_cccp','TIFF')
					or die "Could not get temporary file to write image plane.";
				my $planeInfo = 'format='.$planeXML->getAttribute( 'Format' ).
					' theZ = '.${ $planeIndexes->{ $planeID }->{theZ} }.
					' theW = '.${ $planeIndexes->{ $planeID }->{theW} }.
					' theT = '.${ $planeIndexes->{ $planeID }->{theT} }.
					' Path = '.$planePath;
				my $pixelsWritten;
				if( $planeXML->getAttribute( 'BPP' ) eq 8 ) {
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
				my $nPix = $dims{'x'}*$dims{'y'};
				die "Wrong number of pixels written to file. $pixelsWritten of $nPix pixels written"
					unless ( $pixelsWritten == $nPix);
				return $planePath;
			#
			#
			#############################################################
			}
		}
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
		foreach my $plane(@planes) {
			my $planeID = $plane->getAttribute( 'XYPlaneID' );
			print STDERR "\t\tInspecting plane " . $planeID . "\n" if $debug eq 2;
			#########################################################
			#
			# Store indexes that need storing
			#
			foreach my $index (@planeIndexTypes) {
				my $indexXML = $plane->getElementsByTagNameNS( $CLIns, $index )->[0];
				
				foreach my $outputTo ($indexXML->getElementsByTagNameNS( $CLIns, "OutputTo" ) ) {
					my $semanticElementName = $outputTo->getAttribute( "SemanticElementName" );
					my $formalOutputName       = $outputTo->getAttribute( "FormalOutputName" );
					$outputs{ $formalOutputName }->{$semanticElementName} = 
					${ $planeIndexes->{ $planeID }->{ $index } };
					print STDERR "\tStored index $index, value ".
						$outputs{ $formalOutputName }->{$semanticElementName}.
						" to ".$formalOutputName.'.'.$semanticElementName."\n"
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
		my $stdout = $root->getElementsByTagNameNS( $CLIns, "STDOUT" )->[0];
		my @outputRecords = $stdout->getElementsByTagNameNS( $CLIns, "OutputRecord" );
		print STDERR "Collecting output from STDOUT\n" if $debug and $stdout;
		foreach my $outputRecord( @outputRecords) {
			my $repeatCount = $outputRecord->getAttribute( "RepeatCount" );
			my $terminateAt = $outputRecord->getAttribute( "TerminateAt" );
			my $pat = $outputRecord->getElementsByTagNameNS( $CLIns, "pat" )->[0]->getFirstChild->getData();
			my @outputs = $outputRecord->getElementsByTagNameNS( $CLIns, "Output" );

			while( keepGoing($repeatCount, $terminateAt, $outputStream) and ($outputStream =~ s/$pat// )) {
				$repeatCount-- if defined $repeatCount;
				my @outputRecord;
				foreach my $output(@outputs) {
					foreach my $outputTo ($output->getElementsByTagNameNS( $CLIns, "OutputTo" ) ) {
						# This use of eval is not a security hole. ExecutionInstructions has been validated against XML schema.
						# XML schema dictates AccessBy attribute must be an integer.
						# ...but I'm paranoid, so I'm going to check anyway
						my $accessBy               = $output->getAttribute( "AccessBy" );
						die "Attribute AccessBy is not an integer! Execution Instructions in module ".$self->{_module}->name()." are corrupted. Alert system admin!" 
							if( $accessBy =~ m/\D/ );
						my $formalOutputColumnName = $outputTo->getAttribute( "SemanticElementName" );
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
	# END "Execute the module"
	#
	#####################################################################

}

1;
