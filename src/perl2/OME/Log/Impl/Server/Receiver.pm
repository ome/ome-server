# OME/Log/Impl/Server/Receiver.pm

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


package OME::Log::Impl::Server::Receiver;

use strict;
use warnings;
use threads::shared;
use Thread::Queue;
use Socket;

use OME;
our $VERSION = $OME::VERSION;

use OME::Log::Impl::Server::LogService;
use OME::Log::Impl::TextMessage;



# Internal timeout for receive, in milliseconds.
my $SleepTimeout = 300;
# Internal timeout for listening on socket, in milliseconds.
my $ListenTimeout = 5000;
# The size, in bytes, of the incoming UDP message buffer.
my $RecvBufSize = 10*1024*1024;  # 10Mb




# Constructor. This is not an instance method as well.
# new()
# TO DO: replace die with exceptions (Error.pm)
sub new {
    my $class = shift;
    my $buffer = new Thread::Queue();
    my $quit : shared = 0;  # b/c exit() is invoked from MsgProcessor thread
    socket(SKT,AF_INET,SOCK_DGRAM,getprotobyname('udp')) ||
    die "OME::Log::Impl::Server::Receiver: socket failed: $!" ;
    setsockopt(SKT,SOL_SOCKET,SO_RCVBUF,$RecvBufSize) || # set receive buffer size
    die "OME::Log::Impl::Server::Receiver: setsockopt failed: $!" ;
    my $serverAddr = sockaddr_in(
                    OME::Log::Impl::Server::LogService->Port,
                    inet_aton(OME::Log::Impl::Server::LogService->ServerHost)
                  );
    # notice the above: we don't say INADDR_ANY, msg must come from loopback I/F
    bind(SKT,$serverAddr) ||
    die "OME::Log::Impl::Server::Receiver: bind failed: $!";
    my $self = {
        socketHandle => *SKT{IO},
        buffer => $buffer,
        quit => \$quit
    };
    bless($self,$class);
    return $self;
}

# Receiver processing loop.
# TO DO: replace output to STDERR with exceptions (Error.pm)
#
# NOTE: select
# This is a Perl wrapper function to the corresponding C system call.
# However a difference is that when using select from Perl, the helper
# macros FD_SET, FD_CLR, FD_ZERO, and FD_ISSET aren't available. Instead,
# Perl provides an assignable function vec which can be used to build the
# arguments to select. For example, the Perl statement
#   vec($rin, fileno(SKT), 1) = 1 ;
# sets the bit corresponding to filehandle SKT, and
#   if ( vec($rin, fileno(SKT), 1) )
# checks the same bit.
sub run {
    my ($self,$startupMsg) = @_;
    my ($rin,$rout,$msg);  # select bit vectors (reading) and msg buffer
    my $max_size = OME::Log::Impl::TextMessage->MaxSize;
    my $socket = $self->{socketHandle};
    print($startupMsg);
    while (!${$self->{quit}}) {
        $rin = $msg = '';
        vec($rin,fileno($socket),1) = 1;  # set mask for select
        select($rout=$rin,undef,undef,$ListenTimeout/1000);
        if (vec($rout,fileno($socket),1)) {  # data is waiting on the buffer
            my $ret = recv($socket,$msg,$max_size,0);
            # Returns the address of the sender or undef if there's an error.
            if(defined($ret)) {
                # Note: now we should write this (see SDD):
                # my  $tm = new  OME::Log::Impl::TextMessage();
                # $tm->packMsg(\$msg);
                # $self->{buffer}->enqueue($tm);
                # However, due to bugs in Perl threads, we can't share an object
                # (blessed ref). Thus, we queue up $msg in place of a
                # TextMessage object and we create the TextMessage object
                # in receive().
                $self->{buffer}->enqueue($msg) ;
            } else {
                print(STDERR "\nOME::Log::Impl::Server::Receiver: recv failed: $!\n");
            }
        }
    }
    return;
}

# receive($timeout):TextMessage
# Invoked from the MsgProcessor thread.
sub receive {
    my ($self,$timeout) = @_;
    my $time_waited = 0;
    my ($msg,$tm) = (undef,undef);
    while ($time_waited < $timeout) {
        $msg = $self->{buffer}->dequeue_nb();
        # Note: we queue up strings instead of TextMessage objects,
        # see why in run()
        if ($msg) {
            $tm = new OME::Log::Impl::TextMessage();
            $tm->packMsg(\$msg);
            last;
        }
        select(undef,undef,undef,$SleepTimeout/1000); # sleep for timeout ms
        # Note: we don't use sleep, coz sleep takes seconds in !!!
        $time_waited += $SleepTimeout;
    }
    return $tm;
}

# exit()
# Invoked from the MsgProcessor thread.
sub exit {
    my $self = shift;
    ${$self->{quit}} = 1;
    my  $socket = $self->{socketHandle};
    # Perl might have already cleaned up (a Perl bug?), so we test
    if ($socket) {
        close($socket);
        # Note: even if $socket refers to the copy in the MsgProcessor thread,
        #       this should work anyway b/c the OS file descriptor is the same
        #       one.
    }
    return;
}


1;
