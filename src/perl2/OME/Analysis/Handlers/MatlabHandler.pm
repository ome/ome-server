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

    print "**** Parsing instructions\n";

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
}

sub __openEngine {
    my ($self) = @_;

    if (!$self->{__engineOpen}) {
        my $engine = OME::Matlab::Engine->open("matlab -nodisplay -nojvm");
        die "Cannot open a connection to Matlab!"
          unless $engine;
        $self->{__engine} = $engine;
        $self->{__engineOpen} = 1;

        $engine->eval(q[addpath('/Users/tmacur1/Desktop/OME-Hacking/OME/src/matlab');]);
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
        } else {
            print "Undefined\n";
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

sub placeAttributes {
    my ($self,$variable_name,$semantic_type,$attribute_list) = @_;

    die "Not connected to Matlab"
      unless $self->{__engineOpen};

    my $num_attributes = scalar(@$attribute_list);

    my @elements = $semantic_type->semantic_elements();
    my @names = ('id');
    push @names, $_->name() foreach @elements;

    my $struct = OME::Matlab::Array->
      newStructMatrix(1,$num_attributes,\@names);
    die "Could not create struct"
      unless $struct;

    # Matlab will free this itself, so we need to make sure that the
    # DESTROY method does not try to also free the memory.  This is
    # true of the arrays we create in the next loop, too.
    $struct->makePersistent();

    my $attr_idx = 0;
    foreach my $attribute (@$attribute_list) {
        $self->__createAttribute($struct,$attr_idx,$variable_name,
                                 $attribute,\@elements);
    } continue {
        $attr_idx++;
    };

    my $matlab_name = "ome_${variable_name}";
    $self->{__engine}->eval("global $matlab_name");
    $self->{__engine}->putVariable($matlab_name,$struct);
}

sub printarray {
    #my $name = shift;
    #my $array = $handler->{__engine}->getVariable($name);
    my $array = shift;
    print "  Perl: $array\n";
    print "    Class:  ",$array->class_name(),"\n";
    print "    Order:  ",$array->order(),"\n";
    print "    Dims:   ",join('x',@{$array->dimensions()}),"\n";
    if ($array->is_numeric() || $array->is_logical()) {
        print "    Values: (",join(',',@{$array->getAll()}),")\n";
    }
}

sub __execute {
    my ($self) = @_;

    my $old_guess = OME::SemanticType->GuessRows();
    OME::SemanticType->GuessRows(1);

    my $location = $self->getModule()->location();

    my $inputs = $self->{__matlabInputs};
    # ome_loadPixelsPlane will crash if its input has an arity greater than 1.
    # since we have *NO* use cases that has a FI of ST Pixels or PixelsPlane that accepts a 
    # count > 1, this is not a problem yet.
	my @params;
	foreach( @$inputs ) {
print STDERR "processing __matlab input $_\n";
		if( exists $self->{__inputInstructions}->{$_}->{loadPixelsPlane} ) {
			push @params, "ome_loadPixelsPlane( ome_$_ )";
		} elsif( exists $self->{__inputInstructions}->{$_}->{literalString} ) {
			push @params, "$_";
		} else {
			push @params, "ome_$_";
		}
	}
    my $input_cmd = "(".join(',',@params).")";

    my $outputs = $self->{__matlabOutputs};
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
    print STDERR "***** $command\n";
    my $outBuffer = " " x 512;
    $self->{__engine}->setOutputBuffer($outBuffer, length($outBuffer));
    $self->{__engine}->eval($command);
	print STDERR "Matlab's Output:\n $outBuffer\n";
	
	# Parse the outputs
    foreach my $output (@$outputs) {
    	next if $output eq 'junk';
        my $formal_output = $self->getFormalOutput($output);
        my $semantic_type = $formal_output->semantic_type();

        my $array = $self->{__engine}->getVariable("omeout_$output");
        $array->makePersistent();
        #print "Output $output - $array\n";
        #printarray($array);

#$self->{__outputInstructions}->{$output}->{xml}
#$self->{__outputInstructions}->{$output}->{basicParsing} = 1
#$self->{__outputInstructions}->{$output}->{elementAliases}->{$_->getAttribute('MatlabField')} =
#	$_->getAttribute('Name') 
#$self->{__outputInstructions}->{$output}->{orderedArrayIndexes}->{$_->getAttribute('AccessByArrayIndex')} =
#	$_->getAttribute('Name') 
#$self->{__outputInstructions}->{$output}->{outputIsOrderedArray}
        if (defined $array) {
        	my $outputIsStruct = ( $self->{__outputInstructions}->{$output}->{outputIsOrderedArray} ? undef : 1 );
            die "Outputs should be a structure!"
              if (!$array->is_struct() && $outputIsStruct );
            my $length = $array->n();
            my @field_names;
            my $num_fields;
           	if ( $outputIsStruct ) {
				$num_fields = $array->getNumFields();
				push @field_names, $array->getFieldName($_)
				  foreach (0..$num_fields-1);
			}

			my %data_hash;
            foreach my $attr_idx (0..$length-1) {
                
				# output is in a structure.
				if( $outputIsStruct ) {
					%data_hash = ();
					foreach my $field_idx (0..$num_fields-1) {
						my $field_name = $field_names[$field_idx];
						my $varray = $array->getField($attr_idx,$field_idx);
						$varray->makePersistent();
						#printarray($varray);
						my $value;
						if ($varray->is_char()) {
							$value = $varray->getString();
						} elsif ($varray->is_numeric() || $varray->is_logical()) {
							$value = $varray->get(0,0);
						} else {
							my $class = $varray->class_name();
							die "Can't handle outputs of Matlab type $class";
						}
	
						# Don't put primary key ID's into the hash
						next if $field_name eq "id";
	
						# if element Aliasing is being used and this element has an alias
						if( exists $self->{__outputInstructions}->{$output}->{elementAliasing} and
							exists $self->{__outputInstructions}->{$output}->{elementAliases}->{$field_name} ) {
							$data_hash{
								$self->{__outputInstructions}->{$output}->{elementAliases}->{$field_name}
							} = $value;
						} else {
							$data_hash{$field_name} = $value;
						}
					}
					print "data hash:\n\t".join( "\n\t", map( $_." => ".$data_hash{$_}, keys %data_hash ) )."\n\n";
	                my $attribute = $self->newAttributes($semantic_type,\%data_hash);
				} 
				# output is not in a structure, it is in an ordered array
				else {
					$data_hash{
						$self->{__outputInstructions}->{$output}->{orderedArrayIndexes}->{$attr_idx}
					} = $array->get(0,$attr_idx);
				}
            }
            my $attribute = $self->newAttributes($semantic_type,\%data_hash)
				if( not $outputIsStruct );
        }
    }

    OME::SemanticType->GuessRows($old_guess);
}

sub startAnalysis {
    my ($self,$module_execution) = @_;
    $self->SUPER::startAnalysis($module_execution);

    $self->__openEngine();
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
        $self->
          placeAttributes($formal_input->name(),
                          $semantic_type,
                          $attribute_list);
    }
}

sub executeGlobal {
    my ($self) = @_;
    $self->SUPER::executeGlobal();
    $self->placeInputs('G');
    $self->__execute() if $self->{__executeAt} eq 'executeGlobal';
}

sub startDataset {
    my ($self,$dataset) = @_;
    $self->SUPER::startDataset($dataset);
    $self->placeInputs('G');
    $self->placeInputs('D');
    $self->__execute() if $self->{__executeAt} eq 'startDataset';
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
