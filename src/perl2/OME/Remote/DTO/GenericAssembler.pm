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

sub getDataClass {
    my ($proto,$object_type) = @_;

    my $class;
    if ($object_type =~ /^\@(\w+)$/) {
        my $st_name = $1;
        my $factory = OME::Session->instance()->Factory();
        my $type = $factory->
          findObject('OME::SemanticType',name => $st_name);
        die "Unknown semantic type $st_name"
          unless defined $type;
        $class = $type->requireAttributeTypePackage();
        die "Error loading semantic type package for $st_name"
          unless defined $class;
    } else {
        $class = $DATA_CLASSES{$object_type};
        die "Unknown object type $object_type"
          unless defined $class;
    }

    OME::Factory->__checkClass($class);
    return $class;
}

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
        } elsif ($type =~ m/(has-many|many-to-many)/o ) {
            foreach my $ref_object (@{$dto->{$column}}) {
                $ref_object = __genericDTO("${prefix}.${column}",
                                           $ref_object,$fields_wanted);
            }
        }
    }

    # Every object had better have its ID.
    $dto->{id} = $object->id()
      if (UNIVERSAL::can($object,"id"));

    # Every attribute had better have its semantic type.  If the user
    # doesn't specify what part of the semantic type, they get the ID
    # and name.

    if (UNIVERSAL::isa($object,"OME::SemanticType::Superclass")) {
        my $st_prefix = "${prefix}.semantic_type";
        my $st = $object->semantic_type();
        $fields_wanted->{$st_prefix} = ['id','name','granularity']
          unless defined $fields_wanted->{$st_prefix};
        $dto->{semantic_type} = __genericDTO($st_prefix,$st,$fields_wanted);
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
        } elsif ($val =~ /^REF:([\w@]+):(\d+)$/) {
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

        my $object;
        if (UNIVERSAL::isa($class_name,"OME::SemanticType::Superclass")) {
            my $type = $class_name->semantic_type();
            $object = $factory->newAttribute($type,undef,undef,$serialized);
        } else {
            $object = $factory->newObject($class_name,$serialized);
        }
        die "Could not create object $id"
          unless defined $object;
        $id_hash->{$id} = $object;
        return ($id,$object->id());
    } else {
        # If the ID is just a number, then we're performing an update.
        # First we load in the specified object (dying if it doesn't
        # exist).  Then, for each key in the data hash, we use the
        # respective mutator method to set its new value.  Finally,
        # we call storeObject to perform the update.

        my $object;
        if (UNIVERSAL::isa($data_class,"OME::SemanticType::Superclass")) {
            my $type = $data_class->semantic_type();
            $object = $factory->loadAttribute($type,$id);
        } else {
            $object = $factory->loadObject($class_name,$id);
        }
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

    my $data_class = $proto->getDataClass($object_type);

    my @result = __updateDTO($data_class,$serialized,{});

    return $result[1];
}

sub updateDTOList {
    my ($proto,$list) = @_;

    my $id_hash = {};
    my @result;
    while (my ($object_type,$serialized) = splice(@$list,0,2)) {
        my $data_class = $proto->getDataClass($object_type);

        push @result, __updateDTO($data_class,$serialized,$id_hash);
    }

    return {@result};
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
