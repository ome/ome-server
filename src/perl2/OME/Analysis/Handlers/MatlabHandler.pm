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
		Scalar		=> 'Attr_to_MatlabScalar',
	};
	
	# List of package functions to make ome attributes from output execution instructions
	# Keyed by Tag name of elements under <Output>
	$self->{ _translate_from_matlab } = {
		PixelsArray => 'MatlabArray_to_Pixels',
		Scalar		=> 'MatlabScalar_to_Attr',
		Vector		=> 'MatlabVector_to_Attrs',
		Struct		=> 'MatlabStruct_to_Attr'
	};

	# Mapping from Pixel Types to matlab class bindings
	$self->{ _pixel_type_to_matlab_class } = {
		uint8  => $mxUINT8_CLASS,
		uint16 => $mxUINT16_CLASS,
		uint32 => $mxUINT32_CLASS,
		float  => $mxSINGLE_CLASS,
	};
	
	# Mapping from matlab classes to pixel types. Also limits the supported matlab classes.
	$self->{ _matlab_class_to_pixel_type } = {
		uint8  => 'uint8',
		uint16 => 'uint16',
		uint32 => 'uint32',
		single => 'float'
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
Additionally, they need to record the number of inputs they find:
	$xmlInstr->setAttribute( 'ActualArity', scalar( @input_attr_list ) );
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
Also handles PixelsSlice & other psuedo subclasses of Pixels.
Implements <PixelsArray>
The guts of this were written by Tomasz

=cut

sub Pixels_to_MatlabArray {
	my ( $self, $xmlInstr ) = @_;
	my $session = OME::Session->instance();
	
	# Gather the actual input. It may be a Pixels or it may inherit from Pixels
	my $formal_input = $self->getFormalInput( $xmlInstr->getAttribute( 'FormalInput' ) )
		or die "Could not find FormalInput referenced by ".$xmlInstr->toString();
	my @input_attr_list = $self->getCurrentInputAttributes( $formal_input );
	die "The OME-Matlab interface does not support Formal inputs of arity greater than 1 at this time. Found ".scalar(@input_attr_list)." inputs. Error when processing\n".$xmlInstr->toString()
		if ( scalar @input_attr_list > 1);

	# ActualArity is needed to cope with optional inputs.
	$xmlInstr->setAttribute( 'ActualArity', scalar( @input_attr_list ) );
	return if scalar( @input_attr_list ) eq 0;
	my $input = $input_attr_list[0];

	# Find the pixels, the extents, and the dimensions of this Pixels derivative.
	my (@ROI, @Dims);
	my $pixels;
	my $ascender = $input;
	FIND_PIXELS: while( 1 ) {
		if( $ascender->semantic_type->name eq 'Pixels' ) {
			$pixels = $ascender;
			# if the derivation path did not include PixelsSlice, then Dims needs to be populated.
			@Dims = (
				$pixels->SizeX,
				$pixels->SizeY,
				$pixels->SizeZ,
				$pixels->SizeC,
				$pixels->SizeT
			) unless( @Dims );
			last FIND_PIXELS;
		} elsif ( $ascender->semantic_type->name eq 'PixelsSlice' ) {
			@Dims = (
				$ascender->EndX - $ascender->StartX + 1,
				$ascender->EndY - $ascender->StartY + 1,
				$ascender->EndZ - $ascender->StartZ + 1,
				$ascender->EndC - $ascender->StartC + 1,
				$ascender->EndT - $ascender->StartT + 1,
			) unless( @Dims );
			@ROI = (
				$ascender->StartX, 
				$ascender->StartY, 
				$ascender->StartZ, 
				$ascender->StartC, 
				$ascender->StartT, 
				$ascender->EndX, 
				$ascender->EndY, 
				$ascender->EndZ, 
				$ascender->EndC, 
				$ascender->EndT, 
			);
		}
		# if we are here, we have not found the pixels yet. die if the ascent can go no further.
		die "Input ".$input->semantic_type->name." (id=".$input->id.") does not inherit from Pixels."
		    unless $ascender->can( 'Parent' );
		$ascender = $ascender->Parent();
	}
	
	# Ensure PixelType is supported.
	my $pixelType = $pixels->PixelType();
	die "The OME-Matlab interface does not support $pixelType at this time."
		unless exists $self->{ _pixel_type_to_matlab_class }->{ $pixelType };
	my $class = $self->{ _pixel_type_to_matlab_class }->{ $pixelType };

	# Get the Pixels data into a local file.
	# FIXME: PixelsManager->getLocalFile( $pixels ) should implement the 
	#	 functionality below without loading the whole pixels array into RAM
	#    and taking endianess into consideration
	my $filename = $session->getTemporaryFilename("pixels","raw");
	open my $pix, ">", $filename or die "Could not open local pixels file";
	my $buf = ( @ROI ?
		OME::Image::Server->getROI($pixels->ImageServerID(), @ROI ) : 
		OME::Image::Server->getPixels($pixels->ImageServerID())
	);
	print $pix $buf;
	close $pix;
  	
	# Get that file into Matlab.
	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
	my $matlab_pixels = OME::Matlab::Array->newNumericArray(
		$class,
		$mxREAL,
		@Dims
	) or die "Could not make an array in matlab for Pixels";
	$matlab_pixels->makePersistent();
	$self->{__engine}->eval("global $matlab_var_name");
	$self->{__engine}->putVariable($matlab_var_name,$matlab_pixels);
	# magic one-liner. One liner means no variables are left in matlab's workplace
	# this one-liner fills an array from the temp file
	$self->{__engine}->eval("[$matlab_var_name, nPix] = fread(fopen('$filename', 'r'), size($matlab_var_name),'$pixelType');");

	# Cleanup
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

	# ActualArity is needed to cope with optional inputs.
	$xmlInstr->setAttribute( 'ActualArity', scalar( @$input_attr ) );
	return if scalar( @$input_attr ) eq 0;
	die scalar( @$input_attr )." attributes found for input '$formal_input_name'. ".
		'Cannot use scalar for input that has count greater than 1. '.scalar( @$input_attr ).' Inputs found. Error when processing \''.$xmlInstr->toString()."'"
		if scalar( @$input_attr ) > 1;
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
	my $factory = $session->Factory();
	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
	my $formal_output = $self->getFormalOutput( $xmlInstr->getAttribute( 'FormalOutput' ) )
		or die "Could not find formal output referenced from ".$xmlInstr->toString();
	
	# Get array's dimensions.
	$self->{__engine}->eval("[sizeX,sizeY,sizeZ,sizeC,sizeT] = size($matlab_var_name)");
	my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT) = 
		($self->{__engine}->getVariable('sizeX')->getScalar(),
		 $self->{__engine}->getVariable('sizeY')->getScalar(),
		 $self->{__engine}->getVariable('sizeZ')->getScalar(),
		 $self->{__engine}->getVariable('sizeC')->getScalar(),
		 $self->{__engine}->getVariable('sizeT')->getScalar());
	
	# Get pixel type
	$self->{__engine}->eval("str = class($matlab_var_name)");
	my $type = $self->{__engine}->getVariable('str')->getScalar();
	die "Pixels of Matlab class $type are not supported at this time"
		unless exists $self->{ _matlab_class_to_pixel_type }->{ $type };
	my $pixelType = $self->{ _matlab_class_to_pixel_type }->{ $type };
	
	# Make Pixels
	my ($pixels_data, $pixels_attr) = OME::Tasks::PixelsManager->createPixels(
		$self->getCurrentImage(), 
		$self->getModuleExecution(),
		{
			SizeX		 => $sizeX,
			SizeY		 => $sizeY,
			SizeZ		 => $sizeZ,
			SizeC		 => $sizeC,
			SizeT		 => $sizeT,
			PixelType	 => $pixelType
		},
		( $formal_output->semantic_type->name ne 'Pixels' ? 1 : undef )
	);
	
	# Shovel data into image server via tmp file
	my $filename = $session->getTemporaryFilename("pixels","raw");
	$self->{__engine}->eval("fwrite(fopen('$filename','w'),$matlab_var_name, class($matlab_var_name))");
	my $pixelsWritten = $pixels_data->setPixelsFile($filename,1);
	$session->finishTemporaryFile($filename);

	# Finalize Pixels
	my $pixelsID = OME::Tasks::PixelsManager->finishPixels($pixels_data, $pixels_attr);
	OME::Tasks::PixelsManager->saveThumb($pixels_attr);
	
	# Deal with subclassing. This code has both hardcoded and implicit 
	# dependencies on the structure of STs that subclass Pixels. It assumes that
	# PixelsSlice is the only subclass of Pixels that has additional data fields,
	# and that every other ST that inherits (directy or indirectly) will only
	# have a Parent field. If a PixelsSlice is part of the inheritence chain,
	# its limits will be set the extent of the image.
	my $current_ST = $formal_output->semantic_type();
	my $last_attribute;
	# traverse the inheritence path from the bottom up.
	# Create an attribute for each step along the way, set the Parent element
	# on the subsequent iteration.
	while( $current_ST->name() ne 'Pixels' ) {
		# Make a new attribute
		my $new_attr;
		my @factory_params = ( $current_ST, $self->getCurrentImage(), $self->getModuleExecution() );			
		if( $current_ST->name() eq 'PixelsSlice' ) {
			push( @factory_params, {
				StartX => 0,
				StartY => 0,
				StartZ => 0,
				StartC => 0,
				StartT => 0,
				EndX   => $pixels_attr->SizeX() - 1,
				EndY   => $pixels_attr->SizeY() - 1,
				EndZ   => $pixels_attr->SizeZ() - 1,
				EndC   => $pixels_attr->SizeC() - 1,
				EndT   => $pixels_attr->SizeT() - 1,
				Parent => $pixels_attr
			} );
		} else {
			# All the other Pixels derivatives only have a Parent SE, and we haven't
			# made the parent yet. Thus, the data hash is empty.
			push( @factory_params, { } );
		}
		
		# if last attribute is defined, then we're making a parent attribute
		if( $last_attribute ) {	$new_attr = $factory->newParentAttribute( @factory_params ); } 
		# otherwise, we're making the function output.
		else { $new_attr = $factory->newAttribute( @factory_params ); } 
		
		# Now that we have made a new attribute, use it to satisfy the Parent
		# field of the last attribute.
		if( $last_attribute ) {
			$last_attribute->Parent( $new_attr );
			$last_attribute->storeObject();
		}
		# Update for next loop iteration
		$last_attribute = $new_attr; 
		
		# Take the next step up the ancestry chain
		my $parent_element = $factory->findObject( 
			'OME::SemanticType::Element', 
			{
				semantic_type => $current_ST,
				name          => 'Parent'
			} ) or die "Could not find a parent for ST ".$current_ST->name()." when trying to construct Pixels Parental outputs.";
		$current_ST = $factory->findObject(
			'OME::SemanticType',
			{ name => $parent_element->data_column()->reference_type() }
		) or die "Could not find ST named ".$parent_element->data_column()->reference_type()." when trying to construct Pixels Parental outputs.";
	}
	
}

=head2 MatlabVector_to_Attrs

Operates on vector matlab outputs. Uses <Vector> in conjuction with
<VectorDecoding> and <Templates>. Use this for making a record block.

=cut

sub MatlabVector_to_Attrs {
	my ( $self, $xmlInstr ) = @_;

	# Retrieve value from matlab
	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
	my $matlab_output = $self->{__engine}->getVariable( $matlab_var_name )
		or die "Couldn't retrieve $matlab_var_name";
	$matlab_output->makePersistent();
	my $values = $matlab_output->convertToList();

	# get Vector Decoding
	my $vectorDecodeID = $xmlInstr->getAttribute( 'DecodeWith' )
		or die "DecodeWith attribute not specified in ".$xmlInstr->toString();
	my @decoding_elements = $self->{ execution_instructions }->findnodes( 
		'MLI:VectorDecoder[@ID="'.$vectorDecodeID.'"]/MLI:Element' );

	# decode the Vector
	my @vectorData;
	foreach my $element ( @decoding_elements ) {
		# gather formal output & SE
		my $output_location = $element->getAttribute( 'OutputLocation' );
		my ( $formal_output_name, $SE_name ) = split( /\./, $output_location )
			or die "output_location '$output_location' could not be parsed.";
		my $formal_output = $self->getFormalOutput( $formal_output_name )
			or die "Could not find formal output '$formal_output_name' (from output location '$output_location').";
	
		# Make a data hash
		my $template_id = $xmlInstr->getAttribute( 'UseTemplate' );
		my $data_hash;
		if( $template_id ) {
			my $ST_name;
			($ST_name, $data_hash) = $self->_getTemplateData( $template_id );
			die "Template Semantic Type ($ST_name) differs from ST registered for formal output ($formal_output). Error processing Output Instruction '".$xmlInstr->toString()."'"
				if $formal_output->semantic_type()->name() ne $ST_name;
		}
		# See: "Hackaround for XS variable hidden uniqueness." in MatlabScalar_to_Attr()
		my $index = $element->getAttribute( 'Index' )
			or die "Index attribute not specified in ".$element->toString();
		my $value = $values->[ $index - 1 ];
		$data_hash->{ $SE_name } = "$value";
	
		logdbg "debug", "MatlabVector_to_Attrs: Adding an output to the list. Formal output: ".
			$formal_output->name()." using data:\n\t".join( ', ', map( $_.' => '.$data_hash->{$_}, keys %$data_hash ) );
		push ( @vectorData, $formal_output, $data_hash );
	}
	
	# Actually make the outputs
	$self->newAttributes( @vectorData ); 
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
	#	-Josiah
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

sub _functionInputs { return shift->{ execution_instructions }->findnodes( 'MLI:FunctionInputs/MLI:Input/*[not( @ActualArity ) or (@ActualArity != 0)]' ); }

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

	my $factory = $self->Factory();
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
	my $name = 'ome_input'.scalar( keys( %{ $self->{ __inputVariableNames } } ) );
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
