# OME/Util/Import.pm

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

package OME::Util::Import;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Term::ReadKey;
use File::Find;
use File::Spec::Functions qw(rel2abs);
use Getopt::Long;

use OME::SessionManager;
use OME::Session;
use OME::Tasks::ProjectManager;
use OME::Tasks::ImageTasks;

use Getopt::Long;
Getopt::Long::Configure("bundling");

sub import_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>] [<list of files>]

This utility imports files into OME database and runs the import analysis 
chain against them. The list of files can include directories. All files in 
the specified directory are imported.

The files can be proprietary format image files or OME XML files that define 
OME objects. 


Options:
      
  -d  Use this to specify the dataset name. If you are importing images, you 
      must specify a dataset. If you are importing OME Semantic Type 
      Definitions, Analysis Modules, or Chains this parameter is unnecessary.
      
  -i  With this flag, this utility runs in interactive mode prompting you to 
      enter file/directory names. Enter EOF (control D) to signal you don't 
      want to enter more path names. Hint: you might want to run $script $command_name
      in interactive mode and redirect the path/names from a file. 
      
  -r  Reimports images which are already in the database.  This should
      only be used for testing purposes. This flag is ignored for OME
      XML files.
      
  -h  Print this help message.
  
USAGE
}

sub handleCommand {
	my ($self,$help,$commands) = @_;
	if ($help) {
		$self->import_help($commands);
	    CORE::exit(1);
	} else {
		$self->import($commands);
	}
}

sub import {
 	my ($self,$commands) = @_;
	my $reuse;
	my $help;
	my $datasetName;
	my $interactiveMode;
	
	GetOptions('reimport|r!' => \$reuse,
               'help|h' => \$help,
               'i' => \$interactiveMode,
               'd=i' => \$datasetName);
               
    if (not defined $datasetName) {
    	import_help($self,$commands);
    	print STDERR "\n *** dataset not specified\n";
	    CORE::exit(1);
    }
    
    # create the list of files
    my @file_names;
    
    # first get all the files from user
    if ($interactiveMode) {
    	while (1) {
			print "Enter file/dir name: " if -t STDIN;
			my $input = ReadLine 0;
			last if not defined $input;

			chomp $input;

			# skip lines that begin with a hash sign.
			if ($input !~ m/^\#+.*/) {
				$input = rel2abs ("$input");
				push (@ARGV, $input);
			}
		}
    }

	# get all the files from files/directories specified in @ARGV
    foreach (@ARGV) {
		if (-d $_) {
    		find sub{ push @file_names, $File::Find::name if -e and not -d;}, $_;
    	} elsif (-e $_) {
    		push @file_names, $_;
    	} else {
    		print STDERR "WARNING: $_ does not exist. Not Imported.\n";
    	}
    }
    
	my $manager = OME::SessionManager->new();
	my $session = $manager->TTYlogin();
	my $factory = $session->Factory();
	
	# Get command Line params
	
	# Get a dataset.
	# The dataset name on the command line either matches an existing
	# unlocked dataset owned by the current user, or is the name of a new
	# dataset.
	# Either way, we must associate the dataset with the current project.
	
	my $dataset;
	
	if ($datasetName =~ /^:([0-9]+)$/) {
		my $datasetID = $1;
		$dataset = $factory->loadObject("OME::Dataset",$datasetID);
	} else {
		my $dataset_data = {
							name   => $datasetName,
							owner  => $session->User(),
							locked => 'false'
						   };
		$dataset = $factory->findObject( "OME::Dataset", $dataset_data);
		$dataset = $factory->newObject( "OME::Dataset", $dataset_data )
		  unless $dataset;
	}
	
	$session->dataset( $dataset );
	$session->storeObject();
	
	# Now Get a project
	my $project = $session->project();
	if (not defined $project) {
		print "- Creating a new project...\n";
		$project = $factory->newObject("OME::Project", {
			name => 'Test Project',
			description => 'This project was auto generated by a test script',
			owner => $session->User(),
			group => $session->User()->Group()
		}) or die "Couldn't make a project";
	}
	
	# Assign the dataset to the project
	my $projectManager = new OME::Tasks::ProjectManager;
	$projectManager->addDatasets([ $dataset->id() ], $project->id());
	
	$session->commitTransaction();
	
	my %opts;
	$opts{AllowDuplicates} = 1 if $reuse;
	
	print "Importing files\n";
    my $task = OME::Tasks::NotificationManager->
      new('Importing images',3+scalar(@file_names));
	$task->setPID($$);
	$task->step();
	$task->setMessage('Starting import');

	# don't use forkedimportFiles so users can always control c
	OME::Tasks::ImageTasks::importFiles
	  ($dataset, \@file_names, \%opts, $task);
	
	my $lastStep = -1;
	my $status = $task->state();
	while ($status eq 'IN PROGRESS') {
		$task->refresh();
	
		my $step = $task->last_step();
		if ($step != $lastStep) {
			print "  $step/",$task->n_steps(),": [",
			  $task->state(),"] ",
			  $task->message(),"\n";
			$lastStep = $step;
		}
	
		$status = $task->state();
	
		sleep 2;
	}
	
	$task->refresh();
	my $step = $task->last_step();
	print "  $step/",$task->n_steps(),": [",
	  $task->state(),"] ",
	  $task->message(),"\n";
	
	print "\n\nDone.\n";
	
	#foreach my $image (@$images) {
	#    print $image->id(),": ",$image->name(),"\n";
	#}
}