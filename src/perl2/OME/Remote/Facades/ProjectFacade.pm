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

use OME::Session;
use OME::Project;

=head1 NAME

OME::Remote::Facades::ProjectFacade - implementation of remote facade
methods pertaining to project objects

=cut

sub addDatasetsToProject {
    my ($proto,$project_id,$dataset_ids) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $project = $factory->loadObject('OME::Project',$project_id);
    die "Project does not exist" unless defined $project;

    my @datasets;
    $dataset_ids = [$dataset_ids] unless ref($dataset_ids);
    foreach my $dataset_id (@$dataset_ids) {
        my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
        die "Dataset does not exist" unless defined $dataset;
        push @datasets, $dataset;
    }

    foreach my $dataset (@datasets) {
        $factory->maybeNewObject('OME::Project::DatasetMap',
                                 {
                                  project => $project,
                                  dataset => $dataset,
                                 });
    }

    return;
}

sub addDatasetToProjects {
    my ($proto,$project_ids,$dataset_id) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my @projects;
    $project_ids = [$project_ids] unless ref($project_ids);
    foreach my $project_id (@$project_ids) {
        my $project = $factory->loadObject('OME::Project',$project_id);
        die "Project does not exist" unless defined $project;
        push @projects, $project;
    }

    my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
    die "Dataset does not exist" unless defined $dataset;

    foreach my $project (@projects) {
        $factory->maybeNewObject('OME::Project::DatasetMap',
                                 {
                                  project => $project,
                                  dataset => $dataset,
                                 });
    }

    return;
}

sub removeDatasetsFromProject {
    my ($proto,$project_id,$dataset_ids) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $project = $factory->loadObject('OME::Project',$project_id);
    die "Project does not exist" unless defined $project;

    my @datasets;
    $dataset_ids = [$dataset_ids] unless ref($dataset_ids);
    foreach my $dataset_id (@$dataset_ids) {
        my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
        die "Dataset does not exist" unless defined $dataset;
        push @datasets, $dataset;
    }

    foreach my $dataset (@datasets) {
        my $link = $factory->
          findObject('OME::Project::DatasetMap',
                     {
                      project => $project,
                      dataset => $dataset,
                     });
        $link->deleteObject()
          if defined $link;
    }

    return;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
