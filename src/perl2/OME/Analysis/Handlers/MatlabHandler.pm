# OME/Analysis/Handlers/MatlabHandler.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institue of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
# Written by:  Josiah Johnston <siah@nih.gov>
# Based on code written by: Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Handlers::MatlabHandler;

=head1 NAME

OME::Analysis::Handlers::MatlabHandler - analysis handler for
interfacing with Matlab routines

=head1 SYNOPSIS

	use OME::Analysis::Handlers::MatlabHandler;

=head1 DESCRIPTION

This is a generalized wrapper that allows Matlab functions to be executed from
the OME analysis system.
This package implements the execution instructions specified by
L<http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd>

=cut

use strict;
use Carp;

use OME;
use XML::LibXML;
use Log::Agent;
our $VERSION = $OME::VERSION;

use OME::Matlab;
use OME::Tasks::PixelsManager;
use OME::Analysis::Handler;
use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use fields qw(__engine __engineOpen);

my $supported_NS = 'http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);

	$self->{__engine} = undef;
	$self->{__engineOpen} = 0;
	$self->{__inputVariableNames} = {};
	$self->{__outputVariableNames} = {};
	
	# List of functions in this package make matlab global variables from input execution instructions
	# Keyed by Tag name of elements under <Input>
	$self->{ _translate_to_matlab } = {
		PixelsArray => 'Pixels_to_MatlabArray',
		PixelsSlice => 'PixelsSlice_to_MatlabArray',
		Scalar      => 'Attr_to_MatlabScalar',
	};
	
	# List of package functions to make ome attributes from output execution instructions
	# Keyed by Tag name of elements under <Output>
	$self->{ _translate_from_matlab } = {
		PixelsArray => 'MatlabArray_to_Pixels',
		Scalar      => 'MatlabScalar_to_Attr',
		Struct      => 'MatlabStruct_to_Attr'
	};

	# Mapping from Pixel Types to matlab class bindings
	$self->{ _pixel_type_to_matlab_class } = {
		uint8  => $mxUINT8_CLASS,
		uint16 => $mxUINT16_CLASS,
		uint32 => $mxUINT32_CLASS,
	};
	
	# Mapping from matlab classes to pixel types. Also limits the supported matlab classes.
	$self->{ _matlab_class_to_pixel_type } = {
		uint8  => 'uint8',
		uint16 => 'uint16',
		uint32 => 'uint32',
	};
	
	bless $self,$class;
	return $self;
}

sub DESTROY {
	my ($self) = @_;
	$self->__closeEngine();
}

sub startAnalysis {
	my ($self,$module_execution) = @_;
	$self->__openEngine();

	my $parser = XML::LibXML->new();
	my $tree   = $parser->parse_string( $self->getModule()->execution_instructions() );
	my $root   = $tree->getDocumentElement();
	# This Allows xpath queries on the MLI NS. i.e. $root->findnodes( "MLI:Inputs/*" )
	$root->setAttribute( "xmlns:MLI", $supported_NS );
	
	$self->{ execution_instructions } = $root;
}

sub startImage {
    my ($self,$image) = @_;
    $self->SUPER::startImage($image);

    $self->placeInputs();
	$self->__execute() if $self->__checkExecutionGranularity( ) eq 'I';
	$self->getOutputs();
}

sub finishAnalysis {
	my ($self) = @_;
	$self->__closeEngine();
}

sub __execute {
	my ($self) = @_;
	
	my $location = $self->getModule()->location();
	
	my $input_cmd = "(".join(',', 
		map( $self->_inputVarName( $_ ), $self->_functionInputs() )
	).")";

	my $output_cmd;
	my @output_names = map( $self->_outputVarName( $_ ), $self->_functionOutputs() )
		or die "Couldn't find any outputs!";
	if (scalar(@output_names) eq 1) {
		$output_cmd = $output_names[0]." = ";
	} else {
		$output_cmd = "[".join(',',@output_names)."] = ";
	}

	my $command = "${output_cmd}${location}${input_cmd};";
	logdbg "debug", "***** Command to Matlab: $command\n";
	my $outBuffer = " " x 512;
	$self->{__engine}->setOutputBuffer($outBuffer, length($outBuffer));
	$self->{__engine}->eval($command);
	logdbg "debug", "***** Output from Matlab:\n $outBuffer\n";
}

=head1 Input processing

This group of functions collectively converts OME attributes to Matlab inputs.
They operate on an XML input instruction. Their interface is:
	$self->$translation_function( $XML_input_instruction );
They are registered in new() under the hash: 
	$self->{ _translate_from_matlab }
They are responsible for collecting their inputs from the DB and translating 
them to matlab global variables whose name are given by:
	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
placeInputs() coordinates all this output processing activity.

=head2 placeInputs

Grabs xml instructions for function inputs, then uses the registry of
Input processing functions to divy up the work of getting those inputs into
Matlab.

=cut

sub placeInputs {
	my ($self) = @_;

	my @input_list = $self->_functionInputs();
	foreach my $input( @input_list ) {
		die "In Execution instructions of module ".$self->getModule()->name().", can't handle input: ".$input->tagName()."\n'".$input->toString()."'"
			unless( exists $self->{ _translate_to_matlab }->{ $input->tagName() } );
		my $translation_function = $self->{ _translate_to_matlab }->{ $input->tagName() };
		$self->$translation_function( $input );
	}
}

=head2 Pixels_to_MatlabArray

Translate a Pixels input into a matlab 5d array.
Uses <PixelsArray>
The guts of this were written by Tomasz

=cut

sub Pixels_to_MatlabArray {
	my ( $self, $xmlInstr ) = @_;
	my $session = OME::Session->instance();
	
	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
	my $formal_input = $self->getFormalInput( $xmlInstr->getAttribute( 'FormalInput' ) );
	my @pixel_attr_list = $self->getCurrentInputAttributes( $formal_input );
		
	if ( scalar @pixel_attr_list > 1) {
		print STDERR "The OME-Matlab interface does not support Formal inputs".
		             " of arity greater than 1 at this time.\n";
		return;
	}
	my $pixels = $pixel_attr_list[0];
	
	my $pixelType = $pixels->PixelType();
	die "The OME-Matlab interface does not support $pixelType at this time."
		unless exists $self->{ _pixel_type_to_matlab_class }->{ $pixelType };
	my $class = $self->{ _pixel_type_to_matlab_class }->{ $pixelType };
		
	my $matlab_pixels = OME::Matlab::Array->newNumericArray(
		$class,
		$mxREAL,
		$pixels->SizeX(),
		$pixels->SizeY(),
		$pixels->SizeZ(),
		$pixels->SizeC(),
		$pixels->SizeT()
	) or die "Could not make an array in matlab for Pixels";
	$matlab_pixels->makePersistent();
  
	# FIXME: PixelsManager->getLocalFile( $pixels ) should implement 
	#    the functionality below, but without loading the whole pixels
	#    array into RAM

	#  prepare for the incoming pixels
	my $filename = $session->getTemporaryFilename("pixels","raw");
	open my $pix, ">", $filename or die "Could not open local pixels file";
	# FIXME: take endianess into consideration
	my $buf = OME::Image::Server->getPixels($pixels->ImageServerID());
	print $pix $buf;
	close $pix;
	
	$self->{__engine}->eval("global $matlab_var_name");
	$self->{__engine}->putVariable($matlab_var_name,$matlab_pixels);
	
	# magic one-liner. One liner means no variables are left in matlab's workplace
	# this one-liner fills an array based on OMEIS's output which went to a temp file
	$self->{__engine}->eval("[$matlab_var_name, nPix] = fread(fopen('$filename', 'r'), size($matlab_var_name),'$pixelType');");
	$session->finishTemporaryFile($filename);
}

=head2 PixelsSlice_to_MatlabArray

Translate a PixelsSlice input into a matlab 5d array.
Uses <PixelsSlice>
The guts of this were written by Tomasz

=cut

sub PixelsSlice_to_MatlabArray {
	my ( $self, $xmlInstr ) = @_;
	my $session = OME::Session->instance();
	
	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
	my $formal_input = $self->getFormalInput( $xmlInstr->getAttribute( 'FormalInput' ) );
	my @pixels_slice_attr_list = $self->getCurrentInputAttributes( $formal_input );

	if ( scalar @pixels_slice_attr_list > 1) {
		print STDERR "The OME-Matlab interface does not support Formal inputs".
		             " of arity greater than 1 at this time.\n";
		return;
	}
	my $pixels_slice = $pixels_slice_attr_list[0];
	
	# Go up the line of decent until a PixelsSlice is reached
	while( $pixels_slice->semantic_type()->name() ne 'PixelsSlice' ) {
		$pixels_slice = $pixels_slice->Parent();
	}
        
	# get the dimensions of the pixels slice
	my ($x0, $x1, $y0, $y1, $z0, $z1, $c0, $c1, $t0, $t1) =
		($pixels_slice->StartX(), $pixels_slice->EndX(),
		 $pixels_slice->StartY(), $pixels_slice->EndY(),
		 $pixels_slice->StartZ(), $pixels_slice->EndZ(),
		 $pixels_slice->StartC(), $pixels_slice->EndC(),
		 $pixels_slice->StartT(), $pixels_slice->EndT());
				
	my $pixels = $pixels_slice->Pixels();
	my $pixelType = $pixels->PixelType();
	
	die "The OME-Matlab interface does not support $pixelType at this time."
		unless exists $self->{ _pixel_type_to_matlab_class }->{ $pixelType };
	my $class = $self->{ _pixel_type_to_matlab_class }->{ $pixelType };
		
	my $matlab_pixels = OME::Matlab::Array->newNumericArray(
		$class,
		$mxREAL,
		$x1-$x0+1,
		$y1-$y0+1,
		$z1-$z0+1,
		$c1-$c0+1,
		$t1-$t0+1
	) or die "Could not make an array in matlab for Pixels";
	$matlab_pixels->makePersistent();
  
	# FIXME: PixelsManager->getLocalFile( $pixels ) should implement 
	#    the functionality below, but without loading the whole pixels
	#    array into RAM

	#  prepare for the incoming pixels
	my $filename = $session->getTemporaryFilename("pixels","raw");
	open my $pix, ">", $filename or die "Could not open local pixels file";
	
	# FIXME: take endianess into consideration
	my $buf = OME::Image::Server->getROI($pixels->ImageServerID(), 
		$x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1, );
	print $pix $buf;
	close $pix;
	
	$self->{__engine}->eval("global $matlab_var_name");
	$self->{__engine}->putVariable($matlab_var_name,$matlab_pixels);
	
	# magic one-liner. One liner means no variables are left in matlab's workplace
	# this one-liner fills an array based on OMEIS's output which went to a temp file
	$self->{__engine}->eval("[$matlab_var_name, nPix] = fread(fopen('$filename', 'r'), size($matlab_var_name),'$pixelType');");
	$session->finishTemporaryFile($filename);
}

=head2 Attr_to_MatlabScalar

Translate an input attribute into a matlab scalar
Uses <Scalar>

=cut

sub Attr_to_MatlabScalar {
	my ( $self, $xmlInstr ) = @_;

	# get input value
 	my $input_location = $xmlInstr->getAttribute( 'InputLocation' );
 	my ( $formal_input_name, $SEforScalar ) = split( /\./, $input_location )
 		or die "input_location '$input_location' could not be parsed.";
	my $input_attr = $self->getCurrentInputAttributes( $formal_input_name );
	die scalar( @$input_attr )." attributes found for input '$formal_input_name'. ".
		'Cannot use scalar for input that has count other than 1. Error when processing \''.$xmlInstr->toString()."'"
		unless scalar( @$input_attr ) eq 1;
	my $value = $input_attr->[0]->$SEforScalar();

	# Place value into matlab
	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
	my $array = OME::Matlab::Array->newDoubleScalar($value);
 	$array->makePersistent();
	$self->{__engine}->eval("global $matlab_var_name");
	$self->{__engine}->putVariable($matlab_var_name,$array);
}

=head1 Output processing

This group of functions collectively converts Matlab outputs into OME attributes.
They operate on an XML output instruction. Their interface is:
	$self->$translation_function( $XML_output_instruction );
They are registered in new() under the hash: 
	$self->{ _translate_from_matlab }
They extract the global matlab variable whose name is given by:
	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
and store the results into the DB.
getOutputs() coordinates all this output processing activity.

=head2 getOutputs

Grabs xml instructions for function outputs, then uses the registry of
Output processing functions to divy up the work of getting those outputs from
Matlab into OME.

=cut

sub getOutputs {
	my ($self) = @_;

	my @output_list = $self->_functionOutputs();
	foreach my $output( @output_list ) {
		die "In Execution instructions of module ".$self->getModule()->name().", can't handle output:\n".$output->toString()
			unless( exists $self->{ _translate_from_matlab }->{ $output->tagName() } );
		my $translation_function = $self->{ _translate_from_matlab }->{ $output->tagName() };
		$self->$translation_function( $output );
	}

}

=head2 MatlabArray_to_Pixels

Translate a matlab 5d array into a Pixels attribute & image server object.
Uses <PixelsArray>
The guts of this were written by Tomasz

=cut

sub MatlabArray_to_Pixels {
	my ( $self, $xmlInstr ) = @_;
	my $session = OME::Session->instance();

	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
	my $filename = $session->getTemporaryFilename("pixels","raw");
	
	# figure out the array's dimensions
	$self->{__engine}->eval("[sizeX,sizeY,sizeZ,sizeC,sizeT] = size($matlab_var_name)");
	my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT) = 
		($self->{__engine}->getVariable('sizeX')->getScalar(),
		 $self->{__engine}->getVariable('sizeY')->getScalar(),
		 $self->{__engine}->getVariable('sizeZ')->getScalar(),
		 $self->{__engine}->getVariable('sizeC')->getScalar(),
		 $self->{__engine}->getVariable('sizeT')->getScalar());
	
	# figure out the pixel depth based on array data-type	 
	$self->{__engine}->eval("str = class($matlab_var_name)");
	my $type = $self->{__engine}->getVariable('str')->getScalar();
	die "Pixels of Matlab class $type are not supported at this time"
		unless exists $self->{ _matlab_class_to_pixel_type }->{ $type };
	my $pixelType = $self->{ _matlab_class_to_pixel_type }->{ $type };
	$self->{__engine}->eval("fwrite(fopen('$filename','w'),$matlab_var_name, class($matlab_var_name))");
	my ($pixels_data, $pixels_attr) = OME::Tasks::PixelsManager->createPixels(
		$self->getCurrentImage(), 
		$self->getModuleExecution(),{
			SizeX		 => $sizeX,
			SizeY		 => $sizeY,
			SizeZ		 => $sizeZ,
			SizeC		 => $sizeC,
			SizeT		 => $sizeT,
			PixelType	 => $pixelType
		} );

	my $pixelsWritten = $pixels_data->setPixelsFile($filename,1);
	my $pixelsID = OME::Tasks::PixelsManager->finishPixels($pixels_data, $pixels_attr);
	OME::Tasks::PixelsManager->saveThumb($pixels_attr);
	
	$session->finishTemporaryFile($filename);
}

=head2 MatlabScalar_to_Attr

Operates on scalar matlab outputs. Uses <Scalar> in conjuction with <Templates>

=cut

sub MatlabScalar_to_Attr {
	my ( $self, $xmlInstr ) = @_;

	# gather formal output & SE
 	my $output_location = $xmlInstr->getAttribute( 'OutputLocation' );
 	my ( $formal_output_name, $SEforScalar ) = split( /\./, $output_location )
 		or die "output_location '$output_location' could not be parsed.";
 	my $formal_output = $self->getFormalOutput( $formal_output_name )
		or die "Could not find formal output '$formal_output_name' (from output location '$output_location').";

	# Retrieve value from matlab
	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
 	my $matlab_output = $self->{__engine}->getVariable( $matlab_var_name )
 		or die "Couldn't retrieve $matlab_var_name";
 	$matlab_output->makePersistent();
	my $value = $matlab_output->getScalar();

	# Make a data hash
	my $template_id = $xmlInstr->getAttribute( 'UseTemplate' );
	my $data_hash;
	if( $template_id ) {
		my $ST_name;
		($ST_name, $data_hash) = $self->_getTemplateData( $template_id );
		die "Template Semantic Type ($ST_name) differs from ST registered for formal output ($formal_output). Error processing Output Instruction '".$xmlInstr->toString()."'"
			if $formal_output->semantic_type()->name() ne $ST_name;
	}
	# Hackaround for XS variable hidden uniqueness.
	# Similar to IGG's Black Magic encountered in SemanticTypeImport
	# with sql_type. Namely, DB Driver problems with passing a scalar
	# that ends up being an SQL reserved keyword. In both cases, the 
	# problematic scalar started life in a C library. This black magic 
	# is necessary for NaN data coming from matlab handler, but not for
	# NaN  data coming from perl code.
	# $value = 'NAN' if uc( $value ) eq 'NAN'; was solving this problem
	# This leads me to conclude that the underlying data objects differ and 
	# this difference is hidden in the high level view that perl provides. 
	# A generalized solution is to place the value in quotes. This forces perl
	# to cast it into a string and reinterpret that as a scalar. This strips 
	# any and all XS uniqueness from variables.
	#   -Josiah
	$data_hash->{ $SEforScalar } = "$value";

	logdbg "debug", "MatlabScalar_to_Attr: Trying to make a new attribute for formal output ".
		$formal_output->name()." using data:\n\t".join( ', ', map( $_.' => '.$data_hash->{$_}, keys %$data_hash ) );

	# Actually make the output
	$self->newAttributes( $formal_output, $data_hash );	
}

=head2 MatlabStruct_to_Attr

	$self->MatlabStruct_to_Attr( $xmlInstr );

	given a <Struct> output instruction, will convert a matlab output to an 
	attribute. Uses 

=cut

sub MatlabStruct_to_Attr {
	my ( $self, $xmlInstr ) = @_;

 	my $formal_output = $self->getFormalOutput( $xmlInstr->getAttribute( 'FormalOutput' ) )
 		or die "Formal output could not be found. Error processing output: ".$xmlInstr->toString();

	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
 	my $matlab_output = $self->{__engine}->getVariable( $matlab_var_name )
 		or die "Couldn't retrieve $matlab_var_name";
 	$matlab_output->makePersistent();

	# Loop through outputs in the list
	foreach my $data_hash( @{ $matlab_output->convertToListOfHashes() } ) {
		$self->newAttributes( $formal_output, $data_hash );
	}

}

=head1 XML navigation

These are high level functions to navigate the xml doc.
Hopefully they will serve to isolate xml syntax

=head2 _functionInputs

	my @input_list = $self->_functionInputs();

	get a list of XML instructions for function inputs.

=cut

sub _functionInputs { return shift->{ execution_instructions }->findnodes( "MLI:FunctionInputs/MLI:Input/*" ); }

=head2 _functionOutputs

	my @output_list = $self->_functionOutputs();

	get a list of XML instructions for function outputs.

=cut

sub _functionOutputs { return shift->{ execution_instructions }->findnodes( "MLI:FunctionOutputs/MLI:Output/*" ); }

=head2 _getTemplateData

	my ($ST_name, $data_hash) = $self->_getTemplateData( $template_id );
	
	given a template id, retrieves the ST & data for it.

=cut

sub _getTemplateData {
	my ( $self, $template_id ) = @_;
	my @matches = $self->{ execution_instructions }->findnodes( 'MLI:Templates/*[@ID="'.$template_id.'"]' );
	die "Multiple templates with template_id '$template_id' found" if scalar( @matches ) > 1;
	die "No template with template_id '$template_id' found" if scalar( @matches ) eq 0;
	my $template = $matches[0];

	my $factory	= $self->Factory();
	my $ST = $factory->findObject( "OME::SemanticType", name => $template->tagName() )
		or die "Template is not a known semantic type. '".$template->toString()."'";
	my $data_hash;
	foreach my $SE ( $ST->semantic_elements() ) {
		my $SE_name = $SE->name();
		# Find the value of the semantic element $attrCol.
		# The first place to look is in an attribute
		$data_hash->{$SE_name} = $template->getAttribute($SE_name);
		# The second place to look is in a subNode
		if (not defined $data_hash->{$SE_name} and $template->getElementsByLocalName( $SE_name )->size() > 0) {
			$data_hash->{$SE_name} = $template->getElementsByLocalName( $SE_name )->[0]->firstChild()->data()
		}
		my $sql_type = $SE->data_column()->sql_type();
		if ($sql_type eq 'reference') {
# FIXME: deal with references
		} elsif ($sql_type eq 'boolean') {
			if (defined $data_hash->{$SE_name}) {
				$data_hash->{$SE_name} = $data_hash->{$SE_name} eq 'true' ? '1' : '0';
			} else {
				$data_hash->{$SE_name} = undef;
			}
		} elsif ($sql_type eq 'timestamp') {
			$data_hash->{$SE_name} = XML2ODBC_timestamp ($data_hash->{$SE_name});
		}
	}
	return( $template->tagName(), $data_hash );
}

=head1 Internal utility functions

=head2 XML2ODBC_timestamp

	nabbed from OME::ImportExport::HierarchyImport in order to support templates

=cut

sub XML2ODBC_timestamp () {
	my $value = shift;
	return undef unless $value;
	my ($date,$time,$timezone);
	$date = $1 if $value =~ /^(\d\d\d\d-\d\d-\d\d)/;
	if ($value =~ /(\d\d:\d\d:\d\d(\.\d+)?)(([+-]\d\d?(:\d\d)?)|Z)?$/) {
		$time = defined $1 ? $1 : '';
		$timezone = defined $3 ? $3 : '';
	}
	if ($timezone =~ /[+-]\d\d?$/) {
		$timezone .= ':00';
	}
	
	return $date.' '.$time.$timezone if $date and $time;
	return undef;
}

=head2 _inputVarName

	my $matlab_variable_name = $self->_inputVarName( $xmlInputInstruction );
	
	returns a name unique to each instruction presented. Used to coordinate
	activity across functions.

=cut

sub _inputVarName {
	my ($self, $xml_instruction ) = @_;
	return $self->{ __inputVariableNames }->{ $xml_instruction->toString() }
		if exists $self->{ __inputVariableNames }->{ $xml_instruction->toString() };
	my $name = 'ome_input_'.scalar( keys( %{ $self->{ __inputVariableNames } } ) );
	$name .= '_'.$xml_instruction->getAttribute( 'ID' )
		if( $xml_instruction->getAttribute( 'ID' ) );
	$self->{ __inputVariableNames }->{ $xml_instruction->toString() } = $name;
	return $name;
}

=head2 _outputVarName

	my $matlab_variable_name = $self->_outputVarName( $xmlInputInstruction );
	
	returns a name unique to each instruction presented. Used to coordinate
	activity across functions.

=cut

sub _outputVarName {
	my ($self, $xml_instruction ) = @_;
	return $self->{ __outputVariableNames }->{ $xml_instruction->toString() }
		if exists $self->{ __outputVariableNames }->{ $xml_instruction->toString() };
	my $name = 'ome_output_'.scalar( keys( %{ $self->{ __outputVariableNames } } ) );
	$name .= '_'.$xml_instruction->getAttribute( 'ID' )
		if( $xml_instruction->getAttribute( 'ID' ) );
	$self->{ __outputVariableNames }->{ $xml_instruction->toString() } = $name;
	return $name;
}

=head2 __openEngine

Starts up the Matlab interface (OME::Matlab::Engine)

=cut

sub __openEngine {
	my ($self) = @_;

	if (!$self->{__engineOpen}) {
		my $engine = OME::Matlab::Engine->open("matlab -nodisplay -nojvm");
		die "Cannot open a connection to Matlab!" unless $engine;
		$self->{__engine} = $engine;
		$self->{__engineOpen} = 1;
		my $session = OME::Session->instance();
		my $conf = $session->Configuration() or croak "couldn't retrieve Configuration variables";
		my $matlab_src_dir = $conf->matlab_src_dir or croak "couldn't retrieve matlab src dir from configuration";
		print STDERR "matlab src dir is $matlab_src_dir\n";
		$engine->eval("addpath(genpath('$matlab_src_dir'));");
	}
}

=head2 __closeEngine

Shuts down the Matlab interface (OME::Matlab::Engine)

=cut

sub __closeEngine {
	my ($self) = @_;

	if ($self->{__engineOpen}) {
		$self->{__engine}->close();
		$self->{__engine} = undef;
		$self->{__engineOpen} = 0;
	}
}

=head2 __checkExecutionGranularity

There are constraints on execution granularity that are not specified in
the MLI schema. This function applies those constraints.

=cut

sub __checkExecutionGranularity {
	my $self = shift;
	my $factory = $self->Factory();
	
	my $granularity = $self->{ execution_instructions }->getAttribute( "ExecutionGranularity" )
		or die "ExecutionGranularity not specified in <ExecutionInstructions>";
	my %granularity_name_list = (
		F => 'Feature',
		I => 'Image',
		D => 'Dataset',
		G => 'Global'
	);
	my $granularity_name = $granularity_name_list{ $granularity };
	
	die "Cannot Execute with $granularity_name Granularity without either $granularity_name inputs or outputs"
		unless( 
			$factory->countObjects('OME::Module::FormalInput', {
				module => $self->getModule(),
				'semantic_type.granularity' => $granularity,
			}) ||
			$factory->countObjects('OME::Module::FormalOutput', {
				module => $self->getModule(),
				'semantic_type.granularity' => $granularity,
			})
		);
	# FIXME: It's illegal to have execution granularity finer than the coursest output granularity. Check for this.
	
	return $granularity;
}

=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)
based on code written by Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::Matlab>, L<OME::Matlab::Engine>, 
L<http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd|specification of XML instructions>

=cut


1;
