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
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id           => ['ANALYSES','ANALYSIS_ID',
			 {sequence => 'ANALYSIS_SEQ'}],
	program      => ['ANALYSES','PROGRAM_ID',
			 {reference => 'OME::Program'}],
	experimenter => ['ANALYSES','EXPERIMENTER_ID',
			 {reference => 'OME::Experimenter'}],
	dataset      => ['ANALYSES','DATASET_ID',
			 {reference => 'OME::Dataset'}],
	startTime    => ['ANALYSES','RUN_START_TIME'],
	endTime      => ['ANALYSES','RUN_END_TIME'],
	inputs       => ['ACTUAL_INPUTS','ACTUAL_INPUT_ID',
			 {map       => 'ANALYSIS_ID',
			  reference => 'OME::Analysis::ActualInput'}],
	outputs      => ['ACTUAL_OUTPUTS','ACTUAL_OUTPUT_ID',
			 {map       => 'ANALYSIS_ID',
			  reference => 'OME::Analysis::ActualOutput'}]
    };

    return $self;
}

#    { $FormalInput => { attribute => $Attribute } }
# or { $FormalInput => { analysis  => $Analysis,
#                        output    => $FormalOutput } }

sub performAnalysis {
    my $self = shift;
    my $params = shift;
    my $program = $self->Field("program");
    my $dataset = $self->Field("dataset");
    my $images = $dataset->Field("images");
    my $factory = $self->Factory();

    # This is going to be wicked inefficient in space.  For each of
    # the inputs which come from previous analyses, we have to be able
    # to pick out the outputs by image.  For now, this requires
    # reading each of the input analyses' outputs into a bunch of
    # hashes.

    my $formalInputs = $program->Field("inputs");
    my $formalOutputs = $program->Field("outputs");
    
    foreach my $formalInput (@$formalInputs) {
	my $param = $params->{$formalInput};

	die "One of the inputs is not specified!"
	    unless defined $param;

	if (exists $param->{analysis}) {
	    # pull in all of the appropriate outputs.
	    my $analysis = $param->{analysis};
	    my $formalOutput = $param->{output};
	    my $actualOutputs = $analysis->Field("outputs");
	    my $outputsByImage = {};

	    foreach my $output (@$actualOutputs) {
		my $image = $output->Field("image");
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

    my $class = $program->Field("location");
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

	    my $actualInput = $factory->createObject("OME::Analysis::ActualInput");
	    $actualInput->Field("analysis",$self);
	    $actualInput->Field("formalInput",$formalInput);
	    $actualInput->Field("image",$image);
	    $actualInput->Attribute($attribute);

	    push @actualInputs, $actualInput;
	    $imageParams->{$formalInput} = $attribute;
	}

	# This should return a hash in the form {$FormalOutput => $Attribute}
	my $result = $delegate->analyzeOneImage($image,$imageParams);

	foreach my $formalOutput (@$formalOutputs) {
	    if (exists $result->{$formalOutput}) {
		my $attribute = $result->{$formalOutput};

		my $actualOutput = $factory->createObject("OME::Analysis::ActualOutput");
		$actualOutput->Field("analysis",$self);
		$actualOutput->Field("formalOutput",$formalOutput);
		$actualOutput->Field("image",$image);
		$actualOutput->Attribute($attribute);

		push @actualOutputs, $actualOutput;
	    }
	}
    }

    # Allow the delegate to perform cleanup tasks.
    $delegate->finishAnalysis();

    # Make sure the new analysis's fields are properly assigned.
    $self->Field("inputs",\@actualInputs);
    $self->Field("outputs",\@actualOutputs);

    # Make sure everything gets committed to the database.
    $self->writeObject();
    foreach my $input (@actualInputs) {
	$input->writeObject();
	$input->Attribute()->writeObject();
    }
    foreach my $output (@actualOutputs) {
	$output->writeObject();
	$output->Attribute()->writeObject();
    }
    $self->DBH()->commit();
}



package OME::Analysis::ActualInput;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
use OME::Program;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id          => ['ACTUAL_INPUTS','ACTUAL_INPUT_ID',
			{sequence => 'ACTUAL_INPUT_SEQ'}],
	analysis    => ['ACTUAL_INPUTS','ANALYSIS_ID',
			{reference => 'OME::Analysis'}],
	formalInput => ['ACTUAL_INPUTS','FORMAL_INPUT_ID',
			{reference => 'OME::Program::FormalInput'}],
	image       => ['ACTUAL_INPUTS','IMAGE_ID',
			{reference => 'OME::Image'}],
	attributeID => ['ACTUAL_INPUTS','ATTRIBUTE_ID']
    };

    $self->{attribute} = undef;

    return $self;
}


sub Attribute {
    my $self = shift;
    my $formalInput = $self->Field("formalInput");
    my $dataType = $formalInput->Field("dataType");

    if (@_) {
       	# We are setting the attribute; make sure it is of the
	# appropriate data type, and that it has an ID.

	my $result = $self->{attribute};
	my $attribute = shift;
	die "This attribute is not of the correct type."
	    if ($attribute->DataType() != $dataType);
	die "This attribute does not have an ID."
	    unless (defined $attribute->ID());
	$self->Field("attributeID",$attribute->ID());
	$self->{attribute} = $attribute;
	return $result;
    } else {
	my $attribute = $self->{attribute};
	if (!defined $attribute) {
	  $attribute = OME::Attribute->new($datatype);
	  $attribute->ID($self->Field("attributeID"));
	  $attribute->loadObject();
	  $self->{attribute} = $attribute;
	}
	return $attribute;
    }
}


package OME::Analysis::ActualInput;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
use OME::Program;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id           => ['ACTUAL_OUTPUTS','ACTUAL_OUTPUT_ID',
			 {sequence => 'ACTUAL_OUTPUT_SEQ'}],
	analysis     => ['ACTUAL_OUTPUTS','ANALYSIS_ID',
			 {reference => 'OME::Analysis'}],
	formalOutput => ['ACTUAL_OUTPUTS','FORMAL_OUTPUT_ID',
			 {reference => 'OME::Program::FormalOutput'}],
	image        => ['ACTUAL_OUTPUTS','IMAGE_ID',
			 {reference => 'OME::Image'}],
	attributeID  => ['ACTUAL_OUTPUTS','ATTRIBUTE_ID']
    };

    return $self;
}


sub Attribute {
    my $self = shift;
    my $formalOutput = $self->Field("formalOutput");
    my $dataType = $formalOutput->Field("dataType");

    if (@_) {
       	# We are setting the attribute; make sure it is of the
	# appropriate data type, and that it has an ID.

	my $result = $self->{attribute};
	my $attribute = shift;
	die "This attribute is not of the correct type."
	    if ($attribute->DataType() != $dataType);
	die "This attribute does not have an ID."
	    unless (defined $attribute->ID());
	$self->Field("attributeID",$attribute->ID());
	$self->{attribute} = $attribute;
	return $result;
    } else {
	my $attribute = $self->{attribute};
	if (!defined $attribute) {
	  $attribute = OME::Attribute->new($datatype);
	  $attribute->ID($self->Field("attributeID"));
	  $attribute->loadObject();
	  $self->{attribute} = $attribute;
	}
	return $attribute;
    }
}
