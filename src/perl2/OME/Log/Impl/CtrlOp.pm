# OME/Log/Impl/CtrlOp.pm

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
# Written by:    Andrea Falconi <a.falconi@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Log::Impl::CtrlOp;

use strict;
use warnings;
use OME;
our $VERSION = $OME::VERSION;

use OME::Log::Impl::Request;

use base qw(OME::Log::Impl::Request);



# Constructor. This is not an instance method as well.
# new()
sub new {
    my $class = shift;
    my $self = {
        opID => 0
    };
    bless($self,$class);
    return $self ;
}

# Follows implementation of Request abstract I/F

# getType():int
sub getType {
    return OME::Log::Impl::Request->Control;
}

# marshal():string ref
sub marshal {
    my $self = shift;
    my $text = "TYPE: ".$self->Control."".$self->EoL;
    $text .= "OPID: ".$self->{opID}."".$self->EoL;
    return \$text;
}

# unmashal($lines)
# $lines ref array, each entry is a line in the msg. Line 0 (TYPE) not relevant
# here.
sub unmarshal {
    my ($self,$lines) = @_;
    $lines->[1] =~ m/^OPID: (.*)/;
    $self->{opID} = $1;
    return;
}


1;

