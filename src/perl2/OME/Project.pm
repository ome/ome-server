# OME/Project.pm

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


package OME::Project;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    owner_id => 'owner',
    group_id => 'group'
    });

__PACKAGE__->table('projects');
__PACKAGE__->sequence('project_seq');
__PACKAGE__->columns(Primary => qw(project_id));
__PACKAGE__->columns(Essential => qw(name description));
__PACKAGE__->has_many('dataset_links','OME::Project::DatasetMap' => qw(project_id));
__PACKAGE__->hasa('OME::Experimenter' => qw(owner_id));
__PACKAGE__->hasa('OME::Group' => qw(group_id));


sub datasets {
my $self = shift;
	return map $_->dataset(), $self->dataset_links();
}

sub unlockedDatasets {
my $self = shift;
	return grep {not $_->locked()} $self->datasets();
}

sub addDataset {
my $self = shift;
my $dataset = shift;

	return undef unless defined $dataset;
	my $pdMapIter = OME::Project::DatasetMap->search( dataset_id => $dataset->ID(), project_id => $self->ID() );
	my $pdMap = $pdMapIter->next() if defined $pdMapIter;
	if (not defined $pdMap) {
		$pdMap = OME::Project::DatasetMap->create ( {
			project_id => $self->ID(),
			dataset_id => $dataset->ID()
		} )
			or die ref($self)."->addDataset:  Could not create a new Project::DatasetMap entry.\n";

	}

	return $dataset;
}

sub addDatasetID {
my $self = shift;
my $datasetID = shift;

	my $dataset = OME::Dataset->retrieve ($datasetID);	
	return $self->addDataset($dataset);
}

# stub for future development
sub deleteDataset {

}

# stub for future development
sub deleteDatasetID {

}

# stub for future development
sub removeDataset {

}

# stub for future development
sub removeDatasetID {

}

# returns 1 if this project contains the dataset, else returns undef
sub doesDatasetBelong {
	my $self = shift;
	my $dataset = shift;
	
	return undef unless defined $dataset;
	my @datasets = OME::Project::DatasetMap->search( dataset_id => $dataset->ID(), project_id => $self->ID() );
	return 1 if scalar @datasets > 0;
	return undef;
}

# extension of doesDatasetBelong
sub doesDatasetBelongID {
	my $self = shift;
	my $datasetID = shift;
	my $dataset = $self->Session()->Factory()->loadObject("OME::Dataset",$datasetID);
	return $self->doesDatasetBelong($dataset);
}

sub newDataset {
my $self = shift;
my $datasetName = shift;
my $datasetDescription = shift if @_ > 0;

	my $dataset = OME::Dataset->create ( {
		name        => $datasetName,
		description => $datasetDescription,
		locked      => 'false',
		owner_id    => $self->owner()->ID(),
		group_id    => $self->owner()->group()->ID()
	} )
		or die ref($self)."->newDataset:  Could not create a new dataset.\n";
	
	return $self->addDataset($dataset);
}



package OME::Project::DatasetMap;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::Dataset;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    project_id   => 'project',
    dataset_id => 'dataset'
    });

__PACKAGE__->table('project_dataset_map');
__PACKAGE__->columns(Essential => qw(project_id dataset_id));
__PACKAGE__->hasa('OME::Project' => qw(project_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));


1;

