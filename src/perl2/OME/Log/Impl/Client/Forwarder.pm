# OME/Log/Impl/Client/Forwarder.pm

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


package OME::Log::Impl::Client::Forwarder;

use strict;
use warnings;
use Socket;

our $VERSION = '2.0';

use OME::Log::Impl::Server::LogService;



# The size, in bytes, of the incoming UDP message buffer.
my $SendBufSize = 500*1024;   # 500Kb



# Constructor. This is not an instance method as well.
# new()
# TO DO: replace die with exceptions (Error.pm)
#
# NOTE: setsockopt
# This is a Perl wrapper function to the corresponding C system call.
# We should write:
#
#   setsockopt(SKT,SOL_SOCKET,SO_LINGER,$linger) ;
#
# to make sure that any pending message in the outgoing UDP buffer is
# eventually sent before the socket is closed.
# In fact, the SO_LINGER flag tells the system to block the process on a
# close() until all unsent messages queued on the socket are sent or until
# a given timeout expires. If SO_LINGER is not specified, and close() is issued,
# the system handles the call in a way that allows the process to continue as
# quickly as possible, which means that the outgoing buffer may well be
# deallocated before all messages are transmitted.
# The C function takes a linger structure to specify the the state of the
# option and the linger interval.
# The problem is that the Perl documentation available for setsockopt(),
# doesn't tell you how to pass the linger structure.
# So I'll leave this out for now...
sub new {
    my $class = shift;
    socket(SKT,AF_INET,SOCK_DGRAM,getprotobyname('udp'))||
    die "OME::Log::Impl::Client::Forwarder: socket failed: $!";
    setsockopt(SKT,SOL_SOCKET,SO_SNDBUF,$SendBufSize)|| # set send buffer size
    die "OME::Log::Impl::Client::Forwarder: setsockopt failed: $!";
    my $serverAddr = sockaddr_in(
                    OME::Log::Impl::Server::LogService->Port,
                    inet_aton(OME::Log::Impl::Server::LogService->ServerHost)
                  );
    my $self = {
        socketHandle => *SKT{IO},
        serverAddr => $serverAddr
    };
    bless($self,$class);
    return $self;
}

# sendMsg($txtMsg)
# $txtMsg instance of TextMessage
sub sendMsg {
    my ($self,$txtMsg) = @_;
    $| = 1 ;  # forces a flush right away and after every write
    # no error checking, coz we're on loopback I/F
    send($self->{socketHandle},${$txtMsg->getMsg()},0,$self->{serverAddr});
}

# Close socket
sub DESTROY {
    my $self = shift;
    my $socket = $self->{socketHandle};
    # Perl might have already cleaned up (a Perl bug?), so we test
    if ($socket){
        close($socket);
    }
    return;
}


1;

