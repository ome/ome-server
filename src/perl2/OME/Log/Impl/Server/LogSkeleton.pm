# OME/Log/Impl/Server/LogSkeleton.pm

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

package OME::Log::Impl::Server::LogSkeleton;

use strict;
use warnings;
our $VERSION = '2.0';

use OME::Log::Impl::Server::Logger;
use OME::Log::Impl::LogRecord;
use OME::Log::Impl::Server::Skeleton;

use base qw(OME::Log::Impl::Server::Skeleton);



# Private static field. Array whose entries are references to the subs used to
# invoke the servant's methods. The array is built in order to allow direct
# indexing: the i-sub is the one used to invoke the method whose priority is i.
my @disp_methods = ();


# Subs used to invoke the servant's methods.

my $debug = sub {
    my ($logger,$ctx,$logMsg) = @_;
    $logger->debug($ctx,$logMsg);
};
my $info = sub {
    my ($logger,$ctx,$logMsg) = @_;
    $logger->info($ctx,$logMsg);
};
my $warn = sub {
    my ($logger,$ctx,$logMsg) = @_;
    $logger->warn($ctx,$logMsg);
};
my $error = sub {
    my ($logger,$ctx,$logMsg) = @_;
    $logger->error($ctx,$logMsg);
};
my $fatal = sub {
    my ($logger,$ctx,$logMsg) = @_;
    $logger->fatal($ctx,$logMsg);
};

# Constructor. This is not an instance method as well.
# new()
sub new {
    my $class = shift;
    my $servant = new OME::Log::Impl::Server::Logger();
    $servant->configure();
    my $self = {
        servant => $servant
    };
    bless($self,$class) ;
    $disp_methods[OME::Log::Impl::LogRecord->DebugPriority] = $debug;
    $disp_methods[OME::Log::Impl::LogRecord->InfoPriority] = $info;
    $disp_methods[OME::Log::Impl::LogRecord->WarnPriority] = $warn;
    $disp_methods[OME::Log::Impl::LogRecord->ErrorPriority] = $error;
    $disp_methods[OME::Log::Impl::LogRecord->FatalPriority] = $fatal;
    # Notice the above: rather than saying
    # @disp_methods = ($debug,$info,$warn,$error,$fatal)
    # we use autovivification and we don't make assumptions on the actual values
    # assigned to the priority constants.
    return $self;
}

# Skeleton abstract I/F implementation.
sub dispatch {
    my ($self,$req) = @_;
    my $method = $disp_methods[$req->getPriority()];
    &$method($self->{servant},$req->getContext(),$req->getMessage());
    return;
}


1;
