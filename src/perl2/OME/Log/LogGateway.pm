# OME/Log/LogGateway.pm

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

package OME::Log::LogGateway;

use strict;
use warnings;
use threads;
our $VERSION = '2.0';

use OME::Log::Impl::Client::LogProxy;
use OME::Log::Impl::Client::Forwarder;


# Private class field to link the LogProxy instance.
my $proxy = undef;


# Public static method.
# getLogger():ILogger
sub getLogger {
    if (!$proxy) {   # first time in this thread
        my $forwarder = new OME::Log::Impl::Client::Forwarder();
        $proxy = new OME::Log::Impl::Client::LogProxy($forwarder);
    } else { # either another time in same thread or first time in new copied one
        my $curThread = threads->tid();
        if ($curThread != $proxy->getTid()) {  # first time in new copied thread
            my $forwarder = new OME::Log::Impl::Client::Forwarder();
            $proxy->replaceForwarder($forwarder);
            $proxy->setTid($curThread);
        }
    }
    return $proxy;
}


1;
