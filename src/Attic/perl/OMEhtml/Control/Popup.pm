# Popup.pm:  Site-wide HTML template functions
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

package OMEhtml::Control::Popup;
use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.20';

use CGI qw (:html3);

@ISA = ("OMEhtml::Control");


# new(Field name)
# ---------------

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method
    my $self  = $class->SUPER::new();

    $self->{fieldName} = shift;
    $self->{values} = [];
    $self->{labels} = {};
    $self->{default} = undef;
    
    bless($self,$class);
    return $self;
}

sub defaultValue { my $self = shift; $self->_accessor("default",@_); }


# addChoice(value,label)
# ----------------------

sub addChoice {
    my ($self,$value,$label) = @_;

    push @{$self->{values}}, $value;
    $self->{labels}{$value} = $label;
}


# _getHTML
# --------

sub _getHTML {
    my $self = shift;

    #print STDERR " == $self->{values}\n";
    if ($#{$self->{values}} < 0) {
	return $self->{CGI}->popup_menu(-name => $self->{fieldName});
    }
    return $self->{CGI}->popup_menu(-name => $self->{fieldName},
				    -values => @{$self->{values}},
				    -labels => %{$self->{labels}},
				    -default => $self->{default});
}

