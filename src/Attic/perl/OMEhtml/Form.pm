# Form.pm:  Site-wide HTML template functions
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

package OMEhtml::Form;
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
	sections => []
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


# add(section)
# ------------

sub add {
    my ($self, $section) = @_;

    push @{$self->{sections}}, $section;
}


# getHTMLArray
# ------------

sub getHTMLArray {
    my $self = shift;
    my @html;
    
    foreach my $section (@{$self->{sections}}) {
	push @html, $section->getHTMLArray();
    }
}


# getHTML
# -------

sub oldgetHTML {
    my $self = shift;
    my $html = $self->{CGI}->h1($self->title());

    foreach my $section (@{$self->{sections}}) {
	$html .= $section->getHTML();
    }

    return $html;
}


# getHTML
# -------

sub getHTML {
    my $self = shift;
    my $cgi = $self->{CGI};
    my $face = "Verdana,Arial,Helvetica";
    my $html = $cgi->Tr({-bgcolor => "BLACK"},
			$cgi->td({-bgcolor => "BLACK",
				  -align => "CENTER"},
				 $cgi->font({-color => "WHITE",
					     -face => $face},
					    "<small><b>$self->{title}</b></small>")));

    foreach my $section (@{$self->{sections}}) {
	$html .= $section->getHTML();
    }

    $html = $cgi->table({-cellspacing => 0,
			 -cellpadding => 2,
			 -border => 0},
			$html);

    my $border = $cgi->table({-cellspacing => 0,
			      -cellpadding => 5,
			      -border => 0},
			     $cgi->Tr({-bgcolor => "BLACK"},
				      $cgi->td({-bgcolor => "BLACK"},
					       $html)));

    my $button = $cgi->table({-cellspacing => 2,
			      -cellpadding => 0,
			      -border => 0,
			      -align => "CENTER"},
			     $cgi->Tr($cgi->td({-align => "CENTER"},$border)),
			     $cgi->Tr($cgi->td({-align => "CENTER"},
					       $cgi->submit({-name => "Execute",
							     -value => "OK"}))));

    return $button;
}
 
