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
use Exporter;
use base qw(Exporter);

our @EXPORT = qw(%DATA_CLASSES);
our @EXPORT_OK = qw(%DATA_CLASSES);

our %DATA_CLASSES =
  (
   Project           => 'OME::Project',
   Dataset           => 'OME::Dataset',
   Image             => 'OME::Image',
   Feature           => 'OME::Feature',
   UserState         => 'OME::UserState',
   DataTable         => 'OME::DataTable',
   DataColumn        => 'OME::DataTable::Column',
   SemanticType      => 'OME::SemanticType',
   SemanticElement   => 'OME::SemanticType::Element',
   LookupTable       => 'OME::LookupTable',
   LookupTableEntry  => 'OME::LookupTable::Entry',
   Module            => 'OME::Module',
   FormalInput       => 'OME::Module::FormalInput',
   FormalOutput      => 'OME::Module::FormalOutput',
   ModuleCategory    => 'OME::Module::Category',
   AnalysisChain     => 'OME::AnalysisChain',
   AnalysisNode      => 'OME::AnalysisChain::Node',
   AnalysisLink      => 'OME::AnalysisChain::Link',
   AnalysisPath      => 'OME::AnalysisPath',
   AnalysisPathEntry => 'OME::AnalysisPath::Map',
   ModuleExecution   => 'OME::ModuleExecution',
   ActualInput       => 'OME::ModuleExecution::ActualInput',
   NodeExecution     => 'OME::AnalysisChainExecution::NodeExecution',
   ChainExecution    => 'OME::AnalysisChainExecution'
  );


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


sub __updateDTO {
    my ($class_name,$serialized,$id_hash) = @_;

    my $factory = OME::Session->instance()->Factory();

    die "Cannot update an object with no ID"
      unless defined $serialized->{id};
    my $id = $serialized->{id};
    delete $serialized->{id};

    # First, parse the serialized hash looking for references
    foreach my $key (keys %$serialized) {
        my $val = $serialized->{$key};
        if ($val =~ /^NEW:/) {
            # If we find a reference to a new object, we look for it in
            # $id_hash.  If it doesn't exist, then the user is trying to
            # save a reference to an object we don't know about, so we
            # have an error.

            my $object = $id_hash->{$val};
            die "Reference to a new object which has not been saved yet in $class_name $key $val"
              unless defined $object;
            $serialized->{$key} = $object;
        } elsif ($val =~ /^REF:(\w+):(\d+)$/) {
            # If we find a reference to an existing object, then just
            # store that reference in the field.

            my $ref_type = $1;
            my $id = $2;
            $serialized->{$key} = $id;  #$object;
        }
    }

    if ($id =~ /^NEW:/) {
        # If the ID of the object to be saved looks like a new ID, then
        # we call OME::Factory->newObject.  Also, we save this new
        # object into $id_hash, so that it can be found by other
        # objects being saved in this method call.

        my $object = $factory->newObject($class_name,$serialized);
        $id_hash->{$id} = $object;
        return ($id,$object->id());
    } else {
        # If the ID is just a number, then we're performing an update.
        # First we load in the specified object (dying if it doesn't
        # exist).  Then, for each key in the data hash, we use the
        # respective mutator method to set its new value.  Finally,
        # we call storeObject to perform the update.

        my $object = $factory->loadObject($class_name,$id);
        die "Cannot update nonexisting object $class_name $id"
          unless defined $object;
        foreach my $key (keys %$serialized) {
            $object->$key($serialized->{$key});
        }
        $object->storeObject();
        return;
    }
}

sub updateDTO {
    my ($proto,$object_type,$serialized) = @_;

    my $class_name = $DATA_CLASSES{$object_type};
    die "Unknown object type" unless defined $class_name;

    my @result = __updateDTO($class_name,$serialized,{});
    OME::Session->instance()->commitTransaction();

    return $result[1];
}

sub updateDTOList {
    my ($proto,$list) = @_;

    my $id_hash = {};
    my @result;
    while (my ($object_type,$serialized) = splice(@$list,0,2)) {
        my $class_name = $DATA_CLASSES{$object_type};
        die "Unknown object type" unless defined $class_name;

        push @result, __updateDTO($class_name,$serialized,$id_hash);
    }

    OME::Session->instance()->commitTransaction();

    return {@result};
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
