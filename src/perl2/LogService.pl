#!/usr/bin/perl

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
