# OMEhtml.pm:  Site-wide HTML template functions
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

package OMEhtml;
use strict;
use vars qw($VERSION);
$VERSION = '1.20';

use OMEpl;
use CGI qw (:html3);


# new()
# -----

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method
    my $OME   = shift;
    
    if (!defined $OME) {
	$OME = new OMEpl;
    }

    my $CGI = $OME->cgi;

    my $self = {
	OME       => $OME,
	CGI       => $CGI
	};

    $self->{fontDefaults} = {
	face => 'Verdana,Arial,Helvetica'
	};

    $self->{tableDefaults} = {
	cellspacing => 1,
	cellpadding => 2,
	border      => 0
	};

    $self->{tableHeaderRowDefaults} = {
	bgcolor => '#000000'
	};

    $self->{tableHeaderDefaults} = {
	align => 'CENTER',
	bgcolor => '#000000'
	};

    $self->{tableFormRowDefaults} = {
	bgcolor => '#e0e0e0'
	};

    $self->{tableRowColors} = ['#ffffd0','#d0d0d0'];
    $self->{nextRowColor} = 0;

    $self->{tableRowDefaults} = {
    };

    $self->{tableCellDefaults} = {
	align => 'LEFT'
	};

    bless($self,$class);
    return $self;
}


# lookup(customTable, defaultTable, key)
# --------------------------------------

sub lookup {
    my $custom  = shift;
    my $default = shift;
    my $key     = shift;

    if (defined $custom->{$key}) {
	return $custom->{$key};
    } else {
	return $default->{$key};
    }
}


# combine(default, custom, ...)
# ----------------------------------

sub combine {
    #my $custom  = shift;
    my $table;
    my %result;
    my ($key,$value);

    foreach $table (@_) {
	while (($key,$value) = each %$table)
	{
	    $result{$key} = $value;
	}
    }

    return \%result;
}


# space(n)
# --------
sub space {
    my $n = shift;
    my $result = '';
    my $i;

    for ($i = 0; $i < $n; $i++)
    {
	$result .= '&nbsp;';
    }

    return $result;
}


# font(params, ...)
# -----------------
sub font {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;
    my @content = @_;

    return $CGI->font(combine($self->{fontDefaults},$params),@content);
}


# table(params, ...)
# ------------------

sub table {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;
    my @content = @_;

    return $CGI->table(combine($self->{tableDefaults},$params),@content) . "\n";
}


# tableHeaders(rowParams, columnParams, ...)
# ------------------------------------------

sub tableHeaders {
    my $self      = shift;
    my $CGI       = $self->{CGI};
    my $rowParams = shift;
    my $colParams = shift;
    #my @content   = @_;
    my ($h,$hs);

    $hs = "";
    foreach $h (@_) {
	$hs .= $CGI->td(combine($self->{tableHeaderDefaults},$colParams),
			$self->font({color => 'WHITE'},
				    $CGI->small($CGI->b(space(2).$h.space(2)))));
	$hs .= "\n";
    }
		   
    my $x = $CGI->Tr(combine($self->{tableHeaderRowDefaults},$rowParams),$hs);

    return $x . "\n";
}


# tableRow(params, ...)
# ---------------------

sub tableRow {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;

    my $rowColor = $self->{tableRowColors}->[$self->{nextRowColor}];
    $self->{nextRowColor} = 1 - $self->{nextRowColor};

    return $CGI->Tr(combine($self->{tableRowDefaults},{bgcolor => $rowColor},$params),@_) . "\n";
}


# tableCell(params, ...)
# ----------------------

sub tableCell {
    my $self    = shift;
    my $CGI     = $self->{CGI};
    my $params  = shift;

    my $thisRowColor = $self->{nextRowColor};
    my $rowColor = $self->{tableRowColors}->[$thisRowColor];
	
    return $CGI->td(combine($self->{tableCellDefaults},{bgcolor => $rowColor},$params),
		    $self->font({},
				space(1),
				@_,
				space(1))) . "\n";
}


# spacer(width,height)
# --------------------

sub spacer {
    my $self   = shift;
    my $CGI    = $self->{CGI};
    my $width  = shift;
    my $height = shift;

    return $CGI->img({src => "/perl/spacer.gif", width => $width, height => $height});
}


# tableLine(width)
# ----------------

sub tableLine {
    my $self  = shift;
    my $CGI   = $self->{CGI};
    my $width = shift;
    my $height = shift;

    my $params = {colspan => $width};
    if (defined $height) {
	$params->{height} => $height;
    }

    return $CGI->Tr($self->{tableHeaderRowDefaults},
		    $CGI->td(combine($self->{tableHeaderDefaults},$params),
			     $self->spacer(1,1))) . "\n";
}


# Form definitions:
# -----------------
#
# Form =
#   sections: Section array
#
# Section =
#   inputs: Input array
#
# Input =
#   controls: Control array
#
# Controls
