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
use OME::Image::Server;

our $FACTORY;
our $IMAGE_IMPORT_MODULE_ID;
our @IMAGE_STs;
our @DATASET_STs;
our %DELETED_ATTRS;
our $RECURSION_LEVEL;
our %DELETED_MEXES;  # We shouldn't have circular dependencies here, but just in case.
# Analysis chain execution ids with deleted nodes (keys are ACE ids, values are hash of node ids and 'ACE' => ACE)
our %ACS_DELETED_NODES;
# Deleted omeis Pixels.  Keys are DB PixelIDs, values are 'Repository' and 'ImageServerID'.
our %DELETED_PIXELS;
# Deleted omeis Files.  Keys are DB OriginalFile IDs, values are 'Repository' and 'FileID'.
our %DELETED_ORIGINAL_FILES;

sub getCommands {
    return
      {
       'MEX'     => 'DeleteMEX',
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
    $script $command_name [<options>] [MEX_ID]+

Delete one or more MEXes and all of their descendents. This can potentially delete a lot.
Images, Datasets, the whole lot potentially.
It is suggested to try -n first to see what will happen.
And once its gone, its gone.  You can only get it back from a backup.
You do have a backup, right?

Options:
  -n, --noop        Don't delete anything, just report what would be deleted.
  -d, --delete      Actually delete the MEX(es).  Nothing will happen unless -n or -d is specified.  
  -m, --module      Delete all MEXes for the specified module (ID if numeric, otherwise by name).  
  -f, --keep-files  Keep orphaned OMEIS Files.  
  -p, --keep-pixels Keep orphaned OMEIS Pixels.  
CMDS
}


sub DeleteMEX {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my ($noop,$delete,$module_in,$keep_files,$keep_pixels);

	# Parse our command line options
	GetOptions('noop|n!' => \$noop,
		   'delete|d' => \$delete,
		   'module|m=s' => \$module_in,
		   'keep-files|f' => \$keep_files,
		   'keep-pixels|p' => \$keep_pixels,
		   );

	if (scalar(@ARGV) <= 0 and not defined $module_in) {
		$self->MEX_help();
	}
	$keep_files  = 1 if $noop;
	$keep_pixels = 1 if $noop;
	
	my $manager = OME::SessionManager->new();
    my $session = $self->getSession();
	$FACTORY = $session->Factory();
	
	# This is useful for debugging:
	#$FACTORY->obtainDBH()->{AutoCommit} = 1;

	$IMAGE_IMPORT_MODULE_ID = $session->Configuration()->image_import_module()->id();

	# Get the MEX(es)
	my @MEXes;
	my $module;

	if (defined $module_in and $module_in =~ /^(\d+)$/) {
		$module = $FACTORY->loadObject( "OME::Module", $module_in) or 
			die "Could not load Module ID $module_in\n";
	} elsif (defined $module_in) {
		$module = $FACTORY->findObject( "OME::Module", {name => $module_in}) or 
			die "Could not load Module '$module_in'\n";
	}

	if ($module) {
		@MEXes = $FACTORY->
			findObjects("OME::ModuleExecution",
				{
				module_id => $module->id(),
				});
		
		print "Retreived ",scalar (@MEXes)," MEXes for module '",$module->name(),"'\n";
	}

	foreach my $arg_mex_id (@ARGV) {
		my $arg_mex = $FACTORY->loadObject( "OME::ModuleExecution", $arg_mex_id) or 
			die "Could not load MEX ID=$arg_mex_id specified on the comman-line.\n";
		push (@MEXes,$arg_mex);
		print "Retreived MEX ID = $arg_mex_id\n";
	}



	$RECURSION_LEVEL=0;
	undef %DELETED_ATTRS;
	undef %DELETED_MEXES;
	undef %ACS_DELETED_NODES;
	undef %DELETED_PIXELS;
	undef %DELETED_ORIGINAL_FILES;

	foreach my $MEX (@MEXes) {		
		
		unless ($delete or $noop) {
			print "Nothing to do.  Try -n\n";
			exit;
		}
	
		$self->delete_mex ($MEX,$delete);
	}

	$session->commitTransaction() if $delete;
	
	# We can't combine a DB transaction with an OMEIS transaction,
	# So we do this only if the DB transaction succeeds
	$self->cleanup_omeis($keep_files,$keep_pixels);
	
	undef $FACTORY;
	undef %DELETED_ATTRS;
	undef %DELETED_MEXES;
	undef %ACS_DELETED_NODES;
	undef %DELETED_PIXELS;
	undef %DELETED_ORIGINAL_FILES;
}


sub delete_mex {
my $self = shift;
my $mex = shift;
my $delete = shift;
my $mex_id;

	$mex_id = $mex->id();

	return if exists $DELETED_MEXES{$mex_id};


	# This prevents infinite recursion.  When we actually delete the MEX, this
	# will be set to 1.
	$DELETED_MEXES{$mex_id} = 0;

	$RECURSION_LEVEL++;
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	print $recurs_indent,"++MEX $mex_id: ",$mex->module()->name(),"\n";

	my $input;
	my @actual_inputs = $FACTORY->
		findObjects("OME::ModuleExecution::ActualInput",
			{
			input_module_execution => $mex,
			});
	foreach $input (@actual_inputs) {
		$self->delete_mex ($input->module_execution(),$delete);
	}

	
	# Gather up the typed an untyped outputs
	my @outputs = $mex->module()->outputs();
	my @untyped_outputs = $mex->untypedOutputs();
	push (@outputs,@untyped_outputs);

	foreach my $output (@outputs) {
		my $ST = $output->semantic_type();
		next unless $ST; # Skip the untyped output itself
		my $o_name;
		$o_name =  UNIVERSAL::can ($output,'name') ? $output->name() : '*** Untyped **';
		print $recurs_indent,"  Output = ",$o_name," (",$ST->name(),")\n";

		# Get the output's attributes
		my $attributes = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX($mex,$ST);

		# Delete all attributes - this will delete any vMexes,
		# any references, and the mexes that generated the references.
		foreach my $attr (@$attributes) {
			$self->delete_attribute ($attr,$mex,$delete);
		}
	}
	
	# Delete any untyped outputs - these are OME::ModuleExecution::SemanticTypeOutput
	foreach my $output (@untyped_outputs) {
		print $recurs_indent,"  Untyped output ",$output->id(),"\n";
		$output->deleteObject() if $delete;
	}
	
	# Delete the ACE node executions
	my @node_executions = $FACTORY->
		findObjects("OME::AnalysisChainExecution::NodeExecution",
			{
			module_execution_id => $mex_id,
			});

	foreach my $nodex (@node_executions) {
		print $recurs_indent,"  Node execution ",$nodex->id(),"\n";
		if ($nodex->analysis_chain_execution_id()) {
			$ACS_DELETED_NODES {$nodex->analysis_chain_execution_id()}->{$nodex->id()} = 1;
			$ACS_DELETED_NODES {$nodex->analysis_chain_execution_id()}->{'ACE'} = 
				$nodex->analysis_chain_execution();
		}
		$nodex->deleteObject() if $delete;
	}
	
	# @actual_inputs has actual inputs with this mex as an input mex.
	# To these, we want to add the actual inputs produced by this module.
	my @mex_actual_inputs = $FACTORY->
		findObjects("OME::ModuleExecution::ActualInput",
			{
			module_execution_id => $mex_id,
			});
	push (@actual_inputs,@mex_actual_inputs);

	# Delete actual_inputs that used this mex as an input module and those produced by this module
	foreach $input (@actual_inputs) {
		print $recurs_indent,"  Actual input ",$input->id(),"\n";
		$input->deleteObject() if $delete;
	}
	
	# If the MEX is an $IMAGE_IMPORT_MEX, delete the image
	if ($mex->module->id() == $IMAGE_IMPORT_MODULE_ID and $mex->image()) {
		my $image = $mex->image();
		print $recurs_indent,"  Image ",$image->id()," ",$image->name(),"\n";

		# First, delete all MEXes that have this image as the target.
		my @image_mexes = $FACTORY->
			findObjects("OME::ModuleExecution",
				{
				image_id => $image->id(),
				});
		foreach my $image_mex (@image_mexes) {
			next if $image_mex->id() == $mex_id;
			print $recurs_indent,"  Image MEX ",$image_mex->id(),"\n";
			$self->delete_mex ($image_mex,$delete);
		}
		
		# Next, delete any left-over image attributes that don't have this image as the target.
		my $image_attrs = $self->get_image_attributes ($mex->image());
		foreach my $attr (@$image_attrs) { $self->delete_attribute ($attr,$mex,$delete) ;}

		# Since we're at it, we have to delete the image from the OME::Image::DatasetMap
		my @dataset_links = $FACTORY->findObjects("OME::Image::DatasetMap",
			{ image_id => $mex->image()->id()}
		);
		my @datasets;
		foreach my $dataset_link (@dataset_links) {
			print $recurs_indent,"    Dataset Link to ",$dataset_link->dataset()->name(),
				", ID=",$dataset_link->dataset()->id(),"\n";
			push (@datasets,$dataset_link->dataset());
			$dataset_link->deleteObject() if $delete;
		}
		
		# We have to delete all mexes that have this dataset as their target.
		foreach my $dataset (@datasets) {
			# Find all dataset mexes for this dataset
			my @dataset_mexes = $FACTORY->
				findObjects("OME::ModuleExecution",
					{
					dataset_id => $dataset->id(),
					});
			foreach my $dataset_mex (@dataset_mexes) {
				next if $dataset_mex->id() == $mex_id;
				print $recurs_indent,"      Dataset MEX ",$dataset_mex->id(),"\n";
				$self->delete_mex ($dataset_mex,$delete);
			}
			
			# Since there are no dataset mexes for this dataset, unlock it.
			print $recurs_indent,"    Unlocking Dataset ",
				$dataset->name(),", ID=",$dataset->id(),"\n";
			$dataset->locked(0);
		}
		
		$mex->image()->deleteObject() if $delete;
	}

	# Delete the MEX
	print $recurs_indent,"--MEX $mex_id: ",$mex->module()->name(),"\n";
	$mex->deleteObject() if $delete;
	$DELETED_MEXES{$mex_id} = 1;
	$RECURSION_LEVEL--;
	
	# Perform cleanup tasks on orphaned objects
	# Note that nothing in here should directly or indirectly call
	# delete_mex(), or delete_attribute()
	if ($RECURSION_LEVEL == 0) {
	
		# Clean up AnalysisChainExecution objects consisting only of
		# deleted OME::AnalysisChainExecution::NodeExecution
		my ($ACE_ID,$del_nodes);
		while ( ($ACE_ID,$del_nodes) = each (%ACS_DELETED_NODES) ) {
			my @ACE_nodes = $FACTORY->
				findObjects("OME::AnalysisChainExecution::NodeExecution",
					{
					analysis_chain_execution_id => $ACE_ID,
					});

			my $del_ACE = $del_nodes->{'ACE'};
			foreach my $ACE_node (@ACE_nodes) {
				if (not exists $del_nodes->{$ACE_node->id()}) {
					$del_ACE = undef;
					last;
				}
			}

			if ($del_ACE) {
				print $recurs_indent,"Analysis Chain Execution ",
					$del_ACE->id(),", ",$del_ACE->analysis_chain()->name(),
					" (Chain ID=",$del_ACE->analysis_chain()->id(),")\n";
				$del_ACE->deleteObject() if $delete;
			}
			
		}
	} # Cleanup (RECURSION_LEVEL == 0)
} # delete_mex()


sub get_image_attributes () {
my $self = shift;
my $image = shift;
my @image_attrs;

	@IMAGE_STs = $FACTORY->findObjects("OME::SemanticType",granularity => 'I')
		unless defined @IMAGE_STs;
	
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

	return \@ref_attrs;
}

# This deletes an attribute.
# It collects any vMEXes, references, and any MEXes for the references,
# And deletes all of those as well.
# It calls delete_attribute_object to do the actual deletion
# Any special handling of attributes is done by delete_attribute_object.
sub delete_attribute {
my $self = shift;
my $attr = shift;
# This is the context mex, which isn't necessarily the attribute's mex.
my $mex = shift;
my $delete = shift;

	return unless $attr;
	return if exists $DELETED_ATTRS{$attr->id()};
	# Block infinite recursion
	$DELETED_ATTRS{$attr->id()} = 0;
			
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	my $mex_id = $mex->id();

	# This attribute may have virtual MEXes, so descend again
	my $vMEXes = OME::Tasks::ModuleExecutionManager->getMEXesForAttribute($attr);
	foreach my $vMex (@$vMEXes) {
		next unless $vMex;
		$self->delete_mex ($vMex,$delete) unless $vMex->id() == $mex_id;		
	}
	
	# Once we're back, we delete the vMEXes for this attribute.
    my @virtual_mex_maps = $FACTORY->
		findObjects('OME::ModuleExecution::VirtualMEXMap',
			{ attribute => $attr }
		);
    foreach my $map (@virtual_mex_maps) {
    	print "      VirtualMEXMap to MEX ID=",$map->module_execution_id(),"\n";
        $map->deleteObject() if $delete;
    }


	# These attributes may be referred to by references.
	my $refs = $self->get_references_to ($attr);
	
	foreach my $ref_attr (@$refs) {
		next if exists $DELETED_ATTRS{$ref_attr->id()};

		my $ref_MEXes = OME::Tasks::ModuleExecutionManager->getMEXesForAttribute($ref_attr);
		foreach my $ref_MEX (@$ref_MEXes) {
			next unless $ref_MEX;
			$self->delete_mex ($ref_MEX,$delete) unless $ref_MEX->id() == $mex_id;
		}
		$self->delete_attribute_object ($ref_attr,$delete,$recurs_indent."      Reference from ");
	}
	$self->delete_attribute_object ($attr,$delete,$recurs_indent."      ");
}

# This sub does any special handling for deleting attribute objects
sub delete_attribute_object {
	my $self = shift;
	my $attr = shift;
	my $delete = shift;
	my $message = shift;
	$message = '' unless defined $message;

	my $do_del=1;
	my $do_register=1;
	#
	# Special handling of specific kinds of attributes
	#
	my $ST_name = $attr->semantic_type()->name();
	my $attr_id = $attr->id();
	
	# Things stored in omeis are stored for possible later deletion from omeis
	if ($ST_name eq 'Pixels') {
		$DELETED_PIXELS {$attr_id}->{Repository}    = $attr->Repository();
		$DELETED_PIXELS {$attr_id}->{ImageServerID} = $attr->ImageServerID();
	} elsif ($ST_name eq 'OriginalFile') {
		$DELETED_ORIGINAL_FILES {$attr_id}->{Repository}   = $attr->Repository();
		$DELETED_ORIGINAL_FILES {$attr_id}->{FileID}       = $attr->FileID();
	}

	# We are not deleting experimenters (for now), but we will set their MEX to NULL
	elsif ($ST_name eq 'Experimenter') {
		my $experimenterName = $attr->FirstName().' '.$attr->LastName();
		print $message,"Experimenter ID=$attr_id '$experimenterName' ",
			"Not Deleted - Setting MEX=NULL\n";
		if ($delete) {
			$attr->module_execution_id (undef);
			$attr->storeObject();
		}
		$do_del = 0;
	}

	# Since we are not deleting experimenters (for now), we're also not deleting Groups
	elsif ($ST_name eq 'Group') {
		my $groupName = defined $attr->Name() ? $attr->Name() : 'UNDEFINED';
		print $message,"Group ID=$attr_id '$groupName' ",
			"Not Deleted - Setting MEX=NULL\n";
		if ($delete) {
			$attr->module_execution_id (undef);
			$attr->storeObject();
		}
		$do_del = 0;
	}

	# Since we are not deleting experimenters (for now), we're also not deleting ExperimenterGroups
	elsif ($ST_name eq 'ExperimenterGroup') {
		my $groupName = defined $attr->Group() ? $attr->Group()->Name() : 'UNDEFINED';
		my $experimenterName;
		if (defined $attr->Experimenter()) {
			$experimenterName = $attr->Experimenter()->FirstName().' '.$attr->Experimenter()->LastName();
		} else {
			$experimenterName = 'UNDEFINED';
		}
		print $message,"ExperimenterGroup ID=$attr_id, '$experimenterName' -> '$groupName' ",
			"Not Deleted - Setting MEX=NULL\n";
		if ($delete) {
			$attr->module_execution_id (undef);
			$attr->storeObject();
		}
		$do_del = 0;
	}

	if ($do_del) {
		print $message,"Attribute $attr_id (",$attr->semantic_type()->name(),")\n";
		$attr->deleteObject() if $delete;
		# FIXME:  Should delete LSIDs.
	}
	
	if ($do_register) {
		$DELETED_ATTRS{$attr_id} = 1;
	}
	
}


# Delete omeis objects that are no longer being refered to
sub cleanup_omeis {
my $self = shift;
my $keep_files = shift;
my $keep_pixels = shift;
	
	
	# Delete orphaned OMEIS Pixels
	my $omeis_del;
	my %omeis_ids;
	foreach my $pixels_spec (values %DELETED_PIXELS) {
		# Get all the Pixels that have the same repository and image_server_id
		my @db_pixelses = $FACTORY->
			findAttributes('Pixels',
				{
				ImageServerID => $pixels_spec->{ImageServerID},
				Repository    => $pixels_spec->{Repository},
				});

		$omeis_del = 1;
		foreach my $db_pixels (@db_pixelses) {
			if (not exists $DELETED_PIXELS {$db_pixels->id()}) {
				$omeis_del = 0;
				last;
			}
		}

		if ($omeis_del) {
			my $omeis_ids_key = $pixels_spec->{Repository}->id().':'.$pixels_spec->{ImageServerID};
			if (not exists $omeis_ids{$omeis_ids_key}) {
				print "Deleting OMEIS Pixels $omeis_ids_key\n";
				if ($pixels_spec->{Repository}->IsLocal()) {
					OME::Image::Server->useLocalServer($pixels_spec->{Repository}->Path());
				} else {
					OME::Image::Server->useRemoteServer($pixels_spec->{Repository}->ImageServerURL());
				}
				OME::Image::Server->deletePixels($pixels_spec->{ImageServerID}) unless $keep_pixels;
			}
			$omeis_ids{$omeis_ids_key} = 1;
		}
	} # DELETED_PIXELS

	# Delete orphaned OMEIS Files
	%omeis_ids = ();
	foreach my $file_spec (values %DELETED_ORIGINAL_FILES) {
		# Get all the Files that have the same repository and image_server_id
		my @db_files = $FACTORY->
			findAttributes('OriginalFile',
				{
				FileID => $file_spec->{FileID},
				Repository    => $file_spec->{Repository},
				});

		$omeis_del = 1;
		foreach my $db_file (@db_files) {
			if (not exists $DELETED_ORIGINAL_FILES {$db_file->id()}) {
				$omeis_del = 0;
				last;
			}
		}

		if ($omeis_del) {
			my $omeis_ids_key = $file_spec->{Repository}->id().':'.$file_spec->{FileID};
			if (not exists $omeis_ids{$omeis_ids_key}) {
				print "Deleting OMEIS File $omeis_ids_key\n";
				if ($file_spec->{Repository}->IsLocal()) {
					OME::Image::Server->useLocalServer($file_spec->{Repository}->Path());
				} else {
					OME::Image::Server->useRemoteServer($file_spec->{Repository}->ImageServerURL());
				}
				OME::Image::Server->deleteFile($file_spec->{FileID}) unless $keep_files;
			}
			$omeis_ids{$omeis_ids_key} = 1;
		}
	} # DELETED_ORIGINAL_FILES
}



1;
