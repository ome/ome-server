# OME/Analysis/Handlers/MatlabHandler.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
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
use OME;
our $VERSION = $OME::VERSION;

use OME::Tasks::PixelsManager;
use OME::Analysis::Handlers::DefaultLoopHandler;
use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use fields qw(__engine __engineOpen);

use OME::Matlab;
use XML::LibXML;

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

    $self->__parseInstructions();

    $self->{__engine} = undef;
    $self->{__engineOpen} = 0;

    bless $self,$class;
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    $self->__closeEngine();
}

sub __parseInstructions {
    my $self = shift;

    my $module                = $self->getModule();
    my $executionInstructions = $module->execution_instructions();
    my $parser                = XML::LibXML->new();
    my $tree                  = $parser->parse_string( $executionInstructions );
    my $root                  = $tree->getDocumentElement();

    print "\n**** Parsing instructions\n";

    my $references_needed =
      $root->getElementsByLocalName('ReferencesNeeded')->[0];
    my @references =
      $references_needed->getElementsByLocalName('Reference')
      if $references_needed;
    my %references;
    foreach my $reference (@references) {
        $references{$reference->getAttribute('Location')} = 1;
        print "   Ref $reference\n";
    }

    my $execute_at =
      $root->getAttribute('ExecutionPoint');
    $self->{__executeAt} = $execute_at;
    print "   Execute at $execute_at\n";

    my @input_tags =
      $root->getElementsByLocalName('Inputs')->[0]->
      getElementsByLocalName('Input');
    my @inputs;
	# parse input execution instructions
    foreach my $input_tag (@input_tags) {
    	push @inputs, $input_tag->getAttribute('Name') || $input_tag->getAttribute('Value') || 
    		die "Either Name or Value must be specified for an input to a matlab function. Input tag looks like: \n".$input_tag->toString()."\n";
    	# store execution instructions for this input
    	$self->{__inputInstructions}->{$input_tag->getAttribute('Name')}->{xml} = $input_tag
    		if $input_tag->getAttribute('Name');
		# flag an input as being a literal string
		$self->{__inputInstructions}->{$input_tag->getAttribute('Value')}->{literalString} = 1;
    	# parse the 'loadPixelsPlane' command
		if( $input_tag->getAttribute('loadPixelsPlane') =~ /^(true|t)$/i ) {
			die "Name must be specified if loadPixelsPlane is specified. Input tag looks like: \n".$input_tag->toString()."\n"
				unless $input_tag->getAttribute('Name');
			$self->{__inputInstructions}->{$input_tag->getAttribute('Name')}->{loadPixelsPlane} = 1;
			$references{$input_tag->getAttribute('Name').".Repository"} = 1
				if( not exists $references{$input_tag->getAttribute('Name').".Repository"} );
		}
    }
    $self->{__matlabInputs} = \@inputs;
    print "   Inputs @inputs\n";

	# set $self->{__references} down here because a Repository reference may have been added as a result of the 'loadPixelsPlane' instruction
    $self->{__references} = \%references;

	
    my @output_tags =
      $root->getElementsByLocalName('Outputs')->[0]->
      getElementsByLocalName('Output');
    my @outputs;
	# parse output execution instructions
    foreach my $output_tag (@output_tags) {
    	# if Name is not specified, this output is to be ignored
    	if( $output_tag->getAttribute('Name') ) {
    		push @outputs, $output_tag->getAttribute('Name');
    	} else {
    		push @outputs, "junk";
    	}
    	# store execution instructions for this output
    	$self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{xml} = $output_tag;
		# set flag for basic/advanced parsing
		$self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{basicParsing} = 1
			if( $output_tag->attributes()->length() eq 1 and $output_tag->childNodes()->size() eq 0 );
		my @element_tags = $output_tag->getElementsByLocalName('Element');
		# set semantic element aliasing
		$self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{elementAliases}->{$_->getAttribute('MatlabField')} =
			$_->getAttribute('Name') 
			foreach ( grep( defined $_->getAttribute('MatlabField'), @element_tags) );
		$self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{elementAliasing} = 1
			if( exists $self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{elementAliases} );
		# set semantic element access by array index (rather than field in a structure).
		$self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{orderedArrayIndexes}->{$_->getAttribute('OrderedArrayIndex') - 1} =
			$_->getAttribute('Name') 
			foreach ( grep( defined $_->getAttribute('OrderedArrayIndex'), @element_tags) );
		# set outputIsOrderedArray flag
		$self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{outputIsOrderedArray} = 1
			if( exists $self->{__outputInstructions}->{$output_tag->getAttribute('Name')}->{orderedArrayIndexes} );
    }
    $self->{__matlabOutputs} = \@outputs;
    print "   Outputs @outputs\n";
    print "**** Done Parsing Instructions\n";
}

sub __openEngine {
    my ($self) = @_;

    if (!$self->{__engineOpen}) {
        my $engine = OME::Matlab::Engine->open("matlab -nodisplay -nojvm");
        die "Cannot open a connection to Matlab!"
          unless $engine;
        $self->{__engine} = $engine;
        $self->{__engineOpen} = 1;

        $engine->eval(q[addpath(genpath('/Users/tmacur1/Desktop/OME-Hacking/OME/src/matlab'));]);
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

# 
# retrieve's matlab output via getVariable and shoves it into ome
#
sub retrieveOutputs {
    my ($self,$granularity) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

	die "Not connected to Matlab" unless $self->{__engineOpen};

    my @outputs = $factory->
      findObjects('OME::Module::FormalOutput',
                  {
                   module => $self->getModule(),
                   'semantic_type.granularity' => $granularity,
                  });

      
    foreach my $formal_output (@outputs) {
        my $semantic_type  = $formal_output->semantic_type();
print "**** Done special action for SE Pixels\n";
		
		if ($semantic_type->name() eq "Pixels"){
			my $filename = $session->getTemporaryFilename("pixels","raw");
			my $var_name = "omeout_".$formal_output->name();
			
	    	# figure out the array's dimensions
			$self->{__engine}->eval("[sizeX,sizeY,sizeZ,sizeC,sizeT] = size($var_name)");
			my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT) = 
				($self->{__engine}->getVariable('sizeX')->scalar(),
				 $self->{__engine}->getVariable('sizeY')->scalar(),
				 $self->{__engine}->getVariable('sizeZ')->scalar(),
				 $self->{__engine}->getVariable('sizeC')->scalar(),
				 $self->{__engine}->getVariable('sizeT')->scalar());
			
			# figure out the pixel depth based on array data-type	 
			$self->{__engine}->eval("str = class($var_name)");		
			my $type = $self->{__engine}->getVariable('str')->scalar();
			my ($bbp, $isSigned, $isFloat) = (0,0,0);
			if ($type eq "uint8"){
				$bbp = 1;	
			} elsif ($type eq "uin16"){
				$bbp = 2;
			} elsif ($type eq "uint32"){
				$bbp = 4;
			} elsif ($type eq "int8"){
				$bbp = 1;
				$isSigned = 0;
			} elsif ($type eq "int16"){
				$bbp = 2;
				$isSigned = 1;
			} elsif ($type eq "int32"){
				$bbp = 4;
				$isSigned = 1;
			} elsif ($type eq "single" || $type eq "float"){
				$bbp = 2;
				$isSigned = 1;
				$isFloat = 1;
			} elsif ($type eq "double"){
				$bbp = 4;
				$isSigned = 1;
				$isFloat = 1;
			}
			
			print "bbp = $bbp, isSigned = $isSigned, isFloat = $isFloat\n";
			$self->{__engine}->eval("fwrite(fopen('$filename','w'),$var_name, class($var_name))");
			my ($pixels_data, $pixels_attr) = OME::Tasks::PixelsManager->
						createPixels($self->getCurrentImage(), $self->getModuleExecution(),{
										SizeX        => $sizeX,
										SizeY        => $sizeY,
										SizeZ        => $sizeZ,
										SizeC        => $sizeC,
										SizeT        => $sizeT,
										BitsPerPixel => $bbp*8,
										PixelType    => $type
									  } );
														
	    	my $pixelsWritten = $pixels_data->setPixelsFile($filename,1);
			my $pixelsID = OME::Tasks::PixelsManager->finishPixels($pixels_data, $pixels_attr);
			OME::Tasks::PixelsManager->saveThumb($pixels_attr);
			
			$session->finishTemporaryFile($filename);
print STDERR "pixels written = $pixelsWritten\n";		
print "**** Done special action for SE Pixels\n";
		}
    }
}

sub placeInputs {
    my ($self,$granularity) = @_;
    my $factory = OME::Session->instance()->Factory();

    my @inputs = $factory->
      findObjects('OME::Module::FormalInput',
                  {
                   module => $self->getModule(),
                   'semantic_type.granularity' => $granularity,
                  });

    foreach my $formal_input (@inputs) {
        my $semantic_type  = $formal_input->semantic_type();
		my $attribute_list = $self->getCurrentInputAttributes($formal_input);
		$self -> placeAttributes($formal_input->name(),
							  $semantic_type,
							  $attribute_list);	
    }
}

sub placeAttributes {
    my ($self,$variable_name,$semantic_type,$attribute_list) = @_;

	my $session = OME::Session->instance();
    die "Not connected to Matlab" unless $self->{__engineOpen};
      
    my $num_attributes = scalar(@$attribute_list);
    my @elements = $semantic_type->semantic_elements();
    my @names = ('id');
    push @names, $_->name() foreach @elements;

    # Matlab will free this itself, so we need to make sure that the
    # DESTROY method does not try to also free the memory.  This is
    # true of the arrays we create in the next loop, too.
    my $struct;
    my $attr_idx = 0;
    
   	if ($semantic_type->name() eq "Pixels"){
   	
   		print "**** START special action for SE Pixels\n";
   		 
   		foreach my $attribute (@$attribute_list) {
			# translate the attirbute_list into known pixel attributes§
			my ($omeisID, $pixelType, $sizeX, $sizeY, $sizeZ, $sizeC, $sizeT) =
				($attribute->ImageServerID(), $attribute->PixelType(), $attribute->SizeX(), 
				 $attribute->SizeY(), $attribute->SizeZ(), $attribute->SizeC(), $attribute->SizeT());
			
			# TODO switch based on pixelTypes
			my $class;
			if ($pixelType eq 'uint8') {
				$class = $mxUINT8_CLASS;
			} elsif ($pixelType eq 'uint16') {
				$class = $mxUINT16_CLASS;
			} elsif ($pixelType eq 'uint32') {
				$class = $mxUINT32_CLASS;
			}
				
			$struct = OME::Matlab::Array->newNumericArray($class, $mxREAL,
							$sizeX,$sizeY,$sizeZ,$sizeC,$sizeT);
			$struct->makePersistent();
			die "Could not create struct" unless $struct;
		  
			#  prepare for the incoming pixels
			my $filename = $session->getTemporaryFilename("pixels","raw");
			
			
			open my $pix, ">", $filename or die "Could not open local pixels file";
				
			#Todo macs are big endian and intells are little endian.
			my $buf = OME::Image::Server->getPixels($omeisID);
			print $pix $buf;
			close $pix;
			
			my $matlab_name = "ome_${variable_name}";
			$self->{__engine}->eval("global $matlab_name");
			$self->{__engine}->putVariable($matlab_name,$struct);
			
			# magic one-liner. One liner means no variables are left in matlab's workplace
			# this one-liner fills an array based on OMEIS's output which went to a temp file
			$self->{__engine}->eval("[$matlab_name, nPix] = fread(fopen('$filename', 'r'), size($matlab_name),'$pixelType');");
			$session->finishTemporaryFile($filename);
		}   		
   		print "**** DONE special action for SE Pixels\n";
   		
   	} else {
		print "**** Creating Matlab struct from OME object \n";
		$struct = OME::Matlab::Array->
      		newStructMatrix(1,$num_attributes,\@names);
      	$struct -> makePersistent();
    	die "Could not create struct" unless $struct;
      
		foreach my $attribute (@$attribute_list) {
			$self->__createAttribute($struct,$attr_idx,$variable_name,
									 $attribute,\@elements);
		} continue {
			$attr_idx++;
		};
		print "**** Done Creating Matlab struct\n";
	
		my $matlab_name = "ome_${variable_name}";
		print "putting $matlab_name\n\n";
		$self->{__engine}->eval("global $matlab_name");
		$self->{__engine}->putVariable($matlab_name,$struct);
   	}
}


sub __createAttribute {
    my ($self,$struct,$attr_idx,$attr_name,$attribute,$elements) = @_;

    # Add the primary key ID to the attribute struct
    my $array = OME::Matlab::Array->newDoubleScalar($attribute->id());
    $array->makePersistent();
    $struct->setField($attr_idx,0,$array);

    my $references = $self->{__references};

    my $elem_idx = 1;
    foreach my $element (@$elements) {
        my $name = $element->name();
        print "$name = ";

        my $value = $attribute->$name();
        my $sql_type = $element->data_column()->sql_type();

        my $array;
        if (defined $value) {
            if ($sql_type eq 'string') {
                print "New string $value\n";
                $array = OME::Matlab::Array->newStringScalar($value);
                $array->makePersistent();
            } elsif ($sql_type eq 'boolean') {
                print "New logical $value\n";
                $array = OME::Matlab::Array->newLogicalScalar($value);
                $array->makePersistent();
            } elsif ($sql_type eq 'reference') {
                my $reference_name = "${attr_name}.${name}";
                if ($references->{$reference_name}) {
                    print "New reference ",$value->id(),"\n";
                    $array = $self->
                      __createReferenceAttribute($reference_name,$value);
                } else {
                    print "New unneeded reference ",$value->id(),"\n";
                    $array = OME::Matlab::Array->newDoubleScalar($value->id());
                    $array->makePersistent();
                }
            } else {
                print "New double $value\n";
                $array = OME::Matlab::Array->newDoubleScalar($value);
                $array->makePersistent();
            }
            print "[$sql_type] '$value'\n";
        } else {
            print "[Undefined]\n";
        }

        $struct->setField($attr_idx,$elem_idx,$array)
          if defined $array;
    } continue {
        $elem_idx++;
    };
}

sub __createReferenceAttribute {
    my ($self,$name,$attribute) = @_;

    my $semantic_type = $attribute->semantic_type();
    my @elements = $semantic_type->semantic_elements();
    my @names = ('id');
    push @names, $_->name() foreach @elements;

    my $struct = OME::Matlab::Array->
      newStructMatrix(1,1,\@names);
    die "Could not create struct"
      unless $struct;

    # Matlab will free this itself, so we need to make sure that the
    # DESTROY method does not try to also free the memory.  This is
    # true of the arrays we create in the next loop, too.
    $struct->makePersistent();

    $self->__createAttribute($struct,0,$name,$attribute,\@elements);

    return $struct;
}

sub __execute {
    my ($self) = @_;
    
   # my $old_guess = OME::SemanticType->GuessRows();
   # OME::SemanticType->GuessRows(1);
    
    my $inputs = $self->{__matlabInputs};
    my $location = $self->getModule()->location();
    my $outputs = $self->{__matlabOutputs};
    
	my @params;
	foreach( @$inputs ) {
		if( exists $self->{__inputInstructions}->{$_}->{literalString} ) {
			push @params, "$_";
		} else {
			push @params, "ome_$_";
		}
	}
    my $input_cmd = "(".join(',',@params).")";

    my @results = map { "omeout_$_" } @$outputs;
    my $output_cmd;
    if (scalar(@results) == 0) {
        $output_cmd = "";
    } elsif (scalar(@results) == 1) {
        $output_cmd = $results[0]." = ";
    } else {
        $output_cmd = "[".join(',',@results)."] = ";
    }

    my $command = "${output_cmd}${location}${input_cmd};";
    print STDERR "***** Command to Matlab: $command\n";
    my $outBuffer = " " x 512;
    $self->{__engine}->setOutputBuffer($outBuffer, length($outBuffer));
    $self->{__engine}->eval($command);
	print STDERR "***** Output from Matlab:\n $outBuffer\n";
}

sub startAnalysis {
    my ($self,$module_execution) = @_;
    $self->SUPER::startAnalysis($module_execution);

    $self->__openEngine();
}

sub executeGlobal {
    my ($self) = @_;
    $self->SUPER::executeGlobal();
    $self->placeInputs('G');
    $self->__execute() if $self->{__executeAt} eq 'executeGlobal';
    $self->retrieveOutputs('G');
}

sub startDataset {
	print STDERR "startDataset Called \n\n";
    my ($self,$dataset) = @_;
    $self->SUPER::startDataset($dataset);
    $self->placeInputs('G');
    $self->placeInputs('D');
    $self->__execute() if $self->{__executeAt} eq 'startDataset';
    $self->retrieveOutputs('D');
}

sub startImage {
    my ($self,$image) = @_;
    $self->SUPER::startImage($image);
    
    # startImage can be executed either in dataset or image-dependence.
    # If we're image-dependent, then we need to make sure to feed in any
    # global attributes there might be.  (If we're dataset-dependent,
    # the startDataset method will have already done this.)

    if ($self->getModuleExecution()->dependence() eq 'I') {
        $self->placeInputs('G');
    }

   	$self->placeInputs('I');
    $self->__execute() if $self->{__executeAt} eq 'startImage';
    $self->retrieveOutputs('I');
}

sub startFeature {
    my ($self,$feature) = @_;
    $self->SUPER::startFeature($feature);
    $self->placeInputs('F');
    $self->__execute() if $self->{__executeAt} eq 'startFeature';
}

sub finishFeature {
    my ($self) = @_;
    $self->SUPER::finishFeature();
    $self->__execute() if $self->{__executeAt} eq 'finishFeature';
}

sub finishImage {
    my ($self) = @_;
    $self->SUPER::finishImage();
    $self->__execute() if $self->{__executeAt} eq 'finishImage';
}

sub finishDataset {
    my ($self) = @_;
    $self->SUPER::finishDataset();
    $self->__execute() if $self->{__executeAt} eq 'finishDataset';
}


1;