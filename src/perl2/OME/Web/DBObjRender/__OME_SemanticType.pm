# OME/Web/DBObjRender/__OME_SemanticType.pm
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


package OME::Web::DBObjRender::__OME_SemanticType;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_SemanticType

=head1 DESCRIPTION


=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

=head2 _renderData

makes virtual fields 
	data_type: the SQL type

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $q       = $self->CGI();
	my %record;

	# Language-specific label
	if( exists $field_requests->{ 'label' } ) {
		foreach my $request ( @{ $field_requests->{ 'label' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $obj->label();
		}
	}
	# Replace name with Language-specific label
	if( exists $field_requests->{ 'name' } ) {
		foreach my $request ( @{ $field_requests->{ 'name' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $obj->label();
		}
	}
	if( exists $field_requests->{ '/name' } ) {
		foreach my $request ( @{ $field_requests->{ '/name' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $obj->label();
		}
	}
	# Language-specific description
	if( exists $field_requests->{ 'description' } ) {
		foreach my $request ( @{ $field_requests->{ 'description' } } ) {
			my $request_string = $request->{ 'request_string' };
			$record{ $request_string } = $obj->lang_description();
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
