# OME/Web/Login.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  J-M Burel <j.burel@dundee.ac.uk>
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



package OME::Web::Login;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);

    $self->{RequireLogin} = 0;

    return $self;
}

sub getPageTitle {
    return "Open Microscopy Environment - Login";
}

sub getPageBody {
    my $self = shift;
    my $cgi = $self->CGI();
    my $htmlFormat=new OME::Web::Helper::HTMLFormat;
    my $body = "";

    if ($cgi->param('execute')) {
       # results submitted, try to log in

       my $session = $self->Manager()->createSession($cgi->param('username'),
                              $cgi->param('password'));
      if (defined $session) {
       	$self->Session($session);
            $self->setSessionCookie();
            return ('REDIRECT',$self->pageURL('OME::Web::Home'));
       } else {
	    
          $body .=format_form($htmlFormat,$cgi,1);
      }
    } else {
          $body .=format_form($htmlFormat,$cgi);
    }

    return ('HTML',$body);
}



#----------------
# PRIVATE METHODS
#----------------

sub format_form{
 my ($htmlFormat,$cgi,$invalid)=@_;
 my $text="";
 $text .= $cgi->startform;
 $text .=$htmlFormat->formLogin($invalid);
 $text .=$cgi->endform;
 return $text;
}


1;
