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
use Getopt::Long;

use OME::SessionManager;
use OME::Session;
use OME::Tasks::ProjectManager;
use OME::Tasks::ImageTasks;

use Getopt::Long;
Getopt::Long::Configure("bundling");



sub getCommands {
    return
      {
       'import'     => 'import',
      };
}


sub import_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>] [<list of files>]

This utility imports files into OME database and runs the import analysis 
chain against them.

The files can be proprietary format image files or OME XML files that define 
OME objects.

Options:
      
  -d  Use this to specify the dataset name or ID. Imported images must be associated with a dataset.
      If you don't own an unlocked Dataset with the specified name, a new one will be created for you.
      If you are importing OME Semantic Type Definitions, Analysis Modules, or Chains this parameter is unnecessary.
      If you import images, but don't specify a dataset, a new dataset will be created for you, usually called 'Import Dummy Dataset'
      
  -r  Reimports images which are already in the database.  This should
      only be used for testing purposes. This flag is ignored for OME
      XML files.
      
  -h  Print this help message.
  
USAGE
    CORE::exit(1);
}


sub import {
 	my ($self,$commands) = @_;
	my $reuse;
	my $help;
	my $datasetName;
	
	GetOptions('reimport|r!' => \$reuse,
               'help|h' => \$help,
               'd=s' => \$datasetName);
    my @file_names = @ARGV;
    
    # preliminary idiot traps
    
    
    my $session = $self->getSession();
	my $factory = $session->Factory();
	
	# Get command Line params
	
	# Get a dataset.
	# The dataset name on the command line either matches an existing
	# unlocked dataset owned by the current user, or is the name of a new
	# dataset.
	# if the argument is numeric, it must match an exsting dataset ID.
	
	my $dataset;
	
	if (defined $datasetName) {

		if ($datasetName =~ /^([0-9]+)$/) {
			my $datasetID = $1;
			$dataset = $factory->loadObject("OME::Dataset",$datasetID);
			die "Specified Dataset ID $datasetName doesn't exist!" unless $dataset;
			die "Specified Dataset ID $datasetName is locked!" unless not $dataset->locked();
		} else {
			my $dataset_data = {
								name   => $datasetName,
								owner  => $session->User(),
								locked => 'false'
							   };
			$dataset = $factory->findObject( "OME::Dataset", $dataset_data);
			
			if (not defined $dataset) {
				$dataset = $factory->newObject( "OME::Dataset", $dataset_data );
				# If there is a project in this session, then associate this new dataset with it
				my $project = $session->project();
				if (defined $project) {
					# Assign the dataset to the project
					print '- Adding Dataset "',$dataset->name(),'" to Project "',$project->name(),'"...',"\n";
					my $projectManager = new OME::Tasks::ProjectManager;
					$projectManager->addDatasets([ $dataset->id() ], $project->id());
				}
			}
				
		}
		
		$session->dataset( $dataset );
		

		$session->storeObject();
		$session->commitTransaction();
	}
	
	my %opts;
	$opts{AllowDuplicates} = 1 if $reuse;
	
	print "Importing files\n";
	my $task = OME::Tasks::ImageTasks::forkedImportFiles ($dataset, \@file_names, \%opts);
	
	my $lastStep = -1;
	my $status = $task->state();
	while ($status eq 'IN PROGRESS') {
		$task->refresh();
	
		my $step = $task->last_step();
		my $message = $task->message();
		defined $message or $message = "";
		
		if ($step != $lastStep ) {
			print "  $step/",$task->n_steps(),": [",
			  $task->state(),"] ",
			  $message,"\n";
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