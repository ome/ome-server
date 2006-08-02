# OME/Util/ExportChain.pm

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

package OME::Util::ExecuteChain;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;

use OME::Fork;
use OME::Session;
use OME::SessionManager;
use OME::AnalysisChain;
use OME::Dataset;
use OME::Analysis::Engine;
use OME::Tasks::ChainManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::ModuleExecutionManager;
use Term::ReadKey;

# I really hate those "method clash" warnings, especially since these
# methods are now deprecated.
no strict 'refs';
undef &Class::DBI::min;
undef &Class::DBI::max;
use strict 'refs';

use Getopt::Long;
Getopt::Long::Configure("bundling");


sub getCommands {
    return
      {
       'execute'     => 'execute',
      };
}

sub execute_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:  
    $script $command_name [<options>] [<flags>]

This command uses the Analysis Engine to execute the analysis chain against
a dataset.

Options:
  -a, --analysis-chain (<name> | <id>)
     Analysis chain
  
  -d, --dataset (<name> | <id>)
     Dataset name
    
  -s, --skip_optional_inputs

  -i, --inputs
    specify User inputs by id and source MEX(s)
    ex. -i 551:17,21-552:114 
    means supply formal input 551 with source MEXs 17 & 21
          supply formal input 552 wiht source MEX 114
  
  -f, --force
    Force re-execution of chain (i.e. do not reuse previous module execution 
    results).
  
  -c, --caching
    Enable DBObject caching.

USAGE
}

sub execute {
	my $self = shift;
	
	my ($chainStr, $datasetStr, $reuse, $caching, $inputs_string, $skip_optional_inputs );
	$reuse = 0;
	$caching = 0;
	
	GetOptions ('a|analysis-chain=s' => \$chainStr,
				'd|dataset=s' => \$datasetStr,
				'force|f!' => \$reuse,
				'caching|c!' => \$caching,
				'inputs|i=s' => \$inputs_string,
				'skip_optional_inputs|s!' => \$skip_optional_inputs );

    OME::DBObject->Caching(1) if ($caching or $ENV{'OME_CACHE'});

    my $session = $self->getSession();	
	my $factory = $session->Factory();
	
	# idiot traps
	if (not defined $datasetStr or not defined $chainStr) {
		die "The Dataset and Analysis Chain Names must be specified.\n"; 
	}
	
	# get a dataset
	my $dataset;

	if ($datasetStr =~ /^([0-9]+)$/) {
		my $datasetID = $1;
		$dataset = $factory->loadObject ("OME::Dataset", $datasetID);
		die "Dataset with ID $datasetStr doesn't exist!" unless $dataset;
	} else {
		my $datasetData = {
							name   => $datasetStr,
							owner  => $session->User(),
						  };
		$dataset = $factory->findObject( "OME::Dataset", $datasetData);
		die "Dataset with name $datasetStr doesn't exist!" unless $dataset;
	}

	# get a chain
	my $chain;

	if ($chainStr =~ /^([0-9]+)$/) {
		my $chainID = $1;
		$chain = $factory->loadObject ("OME::AnalysisChain", $chainID);
		die "Analysis Chain with ID $chainStr doesn't exist!" unless $chain;
	} else {
		my $chainData = {
							name   => $chainStr,
							owner  => $session->User(),
						};
		$chain = $factory->findObject( "OME::AnalysisChain", $chainData);
		die "Analysis Chain with name $chainStr doesn't exist!" unless $chain;
	}
	
	# User inputs were given as command line parameters
	my %user_inputs;
	my @input_chunks = split( m/-/, $inputs_string )
		if $inputs_string;
	foreach my $chunk ( @input_chunks ) {
		my ($fi_id, @mex_ids) = split( m/[:|,]/, $chunk );
		my $fi = $factory->loadObject( 'OME::Module::FormalInput', $fi_id )
			or die "Coulnd't load Formal Input (id=$fi_id)";
		my @inputMEXs = map( 
			( $factory->loadObject( 'OME::ModuleExecution', $_ )
				or die "Couldn't load ModuleExecution (id=$_)" ),
			@mex_ids
		);
		$user_inputs{ $fi_id } = \@inputMEXs;
	}

	unless( %user_inputs ) {
	# Retrieve user inputs
	my $cmanager = OME::Tasks::ChainManager->new($session);
	my $user_input_list = $cmanager->getUserInputs($chain);
	@$user_input_list = grep {not $_->[2]->optional} @$user_input_list
		if $skip_optional_inputs;
	print "User Inputs:\n" if (scalar @$user_input_list);

	foreach my $user_input (@$user_input_list) {
		my ($node,$module,$formal_input,$semantic_type) = @$user_input;
		print "\n",$module->name(),".",$formal_input->name(),":\n";
	
		my $new = '';
		my %valid_entries = ( 'N' => undef, 'E' => undef );
		$valid_entries{'S'} = undef if $formal_input->optional();
		while (not exists $valid_entries{ $new }) {
			unless ( $formal_input->optional() ){		
				print "  New or existing? [N]/E  ";
			} else {
				print "This input is optional.  New, existing, or skip? [N]/E/S  ";
			}
			$new = <STDIN>;
			chomp($new);
			$new = uc($new) || 'N';
		}
	
		my @columns = $semantic_type->semantic_elements();
		my $mex;
	
		if ($new eq 'N') {
			my $count = 0;
			my @data_hashes;
	
		  LIST_LOOP:
			while (1) {
				$count++;
				print "  Attribute #$count\n";
				my $data_hash = {};
	
				foreach my $column (@columns) {
					my $column_name = $column->name();
	
					print "    ",$column_name,": ";
					my $value = <STDIN>;
					chomp($value);
					last LIST_LOOP if ($value eq '\d');
					$value = undef if ($value eq '');
					$value = '' if ($value eq '\0');
					$data_hash->{$column_name} = $value;
				}
	
				push @data_hashes, $semantic_type, $data_hash;
			}
	
			# data_hashes has pairs of entries. first item is an ST
			# second one is a hash that maps column names to input values.
			$mex = OME::Tasks::AnnotationManager->
			  annotateGlobal(@data_hashes);
		} elsif( $new eq 'E' ) {
			my @attributes;
	
			print "  Type in a list of attribute ID's, separated by spaces.\n";
			print "  [Enter] by itself will terminate the list.\n";
	
		  LIST_LOOP:
			while (1) {
				print "  ? ";
				my $value = <STDIN>;
				chomp($value);
				my @ids = split(' ',$value);
				last LIST_LOOP if scalar(@ids) == 0;
	
			  ID_LOOP:
				foreach my $id (@ids) {
					if ($id !~ /^\d+$/) {
						print "    $id is not a number.  Skipping.\n";
						next ID_LOOP;
					}
	
					my $attribute = $factory->loadAttribute($semantic_type,$id);
					if (!defined $attribute) {
						print "    Could not find attribute #$id.  Skipping.\n";
						next ID_LOOP;
					}
	
					print "    Adding attribute #$id.\n";
					push @attributes, $attribute;
				}
			}
	
			$mex = OME::Tasks::ModuleExecutionManager->
			  coalateInputs(\@attributes);
		}

		# hash of mexes corresponding to formal inputid.	
		$user_inputs{$formal_input->id()} = $mex;
	}
	}
	
	print "Executing Analysis Chain `".$chain->name()."`\n";
	my $task = OME::Tasks::NotificationManager->
		new("Executing `".$chain->name()."`", -1);
	$task->setMessage('Start Execution of Analysis Chain');
	
	my $pid = OME::Fork->fork();
	
	if (!defined $pid) {
		die "Could not fork off process to perform the analysis chain execution";
	} elsif ($pid) {
		# Execute the chain
		my %flags;
		$flags{ReuseResults} = 1-$reuse; # if $reuse is set to 1 means do not reuse
		OME::Analysis::Engine->
			executeChain($chain,$dataset,\%user_inputs,$task,%flags);
	} else {
	
		# Child process prints the task status
		my $lastStep = -1;
		my $status = $task->state();
		my $mem_usage = 0;
		my $mem_usage_steps = 0; # how many steps (each 2 sec) do we average memory over
		while ($status eq 'IN PROGRESS') {
			$task->refresh();
			next if $task->n_steps == -1;
			
			my $step = $task->last_step();
			my $message = $task->message();
			defined $message or $message = "";
			
			if ($step != $lastStep ) {
				print "	 $step/",$task->n_steps(),": [",
				  $task->state(),"] Currently ",
				  $message;
				$lastStep = $step;
				if ($mem_usage > 0) {
					printf(" (Past Usage: %.2dmb)",$mem_usage/1024/$mem_usage_steps);
				}
				print "\n";
				$mem_usage = 0;
				$mem_usage_steps = 0;
			}
		
			$status = $task->state();
		
			sleep 2;
			# if you want to use the lines below, remove the line above (sleep 2)
			#my @output = `sar -r 5`; # inherently results in 2 second wait
			#if($output[-1] =~ m/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/)
			#{
        		#	$mem_usage += $3;
			#	$mem_usage_steps++;
			#}

		}
		
		# print the final task Info
		$task->refresh();
		my $step = $task->last_step();
		print "	 $step/",$task->n_steps(),": [",
		  $task->state(),"] Currently",
		  $task->message();
		if ($mem_usage > 0) {
			printf(" (Past Usage: %.2dmb)",$mem_usage/1024/$mem_usage_steps);
		}
		print "\n";	
	}
		
	# my $cache = OME::DBObject->__cache();
	# my $numClasses = scalar(keys %$cache);
	# my $numObjects = 0;
	
	# foreach my $class (keys %$cache) {
	#	 my $classCache = $cache->{$class};
	#	 my $numClassObjects = scalar(keys %$classCache);
	#	 printf STDERR "%5d %s\n", $numClassObjects, $class;
	# 	 $numObjects += $numClassObjects;
	# }
	
	# printf STDERR "\n%5d TOTAL\n", $numObjects;
}

sub END {
	print "Exiting...\n";
}

1;
