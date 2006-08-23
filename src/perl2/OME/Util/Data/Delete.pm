# OME/Util/Data/Delete.pm

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

package OME::Util::Data::Delete;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Log::Agent;
use Getopt::Long;
use Carp;

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
our %DELETED_STS;
our %DELETED_IMAGES;
our %DELETED_EXPERIMENTERS;
our %DELETED_GROUPS;
our %DELETED_DATASETS;
# Analysis chain execution ids with deleted nodes (keys are ACE ids, values are hash of node ids and 'ACE' => ACE)
our %ACS_DELETED_NODES;
# Deleted omeis Pixels.  Keys are DB PixelIDs, values are 'Repository' and 'ImageServerID'.
our %DELETED_PIXELS;
# Deleted omeis Files.  Keys are DB OriginalFile IDs, values are 'Repository' and 'FileID'.
our %DELETED_ORIGINAL_FILES;
our %ST_REFS;
# The GraphViz object
our $GRAPH;
# URL for serve.pl used for links in GraphViz
our $WEB_UI;
# Delete OriginalFiles attribute and MEXes if they become orphaned
# (i.e. not used by any other MEX).
our $DELETE_ORPHANED_OFs = 1;

sub getCommands {
    return
      {
       'CHEX'    => 'DeleteCHEX',
       'MEX'     => 'DeleteMEX',
       'Image'   => 'DeleteImage',
       'Dataset' => 'DeleteDataset',
       'ST'      => 'DeleteST',
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
    CHEX        Delete a Chain Execution and all of its dependencies.
    MEX         Delete a Module Execution and all of its dependencies.
    Image       Delete an Image and all of its dependencies.
    Dataset     Delete a dataset and all of its dependencies, optionally deleting Images.
    ST          Delete a Semantic Type and all of its descendents.
CMDS
}
sub DeleteST_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] [ST]+

Delete an ST definition.

This utility can only deal with a small subset of ST deletions. It can only
delete STs that are not referenced by other STs or Module Formal Inputs/Outputs
(therefore there can be no attributes in the DB).

Options:
  -n, --noop        Do not delete anything, just report what would be deleted.
  -d, --delete      Actually delete the STs(es).  Nothing will happen unless -n or -d is specified.  
CMDS
}

sub DeleteST {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my ($noop,$delete);

	# Parse our command line options
	GetOptions(
		'noop|n!' => \$noop,
		'delete|d' => \$delete,
	);

	$self->DeleteST_help($commands) if (scalar(@ARGV) <= 0);
	
    my $session = $self->getSession();
	$FACTORY = $session->Factory();

	# convert the inputed ST ids/names into an array of OME::SemanticType DBObjects
	my @STs;
	foreach my $arg_ST (@ARGV) {
		my $ST;
		if ($arg_ST =~ /^(\d+)$/) {
			$ST = $FACTORY->loadObject( "OME::SemanticType", $arg_ST) or 
				die "Could not load Semantic Type ID $arg_ST\n";
		} else {
			$ST = $FACTORY->findObject( "OME::SemanticType", {name => $arg_ST}) or 
				die "Could not load Semantic Type '$arg_ST'\n";
		}
		push (@STs,$ST);
	}

	# let's try to delete these STs
	$RECURSION_LEVEL=0;
	
	# do these STs meet conditions that make them ineligible for deletion?
	$self->delete_st ($_, $delete, $noop) foreach (@STs);
	$session->commitTransaction() if $delete;
	undef %DELETED_STS;
}

sub DeleteCHEX_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] [CHEX_ID]+

Delete one or more CHEXes and all of their descendents. This can potentially delete a lot.
Images, Datasets, the whole lot potentially.
It is suggested to try -n first to see what will happen.
And once its gone, its gone.  You can only get it back from a backup.
You do have a backup, right?

Options:
  -o, --orph        Keep orphaned Original Files even if they are not used by any other MEX
  -n, --noop        Do not delete anything, just report what would be deleted.
  -d, --delete      Actually delete the CHEX(es).  Nothing will happen unless -n or -d is specified.  
  -c, --chain       Delete all CHEXes for the specified chain (ID if numeric, otherwise by name).  
  -f, --keep-files  Keep orphaned OMEIS Files.  
  -p, --keep-pixels Keep orphaned OMEIS Pixels.
  -g, --graph       Generate a graph of the dependencies using GraphViz, and save in specified file.
CMDS
}


sub DeleteCHEX {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my ($orph,$noop,$delete,$chain_in,$keep_files,$keep_pixels,$make_graph);

	# Parse our command line options
	GetOptions(
		'orph|o!' => \$orph,
		'noop|n!' => \$noop,
		'delete|d' => \$delete,
		'chain|c=s' => \$chain_in,
		'keep-files|f' => \$keep_files,
		'keep-pixels|p' => \$keep_pixels,
		'graph|g=s' => \$make_graph,
	);

	$self->DeleteCHEX_help($commands) if (scalar(@ARGV) <= 0 and not defined $chain_in);
	
	$keep_files  = 1 if $noop;
	$keep_pixels = 1 if $noop;
	$DELETE_ORPHANED_OFs = 0 if $orph;

	my $manager = OME::SessionManager->new();
    my $session = $self->getSession();
	$FACTORY = $session->Factory();
	
	# This is useful for debugging:
	#$FACTORY->obtainDBH()->{AutoCommit} = 1;

	$IMAGE_IMPORT_MODULE_ID = $session->Configuration()->image_import_module()->id();
	
	# Get the MEX(es)
	my @CHEXes;
	my $chain;

	if (defined $chain_in and $chain_in =~ /^(\d+)$/) {
		$chain = $FACTORY->loadObject( "OME::AnalysisChain", $chain_in) or 
			die "Could not load Chain ID $chain_in\n";
	} elsif (defined $chain_in) {
		$chain = $FACTORY->findObject( "OME::AnalysisChain", {name => $chain_in}) or 
			die "Could not load Chain '$chain_in'\n";
	}

	if ($chain) {
		@CHEXes = $FACTORY->
			findObjects("OME::AnalysisChainExecution",
				{
				analysis_chain_id => $chain->id(),
				});
		
		print "Retreived ",scalar (@CHEXes)," CHEXes for chain '",$chain->name(),"'\n";
	}

	foreach my $arg_chex_id (@ARGV) {
		my $arg_chex = $FACTORY->loadObject( "OME::AnalysisChainExecution", $arg_chex_id) or 
			die "Could not load CHEX ID=$arg_chex_id specified on the command-line.\n";
		push (@CHEXes,$arg_chex);
		print "Retreived CHEX ID = $arg_chex_id\n";
	}

	# CONVERT each CHEX into the constituent MEXs
	my @MEXes;
	foreach my $chex (@CHEXes) {
		my @NEXes = $FACTORY->findObjects("OME::AnalysisChainExecution::NodeExecution",
						{ analysis_chain_execution => $chex }) or
						die "Could not load MEXs for CHEX ID ".$chex->id()."\n";
					
		my @CHEX_MEXs = map { $_->module_execution} @NEXes;
		@MEXes = (@MEXes, @CHEX_MEXs);
	}

	$self->delete_mexes (\@MEXes,$delete,$noop,$keep_files,$keep_pixels,$make_graph);
}

sub DeleteImage_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] [Image ID | Name]+

Delete one or more Images and all of their descendents. This can potentially delete a lot.
Images, Datasets, the whole lot potentially.
It is suggested to try -n first to see what will happen.
And once its gone, its gone.  You can only get it back from a backup.
You do have a backup, right?

Options:
  -o, --orph        Keep orphaned Original Files even if they are not used by any other MEX
  -n, --noop        Do not delete anything, just report what would be deleted.
  -d, --delete      Actually delete the Images.  Nothing will happen unless -n or -d is specified.  
  -f, --keep-files  Keep orphaned OMEIS Files.  
  -p, --keep-pixels Keep orphaned OMEIS Pixels.
  -g, --graph       Generate a graph of the dependencies using GraphViz, and save in specified file.
CMDS
}


sub DeleteImage {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my ($orph,$noop,$delete,$keep_files,$keep_pixels,$make_graph);

	# Parse our command line options
	GetOptions(
		'orph|o!' => \$orph,
		'noop|n!' => \$noop,
		'delete|d' => \$delete,
		'keep-files|f' => \$keep_files,
		'keep-pixels|p' => \$keep_pixels,
		'graph|g=s' => \$make_graph,
	);

	$self->DeleteImage_help($commands) if (scalar(@ARGV) <= 0);
	
	$keep_files  = 1 if $noop;
	$keep_pixels = 1 if $noop;
	$DELETE_ORPHANED_OFs = 0 if $orph;
	my $manager = OME::SessionManager->new();
    my $session = $self->getSession();
	$FACTORY = $session->Factory();
	
	# This is useful for debugging:
	#$FACTORY->obtainDBH()->{AutoCommit} = 1;
	$IMAGE_IMPORT_MODULE_ID = $session->Configuration()->image_import_module()->id();

	# Get the objects
	my @objects;
	foreach my $arg (@ARGV) {
		my $obj;
		if ($arg =~ /^(\d+)$/) {
			$obj = $FACTORY->loadObject( "OME::Image", $arg) or 
				die "Could not load Image ID=$arg specified on the command-line.\n";
		} else {
			my @objs = $FACTORY->findObjects( "OME::Image", {name => $arg});
			die "Could not load Image named '$arg' specified on the command-line.\n"
				unless (scalar (@objs));
			die "There is more than one image named '$arg': ".
				join (', ',map {$_->id()} @objs)."\nPlease specify IDs\n"
					if (scalar (@objs) > 1);
			$obj = $objs[0];
		}
		push (@objects,$obj);
		print "Retreived Image ID = ".$obj->id().", Name = ".$obj->name()."\n";
	}
	
	# Get the import module(s) for each image
	my @MEXes;
	foreach my $obj (@objects) {
		my @img_MEXes = $FACTORY->findObjects ('OME::ModuleExecution',{
			image_id => $obj->id(),
			'module_id' => $IMAGE_IMPORT_MODULE_ID,
		});
		push (@MEXes,@img_MEXes);
	}

	$self->delete_mexes (\@MEXes,$delete,$noop,$keep_files,$keep_pixels,$make_graph);
}



sub DeleteDataset_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>] [Dataset ID | Name]+

Delete one or more Datasets and all of their descendents. This can potentially delete a lot.
Images, Datasets, the whole lot potentially.
It is suggested to try -n first to see what will happen.
And once its gone, its gone.  You can only get it back from a backup.
You do have a backup, right?

Options:
  -i, --images      Delete all images (and their dependencies) in each dataset.
  -o, --orph        Keep orphaned Original Files even if they are not used by any other MEX
  -n, --noop        Do not delete anything, just report what would be deleted.
  -d, --delete      Actually delete the Datasets.  Nothing will happen unless -n or -d is specified.  
  -f, --keep-files  Keep orphaned OMEIS Files.  
  -p, --keep-pixels Keep orphaned OMEIS Pixels.
  -g, --graph       Generate a graph of the dependencies using GraphViz, and save in specified file.
CMDS
}


sub DeleteDataset {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my ($do_images,$orph,$noop,$delete,$keep_files,$keep_pixels,$make_graph);

	# Parse our command line options
	GetOptions(
		'images|i!' => \$do_images,
		'orph|o!' => \$orph,
		'noop|n!' => \$noop,
		'delete|d' => \$delete,
		'keep-files|f' => \$keep_files,
		'keep-pixels|p' => \$keep_pixels,
		'graph|g=s' => \$make_graph,
	);

	$self->DeleteDataset_help($commands) if (scalar(@ARGV) <= 0);
	
	$keep_files  = 1 if $noop;
	$keep_pixels = 1 if $noop;
	$DELETE_ORPHANED_OFs = 0 if $orph;
	my $manager = OME::SessionManager->new();
    my $session = $self->getSession();
	$FACTORY = $session->Factory();
	
	# This is useful for debugging:
	#$FACTORY->obtainDBH()->{AutoCommit} = 1;
	$IMAGE_IMPORT_MODULE_ID = $session->Configuration()->image_import_module()->id();

	# Get the objects
	my @objects;
	foreach my $arg (@ARGV) {
		my $obj;
		if ($arg =~ /^(\d+)$/) {
			$obj = $FACTORY->loadObject( "OME::Dataset", $arg) or 
				die "Could not load Dataset ID=$arg specified on the command-line.\n";
		} else {
			my @objs = $FACTORY->findObjects( "OME::Dataset", {name => $arg});
			die "Could not load Dataset named '$arg' specified on the command-line.\n"
				unless (scalar (@objs));
			die "There is more than one Dataset named '$arg': ".
				join (', ',map {$_->id()} @objs)."\nPlease specify IDs\n"
					if (scalar (@objs) > 1);
			$obj = $objs[0];
		}
		push (@objects,$obj);
		print "Retreived Dataset ID = ".$obj->id().", Name = ".$obj->name()."\n";
	}
	
	my @MEXes;
	if ($do_images) {
		foreach my $obj (@objects) {
			foreach my $image ($obj->images() ) {
				my @img_MEXes = $FACTORY->findObjects ('OME::ModuleExecution',{
					image_id => $image->id(),
					'module_id' => $IMAGE_IMPORT_MODULE_ID,
				});
				push (@MEXes,@img_MEXes);
			}
		}
	}

	$self->delete_mexes (\@MEXes,$delete,$noop,$keep_files,$keep_pixels,$make_graph)
		if (scalar (@MEXes));
	$self->delete_dataset ($_,$delete,undef) foreach @objects;
	$session->commitTransaction() if $delete;
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
  -o, --orph        Keep orphaned Original Files even if they are not used by any other MEX
  -n, --noop        Do not delete anything, just report what would be deleted.
  -d, --delete      Actually delete the MEX(es).  Nothing will happen unless -n or -d is specified.  
  -m, --module      Delete all MEXes for the specified module (ID if numeric, otherwise by name).  
  -f, --keep-files  Keep orphaned OMEIS Files.  
  -p, --keep-pixels Keep orphaned OMEIS Pixels.
  -g, --graph       Generate a graph of the dependencies using GraphViz, and save in specified file.
CMDS
}


sub DeleteMEX {
	my ($self,$commands) = @_;
	my $script = $self->scriptName();
	my $command_name = $self->commandName($commands);
	my ($orph,$noop,$delete,$module_in,$keep_files,$keep_pixels,$make_graph);

	# Parse our command line options
	GetOptions(
		'orph|o!' => \$orph,
		'noop|n!' => \$noop,
		'delete|d' => \$delete,
		'module|m=s' => \$module_in,
		'keep-files|f' => \$keep_files,
		'keep-pixels|p' => \$keep_pixels,
		'graph|g=s' => \$make_graph,
	);

	$self->DeleteMEX_help($commands) if (scalar(@ARGV) <= 0 and not defined $module_in);

	$keep_files  = 1 if $noop;
	$keep_pixels = 1 if $noop;
	$DELETE_ORPHANED_OFs = 0 if $orph;
	my $manager = OME::SessionManager->new();
    my $session = $self->getSession();
	$FACTORY = $session->Factory();
	
	# This is useful for debugging:
	#$FACTORY->obtainDBH()->{AutoCommit} = 1;

	$IMAGE_IMPORT_MODULE_ID = $session->Configuration()->image_import_module()->id();
	
	if ($make_graph) {
		GraphViz->require()
			or die "The Perl package GraphViz needs to be installed to use the -g flag.";
		$GRAPH = GraphViz->new(rankdir  => 1);
		# This should maybe be its own configuration variable	
		$WEB_UI = 'http://'.$session->Configuration()->lsid_authority().'/perl2/serve.pl';
	}

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
			die "Could not load MEX ID=$arg_mex_id specified on the command-line.\n";
		push (@MEXes,$arg_mex);
		print "Retreived MEX ID = $arg_mex_id\n";
	}

	$self->delete_mexes (\@MEXes,$delete,$noop,$keep_files,$keep_pixels,$make_graph);


}

sub delete_st {
	my ($self, $ST, $delete, $noop) = @_;
    my $session = $self->getSession();
	
	return if exists $DELETED_STS{$ST->id()};

	# This prevents infinite recursion.  When we actually delete the MEX, this
	# will be set to 1.
	$DELETED_STS{$ST->id()} = 0;
	$RECURSION_LEVEL++;
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '    '; }

	print $recurs_indent,"++Semantic Type ",$ST->id()," ",$ST->name(),"\n";

	# is this ST used as a FormalInput/FormalOutput for some module?
	my $FI = $FACTORY->findObject( "OME::Module::FormalInput", {semantic_type_id  => $ST->id()});		
	die "\nFormalInput '".$FI->name()."' of Module '".$FI->module()->name()."' is defined to be".
		" of Semantic Type '".$ST->name(). "'.\nSo the ST '".$ST->name()."' can't be deleted.\n"
		if (defined $FI);
	
	my $FO = $FACTORY->findObject( "OME::Module::FormalOutput", {semantic_type_id  => $ST->id()});		
	die "\nFormalOutput '".$FO->name()."' of Module '".$FO->module()->name()."' is defined to be".
		" of Semantic Type '".$ST->name(). "'.\nSo the ST '".$ST->name()."' can't be deleted.\n"
		if (defined $FO);
		
	my $untypedOutput = $FACTORY->findObject( "OME::ModuleExecution::SemanticTypeOutput",  {semantic_type_id  => $ST->id()});
	die "\nUntyped Formal Output of Module '".$untypedOutput->module_execution()->module()->name()."' is defined to be".
		" of Semantic Type '".$ST->name(). "'.\nSo the ST '".$ST->name()."' can't be deleted.\n"
		if (defined $untypedOutput);
		
	# is this ST by referenced by other STs ?
	my $ST_refs;
	my @ref_cols = $FACTORY->findObjects("OME::DataTable::Column", {reference_type => $ST->name()});

	foreach my $ref_col (@ref_cols) {
		my @ref_SEs = $FACTORY->findObjects("OME::SemanticType::Element", {data_column_id => $ref_col->id()});
		foreach my $ref_SE (@ref_SEs) {
			$ST_refs->{$ref_SE->semantic_type->name()} = $ref_SE->semantic_type();
		}
	}
	
	# the referencing STs have to be removed as well
	foreach my $ST_ref (keys (%$ST_refs)) {
		print $recurs_indent," -> ".$ST->name()." is being referenced by ST ",$ST_refs->{$ST_ref}->id()," ",$ST_ref,"\n";
		$self->delete_st($ST_refs->{$ST_ref}, $delete, $noop);
	}
	
	# all checks have passed so let's do the delete
	my @SEs = $FACTORY->findObjects("OME::SemanticType::Element", {semantic_type_id => $ST->id()});
	my @cols;
	my $data_tables; # there can be more than one data_table per ST
	foreach my $SE (@SEs) {
	
		# delete the SE
		print $recurs_indent. "  ++".$ST->name()."'s SE ".$SE->name."\n";
		$SE->deleteObject() if $delete;
		
		# if the SE is a reference, drop the foreign key constraint
		my $data_col = $FACTORY->findObject("OME::DataTable::Column", {id => $SE->data_column_id()});
		my $data_table = $FACTORY->findObject("OME::DataTable", {id => $data_col->data_table_id()});

		# this SE is a reference to another ST. We need to remove the foreign constrain
		# on the other ST table
		if ($data_col->reference_type()) {
		
			# what SE 
			my $sql = 'ALTER TABLE "'.lc($data_table->table_name()).'" '.
					  'DROP CONSTRAINT "@'.$ST->name().'.'.$SE->name().'->@'.$data_col->reference_type.'"';

			print $recurs_indent."  ".$sql."\n";
			$FACTORY->obtainDBH()->do($sql) or die $FACTORY->obtainDBH()->errstr() if $delete;
		}
		$data_col->deleteObject() if $delete;

		# record the DataTable this SE used to be written to, so we can drop table in the future
		push (@cols, $data_col);
		$data_tables->{$data_table->table_name()}=$data_table;
	}

	# delete the ST and drop the table, if appropriate	
	$ST->deleteObject() if $delete;
	
	# there can be more than one ST per data_table. So we need to check data_column
	foreach my $tname (keys %$data_tables) {
		my @other_STs_using_data_table = $FACTORY->findObjects("OME::DataTable::Column",
												               {data_table_id => $data_tables->{$tname}->id()});

		if (scalar(@other_STs_using_data_table) == 0) {		
			# if there are other STs
			my $sql = 'DROP TABLE "'.lc($tname).'"';
			print $recurs_indent."  ".$sql."\n";
			$FACTORY->obtainDBH()->do($sql) or die $FACTORY->obtainDBH()->errstr() if $delete;
			$data_tables->{$tname}->deleteObject();
		} else {
			print $recurs_indent. "  Didn't DROP TABLE ".lc($tname)." because it stores other STs\n";
			
			# remove table foreign keys
			
		}
	}
	$DELETED_STS{$ST->id()} = 1;
	$RECURSION_LEVEL--;
}

sub delete_mexes {
	my ($self,$MEXes,$delete,$noop,$keep_files,$keep_pixels,$make_graph) = @_;
	
	my $session = $self->getSession();
	
	$RECURSION_LEVEL=0;
	undef %DELETED_ATTRS;
	undef %DELETED_MEXES;
	undef %DELETED_IMAGES;
	undef %DELETED_DATASETS;
	undef %DELETED_EXPERIMENTERS;
	undef %DELETED_GROUPS;
	undef %ACS_DELETED_NODES;
	undef %DELETED_PIXELS;
	undef %DELETED_ORIGINAL_FILES;
	undef %ST_REFS;

	foreach my $MEX (@$MEXes) {		
		
		unless ($delete or $noop) {
			print "Nothing to do.  Try -n\n";
			exit;
		}
	
		$self->delete_mex ($MEX,$delete,undef);
	}

	$session->commitTransaction() if $delete;
	
	if ($make_graph) {
		my $frmt;
		$frmt = "as_$1" if $make_graph =~ /.+\.(\w+)$/;
		$GRAPH->$frmt ($make_graph);
	}
	
	# We can't combine a DB transaction with an OMEIS transaction,
	# So we do this only if the DB transaction succeeds
	$self->cleanup_omeis($keep_files,$keep_pixels);
	
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
my $from_mex = shift;
my $mex_id;

	confess "NULL MEX!" unless $mex;

	$mex_id = $mex->id();

	return if exists $DELETED_MEXES{$mex_id};


	# This prevents infinite recursion.  When we actually delete the MEX, this
	# will be set to 1.
	$DELETED_MEXES{$mex_id} = 0;

	$RECURSION_LEVEL++;
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	print $recurs_indent,"++MEX $mex_id: ",$mex->module()->name(),"\n";

	# Add this node to the graph
	if ($GRAPH) {
		my $label = $mex->module()->name()."\\n[$mex_id]";
		$label .= ' V' if $mex->virtual_mex();
		$GRAPH->add_node ($mex_id,
			label => $label,
			URL =>"$WEB_UI?Page=OME::Web::DBObjDetail&ID=$mex_id&Type=OME::ModuleExecution",
		);
		$GRAPH->add_edge ($from_mex->id() => $mex_id) if $from_mex;
	}

	
	# If the MEX is an $IMAGE_IMPORT_MEX, delete the image
	$self->delete_image ($mex->image(),$delete,$mex)
		if ($mex->module->id() == $IMAGE_IMPORT_MODULE_ID and $mex->image());


	my $input;
	my @actual_inputs = $FACTORY->
		findObjects("OME::ModuleExecution::ActualInput",
			{
			input_module_execution_id => $mex_id,
			});
	foreach $input (@actual_inputs) {
		print $recurs_indent,"  Actual input ",$input->id(),"\n";
		$self->delete_mex ($input->module_execution(),$delete,$mex) if $input->module_execution();
	}

	
	# Gather up the typed an untyped outputs
	my @outputs = $mex->module()->outputs();
	my @untyped_outputs = $mex->untypedOutputs();
	my @parental_outputs = $mex->parentalOutputs();
	
	my %features;
	my $mex_feature_tag = $mex->new_feature_tag();
	$mex_feature_tag = $2
		if $mex_feature_tag and $mex_feature_tag =~ /(\[Child|Sibling|Root\:)?([^:\[\]]+)(\])?$/;

	my %parentals;
	$parentals{$_->id()} = $_ foreach @parental_outputs;
	push (@outputs,@untyped_outputs,@parental_outputs);

	foreach my $output (@outputs) {
		my $ST = $output->semantic_type();
		next unless $ST; # Skip the untyped output itself
		my $o_name;
		$o_name =  UNIVERSAL::can ($output,'name') ? $output->name() :
			exists $parentals{$output->id()} ? '*** Parental ***' : '*** Untyped ***';
		print $recurs_indent,"  Output = ",$o_name," (",$ST->name(),")\n";

		if ($mex->virtual_mex()) {
			my @virtual_mex_maps = $FACTORY->findObjects('OME::ModuleExecution::VirtualMEXMap', {
					module_execution => $mex,
			});
			foreach my $map (@virtual_mex_maps) {
				print $recurs_indent,"  VirtualMEXMap to MEX ID=",$map->module_execution_id(),"\n";
				$map->deleteObject() if $delete;
			}
		} else {
			my $attributes = OME::Tasks::ModuleExecutionManager->
				getAttributesForMEX($mex,$ST);
			my $feature;
			my $is_feature_output = 1 if $ST->granularity() eq 'F';
			# Delete all attributes - this will delete any vMexes,
			# any references, and the mexes that generated the references.
			foreach my $attr (@$attributes) {
				# Register a feature for deletion if this mex made it
				if ($mex_feature_tag and $is_feature_output) {
					$feature = $attr->feature();
					$features{$feature->id()} = $feature
						if $feature->tag() eq $mex_feature_tag;
				}
				$self->delete_attribute ($attr,$mex,$delete);
			}
		}
	}
	
	# Delete any untyped outputs - these are OME::ModuleExecution::SemanticTypeOutput
	foreach my $output (@untyped_outputs) {
		print $recurs_indent,"  Untyped output ",$output->id(),"\n";
		$output->deleteObject() if $delete;
	}
	
	# Delete any parental outputs - these are OME::ModuleExecution::ParentalOutput
	# These are attributes that get created
	foreach my $output (@parental_outputs) {
		print $recurs_indent,"  Parental output ",$output->id(),"\n";
		$output->deleteObject() if $delete;
	}
	
	# Delete any Feature outputs
	if ($mex_feature_tag) {
		foreach my $feature (values %features) {
			print $recurs_indent,"  Feature output ",$feature->id(),"\n";
			$feature->deleteObject() if $delete;
		}
		%features = ();
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
		findObjects("OME::ModuleExecution::ActualInput",{
			module_execution_id => $mex_id,
			});
	push (@actual_inputs,@mex_actual_inputs);
	

	# Special handling is done for OriginalFile MEXes that become orphaned as a result
	# of deleting this MEX.  Depending on passed-in parameters, if this is the last MEX
	# fed by an OriginalFiles module, delete the mex for the OriginalFiles module as well.
	if ($DELETE_ORPHANED_OFs) {
		foreach $input (@mex_actual_inputs) {
			if ($input->formal_input()->semantic_type()->name() eq 'OriginalFile') {
				my $nOFmexes = $FACTORY->countObjects ('OME::ModuleExecution::ActualInput', {
					'input_module_execution_id' => $input->input_module_execution_id(),
				});
				next unless $nOFmexes == 1;

				my $orph_MEX = $input->input_module_execution();
				my $attributes = OME::Tasks::ModuleExecutionManager->
					getAttributesForMEX($orph_MEX ,'OriginalFile');
				print $recurs_indent,"  Orphaned MEX ".$orph_MEX->id().": ",$orph_MEX->module()->name(),"\n";
				$self->delete_mex ($orph_MEX,$delete,$mex);
				foreach my $attr (@$attributes) {
					next unless $attr and $attr->module_execution();
					my @vMEXes = $FACTORY->findObjects('OME::ModuleExecution::VirtualMEXMap',{
						attribute_id => $attr->id(),
					});
					@vMEXes = () if scalar (@vMEXes) == 1 and
						$vMEXes[0]->module_execution_id() == $orph_MEX->id();
					next if scalar (@vMEXes);

					my @AIs = $FACTORY->findObjects('OME::ModuleExecution::ActualInput',{
			# FIXME: 'input_module_execution.OriginalFileList.id' => $OF->id() # Doesn't work?
						'input_module_execution.OriginalFileList.SHA1' => $attr->SHA1(),
					});
					next if scalar (@AIs);

					my $nAttr = $FACTORY->countObjects('@OriginalFile',{
						module_execution_id => $attr->module_execution_id(),
					});
					if ($nAttr > 1) {
						print $recurs_indent,"  Orphaned Attribute ".$attr->id().": ",$orph_MEX->module()->name(),"\n";
						$self->delete_attribute ($attr,$attr->module_execution(),$delete);
					} elsif ($nAttr == 1) {
						print $recurs_indent,"  Orphaned MEX ".$attr->module_execution()->id().": ",
							$attr->module_execution()->module()->name(),"\n";
						$self->delete_mex ($attr->module_execution(),$delete,$orph_MEX);
					}
					
				}
			}
		}
	}


	# Delete actual_inputs that used this mex as an input module and those produced by this module
	foreach $input (@actual_inputs) {
		print $recurs_indent,"  Actual input ",$input->id(),"\n";
		$input->deleteObject() if $delete;
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


sub delete_image () {
my $self = shift;
my $image = shift;
my $delete = shift;
my $mex = shift;
my $mex_id = defined $mex ? $mex->id() : undef;
my $import_mex;

	return if exists $DELETED_IMAGES{$image->id()};
	$DELETED_IMAGES{$image->id()} = 0;
	
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	print $recurs_indent,"  Image ",$image->id()," ",$image->name(),"\n";

	# First, delete all MEXes that have this image as the target.
	my @image_mexes = $FACTORY->
		findObjects("OME::ModuleExecution",
			{
			image_id => $image->id(),
			});
	foreach my $image_mex (@image_mexes) {
		$import_mex = $image_mex if $image_mex->module->id() == $IMAGE_IMPORT_MODULE_ID;
		next if $image_mex->id() == $mex_id;
		print $recurs_indent,"  Image MEX ",$image_mex->id(),"\n";
		$self->delete_mex ($image_mex,$delete,$mex);
	}
	
	# Next, delete any left-over image attributes that don't have this image as the target.
	my $image_attrs = $self->get_image_attributes ($image);
	foreach my $attr (@$image_attrs) { $self->delete_attribute ($attr,$mex,$delete) ;}

	# Since we're at it, we have to delete the image from the OME::Image::DatasetMap
	my @dataset_links = $FACTORY->findObjects("OME::Image::DatasetMap",
		{ image_id => $image->id()}
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
			$self->delete_mex ($dataset_mex,$delete,$mex);
		}
		
		# Since there are no dataset mexes for this dataset, unlock it.
		print $recurs_indent,"    Unlocking Dataset ",
			$dataset->name(),", ID=",$dataset->id(),"\n";
		if ($delete) {
			$dataset->locked(0);
			$dataset->storeObject();
		}
	}

	$image->deleteObject() if $delete;
	$DELETED_IMAGES{$image->id()} = 1;
}

sub delete_dataset {
my $self = shift;
my $dataset = shift;
my $delete = shift;
my $mex = shift;
my $mex_id = defined $mex ? $mex->id() : undef;
my $dataset_id = $dataset->id();

	return if exists $DELETED_DATASETS{$dataset_id};
	$DELETED_DATASETS{$dataset_id} = 0;
	
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	print $recurs_indent,"  Dataset $dataset_id ",$dataset->name(),"\n";

	# First, delete all MEXes that have this dataset as the target.
	my @dataset_mexes = $FACTORY->
		findObjects("OME::ModuleExecution",
			{
			dataset_id => $dataset_id,
			});
	foreach my $dataset_mex (@dataset_mexes) {
		next if $dataset_mex->id() == $mex_id;
		print $recurs_indent,"  Dataset MEX ",$dataset_mex->id(),"\n";
		$self->delete_mex ($dataset_mex,$delete,$mex);
	}
	
	# Next, delete any left-over dataset attributes that don't have this dataset as the target.
	my $dataset_attrs = $self->get_dataset_attributes ($dataset);
	foreach my $attr (@$dataset_attrs) { $self->delete_attribute ($attr,$mex,$delete) ;}

	# Since we're at it, we have to delete the dataset from the OME::Image::DatasetMap
	my @image_links = $FACTORY->findObjects("OME::Image::DatasetMap",
		{ dataset_id => $dataset_id}
	);

	foreach my $image_link (@image_links) {
		my $img = $image_link->image();
		print $recurs_indent,"    Image Link to ",$img ? $img->name() : 'undefined',
			", ID=",$img ? $img->id() : 'undefined',"\n";
		$image_link->deleteObject() if $delete;
	}

	# And also the dataset from the OME::Project::DatasetMap
	my @project_links = $FACTORY->findObjects("OME::Project::DatasetMap",
		{ dataset_id => $dataset_id}
	);
	foreach my $project_link (@project_links) {
		my $project = $project_link->project();
		print $recurs_indent,"    Project Link to ",$project ? $project->name() : 'undefined',
			", ID=",$project ? $project->id() : 'undefined',"\n";
		$project_link->deleteObject() if $delete;
	}
	
	# The dataset may be referenced from the UserState
	my @USs = $FACTORY->findObjects("OME::UserState",
		{ dataset_id => $dataset_id}
	);
	foreach my $US (@USs) {
		$US->dataset_id(undef);
		$US->storeObject() if $delete;
	}
		
	
	$dataset->deleteObject() if $delete;
	$DELETED_DATASETS{$dataset_id} = 1;
}


sub delete_group {
my $self = shift;
my $group = shift;
my $delete = shift;
my $mex = shift;
my $mex_id = defined $mex ? $mex->id() : undef;
	return if exists $DELETED_GROUPS{$group->id()};
	$DELETED_GROUPS{$group->id()} = 0;

	if ($group->id() == $self->getSession()->experimenter->Group->id()) {
		die "Attempt to delete the default Group of the logged-in OME Experimenter!!!";
	}

	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	print $recurs_indent,"  Group ",$group->id()," ",$group->Name(),"\n";
	
	# A group can be referenced from a MEX, Project, Dataset, Image, Experimenter, AnalysisChain, AnalysisChainExecution
	my @MEXes = $FACTORY->findObjects ('OME::ModuleExecution',group => $group);
	foreach my $MEX (@MEXes) {
		$self->delete_mex ($MEX,$delete,$mex) if $MEX;
	}
	
	my @projects = $FACTORY->findObjects ('OME::Project',group => $group);
	foreach my $project (@projects) {
		print $recurs_indent,"    Project ",$project->name(),
			", ID=",$project->id(),"\n";
		$project->deleteObject() if $delete;
		# The project may be referenced from the UserState
		my @USs = $FACTORY->findObjects("OME::UserState",
			{ project_id => $project->id()}
		);
		foreach my $US (@USs) {
			$US->project_id(undef);
			$US->storeObject() if $delete;
		}
	}
	
	my @datasets = $FACTORY->findObjects ('OME::Dataset',group => $group);
	foreach my $dataset (@datasets) {
		$self->delete_dataset ($dataset,$delete,undef) if $dataset;
	}
	
	my @images = $FACTORY->findObjects ('OME::Image',group => $group);
	foreach my $image (@images) {
		$self->delete_image ($image,$delete,undef) if $image;
	}

	my @experimenters = $FACTORY->findObjects ('@Experimenter',Group => $group);
	foreach my $experimenter (@experimenters) {
		$self->delete_experimenter ($experimenter,$delete,undef);
	}

	$self->delete_attribute ($group,undef,$delete);	


	$DELETED_GROUPS{$group->id()} = 0;
}

sub delete_experimenter {
my $self = shift;
my $experimenter = shift;
my $delete = shift;
my $mex = shift;
my $mex_id = defined $mex ? $mex->id() : undef;

	return if exists $DELETED_EXPERIMENTERS{$experimenter->id()};
	$DELETED_EXPERIMENTERS{$experimenter->id()} = 0;

	if ($experimenter->id() == $self->getSession()->experimenter->id()) {
		die "Attempt to delete the Experimenter associated with the logged-in OME session!!!";
	}

	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	print $recurs_indent,"  Experimenter ",$experimenter->id()," ",$experimenter->FirstName()," ",$experimenter->LastName(),"\n";
	
	# An experimenter can be referenced from a MEX, Project, Dataset, Image, Group, AnalysisChain, AnalysisChainExecution
	my @MEXes = $FACTORY->findObjects ('OME::ModuleExecution',experimenter => $experimenter);
	foreach my $MEX (@MEXes) {
		$self->delete_mex ($MEX,$delete,$mex) if $MEX;
	}
	
	my @projects = $FACTORY->findObjects ('OME::Project',owner => $experimenter);
	foreach my $project (@projects) {
		print $recurs_indent,"    Project ",$project->name(),
			", ID=",$project->id(),"\n";
		$project->deleteObject() if $delete;
		# The project may be referenced from the UserState
		my @USs = $FACTORY->findObjects("OME::UserState",
			{ project_id => $project->id()}
		);
		foreach my $US (@USs) {
			$US->project_id(undef);
			$US->storeObject() if $delete;
		}
	}

	my @datasets = $FACTORY->findObjects ('OME::Dataset',owner => $experimenter);
	foreach my $dataset (@datasets) {
		$self->delete_dataset ($dataset,$delete,undef) if $dataset;
	}

	my @images = $FACTORY->findObjects ('OME::Image',owner => $experimenter);
	foreach my $image (@images) {
		$self->delete_image ($image,$delete,undef) if $image;
	}


	my @groups = $FACTORY->findObjects ('@Group',Leader => $experimenter);
	my @groups2 = $FACTORY->findObjects ('@Group',Contact => $experimenter);
	push (@groups,@groups2);
	foreach my $group (@groups) {
		$self->delete_group ($group,$delete,undef);
	}

	# The Experimenter may be referenced from the UserState
	my @USs = $FACTORY->findObjects("OME::UserState",
		{ experimenter_id => $experimenter->id()}
	);
	foreach my $US (@USs) {
		$US->deleteObject if $delete;
	}


	$self->delete_attribute ($experimenter,undef,$delete);	
	
	
	$DELETED_EXPERIMENTERS{$experimenter->id()} = 1;
}



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

sub get_dataset_attributes () {
my $self = shift;
my $dataset = shift;
my @dataset_attrs;

	@DATASET_STs = $FACTORY->findObjects("OME::SemanticType",granularity => 'D')
		unless defined @DATASET_STs;
	
	foreach my $ST (@DATASET_STs) {
		my @objects = $FACTORY->findAttributes($ST,{dataset_id => $dataset->id()});
		push (@dataset_attrs,@objects);
	}
	
	return \@dataset_attrs;
}

# This belongs in OME::Tasks::SemanticTypeManager
# Or even better in OME::Tasks::AttributeManager
sub get_references_to {
my $self = shift;
my $attr = shift;
my $ST = $attr->semantic_type();
my $attr_id = $attr->id();
my @ref_attrs;


	unless (exists $ST_REFS{$ST}) {
		my $ST_refs;
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
				$ST_refs->{$ref_SE->semantic_type->name()}->{ST} = $ref_SE->semantic_type();
				$ST_refs->{$ref_SE->semantic_type->name()}->{Elements}->{$ref_SE->name()} = $ref_SE;
			}
		}
		
		$ST_REFS{$ST} = $ST_refs;
	}
	
	my $refs = $ST_REFS{$ST};
	
	foreach my $ST_ref (values (%$refs)) {
		foreach my $ref_SE (keys %{$ST_ref->{Elements}}) {
			my @attrs = $FACTORY->findAttributes($ST_ref->{ST}, {
				$ref_SE => $attr_id,
			});
			push (@ref_attrs , @attrs) if scalar (@attrs);
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
my $mex_id = defined $mex ? $mex->id() : undef;

	return unless $attr;
	return if exists $DELETED_ATTRS{$attr->semantic_type()->name().':'.$attr->id()};
	# Block infinite recursion
	$DELETED_ATTRS{$attr->semantic_type()->name().':'.$attr->id()} = 0;
			
	my $recurs_indent='';
	for (my $i=1; $i < $RECURSION_LEVEL;$i++) { $recurs_indent .= '  '; }

	# This attribute may have virtual MEXes, so descend again
	my $vMEXes = OME::Tasks::ModuleExecutionManager->getMEXesForAttribute($attr);
	foreach my $vMex (@$vMEXes) {
		next unless $vMex;
		next unless $vMex->virtual_mex();
		$self->delete_mex ($vMex,$delete,$mex) unless $vMex->id() == $mex_id;		
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
			$self->delete_mex ($ref_MEX,$delete,$mex) unless $ref_MEX->id() == $mex_id;
		}
		$self->delete_attribute_object ($ref_attr,$delete,$recurs_indent."      Reference from ");
	}
	$self->delete_attribute_object ($attr,$delete,$recurs_indent."      ");
	$DELETED_ATTRS{$attr->semantic_type()->name().':'.$attr->id()} = 1;
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
	} elsif ($ST_name eq 'Experimenter') {
		$self->delete_experimenter ($attr,$delete,undef);
	} elsif ($ST_name eq 'Group') {
		$self->delete_group ($attr,$delete,undef);
	}
	
	# Special handling for Experimenters, Groups, ExperimenterGroups?
	# Experimenters and Groups can be refered to from Project, Dataset, Image, Feature

	if ($do_del) {
		print $message,"Attribute $attr_id ($ST_name)\n";
		if ($delete) {
			$attr->deleteObject();
		}
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
				OME::Image::Server->deleteFile($file_spec->{Repository},$file_spec->{FileID})
					unless $keep_files;
			}
			$omeis_ids{$omeis_ids_key} = 1;
		}
	} # DELETED_ORIGINAL_FILES
}



1;
