# Control.pm:  Site-wide HTML template functions
# Author:  Douglas Creager <dcreager@alum.mit.edu>
# Copyright 2002 Douglas Creager.
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 

package OMEhtml::Control;
use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;

use CGI qw (:html3);


# new()
# -----

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method
    
    my $CGI = new CGI;

    my $self = {
	CGI => $CGI,
	prefix => "",
	suffix => "",
	orientation => "horizontal"
	};

    bless($self,$class);
    return $self;
}


# _accessor(variable name, [value])
# ---------------------------------

sub _accessor {
    my $self = shift;
    my $var = shift;
    @_? $self->{$var} = shift: $self->{$var};
}

sub prefix { my $self = shift; $self->_accessor("prefix",@_); }
sub suffix { my $self = shift; $self->_accessor("suffix",@_); }
sub orientation { my $self = shift; $self->_accessor("orientation",@_); }


# getHTML
# -------

sub getHTML {
    my $self = shift;
    #print STDERR "$self getHTML\n";
    my $result = $self->prefix();
    $result .= $self->_getHTML();
    $result .= $self->suffix();
    #print STDERR "$result\n";
    return $result;
}


# _getHTML
# --------

sub _getHTML {
    return "";
}


# getHTMLArray
# ------------
sub getHTMLArray {
    my $self = shift;
    return $self->_getHTML();
}
