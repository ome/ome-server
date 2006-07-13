# OME/Web/Authenticated.pm

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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Web::Authenticated;

use base qw(OME::Web);

=head1 DESCRIPTION 

    Specialized subclass of OME::Web for those pagest that require
    authentication. Provides default, non-guest implementation of
    getTemplate.

    The general idea here is that we will check to see if the session
    is a guest session. If it is, we return undef, indicating that
    this page is not available to guests. Otherwise, we return 
    getAuthenticatedTemplate()  to return the template to be used for
    authenticated users. Web.pm has a default implementation
    which returns the TemplateManager::NO_TEMPLATE token, indicating
    that no template is needed for the specified page.

=cut 

=head2 getTemplate 

=cut


sub getTemplate {
    my $self=shift;
    # not for guests
    return undef if ($self->Session()->isGuestSession());

    return $self->getAuthenticatedTemplate();
}

1;
