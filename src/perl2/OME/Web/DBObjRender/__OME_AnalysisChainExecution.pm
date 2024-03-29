# OME/Web/DBObjRender/__OME_AnalysisChainExecution.pm
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
# Written by:  
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_AnalysisChainExecution;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_AnalysisChainExecution

=head1 DESCRIPTION

Provides custom behavior for rendering an OME::AnalysisChainExecution

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

=head2 _renderData

makes virtual fields breakdown_by_node, which is a list of nodes, each of which
links to a search page that will show all executions of that node in this CHEX.

makes virtual field 'num_errors' that counts MEXs that have error status.
This can be used with a TMPL_IF

implements /name as the chain's name

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	
	my $factory = $obj->Session()->Factory();
	my %record;

	# breakdown_by_node
	if( exists $field_requests->{ 'breakdown_by_node' } ) {
		foreach my $request ( @{ $field_requests->{ 'breakdown_by_node' } } ) {
			my @nodes = $obj->analysis_chain->nodes();
			# FIXME: Original Files and Image import never show up in the chain.
			# When that underlying problem is fixed, this grep should be removed.
			@nodes = grep( 
				($_->module->name ne 'Original files' && 
				$_->module->name ne 'Image import' ),
				@nodes
			);
			
			# Sort Nodes by Module ID. This reflects the order the modules were imported
			# into OME.
			@nodes = sort {$a->module->id cmp $b->module->id} @nodes;
			
			my @node_execution_links;
			foreach my $node ( @nodes ) {
				my $finished_count = $obj->count_node_executions(
					'module_execution.status' => 'FINISHED',
					analysis_chain_node       => $node
				);
				my $unfinished_count = $obj->count_node_executions( 
					'module_execution.status' => 'UNFINISHED',
					analysis_chain_node       => $node
				);
				my $error_count = $obj->count_node_executions( 
					'module_execution.status' => 'ERROR',
					analysis_chain_node       => $node
				);
				my $unready_count = $obj->count_node_executions( 
					'module_execution.status' => 'UNREADY',
					analysis_chain_node       => $node
				);
				
				# render the counter (FINISHED)x (UNFINISHED)x (UNREADY)x (ERROR)x
				my $link = "${finished_count}x";
				$link .= ' <span class="ome_another_caution">'."${unready_count}x</span>" if $unready_count;
				$link .= ' <span class="ome_caution">'."${unfinished_count}x</span>" if $unfinished_count;
				$link .= ' <span class="ome_error">'."${error_count}x</span>" if $error_count;

				# Link straight to the mex if this node has a single NEX
				if( $finished_count+$unfinished_count+$error_count+$unready_count eq 1 ) {
					my $single_nex = $factory->findObject( 
						'OME::AnalysisChainExecution::NodeExecution',
						analysis_chain_execution => $obj,
						analysis_chain_node      => $node
					);
					
					$link .= " <a href='".$self->getObjDetailURL( $single_nex->module_execution );

				# Link to the search page if this node has many NEXs
				} else {
					$link .= " <a href='".
						$self->getSearchURL( 
							'OME::AnalysisChainExecution::NodeExecution',
							analysis_chain_node      => $node->id,
							analysis_chain_execution => $obj->id
						);
				}
				
				# set the Link title and apperance
				$link .= "' title='View Executions of this node' ".
						 ( $error_count ? 
						 	 'class="ome_error"' : (
						   $unfinished_count ?
						   	 'class="ome_caution"': (
						   $unready_count ?
						   	 'class=ome_another_caution':
							 'class="ome_detail"') )
						 ).
						 ">".
						$self->getName( $node )."</a>";
				push( @node_execution_links, $link );
			}
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = '<ul>'.join( "\n", map( "<li>".$_."</li>", @node_execution_links )).'</ul>';
		}
	}
	if( exists $field_requests->{ 'num_errors' } ) {
		foreach my $request ( @{ $field_requests->{ 'num_errors' } } ) {
			my $error_node_count = $obj->count_node_executions( 
				'module_execution.status' => 'ERROR'
			);
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $error_node_count;
		}
	}
	if( exists $field_requests->{ 'class_style' } ) {
		foreach my $request ( @{ $field_requests->{ 'class_style' } } ) {
			my $status = $obj->status;

			my $request_string = $request->{ 'request_string' };
			if ($status eq 'UNFINISHED') {
				$record{ $request_string } = 'class="ome_caution"';
			} elsif ($status eq 'ERROR' or $status eq 'INTERRUPTED') {
				$record{ $request_string } = 'class="ome_error"';
			} elsif ($status eq 'FINISHED') {
				$record{ $request_string } = 'class="ome_punchline"'; 
			}
		}
	}
	if( exists $field_requests->{ 'chex_status' } ) {
		foreach my $request ( @{ $field_requests->{ 'chex_status' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $obj->status;
		}
	}
	
	if( exists $field_requests->{ '/name' } ) {
		foreach my $request ( @{ $field_requests->{ '/name' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $self->
				_trim( $obj->analysis_chain->name, $request );
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
