# OME/Log/Impl/Server/ServerCtrl.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::Log::Impl::Server::ServerCtrl;

use strict;
use warnings;

our $VERSION = '2.0';

use OME::Log::Impl::Client::Forwarder;
use OME::Log::Impl::CtrlOp;
use OME::Log::Impl::TextMessage;



# Constructor. This is not an instance method as well.
# new()
sub new {
    my $class = shift;
    my $forwarder = new OME::Log::Impl::Client::Forwarder();
    my $self = {
        forwarder => $forwarder
    };
    bless($self,$class);
    return $self;
}

# shutdown()
sub shutdown {
    my $self = shift;
    my $op = new OME::Log::Impl::CtrlOp();
    my $txt = $op->marshal();
    my $tm = new OME::Log::Impl::TextMessage();
    $tm->packMsg($txt);
    $self->{forwarder}->sendMsg($tm);
    return;
}


1;

