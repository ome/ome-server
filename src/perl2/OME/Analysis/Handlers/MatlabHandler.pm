# OME/Analysis/MatlabHandler.pm

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


package OME::Analysis::MatlabHandler;

=head1 NAME

OME::Analysis::MatlabHandler - analysis handler for interfacing with
Matlab routines

=head1 SYNOPSIS

	use OME::Analysis::MatlabHandler;

=head1 DESCRIPTION

Boo.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Analysis::DefaultLoopHandler;
use base qw(OME::Analysis::DefaultLoopHandler);
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
    my ($proto,$location,$session,$chain_execution,$module,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,
                                  $chain_execution,$module,$node);

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

    my $module                = $self->{_module};
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
        $references{$reference->getAttribute('Name')} = 1;
        print "   Ref $reference\n";
    }
    $self->{__references} = \%references;

    my $execute_at =
      $root->getAttribute('ExecutionPoint');
    $self->{__executeAt} = $execute_at;
    print "   Execute at $execute_at\n";

    my @input_tags =
      $root->getElementsByLocalName('Inputs')->[0]->
      getElementsByLocalName('Input');
    my @inputs;
    push @inputs, $_->getAttribute('Name') foreach @input_tags;
    $self->{__matlabInputs} = \@inputs;
    print "   Inputs @inputs\n";

    my @output_tags =
      $root->getElementsByLocalName('Outputs')->[0]->
      getElementsByLocalName('Output');
    my @outputs;
    push @outputs, $_->getAttribute('Name') foreach @output_tags;
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

        $engine->eval(q[addpath('/OME/matlab');]);
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

    my $location = $self->{_location};

    my $inputs = $self->{__matlabInputs};
    my @params = map { "ome_$_" } @$inputs;
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
    $self->{__engine}->eval($command);

    # Parse the outputs
    foreach my $output (@$outputs) {
        my $formal_output = $self->getFormalOutput($output);
        my $semantic_type = $formal_output->semantic_type();

        my $array = $self->{__engine}->getVariable("omeout_$output");
        $array->makePersistent();
        #print "Output $output - $array\n";
        #printarray($array);

        if (defined $array) {
            die "Outputs should be a structure!"
              if (!$array->is_struct());
            my $length = $array->n();
            my $num_fields = $array->getNumFields();
            my @field_names;
            push @field_names, $array->getFieldName($_)
              foreach (0..$num_fields-1);

            foreach my $attr_idx (0..$length-1) {
                my %data_hash;

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

                    $data_hash{$field_name} = $value;
                }

                my $attribute = $self->newAttributes($semantic_type,\%data_hash);
            }
        }
    }

    OME::SemanticType->GuessRows($old_guess);
}

sub startAnalysis {
    my ($self,$module_execution) = @_;
    $self->SUPER::startAnalysis($module_execution);

    $self->__openEngine();
}

sub globalInputs {
    my ($self,$input_hash) = @_;
    $self->SUPER::globalInputs($input_hash);

    foreach my $formal_input_name (keys %$input_hash) {
        my $semantic_type = $self->
          getFormalInput($formal_input_name)->semantic_type();
        $self->placeAttributes($formal_input_name,
                               $semantic_type,
                               $input_hash->{$formal_input_name});
    }
}

sub datasetInputs {
    my ($self,$input_hash) = @_;
    $self->SUPER::datasetInputs($input_hash);

    foreach my $formal_input_name (keys %$input_hash) {
        my $semantic_type = $self->
          getFormalInput($formal_input_name)->semantic_type();
        $self->placeAttributes($formal_input_name,
                               $semantic_type,
                               $input_hash->{$formal_input_name});
    }
}

sub imageInputs {
    my ($self,$input_hash) = @_;
    $self->SUPER::imageInputs($input_hash);

    foreach my $formal_input_name (keys %$input_hash) {
        my $semantic_type = $self->
          getFormalInput($formal_input_name)->semantic_type();
        $self->placeAttributes($formal_input_name,
                               $semantic_type,
                               $input_hash->{$formal_input_name});
    }
}

sub featureInputs {
    my ($self,$input_hash) = @_;
    $self->SUPER::featureInputs($input_hash);

    foreach my $formal_input_name (keys %$input_hash) {
        my $semantic_type = $self->
          getFormalInput($formal_input_name)->semantic_type();
        $self->placeAttributes($formal_input_name,
                               $semantic_type,
                               $input_hash->{$formal_input_name});
    }
}

sub precalculateGlobal {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'precalculateGlobal';
}

sub precalculateDataset {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'precalculateDataset';
}

sub precalculateImage {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'precalculateImage';
}

sub calculateFeature {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'calculateFeature';
}

sub postcalculateImage {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'postcalculateImage';
}

sub postcalculateDataset {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'postcalculateDataset';
}

sub postcalculateGlobal {
    my ($self) = @_;
    $self->__execute() if $self->{__executeAt} eq 'postcalculateGlobal';
}


1;
