# OME/Web/DBObjRender/__OME_ModuleExecution.pm
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


package OME::Web::DBObjRender::__OME_ModuleExecution;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_ModuleExecution - Specialized rendering

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjRender);

=head2 _renderData

sets '/name' to either module name or "Virtual MEX [id]"

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my %record;
	# thumbnail url
	if( exists $field_requests->{ '/name' } ) {
		foreach my $request ( @{ $field_requests->{ '/name' } } ) {
			my $request_string = $request->{ 'request_string' };
			if( $obj->module() ) {
				$record{ $request_string } = $self->_trim( $obj->module()->name(),  $request );
			} else {
				$record{ $request_string } = 'Virtual MEX '.$obj->id();
			}
		}
	}
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
