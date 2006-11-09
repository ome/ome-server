# OME/Web/DBObjRender/__OME_AnalysisChainExecution_NodeExecution.pm
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
#	Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_AnalysisChain_Node;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_AnalysisChainExecution_NodeExecution - Specialized rendering

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Web::DBObjRender);

=head2 _renderData

sets '/name' to the module's name

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;

	my %record;
	if( exists $field_requests->{ '/name' } ) {
		my @dup_nodes = $obj->analysis_chain->nodes( module => $obj->module );
		if( scalar( @dup_nodes ) == 1 ) {
			%record = $self->renderData( 
				$obj->module(), 
				{ '/name' => $field_requests->{ '/name' } },
				$options
			);
		} else {
			foreach my $request ( @{ $field_requests->{ '/name' } } ) {
				my $request_string = $request->{ 'request_string' };
				my @links = $obj->input_links();
				my @upstreamNodes = map( $_->from_node, @links );
				my $name = $self->getName( $obj->module )." ( ".
					join( ", ", map( $self->getName( $_ ), @upstreamNodes ) )." ) ";
				$record{ $request_string } = $self->
					_trim( $name, $request );
			}
		}
	}
	return %record;
}

=head1 Author

Tom Macura <tmacura@nih.gov>

=cut

1;
