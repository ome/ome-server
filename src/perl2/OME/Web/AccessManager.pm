# OME/Web/AccessManager.pm

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
# Written by: Harry Hochheiser <hsh@nih.gov>
#-------------------------------------------------------------------------------

package OME::Web::AccessManager;

use OME;

use strict;
use OME::Web::DefaultHeaderBuilder;
use OME::Web::DefaultMenuBuilder;
use OME::Web::GuestMenuBuilder;
use OME::Web::GuestHeaderBuilder;
use base qw(OME::Web);


=head1 NAME 

OME::Web::AccessManager - code for retrieving things  from based on
    access controls.

=cut

=head1 getHeaderBuilder

    Gets a header builder for the user, based on guest status. 

=cut

sub  getHeaderBuilder {
    my $self = shift;

    if ($self->Session()->isGuestSession()) {
	return new OME::Web::GuestHeaderBuilder;
    }
    return new OME::Web::DefaultHeaderBuilder;
    
}

=head2 getMenuBuilder

    Gets a menu builder for the user, based on guest status
=cut

sub getMenuBuilder {
    my $self = shift;
    my $page = shift;

    if ($self->Session()->isGuestSession()) {
	return new OME::Web::GuestMenuBuilder($page);
    }

    return new OME::Web::DefaultMenuBuilder($page);
    
}


=head2 getFooterBuilder
    
    gets a footer builder..
=cut



sub getFooterBuilder {
    my $self = shift;
    my $page = shift;

    my $FOOTER_FILE=undef;

    if ($self->Session()->isGuestSession() && $FOOTER_FILE) {
	return new $FOOTER_FILE;
    }
    return undef;
}

1;
