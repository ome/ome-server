# OME/Analysis.pm

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


package OME::Analysis;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    program_id => 'program',
    experimenter_id => 'experimenter',
    dataset_id => 'dataset'
    });

__PACKAGE__->table('analyses');
__PACKAGE__->sequence('analysis_seq');
__PACKAGE__->columns(Primary => qw(analysis_id));
__PACKAGE__->columns(Timing => qw(run_start_time run_end_time));
__PACKAGE__->hasa('OME::Program' => qw(program_id));
__PACKAGE__->hasa('OME::Experimenter' => qw(experimenter_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));
__PACKAGE__->has_many('inputs','OME::Analysis::ActualInput' => qw(analysis_id));
__PACKAGE__->has_many('outputs','OME::Analysis::ActualOutput' => qw(analysis_id));


#    { $FormalInput => { attribute => $Attribute } }
# or { $FormalInput => { analysis  => $Analysis,
#                        output    => $FormalOutput } }

sub performAnalysis {
    my $self = shift;
    my $params = shift;
    my $program = $self->program();
    my $dataset = $self->dataset();
    my $images = $dataset->images();
    my $factory = $self->Factory();

    # This is going to be wicked inefficient in space.  For each of
    # the inputs which come from previous analyses, we have to be able
    # to pick out the outputs by image.  For now, this requires
    # reading each of the input analyses' outputs into a bunch of
    # hashes.

    my $formalInputs = $program->inputs();
    my $formalOutputs = $program->outputs();

    while (my $formalInput = $formalInputs->next()) {
	my $param = $params->{$formalInput};

	die "One of the inputs is not specified!"
	    unless defined $param;

	if (exists $param->{analysis}) {
	    # pull in all of the appropriate outputs.
	    my $analysis = $param->{analysis};
	    my $formalOutput = $param->{output};
	    my $actualOutputs = $analysis->outputs();
	    my $outputsByImage = {};

	    while (my $output = $actualOutputs->next()) {
		my $image = $output->image();
		$outputsByImage->{$image} = $output;
	    }

	    $param->{byImage} = $outputsByImage;
	} elsif (exists $param->{attribute}) {
	    # nothing special required
	} else {
	    die "There is an invalid input parameter!";
	}
    }

    # The main processing loop.  For each image in the dataset, set up
    # the inputs for this iteration, and delegate to the calculation
    # class to perform the analysis.

    my $class = $program->location();
    eval "require $class";
    my $delegate = $class->new($self);

    my @actualInputs;   # ie, all of them, for all images in the dataset
    my @actualOutputs;

    # Allow the delegate to perform any setup tasks required.
    $delegate->startAnalysis($dataset);
    
    foreach my $image (@$images) {
	my $imageParams = {};

	foreach my $formalInput (@$formalInputs) {
	    my $param = $params->{$formalInput};
	    my $attribute;
	    if (exists $param->{analysis}) {
		$attribute = $param->{byImage}->{$image}->Attribute();
	    } elsif (exists $param->{attribute}) {
		$attribute = $param->{attribute};
	    }

            my $inputData = {
                analysis => $self,
                formalInput => $formalInput,
                image => $image
                };
	    my $actualInput = $factory->createObject("OME::Analysis::ActualInput",$inputData);
	    $actualInput->Attribute($attribute);

	    push @actualInputs, $actualInput;
	    $imageParams->{$formalInput} = $attribute;
	}

	# This should return a hash in the form {$FormalOutput => $Attribute}
	my $result = $delegate->analyzeOneImage($image,$imageParams);

        while (my $formalOutput = $formalOutputs->next()) {
	    if (exists $result->{$formalOutput}) {
		my $attribute = $result->{$formalOutput};

                my $outputData = {
                    analysis => $self,
                    formalOutput => $formalOutput,
                    image => $image
                    };
		my $actualOutput = $factory->createObject("OME::Analysis::ActualOutput",$outputData);
		$actualOutput->Attribute($attribute);

		push @actualOutputs, $actualOutput;
	    }
	}
    }

    # Allow the delegate to perform cleanup tasks.
    $delegate->finishAnalysis();

    # Make sure the new analysis's fields are properly assigned.
    $self->inputs(\@actualInputs);
    $self->outputs(\@actualOutputs);

    # Make sure everything gets committed to the database.
    $self->commit();
    foreach my $input (@actualInputs) {
	$input->commit();
	$input->Attribute()->commit();
    }
    foreach my $output (@actualOutputs) {
	$output->commit();
	$output->Attribute()->commit();
    }
    $self->dbi_commit();
}



package OME::Analysis::ActualInput;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::Program;
use base qw(OME::DBObject);

use fields qw(_attribute);

__PACKAGE__->AccessorNames({
    analysis_id     => 'analysis',
    formal_input_id => 'formal_input'
    });

__PACKAGE__->table('actual_inputs');
__PACKAGE__->sequence('actual_input_seq');
__PACKAGE__->columns(Primary => qw(actual_input_id));
__PACKAGE__->columns(Essential => qw(attribute_id));
__PACKAGE__->hasa('OME::Analysis' => qw(analysis_id));
__PACKAGE__->hasa('OME::Program::FormalInput' => qw(formal_input_id));



sub attribute {
    my $self = shift;
    my $formalInput = $self->formal_input();
    my $columnType = $formalInput->column_type();
    my $dataType = $columnType->datatype();
    my $attributePackage = $dataType->getAttributePackage();

    if (@_) {
       	# We are setting the attribute; make sure it is of the
	# appropriate data type, and that it has an ID.

	my $result = $self->{_attribute};
	my $attribute = shift;
	die "This attribute is not of the correct type."
	    unless ($attribute->isa($attributePackage));
	die "This attribute does not have an ID."
	    unless (defined $attribute->ID());
	$self->attribute_id($attribute->ID());
	$self->{_attribute} = $attribute;
	return $result;
    } else {
	my $attribute = $self->{_attribute};
	if (!defined $attribute) {
	  $attribute = $self->Factory()->loadObject($attributePackage,
						    $self->attribute_id());
	  $self->{_attribute} = $attribute;
	}
	return $attribute;
    }
}


package OME::Analysis::ActualOutput;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::Program;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_id      => 'analysis',
    formal_output_id => 'formal_output'
    });

__PACKAGE__->table('actual_outputs');
__PACKAGE__->sequence('actual_output_seq');
__PACKAGE__->columns(Primary => qw(actual_output_id));
__PACKAGE__->columns(Essential => qw(attribute_id));
__PACKAGE__->hasa('OME::Analysis' => qw(analysis_id));
__PACKAGE__->hasa('OME::Program::FormalOutput' => qw(formal_output_id));


sub attribute {
    my $self = shift;
    my $formalOutput = $self->formal_output();
    my $columnType = $formalOutput->column_type();
    my $dataType = $columnType->datatype();
    my $attributePackage = $dataType->getAttributePackage();

    if (@_) {
       	# We are setting the attribute; make sure it is of the
	# appropriate data type, and that it has an ID.

	my $result = $self->{_attribute};
	my $attribute = shift;
	die "This attribute is not of the correct type."
	    unless ($attribute->isa($attributePackage));
	die "This attribute does not have an ID."
	    unless (defined $attribute->ID());
	$self->attribute_id($attribute->ID());
	$self->{_attribute} = $attribute;
	return $result;
    } else {
	my $attribute = $self->{_attribute};
	if (!defined $attribute) {
	  $attribute = $self->Factory()->loadObject($attributePackage,
						    $self->attribute_id());
	  $self->{_attribute} = $attribute;
	}
	return $attribute;
    }
}


1;
