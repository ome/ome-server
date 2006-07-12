# OME/Web/DBObjRender/__ExternalLink.pm
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


package OME::Web::DBObjRender::__ExternalLink;
use strict;
use OME;
our $VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjRender);


=pod

=head1 NAME

OME::Web::DBObjRender::__ExternalLink - Specialized rendering for ExternalLink Attributes

=head1 METHODS

=head2 _renderData


=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;

	my %rec;	
	if (exists $field_requests->{'URL'}) {

	    foreach my $request (@{$field_requests->{'URL'}}) {
		my $request_string = $request->{'request_string'};
		# request_string should be 'URL' here
		# and obj is an ExternalLink;
		my $URL= $self->getExternalLinkURL($obj);
		$rec{$request_string} = $URL;
	    }
	}
	
	return %rec;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
