# OME/Install/Environment.pm
# The environment module for the OME installer and subsequent tasks. Used to 
# keep state and perform various operations on the environment itself.

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

package OME::Install::Environment;

use warnings;
use strict;

use Carp;

# The singleton instance.
my $soleInstance = undef;

# Private constructor.
my $new = sub {
    my $self = {};
    return bless($self);
};

# Class method to return the singleton instance that deals with the platform
# we're running on.
#
# my $env = OME::Install::Environment->initialize();
#
sub initialize {
    my $class = shift;
    if( !$soleInstance ) { # first time we're called

        # Create the singleton
        $soleInstance = &$new();
    }
    return $soleInstance;
}


1;
