# OME/Remote/DTO/ProjectAssembler.pm

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


package OME::Remote::DTO::ProjectAssembler;
use OME;
our $VERSION = $OME::VERSION;

use OME::Remote::DTO;
use OME::Project;

=head1 NAME

OME::Remote::DTO::ProjectAssembler - routines for creating/parsing
ProjectDTO's from internal Project objects

=cut

sub makeDTO {
    my ($proto,$project) = @_;

    my $dto = __makeHash($project,'OME::Project',
                         ['id','name','description']);

    # TODO: Add the owner and group

    my $owner = $project->owner();
    $dto->{owner} = __makeHash($owner,undef,
                               ['FirstName','LastName','Email',
                                'Institution']);

    return $dto;
}

sub updateDTO {
    my ($proto,$dto) = @_;
    __updateHash($dto,'OME::Project',
                 ['name','description']);

    # TODO: Update the owner and group
}

sub makeProjectDatasetTree {
    my ($proto,$project) = @_;

    my $dto = __makeHash($project,'OME::Project',
                         ['id','name']);

    my @datasets = $project->datasets();
    $dto->{datasets} = [];
    foreach my $dataset (@datasets) {
        my $ds_dto = __makeHash($dataset,undef,
                                ['id','name']);
        push @{$dto->{datasets}}, $ds_dto;
    }

    return $dto;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
