# OME/Project.pm

# Copyright (C) 2003 Open Microscopy Environment
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
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    });

__PACKAGE__->table('projects');
__PACKAGE__->sequence('project_seq');
__PACKAGE__->columns(Primary => qw(project_id));
__PACKAGE__->columns(Essential => qw(name description owner_id group_id));
__PACKAGE__->has_many('dataset_links','OME::Project::DatasetMap' => qw(project_id));

sub owner {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "Owner must be an Experimenter"
          unless $attribute->semantic_type()->name() eq "Experimenter";
        $self->owner_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Experimenter",
                                                          $self->owner_id());
    }
}

sub group {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        die "group must be a Group attribute"
          unless $attribute->semantic_type()->name() eq "Group";
        $self->group_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Group",
                                                          $self->group_id());
    }
}

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
	my $factory=$self->Session()->Factory();
	my $pdMap = $factory->findObject("OME::Project::DatasetMap",
		 dataset_id => $dataset->ID(),
		 project_id => $self->ID()
	);
	

	#my $pdMapIter = OME::Project::DatasetMap->search( dataset_id => $dataset->ID(), project_id => $self->ID() );
	#my $pdMap = $pdMapIter->next() if defined $pdMapIter;

	if (not defined $pdMap) {
		$pdMap=$factory->newObject("OME::Project::DatasetMap",{
			project_id => $self->ID(),
			dataset_id => $dataset->ID()

			} );

		#$pdMap = OME::Project::DatasetMap->create ( {
		#	project_id => $self->ID(),
		#	dataset_id => $dataset->ID()
		#} )
		#	or die ref($self)."->addDataset:  Could not create a new Project::DatasetMap entry.\n";

	}

	return $dataset;
}

sub addDatasetID {
	
	my $self = shift;
	my $datasetID = shift;
	my $factory=$self->Session()->Factory();
	#my $dataset = OME::Dataset->retrieve ($datasetID);
	my $dataset	=$factory->loadObject("OME::Dataset",$datasetID);
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
	my $factory=$self->Session()->Factory();
	return undef unless defined $dataset;
	my @datasets =$factory->findObjects("OME::Project::DatasetMap",
				 dataset_id => $dataset->ID(), 
				 project_id => $self->ID()
				);



	#my @datasets = OME::Project::DatasetMap->search( dataset_id => $dataset->ID(), project_id => $self->ID() );
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

    my $factory = $self->Session()->Factory();
    my $owner = $factory->loadAttribute("Experimenter",$self->owner_id());
    my $group = $owner->Group();
    my $dataset=$factory->newObject("OME::Dataset",{
		name        => $datasetName,
		description => $datasetDescription,
		locked      => 'false',
		owner_id    => $owner->id(),
		group_id    => $group->id(),
	} );

	#my $dataset = OME::Dataset->create ( {
	#	name        => $datasetName,
	#	description => $datasetDescription,
	#	locked      => 'false',
	#	owner_id    => $owner->id(),
	#	group_id    => $group->id(),
	#} )
	#	or die ref($self)."->newDataset:  Could not create a new dataset.\n";
	
	return $self->addDataset($dataset);
}



package OME::Project::DatasetMap;

use strict;
our $VERSION = 2.000_000;

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


# Our current caching implements breaks when there is not a single
# primary key column for the table.  As this is the case for this
# table, turn off caching (just for this class).

__PACKAGE__->Caching(0);

1;

