# OME/Log/Impl/Server/LogService.pm

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


package OME::Log::Impl::Server::LogService;

use strict;
use warnings;
use threads;

use OME;
our $VERSION = $OME::VERSION;

use OME::Log::Impl::Server::Receiver;
use OME::Log::Impl::Server::MsgProcessor;



# The server IP address and port. Hardcoded until we decide on a OME
# system-wide config file.
# Used only by the Forwarder and Receiver. Inlined by the optimizer.
sub Port { return 12345; }
sub ServerHost { return '127.0.0.1'; }



# Start up messages. Private static fields.
my $SUMessage = "\n\n  ----------------  OME Log Service  ----------------\n\n";
my $ReceiverUP = "  Receiver is running.\n";
my $ProcessorUP = "  Message Processor is running.\n\n";

# Shutdown messages to be used by CtrlSkeleton. Inlined by the optimizer.
sub SDMessage { return "\n\n  Shutting the Log Service down... \n\n";  }
sub SDReceiver { return "  Sent shutdown signal to the Receiver.\n";  }
sub SDProcessor {
    return "  Sent shutdown signal to the Message Processor.\n\n";
}

# Shutdown messages. Private static fields.
my $ExitMessage = "\n\n  Shutdown complete, bye... \n\n";
my $ReceiverExit = "\n  Receiver shutdown completed.\n";
my $ProcessorExit = "\n  Message Processor shutdown completed.\n\n";



# Constructor. This is not an instance method as well.
# new()
sub new {
    my $class = shift;
    my $self = {};
    bless($self,$class);
    return $self;
}

# Initialize and start the Log Service.
# start()
sub start {
    my $self = shift;
    print($SUMessage);
    my $receiver = new OME::Log::Impl::Server::Receiver();
    my $processor = threads->new(
            sub {
                my $p = new OME::Log::Impl::Server::MsgProcessor($receiver);
                $p->run($ProcessorUP);
            }
        );
    $receiver->run($ReceiverUP);
    print($ReceiverExit);
    $processor->join();
    print($ProcessorExit);
    print($ExitMessage);
    return;
}


1;
