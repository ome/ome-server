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
use Cwd;
use File::Glob ':glob';

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

  -d, --dataset (<id> | <name>) 
      Specify which dataset images should be imported into. If you don't
      own an unlocked dataset with the specified name, a new one will be
      created for you. If you are importing OME Semantic Type Definitions,
      Analysis Modules, or Chains this parameter is unnecessary. If you
      import images, but don't specify a dataset, a new dataset called
      '<time_stamp> Import Dataset' will be created for you.

  -D, --description
      Use this flag if you want to give a description to your new dataset.

  -i, --format
      Suggests the image formats. The Import Engine first checks if the images
      are of the specified format, if not it reverts to default behaviour and
      tries to discover the image formats. This speeds up import times for
      common images such as TIFFs.

      Permitted Values:
      OME::ImportEngine::OMETIFFreader
      OME::ImportEngine::MetamorphHTDFormat
      OME::ImportEngine::DVreader
      OME::ImportEngine::STKreader
      OME::ImportEngine::BioradReader
      OME::ImportEngine::LSMreader
      OME::ImportEngine::TIFFreader
      OME::ImportEngine::BMPreader
      OME::ImportEngine::DICOMreader
      OME::ImportEngine::XMLreader

  -r, --reimport
      Reimports images which are already in the database.  This should
      only be used for testing purposes. This flag is ignored for OME
      XML files.

USAGE
}


sub import {
 	my ($self,$commands) = @_;
	my $reuse;
	my $datasetName;
	my $datasetDescription;
	my @priority_formats;
	
	my $timestamp = time;
	my $timestr = localtime $timestamp;
	
	GetOptions('reimport|r!' => \$reuse,
               'dataset|d=s' => \$datasetName,
               'description|D=s' => \$datasetDescription,
               'i|format=s'=>\@priority_formats);
               
    # idiot traps
    die "You cannot specify a dataset description without also specifying the dataset name.\n"
    	if (defined $datasetDescription and not defined $datasetName);
    
    my @file_names;
    foreach my $filename (@ARGV) {
    	$filename = Cwd::realpath($filename); # if you use absolute filenames here, OriginalFiles.Path
										 # stores absolute filenames. if you use relative paths,
										 # OriginalFiles.Path stores relative filenames
    	push (@file_names,$filename)
    		if $filename and -f $filename and -r $filename and -s $filename;
    	push (@file_names,bsd_glob("$filename/*")) if $filename and -d $filename and -r $filename;
    }
	die "No valid files or directories specified for import.\n" unless scalar @file_names;

    # suggest a default dataset description
    $datasetDescription = "These images were imported using the OME command-line tool on $timestr. This description was auto-generated. Use the -D command-line parameter to specify your own descriptions during image import." unless $datasetDescription;
    
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
			die "Specified Dataset with ID $datasetName doesn't exist!" unless $dataset;
			die "Specified Dataset with ID $datasetName is locked!" unless not $dataset->locked();
		} else {
			my $dataset_data = {
								name        => $datasetName,
								owner       => $session->User(),
								group       => $session->User()->Group()->id(),
								locked      => 'false'
							   };
			$dataset = $factory->findObject( "OME::Dataset", $dataset_data);
			
			if (not defined $dataset) {
				$dataset_data -> {'description'} = $datasetDescription;
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
	
	# re-arrange image formats per the user's instructions
	my @formats_list;
	if (scalar @priority_formats) {
		my $std_formats_ref = $session->Configuration()->import_formats();
		my @std_formats = @$std_formats_ref;
		
		foreach my $priority_format (@priority_formats) {
			my $found_priority_format = -1;
			for (my $i = 0; $i < scalar @std_formats; $i++) {
				my $std_format = $std_formats[$i];
				if ($priority_format eq $std_format) {
					$found_priority_format = $i;
					last;
				}
			}
			die "Image format $priority_format is unknown\n" if $found_priority_format == -1;
			@std_formats = @std_formats[0..$found_priority_format-1,
										$found_priority_format+1..-1];
		}
		@formats_list = (@priority_formats,@std_formats);
	}

	my %opts;
	$opts{AllowDuplicates} = 1 if $reuse;
	$opts{ImageFormats} = \@formats_list if scalar @formats_list;
	
	print "Importing files\n";
	my $task = OME::Tasks::NotificationManager->
        new('Importing images',3+scalar(@file_names));
	$task->setPID($$);
	$task->step();
	$task->setMessage('Starting import');

	# Get our signos
    use Config;
    my %signo;
    defined $Config{sig_name} || die "No sigs?";
    my $signum=0;
    foreach my $name (split(' ', $Config{sig_name})) {
        $signo{$name} = $signum;
        $signum++;
    }


	my $pid = OME::Fork->fork();

	if (!defined $pid) {
		die "Could not fork off process to perform the import";
	} elsif ($pid) {
		# Parent process
		$SIG{INT}=sub {
			print "\nCaught SIGINT - killing child ($pid) and myself ($$)\n";
			kill $signo{INT},$pid;
			CORE::exit;
		};
		
		my $lastStep = -1;
		my $status = $task->state();
		while ($status eq 'IN PROGRESS') {
			$task->refresh();
		
			my $step = $task->last_step();
			my $message = $task->message();
			defined $message or $message = "";
			
			if ($step != $lastStep ) {
				print "	 $step/",$task->n_steps(),": [",
				  $task->state(),"] ",
				  $message,"\n";
				$lastStep = $step;
			}
		
			$status = $task->state();
		
			sleep 2;
		}
		
	} else {
		# Child process
        $SIG{INT} = sub { $task->died('User Interrupt');CORE::exit; };

		my $session = OME::Session->instance();
		POSIX::setsid() or die "Can't start a new session. $!";
		my $images = OME::Tasks::ImageTasks::importFiles ($dataset, \@file_names, \%opts, $task);
		
		# print the final Task Info
		$task->refresh();
		my $step = $task->last_step();
		print "	 $step/",$task->n_steps(),": [",
		  $task->state(),"] ",
		  $task->message(),"\n";
		 
		print "Successfully Imported:\n" if (scalar @$images);
		foreach my $image (@$images) {
			 print $image->id(),": ",$image->name(),"\n";
		}
	}
}

sub END {
	print "Exiting...\n";
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
