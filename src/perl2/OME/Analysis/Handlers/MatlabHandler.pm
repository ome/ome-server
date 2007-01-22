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
#			   Tom Macura <tmacura@nih.gov>
#			   Arpun Nagaraja <arpun@mit.edu>
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
use Switch;

use OME;
use XML::LibXML;
use Log::Agent;
our $VERSION = $OME::VERSION;

use OME::Matlab;
use OME::Tasks::PixelsManager;
use OME::Analysis::Handler;
use OME::Session;
use OME::ModuleExecution;
use OME::Install::Environment;
#use Devel::Peek; # for debugging the OME::Matlab XS library

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
#use fields qw(__engine __engineOpen);
use Time::HiRes qw(gettimeofday tv_interval);

my $supported_NS = 'http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd';

#############
# CONSTANTS #
#############
my $_environment = initialize OME::Install::Environment;

# List of functions in this package make matlab global variables from input execution instructions
# Keyed by Tag name of elements under <Input>
my %_translate_to_matlab = (
	PixelsArray    => 'Pixels_to_MatlabArray',
	Scalar         => 'Attr_to_MatlabScalar',
	ConstantScalar => 'Constant_to_MatlabScalar',
);

# List of package functions to make ome attributes from output execution instructions
# Keyed by Tag name of elements under <Output>
my %_translate_from_matlab = (
	PixelsArray => 'MatlabArray_to_Pixels',
	Scalar		=> 'MatlabScalar_to_Attr',
	Vector		=> 'MatlabVector_to_Attrs',
	Struct		=> 'MatlabStruct_to_Attr'
);

# Mapping from OME Pixel Types to matlab classes
my %_pixel_type_to_matlab_class = (
	int8   => $mxINT8_CLASS,
	uint8  => $mxUINT8_CLASS,
	int16  => $mxINT16_CLASS,
	uint16 => $mxUINT16_CLASS,
	int32  => $mxINT32_CLASS,
	uint32 => $mxUINT32_CLASS,
	float  => $mxSINGLE_CLASS,
);
	
# Mapping from matlab classes to pixel types. Also limits the supported matlab classes.
my %_matlab_class_to_pixel_type = (
	$mxINT8_CLASS   => 'int8',
	$mxUINT8_CLASS  => 'uint8' ,
	$mxINT16_CLASS  => 'int16',
	$mxUINT16_CLASS => 'uint16',
	$mxINT32_CLASS  => 'int32',
	$mxUINT32_CLASS => 'uint32',
	$mxSINGLE_CLASS => 'float' ,
);

# Mapping from matlab classes to Matlab convert function name
my %_matlab_class_to_convert = (
	$mxLOGICAL_CLASS   => 'logical',
	$mxDOUBLE_CLASS    => 'double',
	$mxSINGLE_CLASS    => 'single',
	$mxINT8_CLASS      => 'int8',
	$mxUINT8_CLASS     => 'uint8',
	$mxINT16_CLASS     => 'int16',
	$mxUINT16_CLASS    => 'uint16',
	$mxINT32_CLASS     => 'int32',
	$mxUINT32_CLASS    => 'uint32',
	$mxINT64_CLASS     => 'int64',
	$mxUINT64_CLASS    => 'uint64',
);

# Mapping from convert function names to matlab classes
my %_convert_to_matlab_class = (
	'logical' => $mxLOGICAL_CLASS, 
	'double'  => $mxDOUBLE_CLASS,
	'single'  => $mxSINGLE_CLASS, 
	'int8'    => $mxINT8_CLASS, 
	'uint8'   => $mxUINT8_CLASS, 
	'int16'   => $mxINT16_CLASS,
	'uint16'  => $mxUINT16_CLASS,
	'int32'   => $mxINT32_CLASS, 
	'uint32'  => $mxUINT32_CLASS, 
	'int64'   => $mxINT64_CLASS,
	'uint64'  => $mxUINT64_CLASS, 
);

# Mapping from matlab classes to strings for display purposes
my %_matlab_class_to_string = (
	$mxUNKNOWN_CLASS   => 'mxUNKNOWN_CLASS',
	$mxCELL_CLASS      => 'mxCELL_CLASS',
	$mxSTRUCT_CLASS    => 'mxSTRUCT_CLASS',
	$mxOBJECT_CLASS    => 'mxOBJECT_CLASS',
	$mxCHAR_CLASS      => 'mxCHAR_CLASS',
	$mxLOGICAL_CLASS   => 'mxLOGICAL_CLASS',
	$mxDOUBLE_CLASS    => 'mxDOUBLE_CLASS',
	$mxSINGLE_CLASS    => 'mxSINGLE_CLASS',
	$mxINT8_CLASS      => 'mxINT8_CLASS',
	$mxUINT8_CLASS     => 'mxUINT8_CLASS',
	$mxINT16_CLASS     => 'mxINT16_CLASS',
	$mxUINT16_CLASS    => 'mxUINT16_CLASS',
	$mxINT32_CLASS     => 'mxINT32_CLASS',
	$mxUINT32_CLASS    => 'mxUINT32_CLASS',
	$mxINT64_CLASS     => 'mxINT64_CLASS',
	$mxUINT64_CLASS    => 'mxUINT64_CLASS',
	$mxFUNCTION_CLASS  => 'mxFUNCTION_CLASS',
);

# Mappings from matlab classes to OME SE datatypes
my %_matlab_class_to_ome_datatype = (
	$mxCHAR_CLASS      => 'string',
	$mxLOGICAL_CLASS   => 'boolean',
	$mxDOUBLE_CLASS    => 'double',
	$mxSINGLE_CLASS    => 'float',
	$mxINT8_CLASS      => 'smallint',
	$mxUINT8_CLASS     => 'smallint',
	$mxINT16_CLASS     => 'smallint',
	$mxUINT16_CLASS    => 'integer',
	$mxINT32_CLASS     => 'integer',
	$mxUINT32_CLASS    => 'bigint',
	$mxINT64_CLASS     => 'bigint',
);

# Mappings from OME SE datatypes to matlab classes 
my %_ome_datatype_to_matlab_class = (
	'string'   => $mxCHAR_CLASS,
	'boolean'  => $mxLOGICAL_CLASS,
	'double'   => $mxDOUBLE_CLASS,
	'float'    => $mxSINGLE_CLASS,
	'smallint' => $mxINT16_CLASS,
	'integer'  => $mxINT32_CLASS,
	'bigint'   => $mxINT64_CLASS,
);
my %_numerical_constants; # this gets filled out in __openMatlab()
my %_matlab_variables; # this is added to as needed - stores matlab vars

########################################
# PERSISTENT MATLAB INSTANCE VARIABLES #
########################################
my $_matlabOpen = 0;
my %_matlab_instances; # hash of matlab instances (i.e. engine, library instances)

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);

	$self->{__inputVariableNames} = {};
	$self->{__outputVariableNames} = {};

	my $factory = OME::Session->instance()->Factory();
 	
	$self->__openMatlab();

	bless $self,$class;
	return $self;
}

sub startAnalysis {
	my ($self,$module_execution) = @_;
	
	my $parser = XML::LibXML->new();
	my $tree   = $parser->parse_string( $self->getModule()->execution_instructions() );
	my $root   = $tree->getDocumentElement();
	
	$self->{ execution_instructions } = $root;
	
	# Use a compiled library if requested
	my $libname = $self->{ execution_instructions }->getAttribute( "LibraryName" );
	
	# If you want to use a library and you haven't already instantiated an instance,
	# do it
	if (defined $libname and not exists $_matlab_instances{ $libname } ) {
		my $useDeclaration = 'OME::Matlab::Lib::'.$libname;
		eval "use $useDeclaration";
		if ( $@ ) {
			# There was some kind of error, so report it and instantiate
			# the engine
			logdbg "debug", "Cannot find library $useDeclaration: \n$@";
			$self->__openEngine() unless $_matlab_instances{ 'engine' };
		} else {
			$_matlab_instances{ $libname } = $useDeclaration->new();
		}
	}
	
	my $mex = $self->getModuleExecution();
	$mex->read_time      (0);
	$mex->write_time     (0);
	$mex->execution_time (0);
}

sub startImage {
	my ($self,$image) = @_;
	$self->SUPER::startImage($image);

	if ($self->__checkExecutionGranularity( ) eq 'I') {	
		my $mex = $self->getModuleExecution();
	
		my $start_time = [gettimeofday()];
		$self->placeInputs();
		$mex->read_time(tv_interval($start_time));
		
		$self->__execute() ;
		
		$start_time = [gettimeofday()];
		$self->getOutputs();
		$mex->write_time(tv_interval($start_time));
	}
}

sub startFeature {
	my ($self,$feature) = @_;
	$self->SUPER::startFeature($feature);

	if ($self->__checkExecutionGranularity( ) eq 'F') {	
		my $mex = $self->getModuleExecution();
	
		my $start_time = [gettimeofday()];
		$self->placeInputs();
		$mex->read_time($mex->read_time() + tv_interval($start_time));
		
		$self->__execute();
		
		$start_time = [gettimeofday()];
		$self->getOutputs();
		$mex->write_time($mex->write_time() + tv_interval($start_time));
	}
}

sub finishAnalysis {
	my ($self) = @_;
	
	$self->__idleMatlab();
	# this insures a check of output arities
	$self->SUPER::finishAnalysis();
}

sub __execute {
	my ($self) = @_;
	my @response;
	
	my $mex = $self->getModuleExecution();
	my $function = $self->getModule()->location();
			
	my @outputs = $self->_functionOutputs() or die "Couldn't find any outputs!";
	my @output_names = map( $self->_outputVarName( $_ ), @outputs );
	my @input_names = map( $self->_inputVarName( $_ ), $self->_functionInputs() );
	
	# Get the actual mxArrays to pass to the compiled modules
	my @inputs = map( $_matlab_variables{ $_ }, @input_names );
	
	# Use the engine unless we've got a library and it's been loaded
	my $instanceName = $self->{ execution_instructions }->getAttribute( "LibraryName" );
	unless ( $_matlab_instances{ $instanceName } ) {
		$instanceName = 'engine';
		$self->__openEngine() unless $_matlab_instances{ 'engine' };
	}
	logdbg "debug", "Using $instanceName ...\n";
	
	my $start_time = [gettimeofday()];
	@response = $_matlab_instances{ $instanceName }->callMatlab( $function, scalar(@outputs), scalar(@inputs), @inputs );
	$mex->execution_time($mex->execution_time() + tv_interval($start_time));
	$mex->error_message($_matlab_instances{ $instanceName }->getMatlabOutputBuffer()) if ($instanceName eq 'engine');

	# Store the outputs into our hash
	foreach my $out_name ( @output_names ) {
		my $array = shift ( @response );
		defined ($array) or die "Output variable $out_name does not exist.\n".
		       "This typically indicates an error in the execution of the program.\n".
		       "The Module Name is ".$mex->module()->name()." and the Module Execution ID is ".$mex->id().".\n";
		$_matlab_variables{ $out_name } = $array;
	}
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
			unless( exists $_translate_to_matlab{ $input->tagName() } );
		my $translation_function = $_translate_to_matlab{ $input->tagName() };
		$self->$translation_function( $input );
	}
}

=head2 _putScalarToMatlab

	my $array = $self->_putScalarToMatlab( $matlab_var_name, $value, $matlab_class);

Puts a scalar of a particular name, value, and class into a hash that represents
the variables "in Matlab". $matlab_class is optional and will default to double
if unspecified. If specified $matlab_class should be one of the constant
class types defined in OME::Matlab. e.g. $mxDOUBLE_CLASS, $mxLOGICAL_CLASS, etc.

returns an instance of OME::Matlab::Array that has had makePersistent
called on it.

=cut

sub _putScalarToMatlab {
	my ($self, $name, $value, $class) = @_;
	my $array;
	
	$class = $mxDOUBLE_CLASS unless defined $class;
	
	# Place value into matlab
	if ($class == $mxCHAR_CLASS) {
		$array = OME::Matlab::Array->newStringScalar($value);
	} elsif ($class == $mxLOGICAL_CLASS) {
		$array = OME::Matlab::Array->newLogicalScalar($value);
	} else {
		$array = OME::Matlab::Array->newNumericScalar($value, $class);
	}
	
	$array->makePersistent();
	
	# store the mxArray into a hash that's keyed by the name of the matlab var
	$_matlab_variables{ $name } = $array;
	
	return $array;
}

=head2 _getScalarFromMatlab

	my ($value, $class) = $self->_getScalarFromMatlab($matlab_var_name, $convert_to_matlab_class);
	
Gets a scalar of a particular name from the _matlab_variables hash.
$convert_to_matlab_class is an optional parameter that signals what is
the desired output Matlab type. If specified it should be one of the
constant class types defined in OME::Matlab. e.g. $mxDOUBLE_CLASS,
$mxLOGICAL_CLASS, etc.

returns the scalar value of the variable and it's MATLAB type (e.g. $mxDOUBLE_CLASS).

=cut

sub _getScalarFromMatlab {
	my ($self, $name, $convert_class) = @_;
	my $array;
	my @response;
	my @inputs;
	my $mex = $self->getModuleExecution();
	
	# Convert array datatype if requested	
	if (defined $convert_class and defined $_matlab_variables{ $name }) {
		push( @inputs, $_matlab_variables{ $name } );
		@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( $_matlab_class_to_convert{$convert_class}, 
 										1, 1, @inputs );
 		$_matlab_variables{ $name } = shift( @response );
 	}
 	
	$array = $_matlab_variables{ $name };
	defined ($array)
		or die "Scalar output variable $name does not exist.\n".
		       "This typically indicates an error in the execution of the program.\n".
		       "The Module Name is ".$mex->module()->name()." and the Module Execution ID is ".$mex->id().".\n";
	my $value = $array->getScalar();
	my $class = $array->class();

	$value = $self->_trimNumeric ($value, $class);

	return ($value, $class);
}

sub _trimNumeric {
	my ($self, $value, $class) = @_;

	# Don't do trimming on NaNs. Perl v 5.8.6 on OS X & Fedora core 4 doesn't 
	# have numeric support for NaNs, so string equality "eq" is a valid test 
	# here, and numeric equality "==" gives wrong answers.
	# See also: http://perldoc.perl.org/perlop.html#Equality-Operators-equality-equal-equals-operator%2c-equality
	return "$value" if( "$value" eq "nan" or
						"$value" eq "NaN" or
						"$value" eq "NAN");

	# Trimming required to avoid overflow and underflow problems with Postgress	
	if( $class eq $mxDOUBLE_CLASS) {
		if( abs( $value ) < $_numerical_constants{min_double} ) {
			$value = 0;
		} elsif( $value < -1 * $_numerical_constants{max_double} ) {
			$value = $_numerical_constants{double_neg_inf};
		} elsif( $value > $_numerical_constants{max_double} ) {
			$value = $_numerical_constants{double_inf};
		}
	} elsif ( $class == $mxSINGLE_CLASS) {
		if( abs( $value ) < $_numerical_constants{min_single} ) {
			$value = 0;
		} elsif( $value < -1 * $_numerical_constants{max_single} ) {
			$value = $_numerical_constants{single_neg_inf};
		} elsif( $value > $_numerical_constants{max_single} ) {
			$value = $_numerical_constants{single_inf};
		}
	}
	
	return $value;
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
	my $omeis_repository = $session->findRepository() or die "Couldn't retrieve repository";
	
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
		} elsif ( $ascender->semantic_type->name eq 'DerivedPixels') {
			@Dims = (
				$ascender->EndX - $ascender->StartX + 1,
				$ascender->EndY - $ascender->StartY + 1,
				$ascender->EndZ - $ascender->StartZ + 1,
				$ascender->EndC - $ascender->StartC + 1,
				$ascender->EndT - $ascender->StartT + 1,
			) unless( @Dims );
			# StartX and StartY are flipped. Because X in OME means width, but in MATLAB means rows
			@ROI = (
				$ascender->StartY, 
				$ascender->StartX, 
				$ascender->StartZ, 
				$ascender->StartC, 
				$ascender->StartT, 
				$ascender->EndY, 
				$ascender->EndX, 
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

	# Convert array datatype if requested
	# FIXME: does this datatype conversion taint $matlab_pixels ?
	my $convertToDatatype = $xmlInstr->getAttribute( 'ConvertToDatatype' );


	my $matlab_var_name = $self->_inputVarName( $xmlInstr );
	
	# Open the connection to OMEIS, because we have to do that for all possible cases
	my @inputs = ();
	my $url = OME::Matlab::Array->newStringScalar($omeis_repository->ImageServerURL());
	push( @inputs, $url );
	my @response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( "openConnectionOMEIS", 1, scalar( @inputs ), @inputs );
	
	# An mxArray that represents the connection to OMEIS
	my $is = shift( @response );
	@inputs = ();
	
	if (scalar @ROI) {
		my $serverID = OME::Matlab::Array->newNumericScalar($pixels->ImageServerID(), $mxSINGLE_CLASS);
		push( @inputs, $is, $serverID );
		
		# Convert all the ROI entries into numeric mxArrays
		foreach my $ROI_entry( @ROI ) {
			my $array = OME::Matlab::Array->newNumericScalar($ROI_entry, $mxSINGLE_CLASS);
			push( @inputs, $array);
		}
		
		@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( "getROI", 1, scalar( @inputs ), @inputs );
		
		if ($convertToDatatype) {
			# put the pixels array onto the input stack so we can convert
			@inputs = shift( @response );
			@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( $convertToDatatype, 1, 1, @inputs );
		}
	} else {
		my $serverID = OME::Matlab::Array->newNumericScalar($pixels->ImageServerID(), $mxSINGLE_CLASS);
		push( @inputs, $is, $serverID );
		@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( "getPixels", 1, scalar( @inputs ), @inputs );
		
		if ($convertToDatatype) {
			# put the pixels array onto the input stack so we can convert
			@inputs = shift( @response );
			@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( $convertToDatatype, 1, scalar( @inputs ), @inputs );
		}
	}
		
	# check that the gotten variable is the right size	
	my $ml_pixels_array = shift( @response );
	my ($rows,$columns,$sizeZ,$sizeC,$sizeT) 
	      = @{$ml_pixels_array->dimensions()};
	$sizeZ = 1 unless defined($sizeZ);
	$sizeC = 1 unless defined($sizeC);
	$sizeT = 1 unless defined($sizeT);

	die "getROI/getPixels failed for pixels ".$pixels->ImageServerID().". The ".
		"returned MATLAB array has dimensions ($rows, $columns, $sizeZ, $sizeC, $sizeT)"
		unless ($rows*$columns*$sizeZ*$sizeC*$sizeT == $Dims[0]*$Dims[1]*$Dims[2]*$Dims[3]*$Dims[4]);
	
	# Store the pixels array if everything is copascetic
	$_matlab_variables{ $matlab_var_name } = $ml_pixels_array;
}

=head2 Attr_to_MatlabScalar

Translate an input attribute into a matlab scalar 
Uses <Scalar>

=cut

sub Attr_to_MatlabScalar {
	my ( $self, $xmlInstr ) = @_;
	my $factory = OME::Session->instance()->Factory();
	
	# get input value
	my $input_location = $xmlInstr->getAttribute( 'InputLocation' )
		or die "Could not find InputLocation in input ".$xmlInstr->toString();
	my ( $formal_input_name, $SEforScalar ) = split( /\./, $input_location )
		or die "InputLocation '$input_location' could not be parsed. Problem processing input ".$xmlInstr->toString();
	my $input_attr = $self->getCurrentInputAttributes( $formal_input_name );

	# ActualArity is needed to cope with optional inputs.
	$xmlInstr->setAttribute( 'ActualArity', scalar( @$input_attr ) );
	return if scalar( @$input_attr ) eq 0;
	die scalar( @$input_attr )." attributes found for input '$formal_input_name'. ".
		'Cannot use scalar for input that has count greater than 1. '.scalar( @$input_attr ).' Inputs found. Error when processing \''.$xmlInstr->toString()."'"
		if scalar( @$input_attr ) > 1;
	my $value = $input_attr->[0]->$SEforScalar();

	# Convert array datatype if requested
	my $class;
	if (my $convertToDatatype = $xmlInstr->getAttribute('ConvertToDatatype')) {
		$class = $_convert_to_matlab_class{$convertToDatatype};
	} else {
		my $se = $factory->findObject( "OME::SemanticType::Element", {
			semantic_type => $self->getFormalInput( $formal_input_name )->semantic_type(),
			name          => "$SEforScalar"
		} );
		$class = $_ome_datatype_to_matlab_class{ $se->data_column()->sql_type() };
	}
	
	# Place value into matlab
	$self->_putScalarToMatlab($self->_inputVarName($xmlInstr), $value, $class);
}

=head2 Constant_to_MatlabScalar

Translate an constant into a matlab scalar
Uses <ConstantScalar>

=cut

sub Constant_to_MatlabScalar {
	my ( $self, $xmlInstr ) = @_;

	# get constant value
	my $value = $xmlInstr->getAttribute( 'Value' );
	die "Could not find Value in input ".$xmlInstr->toString()
		if not defined $value;
		
	my $datatype = $xmlInstr->getAttribute( 'DataType' );
	die "Could not find DataType in input ".$xmlInstr->toString()
		if not defined $value;
		
	# figure out the value's intended datatype	
	my $class;
	if ($datatype eq "char") {
		$class = $mxCHAR_CLASS;
	} else {
		$class = $_convert_to_matlab_class{ $datatype };
	}

	# Place value into matlab
	$self->_putScalarToMatlab($self->_inputVarName($xmlInstr), $value, $class);
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
			unless( exists $_translate_from_matlab{ $output->tagName() } );
		my $translation_function = $_translate_from_matlab{ $output->tagName() };
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
	my $omeis_repository = $session->findRepository() or die "Couldn't retrieve repository";
	my @response;
	my @inputs;
	my $mex = $self->getModuleExecution();
			
	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
	my $formal_output = $self->getFormalOutput( $xmlInstr->getAttribute( 'FormalOutput' ) )
		or die "Could not find formal output referenced from ".$xmlInstr->toString();
	
	# Convert array datatype if requested
	if( my $convertToDatatype = $xmlInstr->getAttribute( 'ConvertToDatatype' ) ) {
		push ( @inputs, $_matlab_variables{ $matlab_var_name } );
		@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( $convertToDatatype, 1, 1, @inputs );
 		$_matlab_variables{ $matlab_var_name } = shift( @response );
	}
	
	# Get array's dimensions and pixel type
	my $ml_pixels_array = $_matlab_variables{ $matlab_var_name };
	defined ($ml_pixels_array)
		or die "Pixels output variable $matlab_var_name does not exist.\n".
		       "This typically indicates an error in the execution of the program.\n".
		       "The Module Name is ".$mex->module()->name()." and the Module Execution ID is ".$mex->id().".\n";
	
	# N.B Rows is Height is SizeY in OME!
	my ($Rows,$Columns,$sizeZ,$sizeC,$sizeT) 
	      = @{$ml_pixels_array->dimensions()};
	my $sizeX = $Columns;
	my $sizeY = $Rows;
	$sizeZ = 1 unless defined($sizeZ);
	$sizeC = 1 unless defined($sizeC);
	$sizeT = 1 unless defined($sizeT);

	my $matlabType = $ml_pixels_array->class();
	die "Pixels of Matlab class ".$_matlab_class_to_string{$matlabType}." are not supported at this time"
		unless exists $_matlab_class_to_pixel_type{$matlabType};
	my $pixelType = $_matlab_class_to_pixel_type{$matlabType};
	
	# Make Pixels
	my @pixels_params = (
		$self->getCurrentImage(), 
		$self->getModuleExecution(),
		{
			SizeX		 => $sizeX,
			SizeY		 => $sizeY,
			SizeZ		 => $sizeZ,
			SizeC		 => $sizeC,
			SizeT		 => $sizeT,
			PixelType	 => $pixelType
		}
	);
	my ($pixels_data, $pixels_attr) = ( 
		$formal_output->semantic_type->name eq 'Pixels' ?
		OME::Tasks::PixelsManager->createPixels( @pixels_params ) :
		OME::Tasks::PixelsManager->createParentalPixels( @pixels_params )
	);
	
	# Open the connection to OMEIS
	@inputs = ();
	my $url = OME::Matlab::Array->newStringScalar($omeis_repository->ImageServerURL());
	push( @inputs, $url );
	@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( "openConnectionOMEIS", 1, scalar( @inputs ), @inputs );
	
	my $is = shift( @response );
	@inputs = ();
	
	my $serverID = OME::Matlab::Array->newNumericScalar($pixels_attr->ImageServerID(), $mxDOUBLE_CLASS);
	push( @inputs, $is, $serverID, $_matlab_variables{ $matlab_var_name } );
	@response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( "setPixels", 1, scalar( @inputs ), @inputs );
	$_matlab_variables{ $matlab_var_name."_pix" } = shift( @response );
	
	my ($value, $class) = $self->_getScalarFromMatlab($matlab_var_name."_pix");
	die "Could not write the expected number of pixels to OMEIS"
		unless $value == $sizeX*$sizeY*$sizeZ*$sizeC*$sizeT;
	
	# Finalize Pixels
	my $pixelsID = OME::Tasks::PixelsManager->finishPixels($pixels_data, $pixels_attr);
	OME::Tasks::PixelsManager->saveThumb($pixels_attr);
	
	# Deal with subclassing. This code has both hardcoded and implicit 
	# dependencies on the structure of STs that subclass Pixels. It
	# implicitly  assumes that  DerivedPixels is the only subclass of
	# Pixels that has additional data fields,  and that every other ST
	# that inherits (directy or indirectly) will only  have a Parent
	# field. If a DerivedPixels is part of the inheritence chain,  its
	# limits will be set the extent of the image.
	
	# convert the ancestry chain into a list of STs.
	my @ST_tree;
	my $current_ST = $formal_output->semantic_type();
	while( $current_ST->name() ne 'Pixels' ) {
		push (@ST_tree, $current_ST);
		
		# Take the next step up the ancestry chain
		my $parent_element = $factory->findObject( 
			'OME::SemanticType::Element', 
			{ semantic_type => $current_ST, name => 'Parent' } 
		) or die "Could not find a parent for ST ".$current_ST->name()." when trying to construct Pixels Parental outputs.";
		$current_ST = $factory->findObject(
			'OME::SemanticType',
			{ name => $parent_element->data_column()->reference_type() }
		) or die "Could not find ST named ".$parent_element->data_column()->reference_type()." when trying to construct Pixels Parental outputs.";
	}
	
	# traverse the list of STs (in reverse) and create the parental types
	my $parent = $pixels_attr;
	foreach (reverse @ST_tree) {
		$current_ST=$_;	
		my $new_attr;
		if( $current_ST->name() eq 'DerivedPixels' ) {
			$new_attr = $self->newAttributes($current_ST,
						{
							StartX => 0,
							StartY => 0,
							StartZ => 0,
							StartC => 0,
							StartT => 0,
							EndX   => ($parent->SizeX() - 1),
							EndY   => ($parent->SizeY() - 1),
							EndZ   => ($parent->SizeZ() - 1),
							EndC   => ($parent->SizeC() - 1),
							EndT   => ($parent->SizeT() - 1),
							Parent => $parent
						} ) or die "couldn't make newAttribute [DerivedPixels] in ancestry tree";
		} else {
			# Every other Pixels derivatives has only one SE (Parent)
			$new_attr = $self->newAttributes($current_ST, {Parent => $parent->ID()} )
				or die "couldn't make newAttribute in ancestry tree";
		}
		$parent = $new_attr;
	}
	
	# record the new attributes as parentoutputs, if requried
	foreach ( push (@ST_tree, 'Pixels') ) {
		$current_ST=$_;	
		if (not $factory->findObject("OME::Module::FormalOutput",
										module        => $self->getModule(),
										semantic_type => $current_ST) ) {
			$factory->newObject("OME::ModuleExecution::ParentalOutput", {
				module_execution => $self->getModuleExecution(),
				semantic_type    => $current_ST,
			});
		}
	}
}

=head2 MatlabVector_to_Attrs

Operates on vector matlab outputs. Uses <Vector> in conjuction with
<VectorDecoding> and <Templates>. Use this for making a record block.

=cut

sub MatlabVector_to_Attrs {
	my ( $self, $xmlInstr ) = @_;
	my $factory = OME::Session->instance()->Factory();

	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
	my $mex = $self->getModuleExecution();
	
	
	# get Vector Decoding
	my $vectorDecodeID = $xmlInstr->getAttribute( 'DecodeWith' )
		or die "DecodeWith attribute not specified in ".$xmlInstr->toString();
	my @decoding_elements = $self->{ execution_instructions }->findnodes( 
		'MLI:VectorDecoder[@ID="'.$vectorDecodeID.'"]/MLI:Element' );
		
	# optional 'global' ConvertToDatatype whose scope is applicable to the whole vector
	my $global_convertToDatatype = $xmlInstr->getAttribute( 'ConvertToDatatype' );
	if ($global_convertToDatatype) {
		die "Invalid convertToDatatype '$global_convertToDatatype'\n" unless $_convert_to_matlab_class{$global_convertToDatatype};
	}
	
	# decode the Vector
	# convert the vector into a cell whose elements have the appropriate class	
	my %matlab_vectors;
	foreach my $element ( @decoding_elements ) {

		# get index
		my $index = $element->getAttribute( 'Index' )
			or die "Index attribute not specified in ".$element->toString();

		# Convert array datatype if requested
		my $convertToDatatype = $element->getAttribute( 'ConvertToDatatype' );
		if ($convertToDatatype) {
			die "Invalid convertToDatatype '$convertToDatatype'\n" unless $_convert_to_matlab_class{$convertToDatatype};
		}
		
		# Use global 
		$convertToDatatype = $global_convertToDatatype
			unless defined $convertToDatatype;
			
		# TODO
		# since "vectors of strings" are really "matrices of chars" they need a special treatment
		# they are cell vectors of strings
		my $inputArray = $_matlab_variables { $matlab_var_name };
		my $class = $inputArray->class();
		
		# Create an array for this value if it's numeric or logical; else, store
		# the array to this hash.  This data storage method is necessary for the section where
		# you load the vector data hash

		if ($convertToDatatype) {
			my @inputs;

			if ( $inputArray->is_numeric() || $inputArray->is_logical() ) {
				my $arrayToConvert = $self->_putScalarToMatlab( 'tempPlaceHolder', @{ $inputArray->getAll() }[$index-1], $class);
				@inputs = ( $arrayToConvert );
			} else {
				@inputs = ( $inputArray );
			}
			
			my @response = $_matlab_instances{ 'utility_or_engine' }->callMatlab( $convertToDatatype, 1, scalar( @inputs ), @inputs );
			$matlab_vectors{ $index } = shift( @response );
		} else {
			if ( $inputArray->is_numeric() || $inputArray->is_logical() ) {
				$matlab_vectors{ $index } = $self->_putScalarToMatlab( 'tempPlaceHolder', @{ $inputArray->getAll() }[$index-1], $class );
			} else {
				$matlab_vectors{ $index } = $inputArray;
			}
		}
	}
	
	$_matlab_variables{ $matlab_var_name."_converted" } = \%matlab_vectors;
	
	# retrieve vector from matlab variable hash
	my $convertedCell = $_matlab_variables{ $matlab_var_name."_converted" };
	defined ($convertedCell)
		or die "Vector output variable $matlab_var_name"."_converted"." does not exist.\n".
		       "This typically indicates an error in the execution of the program.\n".
		       "The Module Name is ".$mex->module()->name()." and the Module Execution ID is ".$mex->id().".\n";

	# load the vector data hash
	my %vectorData; # $vectorData{$formal_output_name}->{$SE_name} = $data	
	foreach my $element ( @decoding_elements ) {
		my $index = $element->getAttribute( 'Index' );
		my $output_location = $element->getAttribute( 'OutputLocation' );
		my ( $formal_output_name, $SE_name ) = split( /\./, $output_location )
			or die "output_location '$output_location' could not be parsed.";
		my $formal_output = $self->getFormalOutput( $formal_output_name )
			or die "Could not find formal output '$formal_output_name' (from output location '$output_location').";
		
		my $array = $convertedCell->{ $index }
			or die "Could not retrieve the $index th cell. The index is most probably out of bounds\n";
		$array->makePersistent();
		my $value = $array->getScalar();
		my $class = $array->class();
		$value = $self->_trimNumeric ($value, $class);
		
		# make sure declared (OME-XML) and actual (MATLAB) data-types are the same
		my $se = $factory->findObject( "OME::SemanticType::Element", {
				semantic_type => $formal_output->semantic_type(),
				name          => "$SE_name"
			} );
		
		die "Semantic Element ($SE_name) of Semantic Type (".$formal_output->semantic_type()->name().
			") is of declared type (".$se->data_column()->sql_type().") but is of actual type (".
			$_matlab_class_to_string{$class}."). \n"
			if ( not exists($_matlab_class_to_ome_datatype{$class}) or 
				 $_matlab_class_to_ome_datatype{$class} ne $se->data_column()->sql_type());
			
		# Make a data hash
		my $template_id = $xmlInstr->getAttribute( 'UseTemplate' )
			and die "UseTemplate is not supported ATM for ".$xmlInstr->tagName().". ask Josiah <siah\@nih.gov> to fix this.";
#		my $data_hash;
#		if( $template_id ) {
#			my $ST_name;
#			($ST_name, $data_hash) = $self->_getTemplateData( $template_id );
#			die "Template Semantic Type ($ST_name) differs from ST registered for formal output ($formal_output). Error processing Output Instruction '".$xmlInstr->toString()."'"
#				if $formal_output->semantic_type()->name() ne $ST_name;
#		}
		# See: "Hackaround for XS variable hidden uniqueness." in MatlabScalar_to_Attr()

		# INDEX is $index
		
		$vectorData{ $formal_output_name }->{ $SE_name } = "$value";
	}
	
	# verbose debugging aid. Should be commented out typically.
	logdbg "debug", "Data from vector $vectorDecodeID is:\n";
	foreach my $formal_output_name ( keys %vectorData ) {
		logdbg "debug", "Formal output $formal_output_name has data hash:\n\t".
			join( ", ", 
				map( $_." => ".$vectorData{$formal_output_name}->{$_}, 
					keys %{ $vectorData{$formal_output_name} } 
				)
			).
		"\n";
	}
	
	# Actually make the outputs
	# Treating %vectorData as an array will automatically convert to the proper format.
	# e.g. ( formal_output_name, data_hash, formal_output_name, data_hash, ...)
	$self->newAttributes( %vectorData );
}

=head2 MatlabScalar_to_Attr

Operates on scalar matlab outputs. Uses <Scalar> in conjuction with <Templates>

=cut

sub MatlabScalar_to_Attr {
	my ( $self, $xmlInstr ) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();

	# gather formal output & SE
	my $output_location = $xmlInstr->getAttribute( 'OutputLocation' );
	my ( $formal_output_name, $SEforScalar ) = split( /\./, $output_location );
	my $formal_output = $self->getFormalOutput( $formal_output_name );

	# Retrieve value from matlab
	my $class;
	if (my $convertToDatatype = $xmlInstr->getAttribute('ConvertToDatatype') ) {
		$class = $_convert_to_matlab_class{$convertToDatatype};
	}
	
	my $value;
	($value, $class) = $self->_getScalarFromMatlab($self->_outputVarName($xmlInstr), $class);

	# make sure declared (OME-XML) and actual (MATLAB) data-types are the same
	my $se = $factory->findObject( "OME::SemanticType::Element", {
			semantic_type => $formal_output->semantic_type(),
			name          => "$SEforScalar"
		} );
	die "Semantic Element ($SEforScalar) of Semantic Type (".$formal_output->semantic_type()->name().
	    ") is of declared type (".$se->data_column()->sql_type().") but is of actual type (".
	    $_matlab_class_to_string{$class}."). \n"
		if ( not exists($_matlab_class_to_ome_datatype{$class}) or 
			 $_matlab_class_to_ome_datatype{$class} ne $se->data_column()->sql_type());
	
	# Make a data hash
	my $template_id = $xmlInstr->getAttribute( 'UseTemplate' );
	my $data_hash;
	if( $template_id ) {
		my $ST_name;
		($ST_name, $data_hash) = $self->_getTemplateData( $template_id );
		die "Template Semantic Type ($ST_name) differs from ST registered for formal output ($formal_output). Error processing Output Instruction '".$xmlInstr->toString()."'"
			if $formal_output->semantic_type()->name() ne $ST_name;
	}
	# Hackaround for XS wierdness, or more descriptively: XS variable hidden uniqueness.
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

	1/6/05 TJM: N.B we don't have a real use-case for this function of the 
	MatlabHandler this function is missing checks that make sure (OME-XML) 
	declared and actual(MATLAB) data-types are the same.

=cut

sub MatlabStruct_to_Attr {
	my ( $self, $xmlInstr ) = @_;
	my $mex = $self->getModuleExecution();
	
	my $formal_output = $self->getFormalOutput( $xmlInstr->getAttribute( 'FormalOutput' ) )
		or die "Formal output could not be found. Error processing output: ".$xmlInstr->toString();

	my $matlab_var_name = $self->_outputVarName( $xmlInstr );
	my $matlab_output = $_matlab_variables{ $matlab_var_name };
	defined ($matlab_output)
		or die "Struct output variable $matlab_var_name does not exist.\n".
		       "This typically indicates an error in the execution of the program.\n".
		       "The Module Name is ".$mex->module()->name()." and the Module Execution ID is ".$mex->id().".\n";
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
	my $name = 'ome_input_'.scalar( keys( %{ $self->{ __inputVariableNames } } ) );
	if( $xml_instruction->getAttribute( 'ID' ) ) {
		$name .= '_'.$xml_instruction->getAttribute( 'ID' );
	} else {
		$name .= '_'.$xml_instruction->tagName();
	}
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
	if( $xml_instruction->getAttribute( 'ID' ) ) {
		$name .= '_'.$xml_instruction->getAttribute( 'ID' );
	} else {
		$name .= '_'.$xml_instruction->tagName();
	}
	$self->{ __outputVariableNames }->{ $xml_instruction->toString() } = $name;
	return $name;
}

=head2 ___openMatlab

Starts up the Matlab interface

=cut

sub __openMatlab {
	my ($self) = @_;
	my $instance;
		
	# initially open the MATLAB interface
	if (!$_matlabOpen) {
		# Let's try to use the library
		eval "use OME::Matlab::Lib::Utility";

		if ( $@ ) {
			logdbg "debug", "Could not find utility library, using the engine instead.\n\tError message: $@";
			$instance = $self->__openEngine();
			die "Could not open a connection to Matlab Engine!" unless $instance;
		} else {
			logdbg "debug", "Found the utility library, going to use that instead of the engine.";
			$instance = OME::Matlab::Lib::Utility->new();
			die "Could not open a connection to Matlab utility library!" unless $instance;
		}
		
		# If we have an engine instance, we are storing it twice, but that's okay because
		# the cleanliness of the 'utility' code depends on this.
		$_matlab_instances{ 'utility_or_engine' } = $instance;
		$_matlabOpen = 1;
	}
	
	# figure out MATLAB constants
	if (not exists $_numerical_constants{'min_double'}) {
		my $min_double;
		my $max_double;
		my $min_single;
		my $max_single;
		my $double_neg_inf;
		my $double_inf;
		my $single_neg_inf;
		my $single_inf;
		
		# Odd entries are functions, even entries are inputs
		my @functions_and_inputs = (
			'realmin', 'double',
			'realmax', 'double',
			'realmin', 'single',  
			'realmax', 'single',  
			'double', '-inf',
			'double', 'inf',  
			'single', '-inf',
			'single', 'inf',  
		);
		
		my $counter = 0;
		while ( scalar ( @functions_and_inputs ) ) {
			my $function = shift ( @functions_and_inputs );
			my $value = shift ( @functions_and_inputs );
			
			my @input = ( OME::Matlab::Array->newStringScalar( $value ) );
			my @response = $_matlab_instances{ 'utility_or_engine' }->callMatlab($function, 1, scalar( @input ), @input);
			my $retVal = shift( @response );
			my $value_to_store;
			
			# If the value we're supposed to get is "inf" or "-inf", MATLAB returns
			# the ASCII values, so we have to convert them into char entries.
			# The way I'm checking for this is just seeing if there's more than
			# one entry in the mxArray that's returned. I'm not sure how secure
			# this is, so if someone can come up with a better solution, please
			# implement it.
			if ( scalar ( @{ $retVal->getAll() } ) > 1 ) {
				foreach my $entry ( @{ $retVal->getAll() } ) {
					$value_to_store .= chr($entry);
				}
			} else {
				$value_to_store = @{ $retVal->getAll() }[0];
			}			
			
			switch ($counter) {
				case 0 { $min_double = $value_to_store };
				case 1 { $max_double = $value_to_store };
				case 2 { $min_single = $value_to_store };
				case 3 { $max_single = $value_to_store  };
				case 4 { $double_neg_inf = $value_to_store };
				case 5 { $double_inf = $value_to_store };
				case 6 { $single_neg_inf = $value_to_store };
				case 7 { $single_inf = $value_to_store };
			}
	
			$counter++;
		}
		
		%_numerical_constants = (
			'min_double' => $min_double,
			'max_double' => $max_double,
			'min_single' => $min_single,
			'max_single' => $max_single,
			'double_neg_inf' => $double_neg_inf,
			'double_inf'     => $double_inf,
			'single_neg_inf' => $single_neg_inf,
			'single_inf'     => $single_inf,
		);	
	}
}

=head2 __closeMatlab

Shuts down the Matlab interface - well, just the engine at the moment.
TODO: Implement something to shut down each instance.

=cut

sub __closeMatlab {
	$_matlab_instances{ 'engine' }->close() if $_matlab_instances{ 'engine' };
}

=head2 __idleMatlab

Frees up memory used by the matlab interfaces - well, just the engine at the moment.
TODO: Implement something to shut down each instance.

=cut

sub __idleMatlab {
	$_matlab_instances{ 'engine' }->eval("clear") if $_matlab_instances{ 'engine' };
}

sub __openEngine {

	# load environment variables
	my $session = OME::Session->instance();
	my $MATLAB = $_environment->matlab_conf() or croak "couldn't retrieve MATLAB environment variables";
	my $matlab_exec = $MATLAB->{EXEC} or croak "couldn't retrieve matlab exec path from environment";
	my $matlab_flags = $MATLAB->{EXEC_FLAGS} or croak "couldn't retrieve matlab exec flags from environment";
	my $matlab_src_dir = $MATLAB->{MATLAB_SRC} or croak "couldn't retrieve matlab src dir from environment";
	
	logdbg "debug", "Matlab src dir is $matlab_src_dir";
	logdbg "debug", "Matlab exec is $matlab_exec";
	
	# Although $matlab_exec is the fully qualified path to the matlab executable,
	# /usr/bin and /bin needs to be in the PATH environment variable so the
	# $matlab_exec has access to basic functions such as cd/mkdir/chown that it
	# needs. Apache doesn't have the PATH variable set by default
	my $instance = OME::Matlab::Engine->open("env PATH=/usr/bin:/bin $matlab_exec $matlab_flags");
	
	# Add the matlab source directory to the path so we can find our functions
	$instance->eval("clear; addpath(genpath('$matlab_src_dir'));");
	
	# Store the engine into its own place, because we'll need it in execute
	$_matlab_instances{ 'engine' } = $instance;
	
	return $instance;
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


=head2 validateAndProcessExecutionInstructions
	
overrides superclass method to check

=cut

sub validateAndProcessExecutionInstructions {
    my ($self, $module, $executionInstructionsXML) = @_; 
    
    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    
	# This Allows xpath queries on the MLI NS. i.e. $root->findnodes( "MLI:Inputs/*" )
	$executionInstructionsXML->setAttribute( "xmlns:MLI", $supported_NS );

	#	Output Checking:
	# Verify OutputLocation of <Scalar>'s refer to something that exists.
	my @scalar_outputs = $executionInstructionsXML->findnodes( 
		".//MLI:Output/MLI:Scalar"
	);
	foreach my $scalar ( @scalar_outputs ) {
		my $output_location = $scalar->getAttribute( 'OutputLocation' )
			or die "OutputLocation is not specified in ".$scalar->toString();
		$self->__check_output_location( $module, $output_location );
	}

	#	Output Checking: <VectorDecoder>
	my @vector_defs = $executionInstructionsXML->findnodes( 'MLI:VectorDecoder' );
	my %vector_def_ids;
	foreach my $vector_def ( @vector_defs ) {
		# prevent duplicate IDs
		my $vectorID = $vector_def->getAttribute( 'ID' )
			or die "ID not specified in ".$vector_def->toString();
		die "A VectorDecoder with this ID has already been defined. Duplicate IDs found in:\n".
			$vector_def_ids{ $vectorID }->toString."\n-- AND --\n".
			$vector_def->toString."\n"
			if exists $vector_def_ids{ $vectorID };
		$vector_def_ids{ $vectorID } = $vector_def;

		# Is this vector used?
		my @vector_outputs = $executionInstructionsXML->findnodes( 
			'.//MLI:Vector[@DecodeWith="'.$vectorID.'"]' )
			or warn "Warning, VectorDecoder ID='$vectorID' is not referenced by any outputs.";
	
		# Make sure two Vector elements don't write the the same place
		# Check for data collision and referential integrity of output location.
		my @elements = $vector_def->findnodes( 'MLI:Element' );
		my %outputLocations;
		foreach my $element( @elements ) {
			my $output_location = $element->getAttribute( 'OutputLocation' );
			confess "Write collision! Another Vector Element references this $output_location. Error processing ".$vector_def->toString()." in Module ".$module->name()
				if exists $outputLocations{ $output_location };
			$self->__check_output_location( $module, $output_location );
			$outputLocations{ $output_location } = undef;
		}
	}

	#	Output Checking: <Vector>
	my @vectors = $executionInstructionsXML->findnodes( './/MLI:Output/MLI:Vector' );
	foreach my $vector ( @vectors ) {
		# Does the decoder referenced actually exist?
		my $vectorDecodeID = $vector->getAttribute( 'DecodeWith' )
			or die "DecodeWith attribute not specified in ".$vector->toString();
		my @vector_decoders = $executionInstructionsXML->findnodes( 
			'.//MLI:VectorDecoder[@ID="'.$vectorDecodeID.'"]' )
			or die "Can't find VectorDecoder referenced by Vector output ".$vector->toString;
	}
	
    return $executionInstructionsXML;
}

=pod

=head1 AUTHORS

Josiah Johnston (siah@nih.gov),
Tom Macura (tmacura@nih.gov),
Arpun Nagaraja (arpun@mit.edu),
based on code written by Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::Matlab>, L<OME::Matlab::Engine>, 
L<http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd|specification of XML instructions>

=cut


1;
