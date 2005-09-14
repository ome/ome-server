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
# Written by:	 Josiah Johnston <siah@nih.gov>
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

# Finds inputs & stiches them together


# FIXME:
# Allow modules that use this interface to input VectorLegends, and only
# create new VectorLegends if none are found in the list of module inputs.
# This would mandate checking to see if the vector legend actual input is 
# compatible with the sig stitcher module.

sub execute {
	my ($self,$dependence,$target) = @_;
	my $factory = OME::Session->instance()->Factory();

	my $mex = $self->getModuleExecution();
	my $module = $mex->module();
	
	# Figure out what's been passed in this time.
	my @formal_inputs = $factory->findObjects('OME::Module::FormalInput', { module => $module });
	@formal_inputs = sort { $a->name cmp $b->name } @formal_inputs;

	# Make some entries for each input
	my $signature_vector_size = 0;
	foreach my $formal_input ( @formal_inputs ) {
		die "Inputs of arity greater than 1 are not supported at this time. Error with input ".$formal_input->name()
			if $formal_input->list();
		
		# Collect the actual inputs for all the images
		my @input_attr_list = $self->getInputAttributes( $formal_input )
		  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";
		
		# Every semantic element gets an entry in the vector
		my @SEs = $formal_input->semantic_type->semantic_elements();
		@SEs = sort { $a->name cmp $b->name } @SEs;
		foreach my $se ( @SEs ) {
		
			# is SE of an appropriate type i.e a double
			next if $se->data_column()->sql_type() eq 'string';
			next if $se->data_column()->sql_type() eq 'reference';

			$signature_vector_size++;
			my $se_name = $se->name();
			
			# Define a new vector position.
			my $position = $factory->newAttribute( 
# The line below is for a Gloabl Signature Vector Legend
#				'SignatureVectorLegend', undef, $mex,
				'SignatureVectorLegend', $target, $mex,
				{
					VectorPosition  => $signature_vector_size,
					FormalInput     => $formal_input->name,
					SemanticElement => $se_name
				} 
			) or die "Couldn't make a SignatureVectorLegend";
			
			# Create a vector entry for each image
			foreach my $input_attr (@input_attr_list ) {
				$factory->newAttribute( 
					'SignatureVectorEntry', $input_attr->image, $mex,
					{
						Value  => $input_attr->$se_name,
						Legend => $position
					} 
				) or die "Couldn't make a new vector entry";
			}
		}
	}

}

1;

__END__

=head1 AUTHOR

Josiah Johnston <siah@nih.gov>

=cut
