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

Boo.

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

sub getCurrentImage { return shift->{_current_image}; }
sub getCurrentFeature { return shift->{_current_feature}; }

# These are high level functions to navigate the xml doc.
# Hopefully they will serve to isolate xml syntax
sub _functionInputs { return shift->{ execution_instructions }->findnodes( "MLI:FunctionInputs/MLI:Input/*" ); }
sub _functionOutputs { return shift->{ execution_instructions }->findnodes( "MLI:FunctionOutputs/MLI:Output/*" ); }
sub _getTemplate { 
	my ( $self, $template_id ) = @_;
	my @matches = $self->{ execution_instructions }->findnodes( 'MLI:Templates/*[@ID="'.$template_id.'"]' );
	die "Multiple templates with template_id '$template_id' found" if scalar( @matches ) > 1;
	die "No template with template_id '$template_id' found" if scalar( @matches ) eq 0;
	return $matches[0];
}

# my ($ST_name, $data_hash) = $self->_getTemplateData( $template_id );
sub _getTemplateData {
	my ( $self, $template_id ) = @_;
	my $template = $self->_getTemplate( $template_id )
		or return (undef, undef);

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


# For testing purposes -- make an instance that does not call it's
# superclass constructor.  Beware: this instance will not be a valid
# analysis module, though it will allow you to call all of the Matlab-
# related helper functions and test them.

sub newtest {
	my ($proto) = @_;
	my $class = ref($proto) || $proto;

	my $self = {};
	$self->{__engine} = undef;
	$self->{__engineOpen} = 0;

	bless $self,$class;
	return $self;
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);

	$self->{__engine} = undef;
	$self->{__engineOpen} = 0;
	
	# FIXME: describe interfaces to these functions once things have stabalized

	# List of functions in this package make matlab global variables from input execution instructions
	# Keyed by Tag name of elements under 'FunctionInputs'
	$self->{ _translate_to_matlab } = {
		PixelsInput => 'Pixels_to_MatlabArray',
#		Scalar => 'Attr_to_MatlabScalar',
#		Struct => 'Attr_to_MatlabStruct'
	};
	
	# List of package functions to make ome attributes from output execution instructions
	# Keyed by Tag name of elements under 'FunctionOutputs'
	$self->{ _translate_from_matlab } = {
		PixelsOutput => 'MatlabArray_to_Pixels',
		Scalar       => 'MatlabScalar_to_Attr',
		Struct       => 'MatlabStruct_to_Attr'
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
	$root->setAttribute( "xmlns:MLI", "http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd" );
	
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
		$engine->eval("addpath(genpath('$matlab_src_dir'));");
	}
}

sub __closeEngine {
	my ($self) = @_;

	if ($self->{__engineOpen}) {
		$self->{__engine}->close();
		$self->{__engine} = undef;
		$self->{__engineOpen} = 0;
	}
}

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

# return matlab variable name for an input
sub _inputVarName {
	my ($self, $input_instruction ) = @_;
	return 'ome_input_'.$input_instruction->getAttribute( 'ID' );
}
# return matlab variable name for an output
sub _outputVarName {
	my ($self, $output_instruction ) = @_;
	return 'ome_output_'.$output_instruction->getAttribute( 'ID' );
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

# There are constraints on execution granularity that are not specified in the MLI schema.
# This function applies those constraints.
sub __checkExecutionGranularity {
	my $self = shift;
	my $factory = $self->Factory();
	
	my $granularity = $self->{ execution_instructions }->getAttribute( "ExecutionGranularity" );
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

# FIXME: Test this function
# Translate a matlab 5d array into a Pixels attribute & image server object.
# the guts of this were written by Tomasz
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

# Translate a Pixels input into a matlab 5d array.
# the guts of this were written by Tomasz
sub Pixels_to_MatlabArray {
	my ( $self, $xmlInstr ) = @_;
	my $session = OME::Session->instance();
	
	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
	my $formal_input = $self->getFormalInput( $xmlInstr->getAttribute( 'FormalInput' ) );
	my @pixel_attr_list = $self->getCurrentInputAttributes( $formal_input );
	
	foreach my $pixels (@pixel_attr_list) {
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
}

sub MatlabScalar_to_Attr {
	my ( $self, $xmlInstr ) = @_;

	# gather formal output & SE
 	my $output_location = $xmlInstr->getAttribute( 'OutputLocation' );
 	my ($formal_output, $SEforScalar);
 	if( $output_location =~ m/^(\w+)\.(\w+)$/ ) {
 		$SEforScalar = $2;
 		my $formal_output_name = $1;
 		$formal_output = $self->getFormalOutput( $1 )
 			or die "Could not find formal output '$formal_output_name' (from output location '$output_location').";
 	} else {
 		die "output_location '$output_location' could not be parsed.";
 	}

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
	$data_hash->{ $SEforScalar } = $value;

	# Actually make the output
	$self->newAttributes( $formal_output, $data_hash );	
}

# FIXME: add <Struct> to the schema
# Outputs that are Structures: Map directly to OME attrs
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

# FIXME: Develop an XML tag for this & implement the function. The majority of the code already exists.
# Note: This is not pressing.
sub Attr_to_MatlabStruct {
	my ( $self, $xmlInstr ) = @_;
	
# OLD code for making Matlab structure array from list of attributes
# 	my @elements = $semantic_type->semantic_elements();
# 	my @names = ('id', map( $_->name(), @elements ) );
# 	$struct = OME::Matlab::Array->
# 		newStructMatrix(1,$num_attributes,\@names);
# 	$struct->makePersistent();
# 	die "Could not create struct" unless $struct;
#   
# 	foreach my $attribute (@$attribute_list) {
# 		$self->__createAttribute($struct,$attr_idx,$variable_name,
# 								 $attribute,\@elements);
# 	} continue {
# 		$attr_idx++;
# 	};
# 	logdbg "debug", "**** Done Creating Matlab struct\n";
# 
# 	my $matlab_name = "ome_${variable_name}";
# 	logdbg "debug", "putting $matlab_name\n\n";
# 	$self->{__engine}->eval("global $matlab_name");
# 	$self->{__engine}->putVariable($matlab_name,$struct);

# MORE OLD code for translating OME Attrs into Matlab structures
# sub __createAttribute {
# 	my ($self,$struct,$attr_idx,$attr_name,$attribute,$elements) = @_;
# 
# 	# Add the primary key ID to the attribute struct
# 	my $array = OME::Matlab::Array->newDoubleScalar($attribute->id());
# 	$array->makePersistent();
# 	$struct->setField($attr_idx,0,$array);
# 
# 	my $references = $self->{__references};
# 
# 	my $elem_idx = 1;
# 	foreach my $element (@$elements) {
# 		my $name = $element->name();
# 		logdbg "debug", "$name = ";
# 
# 		my $value = $attribute->$name();
# 		my $sql_type = $element->data_column()->sql_type();
# 
# 		my $array;
# 		if (defined $value) {
# 			if ($sql_type eq 'string') {
# 				logdbg "debug", "New string $value\n";
# 				$array = OME::Matlab::Array->newStringScalar($value);
# 				$array->makePersistent();
# 			} elsif ($sql_type eq 'boolean') {
# 				logdbg "debug", "New logical $value\n";
# 				$array = OME::Matlab::Array->newLogicalScalar($value);
# 				$array->makePersistent();
# 			} elsif ($sql_type eq 'reference') {
# 				my $reference_name = "${attr_name}.${name}";
# 				if (exists $references->{$reference_name}) {
# 					logdbg "debug", "New reference ",$value->id(),"\n";
# 					$array = $self->
# 					  __createReferenceAttribute($reference_name,$value);
# 				} else {
# 					logdbg "debug", "New unneeded reference ",$value->id(),"\n";
# 					$array = OME::Matlab::Array->newDoubleScalar($value->id());
# 					$array->makePersistent();
# 				}
# 			} else {
# 				logdbg "debug", "New double $value\n";
# 				$array = OME::Matlab::Array->newDoubleScalar($value);
# 				$array->makePersistent();
# 			}
# 			logdbg "debug", "[$sql_type] '$value'\n";
# 		} else {
# 			logdbg "debug", "[Undefined]\n";
# 		}
# 
# 		$struct->setField($attr_idx,$elem_idx,$array)
# 		  if defined $array;
# 	} continue {
# 		$elem_idx++;
# 	};
# }
# 
# sub __createReferenceAttribute {
# 	my ($self,$name,$attribute) = @_;
# 
# 	my $semantic_type = $attribute->semantic_type();
# 	my @elements = $semantic_type->semantic_elements();
# 	my @names = ('id');
# 	push @names, $_->name() foreach @elements;
# 
# 	my $struct = OME::Matlab::Array->
# 	  newStructMatrix(1,1,\@names);
# 	die "Could not create struct"
# 	  unless $struct;
# 
# 	# Matlab will free this itself, so we need to make sure that the
# 	# DESTROY method does not try to also free the memory.	This is
# 	# true of the arrays we create in the next loop, too.
# 	$struct->makePersistent();
# 
# 	$self->__createAttribute($struct,0,$name,$attribute,\@elements);
# 
# 	return $struct;
# }
}

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

1;
