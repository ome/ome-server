#!/usr/bin/perl -w
# OME/Tests/ImportTest.pl

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


use OME::Image;
use OME::Dataset;
use OME::Project;
use OME::Session;
use OME::SessionManager;
use OME::Tasks::ImageTasks;
use OME::Project;
use Term::ReadKey;

print "\nOME Test Case - Image Import\n";
print "----------------------------\n";

if (scalar(@ARGV) == 0) {
    print "Usage:  ImportTest dataset_name [file list]\n\n";
    exit -1;
}

print "Please login to OME:\n";

print "Username? ";
ReadMode(1);
my $username = ReadLine(0);
chomp($username);

print "Password? ";
ReadMode(2);
my $password = ReadLine(0);
chomp($password);
print "\n";
ReadMode(1);

my $manager = OME::SessionManager->new();
my $session = $manager->createSession($username,$password);

if (!defined $session) {
    print "That username/password does not seem to be valid.\nBye.\n\n";
    exit -1;
}

print "Great, you're in.\n\n";

my $projectName = "ImportTest2 project";
my $projectDesc = "This project was created by the ImportTest test case.";
my $projectUser = $session->User();
my $projectGroup;
my $status = 1;
my $age;
my $data;
my $project;
my $project_id;
my @projects;

# See if this project already defined. If not, create it.

@projects = OME::Project->search(name => $projectName);
if (scalar @projects > 0) {
    $project = $projects[0];    # it exists, retrieve it from the DB
    $project_id = $project->ID();
    $project = $session->Factory()->loadObject("OME::Project", $project_id);
    $status = 0
	unless defined $project;
    $age = "old";
}
else {             # otherwise create it
    print STDERR "- Creating a new project...\n";
    $age = "new";
    $projectGroup = $projectUser->group()->ID();
    $data = {name => $projectName,
		description => $projectDesc,
	        owner_id => $projectUser->ID(),
	        group_id => $projectGroup};
    $project = $session->Factory()->newObject("OME::Project", $data);
    if (!defined $project) {
	$status = 0;
	print " failed to create new project $projectName.\n";
    }
    else {
	$project->writeObject();
    }
}

# Die if we don't have a project object at this juncture.
die "Project undefined\n" unless defined $project;

# Now, get a dataset.
# The dataset name on the command line either matches an existing unlocked dataset owned by the current user,
# or is the name of a new dataset.
# Either way, we must associate the dataset with the current project.

my $datasetName = shift; # from @ARGV
my $datasetIter = OME::Dataset->search3(name => $datasetName, owner_id => $projectUser->ID(), locked => 'false');
my $dataset = $project->addDataset ($datasetIter->next()) if defined $datasetIter;
$dataset = $project->newDataset ($datasetName) unless defined $dataset;

# die if we still don't have a dataset object.
die "Dataset undefined\n" unless defined $dataset;

$session->project($project);
$session->dataset($dataset);
$session->writeObject();
	print "- Importing files into $age project '$projectName'... ";
	OME::Tasks::ImageTasks::importFiles($session, $dataset, \@ARGV);
	print "done.\n";

exit 0;

