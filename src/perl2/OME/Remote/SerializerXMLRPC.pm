# OME/Remote/Facade.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Remote::SerializerXMLRPC;
use base qw(XMLRPC::Serializer);

use Carp;
use strict;
use OME;
our $VERSION = $OME::VERSION;
our $XMLRPC_RESPONCE_OBJECT = 'OME::Remote::Response::XMLRPC';
our $NULL_STRING= "*([-NULL-])*";

sub envelope {
	my $self = shift;
	my $first_object = @_[2];
	my $first_object_ref = ref ($first_object);
	my $body;
	# Put timing code here
	if (not $first_object_ref eq $XMLRPC_RESPONCE_OBJECT) {
		$body = $self->SUPER::envelope(@_);
	} else {
		$body = $$first_object;
	}
	# timer stop
#print STDERR $body."\n";
	return $body;
}

sub encode_scalar {
	my $self = shift;
	return ['value', {}, [['string',{},$NULL_STRING]]] unless defined $_[0];
	return $self->SOAP::Serializer::encode_scalar(@_);
}


1;

=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=cut
