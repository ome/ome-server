# TextField.pm:  Site-wide HTML template functions
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

package OMEhtml::Control::TextField;
use strict;
use vars qw($VERSION @ISA);
$VERSION = 2.000_000;

use CGI qw (:html3);

@ISA = ("OMEhtml::Control");


# new(Field name, Extra params)
# -----------------------------

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method
    my $self  = $class->SUPER::new();

    $self->{fieldName} = shift;

    $self->{params} = shift;
    $self->{params}{-name} = $self->{fieldName};
    
    bless($self,$class);
    return $self;
}


# _getHTML
# --------

sub _getHTML {
    my $self = shift;
    
    return $self->{CGI}->textfield($self->{params});
}

