# OME/Remote/Facades/ProjectFacade.pm

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


package OME::Remote::Facades::ProjectFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Remote::DTO::ProjectAssembler;
use OME::Session;
use OME::Project;

=head1 NAME

OME::Remote::Facades::ProjectFacade - implementation of remote facade
methods pertaining to project objects

=cut

sub retrieveProject {
    my ($proto,$id) = @_;

    my $factory = OME::Session->instance()->Factory();
    my $project = $factory->loadObject('OME::Project',$id);
    die "Project does not exist" unless defined $project;

    my $dto = OME::Remote::DTO::ProjectAssembler->makeDTO($project);
    return $dto;
}

sub saveProject {
    my ($proto,$dto) = @_;
    OME::Remote::DTO::ProjectAssembler->updateDTO($dto);
    OME::Session->instance()->commitTransaction();
}

sub getProjectDatasetTree {
    my ($proto,$projectID) = @_;

    my $factory = OME::Session->instance()->Factory();
    my $project = $factory->loadObject('OME::Project',$id);
    die "Project does not exist" unless defined $project;

    my $dto = OME::Remote::DTO::ProjectAssembler->
      makeProjectDatasetTreeDTO($project);
    return $dto;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
