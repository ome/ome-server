# OME/Tasks/ProjectManager.pm

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
# Written by:    J-M Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Tasks::ProjectManager;

=head1 NAME

OME::Tasks::ProjectManager - manage user's projects

=head1 SYNOPSIS

	use OME::Tasks::ProjectManager;
	my $projectManager = new OME::Tasks::ProjectManager($session);

=head1 DESCRIPTION

The OME::Tasks::ProjectManager provides a list of methods to manage user's projects

=head1 OBTAINING A PROJECTMANAGER

To retrieve an OME::Tasks::ProjectManager to use for managing the project, the user must log in to OME.  This is done via the L<OME::SessionManager|OME::SessionManager> class.  Logging in via OME::SessionManager yields an L<OME::Session|OME::Session> object.

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);
	my $projectManager = new OME::Tasks::ProjectManager;

=head1 METHODS (ALPHABETICAL ORDER)

The following methods are available to a "ProjectManager."

=head2 add ($datasetID,$projectID)

	$projectManager->add($dataset->id(), $project->id());

	$projectManager->add($dataset->id());

Adds the "Dataset" by reference of its ID to the "Project" by reference of its ID. It also makes the dataset active by means of the "Session."

Note: The project ID is optional and if it is not defined the dataset is added to the current, active project ($session->Project());

=head2 change ($description,$name,$projectID)

	$projectManager->change(
		"My new description",
		"My new name",
		$project->id(),
	);
	
	$projectManager->change(
		"My new description",
		"My new name",
	);

Changes the "Project's" name and/or description by reference of its ID (or the current, active project if unspecified).

=head2 create ($hash_ref)

	$projectManager->create( {
		name => 'My New Project',
		description => 'A great new idea!',
		owner_id => $session->User()->ID(),
	});

Create a new project and update the OME session; sets the current dataset to undefined.

Note: This method is purely a macro for OME::Factory->newObject().

=head2 delete ($id)

	$projectManager->delete($project->id());

Delete a project and update OME session if the project is the current project.

Note: If the user doesn't have another project, the current active project and dataset are set to undefined. Otherwise the first arbitrary project and/or dataset are set to active.

=head2 getAllProjects ()

	my @projects = $projectManager->getAllProjects();

	Get all the projects in the database.

=head2 getUserProjects ($experimenter)

	my @user_projects = $projectManager->getUserProjects();
	my @other_user_projects = $projectManager->getUserProjects(
		$other_experimenter
	);

	Get all the projects owned by a given user.

Note: By default this method uses the Session's experimenter as a filter.

=head2 nameExists ($name)

	if ($projectManager->nameExists("A really good project name") {
		...

	} else {
		...
	}
		

Check if a given project name already exists in the database.

Returns successful (1) or unsuccessful (0) in matching.

=head2 listMatching ($userID,$array_ref)
	
	my $projects = $projectManager->listMatching();

	foreach (@$projects) {
		...
	}

Returns a list of all the project objects in the database.

	my $user_projects = $projectManager->listMatching(
		$session->User()->id(),
	);

	foreach (@$user_projects) {
		...
	}

Returns a list of all the project objects in the database owned by the specified user ID.

	my $related_projects = $projectManager->listMatching(
		$session->User()->id(),
		[ $ome_group_a->id(), $ome_group_b->id(), $ome_group_c->id() ],
	);

	foreach (@$related_projects) {
		...
	}

Returns a list of all the project objects in the database owned by the specified user ID or owned by one of the groups specified.

=head2 load ($projectID)

	my $project_a = $projectManager->load( 1 );
	my $project_b = $projectManager->load( 2 );

Returns a project object.

=head2 removeDatasets ($hash_ref)

	$projectManager->removeDatasets({
		$project1 => [1, 5, 10, 9],
		$project2 => [$dataset1, $dataset2],
	});

	$projectManager->removeDatasets({
		1 => [2, 7],
		5 => [$dataset5, $dataset9],
	})

Project removal method which accepts a hash reference keyed by either project object or project ID and containing a value comprised of an array reference of dataset objects or dataset ID's.

Returns 1 on success and undef on failure, this is an *all or nothing method* (either every remove is successful or the entire task fails)

=head2 switch ($id,$bool)

	$projectManager->switch(1, 1);

Switches the current active project. If the boolean switch is active other checking will be done on the session in order to preserve dataset integrity.

=cut

use strict;
use OME::SetDB;
use OME::DBObject;
OME::DBObject->Caching(0);

use OME;
our $VERSION = $OME::VERSION;
use Carp;

sub new{
	my $class=shift;
	my $self={};
	
	return bless($self,$class);
}

###############################
# Parameters:
# 	datasetID = dataset_id to add
#	projectID = if not defined, add to current project

sub add{
	my $self=shift;
	my $session=$self->Session();
	my ($datasetID,$projectID)=@_;
	my $project;

	if (defined $projectID){
	    $project=$session->Factory()->loadObject("OME::Project",$projectID);
	}else{
	    $project=$session->project();
	}

	my $dataset=$self->addToProject($datasetID,$project->id());
	$session->dataset($dataset);

	$session->storeObject();
	$session->commitTransaction();

	return $dataset;
}


#################
# Parameters: (void)
# 	
sub getAllProjects {
	my $self = shift;
	my $factory = $self->Session()->Factory();

	return $factory->findObjects("OME::Project");
};

#################
# Parameters: (experimenter object)
#
sub getUserProjects {
	my ($self, $experimenter) = shift;
	my $factory = $self->Session()->Factory();

	$experimenter = $self->Session()->User() unless defined $experimenter;

	return $factory->findObjects("OME::Project", owner_id => $experimenter->id());
}

#################
# Parameters
#	datasetId
#	projectID
sub addToProject{
    my $self=shift;
    my ($datasetID,$projectID)=@_;
    my $session=$self->Session();
    my $factory=$session->Factory();

    # maybeNewObject will work regardless of whether the values
    # are objects or ID's

    $factory->maybeNewObject("OME::Project::DatasetMap",
                             {
                              project_id => $projectID,
                              dataset_id => $datasetID,
                             });
    $session->commitTransaction();

    return ref($datasetID)?
      $datasetID:
      $factory->loadObject("OME::Dataset",$datasetID);
}


###############################
# Paramaters:
#	description = project's description 
#	name		= project's name
#	projectID	= projectId (optional)

sub change{
 	my $self=shift;
	my $session=$self->Session();
	my ($description,$name,$projectID)=@_;
	my $project;
	if (defined $projectID){
		$project=$session->Factory()->loadObject("OME::Project",$projectID);
	}else{
		$project=$session->project();
	}
	$project->name($name) if defined $name;
	$project->description($description) if defined $description;
	$project->storeObject();
	$session->commitTransaction();
	return 1;


}

#####################
# Parameters:
#	ref = project's informations

sub create{
	my $self=shift;
	my $session=$self->Session();
	my ($ref)=@_;
	my $existingDataset=$session->dataset();
	my $project = $session->Factory()->newObject("OME::Project", $ref);
	$project->storeObject();
	$session->project($project);
	if (defined $existingDataset){
		 $session->dataset(undef);
	}
	$session->storeObject();
	$session->commitTransaction();
	


	return 1;

}

######################
# Parameters:
#	id = project_id to delete

sub delete{
	my $self=shift;
	my $session=$self->Session();
	my ($id)=@_;
	my $result=undef;
	my $rep=undef;
	my $currentProject=$session->project();
	my $deleteProject=$session->Factory()->loadObject("OME::Project",$id);
	my @projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id() );
	 
	#my @datasets=$deleteProject->datasets();
	my @datasets=();
     	my @dMaps=$session->Factory()->findObjects(
			"OME::Project::DatasetMap",
			'project_id'=>$deleteProject->id()
		);
     	foreach my $d (@dMaps){
      		push(@datasets,$d->dataset());
    	} 

	my $db=new OME::SetDB(
		OME::DBConnection->DataSource(),
		OME::DBConnection->DBUser(),
		OME::DBConnection->DBPassword()
	);

	if (scalar(@datasets)>0){
	  $result=deleteProjectDatasetMap($deleteProject,\@datasets,$db);
	  return $result unless (defined $result);
	}

	if ($deleteProject->id()==$currentProject->id()){
	  if (scalar(@projects)==1){
	     $session->dataset(undef) if scalar(@datasets)>0;
	     $session->project(undef);
	     $session->storeObject();
		 $session->commitTransaction();
	  }else{
		$self->reorganizeSession($deleteProject,\@projects);
 	  }
	}

	$rep=deleteProject($deleteProject,$db);
	$db->Off();
	return $rep;
	 
}

################
# Parameters:
# name = project's name
# Return: 1 or 0

sub nameExists {
	my $self=shift;
	my $session=$self->Session();
	my ($name)=@_;
	my @list=$session->Factory()->findObjects("OME::Project",'name'=>$name);
	return scalar(@list) > 0 ? 1 : 0;
}



###############
# Parameters: 
#	userID (Optional)
#	$ref=ref array  list group_id (optional)
# Return: ref array of project objects owned by a given user.

sub listMatching{
	my $self=shift;
	my $session=$self->Session();
	my ($userID,$ref)=@_;
	my @projects=();
	if (defined $userID){
		@projects=$session->Factory()->findObjects("OME::Project",'owner_id'=>$session->User()->id());

	}else{
		if (defined $ref){
			foreach (@$ref){
			   push(@projects,$session->Factory()->findObjects("OME::Project",'group_id'=>$_));
			}
		
		}else{
			 @projects=$session->Factory()->findObjects("OME::Project");
		}
	}
	return \@projects;
}


############
# Parameters:
#	projectID =project_id to load
# Return: project object

sub load{
	my $self=shift;
	my $session=$self->Session();
	my ($projectID)=@_;
	my $project=$session->Factory()->loadObject("OME::Project",$projectID);
	return $project;
}

sub removeDatasets {
	my ($self, $to_remove) = @_;
	my $factory = $self->Session()->Factory();

	# Unless you give me something, go away
	return undef unless $to_remove;

	foreach my $project_key (keys %$to_remove) {
		my $project_id;
		my $sql = 'DELETE FROM project_dataset_map WHERE project_id = ';

		# Translate possible object key to a valid ID
		carp ref($project_key);
		if (ref($project_key) eq 'OME::Project') {
			carp "Object.";
			$project_id = $project_key->id();
		} else {
			$project_id = $project_key;
		}

		$sql .= $project_id . ' AND dataset_id in (';

		# Make sure we've got a set of datasets
		next unless defined $to_remove->{$project_key};

		my $i = 0;

		foreach my $dataset_id (@{$to_remove->{$project_key}}) {
			# Commas only if we're on at least the second element
			if ($i > 0) { $sql .= ','; }

			if (ref($dataset_id) eq 'OME::Dataset') {
				$dataset_id = $dataset_id->id();
			}
			
			$sql .= $dataset_id;
			++$i;
		}

		$sql .= ');';

		# Failure checking
		my $dbh;
		unless ($dbh = $factory->obtainDBH()) {
			carp "Failure to retrieve DBH";
			return;
		}

		carp $sql;
		$dbh->do($sql);
	
		if ($dbh->errstr) {
			carp $dbh->errstr, "rolling back.";
			$dbh->rollback;
			return;
		}

		$dbh->commit;
	}

	return 1;
}

		

###############
# Parameters:
#	id = project_id
#	bool (optional) = check associated dataset

sub switch{
	my $self=shift;
	my $session=$self->Session();
	my ($id,$bool)=@_;
	my $project=$session->Factory()->loadObject("OME::Project",$id);
	$session->project($project);
	if (not defined $bool){
	    my @datasets=();
     	    my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$project->id() );
     	    foreach my $d (@dMaps){
      		 push(@datasets,$d->dataset());
    	    }



	  #my @datasets=$project->datasets();
	  if (scalar(@datasets)==0){
	   $session->dataset(undef); 		
	  }else{
	   $session->dataset($datasets[0]);
	  }
	}

	$session->storeObject();
	$session->commitTransaction();

	return 1;
}


###########################
# PRIVATE METHODS		  #
###########################

# METHODS DON'T USE delete function of Class::DBI

sub deleteProject{
	my ($deleteProject,$db)=@_;
	my $tableProject="projects";	
 	my ($condition,$result);
 	$condition="project_id=".$deleteProject->id();
 	$result=do_request($tableProject,$condition,$db);
 	return (defined $result)?1:undef;
}


sub deleteProjectDatasetMap{
  	my ($deleteProject,$ref,$db)=@_;
  	my $tableProjectMap="project_dataset_map";
  	my $result;
  	foreach (@$ref){
   	 my ($condition);
    	 $condition="project_id=".$deleteProject->id()." AND dataset_id=".$_->id();
    	 $result=do_request($tableProjectMap,$condition,$db);
    	 return undef if (!defined $result);
	
      }
  	return (defined $result)?1:undef;
}



sub reorganizeSession{
	my ($self,$deleteProject,$ref)=@_;
	my $session = $self->Session(); 
	my @new=();
	foreach (@$ref){
        push(@new,$_) unless $_->id()==$deleteProject->id();
	}
	my $newproject=$new[0];
	my @newdataset=();
     	my @dMaps=$session->Factory()->findObjects("OME::Project::DatasetMap",'project_id'=>$newproject->id() );
     	foreach my $d (@dMaps){
      	push(@newdataset,$d->dataset());
    	}


	#my @newdataset=$newproject->datasets();
	$session->project($newproject);
	if (scalar(@newdataset)==0){
		$session->dataset(undef);	
	}else{
		$session->dataset($newdataset[0]);
	}
	$session->writeObject(); 
	return 1;
}

# Macro to return the Session instance
sub Session { return OME::Session->instance() }

sub do_request{
 	my ($table,$condition,$db)=@_;
 	my $result;
 	if (defined $db){
      	$result=$db->DeleteRecord($table,$condition);
	 }
 	return $result;
}

=head1 AUTHOR

JMarie Burel (jburel@dundee.ac.uk)

=head1 SEE ALSO

L<OME::Project|OME::Project>,
L<OME::DBObject|OME::DBObject>,
L<OME::Factory|OME::Factory>,
L<OME::SetDB|OME::SetDB>,

=cut

1;

