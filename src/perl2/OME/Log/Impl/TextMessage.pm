# OME/Log/Impl/TextMessage.pm

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


package OME::Log::Impl::TextMessage;

use strict;
use warnings;
use OME;
our $VERSION = $OME::VERSION;


# Max msg size constant. The actual value is 4Kb. As a result, our UDP datagrams
# won't exceed 4Kb+8b (8b is UDP header). Inlined by the optimizer.
sub MaxSize { return 4096; }



# Constructor. This is not an instance method as well.
# new()
sub new {
    my $class = shift;
    my $self = {
        msg => undef
    } ;
    bless($self,$class);
    return $self;
}

# packMsg($text)
# $str string ref
sub packMsg {
    my ($self,$text) = @_;
    if (MaxSize()<length($$text)) {
        $text = \(substr($$text,0,MaxSize()));
    }
    $self->{msg} = $text;
    return ;
}

# getMsg(): ref to msg string
sub getMsg {
    my $self = shift;
    return $self->{msg};
}


1;
