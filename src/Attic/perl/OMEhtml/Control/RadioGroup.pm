# RadioGroup.pm:  Site-wide HTML template functions
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

package OMEhtml::Control::RadioGroup;
use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.20';

use CGI qw (:html3);

@ISA = ("OMEhtml::Control");


# new(Group name)
# ---------------

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method
    my $self  = $class->SUPER::new();

    $self->{groupName} = shift;
    $self->{values} = [];
    $self->{labels} = {};
    $self->{extras} = [];
    $self->{default} = undef;
    $self->{separator} = "";
    $self->{radioGroup} = undef;
    $self->{radioGroupValid} = 0;
    
    bless($self,$class);
    return $self;
}

sub defaultValue { my $self = shift; $self->_accessor("default",@_); }
sub separator { my $self = shift; $self->_accessor("separator",@_); }


# addButton(value,label,[extra control])
# --------------------------------------

sub addButton {
    my ($self,$value,$label,$extra) = @_;

    push @{$self->{values}}, $value;
    $self->{labels}{$value} = $label;
    push @{$self->{extras}}, $extra;

    my $x = $#{$self->{extras}};

    #print STDERR "  adding $value $extra - $x\n";
}


# getHTMLArray
# ------------

sub getHTMLArray {
    my $self = shift;

    my @rg;
    if (!$self->{radioGroupValid}) {
	@rg = $self->{CGI}->radio_group(-name => $self->{groupName},
					-values => $self->{values},
					-labels => $self->{labels},
					-default => $self->{default});
	$self->{radioGroup} = \@rg;
	$self->{radioGroupValid} = 1;
    }

    my @v  = @{$self->{values}};
    my @ex = @{$self->{extras}};
    my @html;

    for (my $i = 0; $i <= $#rg; $i++) {
	my ($value, $rb, $extra) = ($v[$i], $rg[$i], $ex[$i]);
	if (defined $extra) {
	    my $q = $extra->getHTML();
	    print STDERR "  -- $q\n";
	    $rb .= $q;
	}
	push @html, $rb;
    }

    return @html;
}


# _getHTML
# --------

sub _getHTML {
    my $self = shift;
    my @rg;
    
    if (!$self->{radioGroupValid}) {
	@rg = $self->{CGI}->radio_group(-name => $self->{groupName},
					-values => $self->{values},
					-labels => $self->{labels},
					-default => $self->{default});
	$self->{radioGroup} = \@rg;
	$self->{radioGroupValid} = 1;
    }

    my @v  = @{$self->{values}};
    my @ex = @{$self->{extras}};
    my @html;

    #print STDERR "  !! $self->{radioGroup}\n";

    for (my $i = 0; $i <= $#rg; $i++) {
	my ($value, $rb, $extra) = ($v[$i], $rg[$i], $ex[$i]);
	if (defined $extra) {
	    #print STDERR "  ** $extra\n";
	    my $q = $extra->getHTML();
	    #print STDERR "  -- $q\n";
	    $rb .= $q;
	}
	push @html, $rb;
    }

    return join($self->separator(), @html);
}

