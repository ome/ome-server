#!/usr/bin/perl -w
# OME/Tests/ImportTest.pl

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


use OME::Session;
use OME::SessionManager;
use OME::Tasks::ImageTasks;
use OME::Tasks::DatasetManager;
use Log::Agent;

use Benchmark qw(timediff timestr);

print "\nOME Test Case - Image Import\n";
print "----------------------------\n";

if ((scalar(@ARGV) == 0) || (($ARGV[0] =~ m/^-*/) && (scalar(@ARGV) == 1))) {
    print "Usage:  ImportTest dataset_name [file list]\n\n";
    exit -1;
}

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

OME::DBObject->Caching(1) if ($ENV{'OME_CACHE'});

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

$project = $factory->
  findObject("OME::Project",
             name => $projectName);

if (defined $project) {
    $project_id = $project->ID();
    $status = 0;
    $age = "old";
}
else {             # otherwise create it
    print STDERR "- Creating a new project...\n";
    $age = "new";
    $projectGroup = $projectUser->Group()->id();
    $data = {name => $projectName,
             description => $projectDesc,
	        owner_id => $projectUser->id(),
	        group_id => $projectGroup};
    $project = $factory->newObject("OME::Project", $data);
    if (!defined $project) {
	$status = 0;
	print " failed to create new project $projectName.\n";
    }
    else {
	$project->storeObject();
    $session->commitTransaction();
    }
}

# Die if we don't have a project object at this juncture.
die "Project undefined\n" unless defined $project;

# Now, get a dataset.
# The dataset name on the command line either matches an existing unlocked dataset owned by the current user,
# or is the name of a new dataset.
# Either way, we must associate the dataset with the current project.

my $switch;
if (($ARGV[0]) =~ m/^-/) {
    $switch = shift;  # if 1st arg in ARGV starts w/ a "-" it's a switch
}
my $datasetName = shift; # from @ARGV
my $datasetIter = $factory->
  findObjects("OME::Dataset",
              name => $datasetName,
              owner_id => $projectUser->ID(),
              locked => 'false');
my $dataset = $project->addDataset ($datasetIter->next()) if defined $datasetIter;
$dataset = $project->newDataset ($datasetName) unless defined $dataset;

# die if we still don't have a dataset object.
die "Dataset undefined\n" unless defined $dataset;

$session->project($project);
$session->dataset($dataset);
$session->storeObject();
$session->commitTransaction();
	print "- Importing files into $age project '$projectName'... \n";
my $t0 = new Benchmark;
	my $datasetManager = new OME::Tasks::DatasetManager;
	my $images = OME::Tasks::ImageTasks::importFiles(@ARGV);
	my @image_ids = map($_->id(), @$images);
	$datasetManager->addImages( \@image_ids, $dataset->id());
my $t1 = new Benchmark;
	print "done.\n";

my $td = timediff($t1,$t0);
print "\nTiming:\n".timestr($td)."\n";

exit 0;

