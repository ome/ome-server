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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Util::Delete;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Log::Agent;
use Getopt::Long;

use OME::SessionManager;
use OME::Session;
use OME::Tasks::ModuleExecutionManager;

our $FACTORY;
our $IMAGE_IMPORT_MODULE_ID;
our @IMAGE_STs;
our @DATASET_STs;
our %DELETED_ATTRS;

sub getCommands {
    return
      {
       'MEX'  => 'DeleteMEX',
      };
}


sub listCommands {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    
    print <<"CMDS";
Usage:
    $script $command_name [command] [options]

Available OME database deletion related commands are:
    MEX         Delete a Module Execution and all of its descendents.
CMDS
}


sub DeleteMEX_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] MEX_ID

Delete a MEX and all of its descendents. This can potentially delete a lot.
Images, Datasets, the whole lot potentially.
It is suggested to try -n first to see what will happen.
And once its gone, its gone.  You can only get it back from a backup.
You do have a backup, right?

Options:
  -n, --noop       Don't actually delete anything, just report what would be deleted.
  -d, --delete     Actually delete the MEX.  Nothing will happen unless -n or -d is specified.  
CMDS
}


sub DeleteMEX {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my $noop;
	my $delete;
	my $help;

	undef %DELETED_ATTRS;

	# Parse our command line options
	GetOptions('noop|n!' => \$noop,
		   'delete|d' => \$delete);

	if (scalar(@ARGV) <= 0) {
		$self->MEX_help();
	}

	my $manager = OME::SessionManager->new();
	my $session = $manager->TTYlogin();
	$FACTORY = $session->Factory();
	$IMAGE_IMPORT_MODULE_ID = $session->Configuration()->image_import_module()->id();

	# Get the MEX
	my ($delMEX_ID) = @ARGV;
	
	my $delMEX = $FACTORY->loadObject( "OME::ModuleExecution", $delMEX_ID);
	die "Could not retreive MEX ID=$delMEX_ID\n" unless $delMEX;
	
	print "Retreived MEX ID = $delMEX_ID\n";
	
	unless ($delete or $noop) {
		print "Nothing to do.  Try -n\n";
		exit;
	}

	$self->delete_mex ($delMEX,$delete);

	$session->commitTransaction() if $delete;
	
	undef $FACTORY;
}


sub delete_mex {
my $self = shift;
my $mex = shift;
my $delete = shift;

	my $input;
	my @actual_inputs = $FACTORY->
		findObjects("OME::ModuleExecution::ActualInput",
			{
			input_module_execution => $mex,
			});
	foreach $input (@actual_inputs) {
		$self->delete_mex ($input->module_execution(),$delete);
	}

	print "vvv MEX ",$mex->id(),": ",$mex->module()->name(),"\n";
	
	# Gather up the typed an untyped outputs
	my @outputs = $mex->module()->outputs();
	my @untyped_outputs = $mex->untypedOutputs();
	push (@outputs,@untyped_outputs);

	foreach my $output (@outputs) {
		my $ST = $output->semantic_type();
		next unless $ST; # Skip the untyped output itself
		my $o_name = "*** Untyped ***" unless UNIVERSAL::can ($output,'name');
		$o_name = $output->name() unless $o_name;
		print "    Output = ",$o_name," (",$ST->name(),")\n";

		# Get the output's attributes
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($mex,$ST);

		foreach my $attr (@$attributes) {
			next unless $attr;
			next if exists $DELETED_ATTRS{$attr->id()};
			
			# These attributes may have virtual MEXes, so descend again
			my $vMEXes = OME::Tasks::ModuleExecutionManager->getMEXesForAttribute($attr);
			foreach my $vMex (@$vMEXes) {
				next unless $vMex;
				$self->delete_mex ($vMex,$delete) unless $vMex->id() == $mex->id();
			}
			
			# These attributes may be referred to by references.
			my $refs = $self->get_references_to ($attr);
			foreach my $ref_attr (@$refs) {
				next if exists $DELETED_ATTRS{$ref_attr->id()};

				my $ref_MEXes = OME::Tasks::ModuleExecutionManager->getMEXesForAttribute($ref_attr);
				foreach my $ref_MEX (@$ref_MEXes) {
					next unless $ref_MEX;
					$self->delete_mex ($ref_MEX,$delete) unless $ref_MEX->id() == $mex->id();
				}
				print "            Reference Attribute ",$ref_attr->id()," (",$ref_attr->semantic_type()->name(),")\n";
				$ref_attr->deleteObject() if $delete;
				$DELETED_ATTRS{$ref_attr->id()} = 1;
			}
			
			print "        Attribute = ",$attr->id(),"\n";
			$attr->deleteObject() if $delete;
			$DELETED_ATTRS{$attr->id()} = 1;
		}
	}
	
	# Delete any untyped outputs
	foreach my $output (@untyped_outputs) {
		print "    Untyped output ",$output->id(),"\n";
		$output->deleteObject() if $delete;
	}
	
	# Delete the node executions
	my @node_executions = $FACTORY->
		findObjects("OME::AnalysisChainExecution::NodeExecution",
			{
			module_execution => $mex,
			});
	foreach my $nodex (@node_executions) {
		print "    Node execution ",$nodex->id(),"\n";
		$nodex->deleteObject() if $delete;
	}
	
	# Delete AnalysisChainExecutions that are no longer valid.

	# Delete the actual_inputs that used this mex as an input module
	foreach $input (@actual_inputs) {
		print "    Actual input ",$input->id(),"\n";
		$input->deleteObject() if $delete;
	}
	
	# If the MEX is an $IMAGE_IMPORT_MEX, delete the image
	if ($mex->module->id() == $IMAGE_IMPORT_MODULE_ID) {
		print "    Image ",$mex->image()->id()," ",$mex->image()->name(),"\n";
		my $image_attrs = $self->get_image_attributes ($mex->image());
		foreach my $img_attr (@$image_attrs) {
			next if exists $DELETED_ATTRS{$img_attr->id()};

			my $img_MEXes = OME::Tasks::ModuleExecutionManager->getMEXesForAttribute($img_attr);
			foreach my $img_MEX (@$img_MEXes) {
				next unless $img_MEX;
				$self->delete_mex ($img_MEX,$delete) unless $img_MEX->id() == $mex->id();
			}
			print "        Image Attribute ",$img_attr->id()," (",$img_attr->semantic_type()->name(),")\n";
			$img_attr->deleteObject() if $delete;
			$DELETED_ATTRS{$img_attr->id()} = 1;
		}
		
		# And, since we're at it, we have to delete the image from the OME::Image::DatasetMap
		my @dataset_links = $FACTORY->findObjects("OME::Image::DatasetMap",{ image_id => $mex->image()->id()});
		my @datasets;
		foreach my $dataset_link (@dataset_links) {
			print "        Dataset Link ",$dataset_link->id()," (",$dataset_link->dataset()->name(),", ID=",$dataset_link->dataset()->id(),")\n";
			push (@datasets,$dataset_link->dataset());
			$dataset_link->deleteObject() if $delete;
		}
		
		# We have to delete locked datasets where we deleted this image.
		foreach my $dataset (@datasets) {
			next unless $dataset->locked();
			print "------- WARNING: Locked Dataset ",$dataset->name()," (ID=",$dataset->id(),") is losing this image.  DATABASE CORRUPTION !!! AAAAAHHHHH!!!!\n";
		}
		
		$mex->image()->deleteObject() if $delete;
	}

	# Delete the MEX
	print "^^^ MEX ",$mex->id(),"\n";
	$mex->deleteObject() if $delete;
}


sub get_image_attributes () {
my $self = shift;
my $image = shift;
my @image_attrs;

	@IMAGE_STs = $FACTORY->findObjects("OME::SemanticType",granularity => 'I') unless defined @IMAGE_STs;
	
	foreach my $ST (@IMAGE_STs) {
		my @objects = $FACTORY->findAttributes($ST,{image_id => $image->id()});
		push (@image_attrs,@objects);
	}
	
	return \@image_attrs;
}

# This belongs in OME::Tasks::SemanticTypeManager
# Or even better in OME::Tasks::AttributeManager
sub get_references_to {
my $self = shift;
my $attr = shift;
my $ST = $attr->semantic_type();
my %ST_refs;
my $attr_id = $attr->id();
my @ref_attrs;


	my @ref_cols = $FACTORY->
		findObjects("OME::DataTable::Column",
			{
			reference_type => $ST->name(),
	});

	foreach my $ref_col (@ref_cols) {
		my @ref_SEs = $FACTORY->findObjects("OME::SemanticType::Element",
			{
			data_column_id => $ref_col->id(),
			});
		foreach my $ref_SE (@ref_SEs) {
			$ST_refs {$ref_SE->semantic_type->name()}->{ST} = $ref_SE->semantic_type();
			$ST_refs {$ref_SE->semantic_type->name()}->{Elements}->{$ref_SE->name()} = $ref_SE;
		}
	}
	
	foreach my $ST_ref (values (%ST_refs)) {
		foreach my $ref_SE (keys %{$ST_ref->{Elements}}) {
			my @attrs = $FACTORY->findAttributes($ST_ref->{ST}, {
				$ref_SE => $attr_id,
			});
			push (@ref_attrs , @attrs);
		}
	}
	
	foreach my $ref_attr (@ref_attrs) {
		print "        Reference Attribute ",$ref_attr->id(),"\n";
	}
	
	return \@ref_attrs;
}

1;
