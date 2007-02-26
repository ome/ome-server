# OME/Analysis/Modules/Classification/SignatureStitcher.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
# Written by:	Tom Macura <tmacura@nih.gov>
#              based on Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------

=head1 NAME

OME::Analysis::Modules::Classification::SignatureStitcher - Merge
signature inputs into a vector

=head1 DESCRIPTION

Generic code underlying any and all signature stitching. Module inputs
are detected at run time. This will produce outputs
SignatureVectorLegend and SignatureVectorEntry. See
OME/src/xml/OME/Tests/SigStitcher.ome for an example of a module written
against this.

=head1 Notes for Future Direction

SignatureVectorLegend could easily be global granularity. It needs to be
generated once when the chain is locked. At this time, modules that
accept any non global inputs are not allowed to produce global outputs.

Prerequisates for transitioning to Global granularity are changing the
AE to allow global outputs.
A co-requisate is the transition of the BayesNetClassifier.

=cut

package OME::Analysis::Modules::Classification::SignatureStitcher;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
use OME::Analysis::Handler;
use OME::Tasks::ModuleExecutionManager;

use base qw(OME::Analysis::Handler);
use Time::Local;
use Time::HiRes qw(gettimeofday tv_interval);

# Finds inputs & stiches them together


# FIXME:
# Allow modules that use this interface to input VectorLegends, and only
# create new VectorLegends if none are found in the list of module inputs.
# This would mandate checking to see if the vector legend actual input is 
# compatible with the sig stitcher module.

sub print_err_msg {
	my ($self,$txt) = @_;
	my $timestamp = time;
	my $timestr = localtime $timestamp;
	logdbg "debug", "[$timestr] ".$txt;		
}

sub execute {
	my ($self,$dependence,$target) = @_;
	my $factory = OME::Session->instance()->Factory();

	my $start_timestamp = time;
	my $start_timestr = localtime $start_timestamp;

	my $mex = $self->getModuleExecution();
	my $module = $mex->module();
	
	#
	# Build the Signature Vector Legend 
	#
	$self->print_err_msg ("	Creating Signature VectorLegend (Perl)");
	my @formal_inputs = $factory->findObjects('OME::Module::FormalInput', { module => $module });
	@formal_inputs = sort { $a->name cmp $b->name } @formal_inputs;
	
	my @VectorPositions;
	my @FormalInputs;
	my @SemanticElements;
	my @Targets;

	my %SignatureVectorLegends = (
			VectorPosition => \@VectorPositions,
			FormalInput => \@FormalInputs,
			SemanticElement => \@SemanticElements,
			Target => \@Targets);

	my $signature_vector_size = 0;
	my $num_of_signatures = 0;
	foreach my $formal_input ( @formal_inputs ) {
		
		# this should only be called once
		if (not $num_of_signatures) {
			my @input_attr_list = $self->getInputAttributes( $formal_input )
			  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";
			$num_of_signatures = scalar (@input_attr_list);
		}
		
		my @SEs = $formal_input->semantic_type->semantic_elements();
		@SEs = sort { $a->name cmp $b->name } @SEs;
		
		foreach my $se ( @SEs ) {
		
			# is SE of an appropriate type i.e a double
			next if $se->data_column()->sql_type() eq 'string';
			next if $se->data_column()->sql_type() eq 'reference';

			$signature_vector_size++;
			
			# Define a new vector position.
			push (@VectorPositions, $signature_vector_size);
			push (@FormalInputs, $formal_input->name());
			push (@SemanticElements, $se->name());
			push (@Targets, $target->id());
		}
	}
	
	#	
	# Build the Signature Vector Entry 
	#
	$self->print_err_msg ("	Writing Signature VectorLegend (newObjectsNitrox)");
	my $SignatureVectorLegendST = $factory->findObject("OME::SemanticType", name => 'SignatureVectorLegend');
	$factory->newObjectsNitrox ($SignatureVectorLegendST, $mex, \%SignatureVectorLegends)
		or die "Couldn't make SignatureVectorLegends";

	# prepare for the Signature Vector Entry outputs;
	$self->print_err_msg ("	Creating SignatureVectorEntry (Perl)");

	my $SignatureVectorEntryST = $factory->findObject("OME::SemanticType", name => 'SignatureVectorEntry');

	$factory->maybeNewObject("OME::ModuleExecution::SemanticTypeOutput", {
			module_execution => $mex,
			semantic_type    => $SignatureVectorEntryST,
	}) or die "Couldn't record MEX's SemanticTypeOutput of SignatureVectorEntry";

	my @Values;
	my @Legends;
	@Targets = ();
	# pre-sizing is only a guess I assume that each ST has less than 64 SEs
	# if this guess is wrong, performance will degrade
	$#Values= 64 * $num_of_signatures-1;
	$#Legends=64 * $num_of_signatures-1;
	$#Targets=64 * $num_of_signatures-1;

	my %SignatureVectorEntries = (
		Value => \@Values,
		Legend => \@Legends,
		Target => \@Targets,
	);
	
	foreach my $formal_input ( @formal_inputs ) {
		die "Inputs of arity greater than 1 are not supported at this time. Error with input ".$formal_input->name()
			if $formal_input->list();
		
		$self->print_err_msg ("	Creating Signature Vector for ".$formal_input->name());
		
		# Collect the actual inputs for all the images
		my @input_attr_list = $self->getInputAttributes( $formal_input )
		  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";
		
		# Every semantic element gets an entry in the vector
		my @SEs = $formal_input->semantic_type->semantic_elements();
		@SEs = sort { $a->name cmp $b->name } @SEs;

		my $i=0;
		foreach my $se ( @SEs ) {
			# is SE of an appropriate type i.e a double
			next if $se->data_column()->sql_type() eq 'string';
			next if $se->data_column()->sql_type() eq 'reference';
			my $se_name = $se->name();
			
			my $position = $factory->findAttribute('SignatureVectorLegend',{
													FormalInput => $formal_input->name(),
													SemanticElement => $se_name,
												  })
			or die "Couldn't find a SignatureVectorLegend for".$formal_input->name().$se->name();

			# Create a vector entry for each image
			foreach my $input_attr (@input_attr_list ) {
				$Values[$i] = $input_attr->$se_name;
				$Legends[$i] = $position->id();
				$Targets[$i] = $input_attr->feature_id();
				$i++;
			}									
		}
		
		$self->print_err_msg ("	Writing SignatureVectorEntry (newObjectsNitrox)");
		my %newObjectsOptions = (
			ChunkSize => 16000,
			CommitTransaction => 1,
			ObjCount => $i,
		);
		$factory->newObjectsNitrox( $SignatureVectorEntryST, $mex,
									\%SignatureVectorEntries, \%newObjectsOptions)
				or die "Couldn't make a new vector entry";
	}
	
	my $end_timestamp = time;
	my $end_timestr = localtime $end_timestamp;
	
	print "Started $start_timestr\n";
	print "Finished $end_timestr\n";
	
	$self->print_err_msg ("...done");
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Josiah Johnston <siah@nih.gov>

=cut
