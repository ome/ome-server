# OME/Remote/DTO/GenericAssembler.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
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


package OME::Remote::DTO::GenericAssembler;
use OME;
our $VERSION = $OME::VERSION;

our $SHOW_ASSEMBLY = 0;

use OME::Remote::DTO;

=head1 NAME

OME::Remote::DTO::GenericAssembler - routines for creating/parsing
arbitrary DTO's from internal DBObjects

=cut

sub __massageFieldsWanted ($) {
    my $fields_wanted = shift;

    # We need to massage the $fields_wanted hash to make it useful to
    # the __makeDTO helper method.

    my %massaged;

    foreach my $key (%$fields_wanted) {
        if ($key eq ".") {
            $massaged{""} = $fields_wanted->{$key};
        } else {
            $massaged{".${key}"} = $fields_wanted->{$key};
        }
    }

    return \%massaged;
}

sub makeDTO {
    my ($proto,$object,$fields_wanted) = @_;
    $fields_wanted = __massageFieldsWanted($fields_wanted);
    return __genericDTO("",$object,$fields_wanted);
}

sub makeDTOList {
    my ($proto,$object_list,$fields_wanted) = @_;
    $fields_wanted = __massageFieldsWanted($fields_wanted);
    my @dto_list;

    foreach my $object (@$object_list) {
        push @dto_list, __genericDTO("",$object,$fields_wanted);
    }
    return \@dto_list;
}

sub __genericDTO {
    my ($prefix,$object,$fields_wanted) = @_;

    print STDERR "$prefix $object\n" if $SHOW_ASSEMBLY;

    my $columns = $fields_wanted->{$prefix};
    die "Fields not specified for '$prefix' element"
      unless (defined $columns) && (ref($columns) eq 'ARRAY');
    my $dto = __makeHash($object,undef,$columns);
    return $dto unless defined $dto;

    foreach my $column (@$columns) {
        print STDERR "  $column ",ref($dto->{$column}),"\n"
          if $SHOW_ASSEMBLY;

        my $type = $object->getColumnType($column);
        # __makeHash will have already ensured that each column exists

        # If this is an attribute reference, load the appropriate
        # ST class
        $object->__activateSTColumn($column);

        if ($type eq 'has-one') {
            my $ref_object = $dto->{$column};
            $dto->{$column} = __genericDTO("${prefix}.${column}",
                                           $ref_object,$fields_wanted);
        } elsif ($type eq 'has-many') {
            foreach my $ref_object (@{$dto->{$column}}) {
                $ref_object = __genericDTO("${prefix}.${column}",
                                           $ref_object,$fields_wanted);
            }
        }
    }

    print STDERR "/$prefix\n"
      if $SHOW_ASSEMBLY;

    return $dto;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
