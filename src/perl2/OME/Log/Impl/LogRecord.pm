# OME/Log/Impl/LogRecord.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
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

package OME::Log::Impl::LogRecord;

use strict;
use warnings;
our $VERSION = '2.0';

use OME::Log::Impl::Request;

use base qw(OME::Log::Impl::Request);

# Priority constants. Inlined by the optimizer.
sub DebugPriority { return 0; }
sub InfoPriority { return 1; }
sub WarnPriority { return 2; }
sub ErrorPriority { return 3; }
sub FatalPriority { return 4; }



# Constructor. This is not an instance method as well.
#
# This is to be used on client-side:
# new($logCtx,$priority,$logMsg)
# $logCtx is ref to hash (LogContext class implemented as hash), $priority is
# int and $logMsg a ref to string.
# NOTICE:
# $logCtx fields are as follows:
# pid, tid are int
# file, line, class, method are refs to string
# timestamp is a ref to hash containing sec, min, hour, day, month, year
#
# Also no args constructor provided, to be used on server-side: new()
# fields ini to undef
sub new {
    my  ($class,$logCtx,$priority,$logMsg) = @_;
    my  $self = {
        priority => defined($priority) ? $priority : undef,  # b/c 0 for debug
        logMsg => $logMsg || undef,
        logCtx => $logCtx || undef
    } ;
    bless($self,$class);
    return  $self;
}

# getPriority():int
sub getPriority {
    my $self = shift;
    return $self->{priority};
}

# getMessage():ref to string
sub getMessage {
    my $self = shift;
    return $self->{logMsg};
}

# getContext():ref to hash
sub getContext {
    my $self = shift;
    return $self->{logCtx};
}


# Follows implementation of Request abstract I/F

# getType():int
sub getType {
    return OME::Log::Impl::Request->Log;
}

# marshal():string ref
sub marshal {
    my  $self = shift;
    my  $text = "TYPE: ".$self->Log."".$self->EoL;
    $text .= "CONTEXT: PID<".$self->{logCtx}->{pid}."> ";
    $text .= "TID<".$self->{logCtx}->{tid}."> ";
    $text .= "FILE<".${$self->{logCtx}->{file}}."> ";
    $text .= "LINE<".${$self->{logCtx}->{line}}."> ";
    $text .= "PKG<".${$self->{logCtx}->{class}}."> ";
    $text .= "SUB<".${$self->{logCtx}->{method}}."> ".$self->EoL;
    $text .= "TIMESTAMP: ".$self->{logCtx}->{timestamp}->{day}."/";
    $text .= $self->{logCtx}->{timestamp}->{month}."/";
    $text .= $self->{logCtx}->{timestamp}->{year}." ";
    $text .= $self->{logCtx}->{timestamp}->{hour}.":";
    $text .= $self->{logCtx}->{timestamp}->{min}.":";
    $text .= $self->{logCtx}->{timestamp}->{sec}." GMT".$self->EoL;
    $text .= "PRIORITY: ".$self->{priority}."".$self->EoL;
    $text .= "MESSAGE: ".${$self->{logMsg}}."".$self->EoL;
    return \$text;
}

# unmashal($lines)
# $lines ref array, each entry is a line in the msg. Line 0 (TYPE) not relevant
# here.
sub unmarshal {
    my  ($self,$lines) = @_;
    $lines->[1] =~
    m/^CONTEXT: PID<(.*)> TID<(.*)> FILE<(.*)> LINE<(.*)> PKG<(.*)> SUB<(.*)>/;
    my  ($file,$line,$class,$method) = ($3,$4,$5,$6);
    my  $logCtx = {
        pid => $1, tid => $2,
        file => \$file, line => \$line, class => \$class, method => \$method,
        timestamp => undef
    };
    $lines->[2] =~ m/^TIMESTAMP: (.*)\/(.*)\/(.*) (.*):(.*):(.*) GMT/;
    my  $timestamp = {
        sec => $6, min => $5, hour => $4,
        day => $1, month => $2, year => $3
    } ;
    $logCtx->{timestamp} = $timestamp;
    $self->{logCtx} = $logCtx;
    $lines->[3] =~ m/^PRIORITY: (.*)/;
    $self->{priority} = $1;
    $lines->[4] =~ m/^MESSAGE: (.*)/;
    my  $logMsg = $1;
    $self->{logMsg} = \$logMsg;
    return;
}


1;

