# OME/Log/Impl/Server/CtrlSkeleton.pm

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


package OME::Log::Impl::Server::CtrlSkeleton;

use strict;
use warnings;
our $VERSION = '2.0';

use OME::Log::Impl::Server::LogService;
use OME::Log::Impl::Server::Skeleton;

use base qw(OME::Log::Impl::Server::Skeleton);



# Constructor. This is not an instance method as well.
# new(Receiver,MsgProcessor)
sub new {
    my ($class,$receiver,$processor) = @_;
    my $self = {
        receiver => $receiver,
        processor => $processor
    };
    bless($self,$class);
    return $self;
}

# Private instance method.
# shutdown()
my $shutdown = sub {
    my $self = shift;
    print(OME::Log::Impl::Server::LogService->SDMessage);
    $self->{receiver}->exit();
    print(OME::Log::Impl::Server::LogService->SDReceiver);
    $self->{processor}->exit();
    print(OME::Log::Impl::Server::LogService->SDProcessor);
    return;
};

# Skeleton abstract I/F implementation.
sub dispatch {
    my ($self,$req) = @_;
    $self->$shutdown();
    return;
}


1;
