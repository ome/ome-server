# OME/Remote/Facades/GenericFacade.pm

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


package OME::Remote::Facades::GenericFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Factory;

use OME::Remote::DTO::GenericAssembler;

=head1 NAME

OME::Remote::Facades::GenericFacade - remote facade methods for
retrieving arbitrary DBObjects and Attributes

=cut

sub countObjects {
    my ($proto,$object_type,$criteria) = @_;

    my $class_name = OME::Remote::DTO::GenericAssembler->
      getDataClass($object_type);
    my $factory = OME::Session->instance()->Factory();

    die "Criteria must be a hash, not $criteria"
      if (defined $criteria) && (ref($criteria) ne 'HASH');

    return $factory->countObjects($class_name,$criteria);
}

sub loadObject {
    my ($proto,$object_type,$id,$fields_wanted) = @_;

    my $class_name = OME::Remote::DTO::GenericAssembler->
      getDataClass($object_type);
    my $factory = OME::Session->instance()->Factory();

    die "Fields wanted must be a hash, not $fields_wanted"
      if (defined $fields_wanted) && (ref($fields_wanted) ne 'HASH');

    my $result = $factory->loadObject($class_name,$id);
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($result,$fields_wanted);

    return $dto;
}

sub retrieveObject {
    my ($proto,$object_type,$criteria,$fields_wanted) = @_;

    my $class_name = OME::Remote::DTO::GenericAssembler->
      getDataClass($object_type);
    my $factory = OME::Session->instance()->Factory();

    die "Criteria must be a hash, not $criteria"
      if (defined $criteria) && (ref($criteria) ne 'HASH');

    die "Fields wanted must be a hash, not $fields_wanted"
      if (defined $fields_wanted) && (ref($fields_wanted) ne 'HASH');

    my $result = $factory->findObject($class_name,$criteria);
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($result,$fields_wanted);

    return $dto;
}

sub retrieveObjects {
    my ($proto,$object_type,$criteria,$fields_wanted) = @_;

    my $class_name = OME::Remote::DTO::GenericAssembler->
      getDataClass($object_type);
    OME::Factory->__checkClass($class_name);
    my $factory = OME::Session->instance()->Factory();

    die "Criteria must be a hash, not $criteria"
      if (defined $criteria) && (ref($criteria) ne 'HASH');

    die "Fields wanted must be a hash, not $fields_wanted"
      if (defined $fields_wanted) && (ref($fields_wanted) ne 'HASH');

    my @result = $factory->findObjects($class_name,$criteria);
    my $dtos = OME::Remote::DTO::GenericAssembler->
      makeDTOList(\@result,$fields_wanted);

    return $dtos;
}

sub updateObject {
    my ($proto,$object_type,$serialized) = @_;

    my $factory = OME::Session->instance()->Factory();

    die "Serialized object must be a hash, not $serialized"
      if (defined $serialized) && (ref($serialized) ne 'HASH');

    return OME::Remote::DTO::GenericAssembler->
        updateDTO($object_type,$serialized);
}

sub updateObjects {
    my ($proto,$list) = @_;

    return OME::Remote::DTO::GenericAssembler->
      updateDTOList($list);
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut

