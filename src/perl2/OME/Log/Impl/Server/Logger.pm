# OME/Log/Impl/Server/Logger.pm

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

package OME::Log::Impl::Server::Logger;

use strict;
use warnings;
our $VERSION = '2.0';

use Log::Log4perl;




# Private static field to store path to config file.
my $ConfigFile = 'OME-LS.conf';



# Constructor. This is not an instance method as well.
# new()
sub new {
    my $class = shift;
    my $self = {};
    bless($self,$class);
    return  $self;
}


# Read config file.
sub configure {
    Log::Log4perl::init($ConfigFile);
    return;
}

# Adaption methods.

sub debug {
    my ($self,$ctx,$logMsg) = @_;
    my $logger = Log::Log4perl->get_logger(
        ${$ctx->{class}}."::".${$ctx->{method}});
    my $record = formatRecord($ctx,$logMsg);
    $logger->debug($$record);
    return;
}

#------------------------------------------------------------
sub info {
    my ($self,$ctx,$logMsg) = @_;
    my $logger = Log::Log4perl->get_logger(
        ${$ctx->{class}}."::".${$ctx->{method}});
    my $record = formatRecord($ctx,$logMsg);
    $logger->info($$record);
    return;
}

#--------------------------------------------------------------
sub warn {
    my ($self,$ctx,$logMsg) = @_;
    my $logger = Log::Log4perl->get_logger(
        ${$ctx->{class}}."::".${$ctx->{method}});
    my $record = formatRecord($ctx,$logMsg);
    $logger->warn($$record);
    return;
}

#--------------------------------------------------------------
sub error {
    my ($self,$ctx,$logMsg) = @_;
    my $logger = Log::Log4perl->get_logger(
        ${$ctx->{class}}."::".${$ctx->{method}});
    my $record = formatRecord($ctx,$logMsg);
    $logger->error($$record);
    return;
}

#-----------------------------------------------------------
sub fatal {
    my ($self,$ctx,$logMsg) = @_;
    my $logger = Log::Log4perl->get_logger(
        ${$ctx->{class}}."::".${$ctx->{method}});
    my $record = formatRecord($ctx,$logMsg);
    $logger->fatal($$record);
    return;
}



# Private static method to format the record containing the logging info.
# formatRecord($ctx,$logMsg):$record
# $ctx     ref to log context hash
# $logMsg  ref to log message
# $record  ref to the formatted string
sub formatRecord {
    my ($ctx,$logMsg) = @_;
    my $tmp = $ctx->{timestamp}->{day};
    my $record = " ".($tmp<10?"0".$tmp:$tmp)."/";
    $tmp = $ctx->{timestamp}->{month};
    $record .= ($tmp<10?"0".$tmp:$tmp)."/";
    $record .= $ctx->{timestamp}->{year}." ";
    $tmp = $ctx->{timestamp}->{hour};
    $record .= ($tmp<10?"0".$tmp:$tmp).":";
    $tmp = $ctx->{timestamp}->{min};
    $record .= ($tmp<10?"0".$tmp:$tmp).":";
    $tmp = $ctx->{timestamp}->{sec};
    $record .= ($tmp<10?"0".$tmp:$tmp)." GMT ";
    $record .= " -------------------------------\n";
    $record .= "CONTEXT: PID<".$ctx->{pid}."> ";
    $record .= "TID<".$ctx->{tid}."> ";
    $record .= "FILE<".${$ctx->{file}}."> ";
    $record .= "LINE<".${$ctx->{line}}."> ";
    $record .= "PKG<".${$ctx->{class}}."> ";
    $record .= "SUB<".${$ctx->{method}}."> \n";
    $record .= "MESSAGE: ".$$logMsg."\n";
    $record .= "   --------------------------------------------------------\n";
    return \$record;
}


1;
