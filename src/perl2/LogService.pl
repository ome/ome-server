#!/usr/bin/perl

# LogService.pl

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

use strict;
use warnings;

use OME::Log::Impl::Server::LogService;
use OME::Log::Impl::Server::ServerCtrl;


my $param = $ARGV[0] || '';
if ($param eq "start") {
    my $server = new OME::Log::Impl::Server::LogService();
    $server->start();
} elsif ($param eq "stop") {
    my $ctrl = new OME::Log::Impl::Server::ServerCtrl();
    $ctrl->shutdown();
} else {
    usage() ;
}


sub usage {
    print("\n------------------------- USAGE -------------------------\n\n");
    print("LogService start     to start the Log Service\n");
    print("LogService stop      to stop the Log Service\n");
    print("\n---------------------------------------------------------\n\n");
}
