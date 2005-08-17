# OME/Web/DBObjRender/__SamplePreparation.pm
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


package OME::Web::DBObjRender::__SamplePreparation;
use strict;
use OME;
our $VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjRender);

=pod

=head1 NAME

OME::Web::DBObjRender::__SamplePreparation - Specialized rendering for SamplePreparation Attributes

=head1 METHODS

=head2 _renderData

sets '/name' to the first 15 letters of the Description

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	my %record;
	if( exists $field_requests->{ '/name' } ) {
		foreach my $request ( @{ $field_requests->{ '/name' } } ) {
			my $request_string = $request->{ 'request_string' };
			my $name = $obj->Description;
			$record{ $request_string } = $self->_trim( $name, { max_text_length => 50 } );
		}
	}
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>


=cut

1;
