# Section.pm:  Site-wide HTML template functions
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

package OMEhtml::Section;
use strict;
use vars qw($VERSION);
$VERSION = '1.20';

use CGI qw (:html3);


# new(Title)
# ----------

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method
    
    my $CGI = new CGI;
    my $title = shift;

    my $self = {
	CGI => $CGI,
	title => $title,
	controls => []
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

sub title { my $self = shift; $self->_accessor("title",@_); }


# add(control)
# ------------

sub add {
    my ($self, $control) = @_;

    push @{$self->{controls}}, $control;
}


# getHTMLArray
# ------------

sub getHTMLArray {
    my $self = shift;
    my @html;
    
    foreach my $control (@$self->{controls}) {
	push @html, $control->getHTMLArray();
    }
}


# getHTML
# -------

sub oldgetHTML {
    my $self = shift;
    my $cgi = $self->{CGI};
    my $html = $cgi->h3($self->title());

    foreach my $control (@{$self->{controls}}) {
	my $html .= $control->getHTML();
    }

    return $html;
}


# getHTML
# -------

sub getHTML {
    my $self = shift;
    my $cgi = $self->{CGI};

    my $face = "Verdana,Arial,Helvetica";

    my $html = $cgi->Tr({-bgcolor => "a0a0a0"},
			$cgi->td({-bgcolor => "#a0a0a0",
				  -align   => "CENTER"},
				 $cgi->font({-color => "WHITE",
					     -face => $face},
					    "<small><b>$self->{title}</b></small>")));
    
    my $tr = "";

    foreach my $control (@{$self->{controls}}) {
	my $pre = $cgi->td({-bgcolor => "#e0e0e0"},
			   $cgi->font({-face => $face},"<small><b>".$control->prefix()."</b></small>"));
	my @c   = $control->getHTMLArray();
	my $suf = $cgi->td({-bgcolor => "#e0e0e0"},
			   $cgi->font({-face => $face},$control->suffix()));
	my $main = "";

	if ($control->orientation() eq "horizontal") {
	    foreach my $c (@c) {
		$main .= $cgi->td({-bgcolor => "#e0e0e0"},
				  $cgi->font({-face => $face},$c));
	    }
	    $tr .= $cgi->Tr({-bgcolor => "#e0e0e0"},$pre . $main . $suf);
	} else {
	    foreach my $c (@c) {
		$main .= $cgi->Tr({-bgcolor => "#e0e0e0"},
				  $pre . $cgi->td({-bgcolor => "#e0e0e0"},,
						  $cgi->font({-face => $face},$c)) . $suf);
	    }
	    $tr .= $main;
	}
    }

    $tr = $cgi->Tr({-bgcolor => "#e0e0e0"},
		   $cgi->td({-bgcolor => "#e0e0e0", -align => "CENTER"},
			    $cgi->table({-cellspacing => 0,
					 -cellpadding => 3,
					 -border => 0},
					$tr)));

    $html .= $tr;
    return $html;
}
