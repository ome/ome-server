# OME/Log/Impl/Server/Skeleton.pm

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


package OME::Log::Impl::Server::Skeleton;

use strict;
use warnings;
our $VERSION = '2.0';

use OME::Log::Impl::Request;
use OME::Log::Impl::Server::LogSkeleton;
use OME::Log::Impl::Server::CtrlSkeleton;



# Private static field. Array whose entries are the concrete request handlers.
# The array is built in order to allow direct indexing: the i-req handler is
# the one in charge of handling request whose id is i.
my @req_handlers = ();


# Static initializer.
# init(Receiver,MsgProcessor)
sub init {
    my (undef,$receiver,$processor) = @_;
    my $ctrl_handler =
        new OME::Log::Impl::Server::CtrlSkeleton($receiver,$processor);
    my $log_handler = new  OME::Log::Impl::Server::LogSkeleton();
    $req_handlers[OME::Log::Impl::Request->Control] = $ctrl_handler;
    $req_handlers[OME::Log::Impl::Request->Log] = $log_handler;
    # Notice the above: rather than saying
    #   @req_handlers = ($ctrl_handler,$log_handler)
    # we use autovivification and we don't make assumptions on the actual values
    # assigned to the Control and Log constants.
    return;
}

# getSkeleton(Request):Skeleton
# $text ref to string
sub getSkeleton {
    my (undef,$req) = @_;
    return @req_handlers[$req->getType()];
}

# Skeleton abstract I/F
sub dispatch { return undef; }


1;
