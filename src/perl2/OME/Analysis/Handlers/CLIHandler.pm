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

use OME::Analysis::Handler;
use base qw(OME::Analysis::Handler);

use fields qw(_outputHandle);

sub new {
    my ($proto,$location,$session,$program,$node) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new($location,$session,$program,$node);

    bless $self,$class;
    return $self;
}


sub precalculateImage {
    my ($self) = @_;

    my $image = $self->getCurrentImage();

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
}


sub postcalculateImage {
    my ($self) = @_;

    my $output = $self->{_outputHandle};
    my $program = $self->{_program};
    my $image = $self->getCurrentImage();
    my $factory = $self->Factory();

    my $headerString = <$output>;
    chomp $headerString;
    my @headers = split("\t",$headerString);

    # The following hack is necessary now that inputs/outputs
    # are row-based instead of column-based.

    my %xy_hash = (
                   'Wave'       => ['wavenumber',
                                     ['Plane mean','Plane geomean','Plane sigma',
                                      'Plane minimum','Plane maximum',
                                      'Plane centroid']],
                   'Time'       => ['timepoint',
                                     ['Plane mean','Plane geomean','Plane sigma',
                                      'Plane minimum','Plane maximum',
                                      'Plane centroid']],
                   'Z'          => ['zsection',
                                     ['Plane mean','Plane geomean','Plane sigma',
                                      'Plane minimum','Plane maximum',
                                      'Plane centroid']],
                   'Min'        => ['min',['Plane minimum']],
                   'Max'        => ['max',['Plane maximum']],
                   'Mean'       => ['mean',['Plane mean']],
                   'GeoMean'    => ['geomean',['Plane geomean']],
                   'Sigma'      => ['sigma',['Plane sigma']],
                   'Centroid_X' => ['x',['Plane centroid']],
                   'Centroid_Y' => ['y',['Plane centroid']]
        );

    my %xyz_hash = (
                    'Wave'       => ['wavenumber',
                                     ['Stack mean','Stack geomean','Stack sigma',
                                      'Stack minimum','Stack maximum',
                                      'Stack centroid']],
                    'Time'       => ['timepoint',
                                     ['Stack mean','Stack geomean','Stack sigma',
                                      'Stack minimum','Stack maximum',
                                      'Stack centroid']],
                    'Min'        => ['min',['Stack minimum']],
                    'Max'        => ['max',['Stack maximum']],
                    'Mean'       => ['mean',['Stack mean']],
                    'GeoMean'    => ['geomean',['Stack geomean']],
                    'Sigma'      => ['sigma',['Stack sigma']],
                    'Centroid_x' => ['x',['Stack centroid']],
                    'Centroid_y' => ['y',['Stack centroid']],
                    'Centroid_z' => ['z',['Stack centroid']]
                   );

    my %hashes = (
                  'Plane statistics' => \%xy_hash,
                  'Stack statistics' => \%xyz_hash
                  );

#     my %output_names = (
#                         'Plane statistics' => 'Plane info',
#                         'Stack statistics' => 'Stack info'
#                         );

    my $useful_hash = $hashes{$program->program_name()};
    my %attribute_data;

    while (my $input = <$output>) {
        chomp $input;
        my @data = split("\t",$input);
        my $count = 0;

        foreach my $datum (@data) {
            my $output_name = $headers[$count];

            #print STDERR "      * $output_name\n";
            #print STDERR "      $output_name = '$datum'\n";
            #my $column_type = $formal_output->column_type();
            #my $column_name = lc($column_type->column_name());
            #my $datatype = $formal_output->datatype();

            my $column_info = $useful_hash->{$output_name};
            my $column_name = uc($column_info->[0]);
            my $output_list = $column_info->[1];

            foreach my $formal_output_name (@$output_list) {
                $attribute_data{$formal_output_name}->{$column_name} = $datum;
            }

            #print STDERR "      $column_name\n";
            #my $datatype = $column_type->datatype();
            #my $attribute;
            #if (exists $attributes{$datatype->id()}) {
            #    $attribute = $attributes{$datatype->id()};
            #} else {
            #    $attribute = $factory->newAttribute($datatype->table_name(),{
            #        image_id => $image->id()
            #        });
            #    # so we can find it later
            #    $attributes{$datatype->id()} = $attribute;
            #    # so we can commit it later
            #    push @attributes, $attribute;
            #}

            #$attribute_data->{$column_name} = $datum;
            $count++;
        }

        my $attributes = $self->newAttributes(%attribute_data);
    }

    #foreach my $attribute (@attributes) {
    #    $attribute->commit();
    #}
}


1;
