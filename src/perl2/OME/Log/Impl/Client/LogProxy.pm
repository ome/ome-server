# OME/Log/Impl/Client/LogProxy.pm

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

package OME::Log::Impl::Client::LogProxy;

use strict;
use warnings;
use threads;
our $VERSION = '2.0';

use OME::Log::ILogger;
use OME::Log::Impl::LogRecord;
use OME::Log::Impl::TextMessage;

use base qw(OME::Log::ILogger);



# Constructor. This is not an instance method as well.
# new($fwd)
sub new {
    my ($class,$fwd) = @_;
    my $self = {
        pid => $$,
        tid => threads->tid(),
        forwarder => $fwd
    };
    bless($self,$class);
    return $self;
}


# Private static method to collect timestamp as returned by time function into
# hash. Month adjusted in order to be in [1,12] and year in [1900,-).
# Returned value is ref to hash.
my $getTime = sub {
    my ($sec,$min,$hour,$day,$month,$year) = gmtime(shift);
    return {  sec => $sec, min => $min, hour => $hour,
              day => $day, month => $month+1, year => $year+1900 };
};

# Private static field used by formatCallFrame.
my $NotAvailable = 'not available';

# Private static method to strip out pkg from subroutine name.
# We also set possible undefined values in call frame array to $NotAvailabe.
# This is b/c caller may not return meaningful values (for ex, when log methods
# are called in main). Input is a ref to call frame array.
# No return value.
my $adjustCallFrame = sub {
    my $callFrame = shift;
    if (!$callFrame->[0]) { $callFrame->[0] = $NotAvailable; }
    if (!$callFrame->[1]) { $callFrame->[1] = $NotAvailable; }
    if (!$callFrame->[2]) { $callFrame->[2] = $NotAvailable; }
    if (!$callFrame->[3]) {
            $callFrame->[3] = $NotAvailable;
    } else {  # strip out pkg from subroutine name
        my @x = split(/::/,$callFrame->[3]);
        $callFrame->[3] = pop(@x);
    }
};

# Private instance method.
# dispatch($priority,$logMsg,$callerSub,$timestamp)
# $priority is an integer; $logMsg is a ref to string,
# $callerSub is a ref to string, $timestamp ref to hash.
my $dispatch = sub {
    my ($self,$priority,$logMsg,$callerSub,$timestamp) = @_;
    my @callFrame = (undef,undef,undef,undef);
# @callFrame contains ($pkg,$file,$line,$sub)
# We grab the call frame info here. Remember that caller(N) might not return
# info about the expected call frame, for N > 1.
    @callFrame = caller(1);
    $callFrame[3] = $$callerSub;
    &$adjustCallFrame(\@callFrame);
    my $logContext = {
        pid => $self->{pid},
        tid => $self->{tid},
        file => \($callFrame[1]),
        line => \($callFrame[2]),
        class => \($callFrame[0]),
        method => \($callFrame[3]),
        timestamp => $timestamp
    };
    my $rec = new OME::Log::Impl::LogRecord($logContext,$priority,$logMsg);
    my $txt = $rec->marshal();
    my $tm = new OME::Log::Impl::TextMessage();
    $tm->packMsg($txt) ;
    $self->{forwarder}->sendMsg($tm);
    return;
};

# For sole use by the LogGateway.
# replaceForwarder($fwd)
sub replaceForwarder {
    my ($self,$fwd) = @_;
    $self->{forwarder} = $fwd;
}

# For sole use by the LogGateway.
# getTid():int
sub getTid {
    my $self = shift;
    return $self->{tid};
}
# For sole use by the LogGateway.
# setTid($tid)
sub setTid {
    my ($self,$tid) = @_;
    return $self->{tid} = $tid;
}


# ------- ILogger I/F implementation --------------------------------------

# info($logMsg)
sub info {
    my ($self,$logMsg) = @_;
    my $timestamp = &$getTime(time);
    my $priority = OME::Log::Impl::LogRecord->InfoPriority;
    my (undef,undef,undef,$callerSub) = caller(1);
# @caller returns ($pkg,$file,$line,$sub)
# Here we grab the sub that contains the call to info. This is because
# we would need to say caller(2) in dispatch, but caller(N) might not return
# info about the expected call frame, for N > 1.
    $self->$dispatch($priority,\$logMsg,\$callerSub,$timestamp);
    return;
}

# all following implementations are cut&paste from info, only priority changes

sub debug {
    my ($self,$logMsg) = @_;
    my $timestamp = &$getTime(time);
    my $priority = OME::Log::Impl::LogRecord->DebugPriority;
    my (undef,undef,undef,$callerSub) = caller(1);
    $self->$dispatch($priority,\$logMsg,\$callerSub,$timestamp);
    return;
}

sub warn {
    my ($self,$logMsg) = @_;
    my $timestamp = &$getTime(time);
    my $priority = OME::Log::Impl::LogRecord->WarnPriority;
    my (undef,undef,undef,$callerSub) = caller(1);
    $self->$dispatch($priority,\$logMsg,\$callerSub,$timestamp);
    return;
}

sub error {
    my ($self,$logMsg) = @_;
    my $timestamp = &$getTime(time);
    my $priority = OME::Log::Impl::LogRecord->ErrorPriority;
    my (undef,undef,undef,$callerSub) = caller(1);
    $self->$dispatch($priority,\$logMsg,\$callerSub,$timestamp);
    return;
}

sub fatal {
    my ($self,$logMsg) = @_;
    my $timestamp = &$getTime(time);
    my $priority = OME::Log::Impl::LogRecord->FatalPriority;
    my (undef,undef,undef,$callerSub) = caller(1);
    $self->$dispatch($priority,\$logMsg,\$callerSub,$timestamp);
    return;
}


1;

