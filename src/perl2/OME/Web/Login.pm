# OME/Web/Login.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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
    my $body = "";

    if ($cgi->param('execute')) {
    # results submitted, try to log in

    my $session = $self->Manager()->createSession($cgi->param('username'),
                              $cgi->param('password'));
    if (defined $session) {
#    	$self->Session($session);
    	OME::Web->Session($session);
print STDERR "\n\nself->Session() defined\n\n" if defined $self->Session();
print STDERR "\n\nself->Session() not defined\n\n" if not defined $self->Session();
        $self->setSessionCookie();
        return ('REDIRECT',$self->pageURL('OME::Web::Home'));
    } else {
        $body .= $cgi->h3("Invalid login");
        $body .= $cgi->p("The username and password you entered doesn't match an experimenter in the system.  Please try again.");
        $body .= $cgi->start_form("POST","serve.pl?Page=OME::Web::Login");
        $body .= $cgi->start_table({-border => 0, -cellspacing => 4, -cellpadding => 0});
        $body .= $cgi->Tr({-align => 'left', -valign => 'middle'},
                  $cgi->td($cgi->b("Username"),
                       $cgi->textfield(-name => 'username',
                               -size => 25)));
        $body .= $cgi->Tr({-align => 'left', -valign => 'middle'},
                  $cgi->td($cgi->b("Password"),
                   $cgi->password_field(-name => 'password',
                            -size => 25)));
        $body .= $cgi->Tr({-align => 'center', -valign => 'middle'},
                  $cgi->td({-colspan => 2},
                       $cgi->submit({-name  => 'execute',
                             -value => 'OK'})));
        $body .= $cgi->end_table;
    }
    } else {
    $body .= $cgi->h3("Login");
    $body .= $cgi->p("Please enter your username and password.");
    $body .= $cgi->start_form("POST","serve.pl?Page=OME::Web::Login");
    $body .= $cgi->start_table({-border => 0, -cellspacing => 4, -cellpadding => 0});
    $body .= $cgi->Tr({-align => 'left', -valign => 'middle'},
              $cgi->td($cgi->b("Username"),
                   $cgi->textfield(-name => 'username',
                           -size => 25)));
    $body .= $cgi->Tr({-align => 'left', -valign => 'middle'},
              $cgi->td($cgi->b("Password"),
                   $cgi->password_field(-name => 'password',
                            -size => 25)));
    $body .= $cgi->Tr({-align => 'center', -valign => 'middle'},
              $cgi->td({-colspan => 2},
                   $cgi->submit({-name  => 'execute',
                         -value => 'OK'})));
    $body .= $cgi->end_table;
    }

    return ('HTML',$body);
}

1;
