# OME/Log/Impl/Request.pm

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


package OME::Log::Impl::Request;

use strict;
use warnings;
use OME;
our $VERSION = $OME::VERSION;

use OME::Log::Impl::LogRecord ;
use OME::Log::Impl::CtrlOp ;



# Request IDs constants. Inlined by the optimizer.
sub Control { return 0; }
sub Log { return 1; }

# The Internet line terminator "\015\012". Inlined by the optimizer.
sub EoL { return "\015\012"; }


# getRequest($text):Request
# $text ref to string
sub getRequest {
    my (undef,$text) = @_;
    my $eol = EoL();
    my @lines = split(/$eol/,$$text);
    $lines[0] =~ m/^TYPE: (.*)/;
    my  $type = $1;
    my  $req = undef;
    if ($type == Log()){
        $req = new OME::Log::Impl::LogRecord();
    } else {
        $req = new OME::Log::Impl::CtrlOp();
    }
        $req->unmarshal(\@lines);
    return  $req;
}

# Request abstract I/F
sub getType { return undef; }
sub marshal { return undef; }
sub unmarshal { return undef; }


1;
