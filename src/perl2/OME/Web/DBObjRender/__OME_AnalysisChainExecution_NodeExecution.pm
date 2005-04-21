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
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_AnalysisChainExecution_NodeExecution;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_AnalysisChainExecution_NodeExecution -
Specialized rendering

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjRender);

=head2 _renderData

sets '/name' to the MEX's name
sets 'target' to the MEX's target

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my %record;
	if( exists $field_requests->{ '/name' } ) {
		foreach my $request ( @{ $field_requests->{ '/name' } } ) {
			my $request_string = $request->{ 'request_string' };
			my %rendered_data = $self->renderData( 
				$obj->module_execution(), 
				{ '/name' => [ $request ] },
				$options
			);
			$record{ $request_string } = $rendered_data{ '/name' };
		}
	}
	if( exists $field_requests->{ 'target' } ) {
		foreach my $request ( @{ $field_requests->{ 'target' } } ) {
			my $request_string = $request->{ 'request_string' };
			my $target = ( $obj->module_execution->dataset ?
				$obj->module_execution->dataset :
				$obj->module_execution->image
			);
			my $mode = ( exists $request->{render} ? $request->{render} : undef );
			$record{ $request_string } = $self->
				render( $target, $mode );
		}
	}
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
