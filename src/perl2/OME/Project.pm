# OME/Project.pm

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


package OME::Project;

=head1 NAME

OME::Project - a collection of datasets

=head1 DESCRIPTION

The C<Project> class represents OME projects, which are a collection
of datasets.  Projects and datasets form a many-to-many map, as do
images and datasets.  A user's session usually has a single project
selected as the "active project".

=head1 METHODS (C<Project>)

The following methods are available to C<Project> in addition to those
defined by L<OME::DBObject>.

=head2 name

	my $name = $project->name();
	$project->name($name);

Returns or sets the name of this project.

=head2 description

	my $description = $project->description();
	$project->description($description);

Returns or sets the description of this project.

=head2 owner

	my $owner = $project->owner();
	$project->owner($owner);

Returns or sets the owner of this project.

=head2 group

	my $group = $project->group();
	$project->group($group);

Returns or sets the group that this project belongs to.

=head2 ...

	other methods exist. check out the code to see them.


=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setSequence('project_seq');
__PACKAGE__->setDefaultTable('projects');
__PACKAGE__->addPrimaryKey('project_id');
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn('owner_id' => 'owner_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'experimenters',
                       });
__PACKAGE__->addColumn('group_id' => 'group_id',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'groups',
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->addColumn(view => 'view',{SQLType => 'varchar(64)'});

# Has-manys don't do anything yet, but this is what they'd look like.
__PACKAGE__->hasMany('dataset_links','OME::Project::DatasetMap','project');


# Added by IGG to restore the datasets() method.
# FIXME:  Please remove when hasMany gets supported.
sub datasets {
	my $self = shift;
	my $factory = $self->Session()->Factory();
	my @projectDatasets = $factory->findObjects("OME::Project::DatasetMap",
				 project_id => $self->ID()
				);
	my @datasets;
	foreach (@projectDatasets) {
		push (@datasets,$factory->loadObject ('OME::Dataset',$_->dataset_id()) );
	} 
	return @datasets;
	
}

sub owner {
    my $self = shift;
    if (@_) {
        my $attribute = shift;
        $attribute->verifyType('Experimenter');
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
        $attribute->verifyType('Group');
        $self->group_id($attribute->id());
        return undef;
    } else {
        return $self->Session()->Factory()->loadAttribute("Group",
                                                          $self->group_id());
    }
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
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
#use OME::Dataset;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('project_dataset_map');
__PACKAGE__->addColumn('project_id','project_id');
__PACKAGE__->addColumn('project','project_id','OME::Project',
                      {
                       SQLType => 'integer',
                       NotNull => 1,
                       ForeignKey => 'projects',
                      });
__PACKAGE__->addColumn('dataset_id','dataset_id');
__PACKAGE__->addColumn('dataset','dataset_id','OME::Dataset',
                      {
                       SQLType => 'integer',
                       NotNull => 1,
                       ForeignKey => 'datasets',
                      });


# Our current caching implements breaks when there is not a single
# primary key column for the table.  As this is the case for this
# table, turn off caching (just for this class).

__PACKAGE__->Caching(0);


1;
