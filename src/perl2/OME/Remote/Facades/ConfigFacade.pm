# OME/Remote/Facades/ConfigFacade.pm

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


package OME::Remote::Facades::ConfigFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Factory;

use OME::Remote::DTO::GenericAssembler;

=head1 NAME

OME::Remote::Facades::ConfigFacade - remote facade methods for
retrieving session configuration values

=cut

use constant DEFAULT_MODULE_SPEC =>
  {
   '.' => ['id','name','default_iterator','new_feature_tag'],
  };

use constant DEFAULT_CHAIN_SPEC =>
  {
   '.' => ['id','name'],
  };

sub configAnnotationModule {
    my ($proto,$spec) = shift;

    $spec = DEFAULT_MODULE_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $module = $session->Configuration()->annotation_module();
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($module,$spec);

    return $dto;
}

sub configOriginalFilesModule {
    my ($proto,$spec) = shift;

    $spec = DEFAULT_MODULE_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $module = $session->Configuration()->original_files_module();
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($module,$spec);

    return $dto;
}

sub configGlobalImportModule {
    my ($proto,$spec) = shift;

    $spec = DEFAULT_MODULE_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $module = $session->Configuration()->global_import_module();
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($module,$spec);

    return $dto;
}

sub configDatasetImportModule {
    my ($proto,$spec) = shift;

    $spec = DEFAULT_MODULE_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $module = $session->Configuration()->dataset_import_module();
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($module,$spec);

    return $dto;
}

sub configImageImportModule {
    my ($proto,$spec) = shift;

    $spec = DEFAULT_MODULE_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $module = $session->Configuration()->image_import_module();
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($module,$spec);

    return $dto;
}

sub configImportChain {
    my ($proto,$spec) = shift;

    $spec = DEFAULT_CHAIN_SPEC
      unless defined $spec && ref($spec) eq 'HASH';

    my $session = OME::Session->instance();
    my $chain = $session->Configuration()->import_chain();
    my $dto = OME::Remote::DTO::GenericAssembler->
      makeDTO($chain,$spec);

    return $dto;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
