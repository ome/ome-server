# OME/Web/DBObjRender/__OME_Dataset.pm
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


package OME::Web::DBObjRender::__OME_Dataset;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_Dataset - Specialized rendering for OME::Dataset

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjRender);

=head2 getRefSearchField

Set default to session's active dataset.

=cut

sub _getRefSearchField {
	my ($self, $from_type, $to_type, $accessor_to_type, $default) = @_;
 	my $q = $self->CGI();
	$q->param( $accessor_to_type.'.name', $default ) # or $self->Session()->dataset()->name() ) )
		unless defined $q->param($accessor_to_type.'.name' );
	return ( 
		$q->textfield( -name => $accessor_to_type.'.name' , -size => 17 ),
		$accessor_to_type.'.name'
	);
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
