# OME/Log/Impl/Server/MsgProcessor.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  Andrea Falconi <a.falconi@dundee.ac.uk>
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

package OME::Log::Impl::Server::MsgProcessor;

use strict;
use warnings;
our $VERSION = '2.0';

use OME::Log::Impl::Request;
use OME::Log::Impl::Server::Skeleton;


# Internal timeout for receive, in milliseconds.
my $ReceiveTimeout = 6000;


# Constructor. This is not an instance method as well.
# new()
sub new {
    my ($class,$receiver) = @_;
    my $self = {
        receiver => $receiver,
        quit => 0
    };
    bless($self,$class);
    OME::Log::Impl::Server::Skeleton->init($receiver,$self);
    return $self;
}

# MsgProcessor processing loop.
sub run {
    my ($self,$startupMsg) = @_;
    my ($tm,$req,$handler);
    print($startupMsg);
    while (!$self->{quit}) {
        $tm = $self->{receiver}->receive($ReceiveTimeout);
        if ($tm) {
            $req = OME::Log::Impl::Request->getRequest($tm->getMsg());
            $handler = OME::Log::Impl::Server::Skeleton->getSkeleton($req);
            $handler->dispatch($req);
        }
    }
    return;
}

# exit()
sub exit {
    my $self = shift;
    $self->{quit} = 1;
    return;
}


1;
