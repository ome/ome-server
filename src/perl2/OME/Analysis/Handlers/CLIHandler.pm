# OME/Analysis/CLIHandler.pm

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


package OME::Analysis::CLIHandler;

use strict;
our $VERSION = '1.0';

use IO::File;

use base qw(OME::Analysis::Handler);

use fields qw(_outputHandle _currentImage);

sub new {
    my ($proto,$location,$factory,$program) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$factory,$program);

    bless $self,$class;
    return $self;
}


sub startDataset {
    my ($self,$dataset) = @_;
}


sub datasetInputs {
    my ($self,$inputHash) = @_;
}


sub precalculateDataset {
    my ($self) = @_;
}


sub startImage {
    my ($self,$image) = @_;

    my $dims = $image->Dimensions();

    my $dimString = "Dims=".$dims->size_x().",".$dims->size_y().
	",".$dims->size_z().",".$dims->num_waves().",".$dims->num_times().
	",".$dims->bits_per_pixel()/8;

    my $pathString = "Path=".$image->getFullPath();

    my $output = new IO::File;
    my $location = $self->{_location};
    open $output, "$location $pathString $dimString |" or
	die "Cannot open analysis program";

    print STDERR "      $location $pathString $dimString\n";

    $self->{_outputHandle} = $output;
    $self->{_currentImage} = $image;
}


sub imageInputs {
    my ($self,$inputHash) = @_;
}


sub precalculateImage {
    my ($self) = @_;
}


sub startFeature {
    my ($self,$feature) = @_;
}


sub featureInputs {
    my ($self,$inputHash) = @_;
}


sub calculateFeature {
    my ($self) = @_;
}


sub collectFeatureOutputs {
    my ($self) = @_;
    return {};
}


sub finishFeature {
    my ($self) = @_;
}


sub postcalculateImage {
    my ($self) = @_;
}


sub collectImageOutputs {
    my ($self) = @_;
    my $output = $self->{_outputHandle};
    my $program = $self->{_program};
    my $image = $self->{_currentImage};
    my $factory = $self->{_factory};

    my $headerString = <$output>;
    chomp $headerString;
    my @headers = split("\t",$headerString);

    my %outputs;
    my @outputs = $program->outputs();
    foreach my $formal_output (@outputs) {
	#print STDERR "      - ".$formal_output->name()."\n";
	$outputs{$formal_output->name()} = $formal_output;
    }

    my %imageOutputs;
    my @attributes;

    while (my $input = <$output>) {
	chomp $input;
	my @data = split("\t",$input);
	my $count = 0;
	my %attributes;
	foreach my $datum (@data) {
	    my $output_name = $headers[$count];
	    #print STDERR "      * $output_name\n";
	    #print STDERR "      $output_name = '$datum'\n";
	    my $formal_output = $outputs{$output_name};
	    my $column_type = $formal_output->column_type();
	    my $column_name = lc($column_type->column_name());
	    my $datatype = $column_type->datatype();
	    my $attribute;
	    if (exists $attributes{$datatype->id()}) {
		$attribute = $attributes{$datatype->id()};
	    } else {
		my $pkg = $datatype->requireAttributePackage();
		$attribute = $factory->newObject($pkg,{
		    image_id => $image->id()
		    });
		# so we can find it later
		$attributes{$datatype->id()} = $attribute;
		# so we can commit it later
		push @attributes, $attribute;
	    }

	    $attribute->set($column_name,$datum);
	    push @{$imageOutputs{$formal_output->name()}}, $attribute;
	    $count++;
	}
    }

    foreach my $attribute (@attributes) {
	$attribute->commit();
    }

    return \%imageOutputs;
}


sub finishImage {
    my ($self) = @_;
}


sub postcalculateDataset {
    my ($self) = @_;
}


sub collectDatasetOutputs {
    my ($self) = @_;
    return {};
}


sub finishDataset {
    my ($self) = @_;
}


1;
