# OME/Remote/Facades/AnnotationFacade.pm

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


package OME::Remote::Facades::AnnotationFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Tasks::AnnotationManager;
use OME::Remote::DTO::GenericAssembler;

=head1 NAME

OME::Remote::Facades::AnnotationFacade - implementation of remote
facade methods pertaining to annotation attributes

=cut

my %TARGET_CLASSES =
  (
   'D' => 'OME::Dataset',
   'I' => 'OME::Image',
   'F' => 'OME::Feature',
  );

use constant DEFAULT_MEX_SPEC =>
  {
   '.' => ['id','dependence','dataset','image','module'],
   'dataset' => ['id','name'],
   'image' => ['id','name'],
   'module' => ['id','name'],
  };

sub annotateAttributes {
    my $proto = shift;
    my $factory = OME::Session->instance()->Factory();
    my $spec = shift;
    $spec = DEFAULT_MEX_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my @params;

    my $granularity = shift;
    die "Invalid granularity $granularity"
      unless $granularity =~ /^[GDIF]$/o;
    push @params, $granularity;

    if ($granularity ne 'G') {
        my $target_id = shift;
        my $target = $factory->
          loadObject($TARGET_CLASSES{$granularity},$target_id);
        die "Cannot load target $target_id"
          unless defined $target;
        push @params, $target;
    }

    my @new_ids;
    my $id_hash = {};

    while (@_) {
        my $st_id = shift;
        my $st = $factory->loadObject('OME::SemanticType',$st_id);
        die "Cannot find semantic type $st_id"
          unless defined $st;
        push @params, $st;

        my $data_hash = shift;
        delete $data_hash->{semantic_type};
        my $new_id = OME::Remote::DTO::GenericAssembler->
          __parseUpdateHash($st->requireAttributeTypePackage(),
                            $data_hash,$id_hash);

        push @new_ids, $new_id;
        push @params, $data_hash;
    }

    my ($mex,$attributes) = OME::Tasks::AnnotationManager->
      __annotate(@params);

    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($mex,$spec);
    my $hash = {MEX => $dto};
    foreach my $new_id (@new_ids) {
        print STDERR "    New $new_id\n";
        my $attribute = shift (@$attributes);
        $hash->{$new_id} = $attribute->id();
    }

    print STDERR "    $hash ",keys %$hash,"\n";
    return $hash;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
