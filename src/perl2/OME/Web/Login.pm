# OME/Web/Login.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
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
# Written by:    J-M Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::Login;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
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
    my $q = $self->CGI();

	if ($q->param('execute')) {
		# results submitted, try to log in
		my $session = $self->Manager()->createSession(
			$q->param('username'),
			$q->param('password'),
		);
		$q->delete_all();

		if (defined $session) {
			# login successful, redirect
			$self->Session($session);
            $self->setSessionCookie();
            return ('REDIRECT',$self->pageURL('OME::Web::Home'));
		} else {
			# login failed, report it
			return ('HTML', $self->loginForm($q->h3("The username and/or password you entered don't match an experimenter in the system.  Please try again.")));
		}
    } else { return ('HTML', $self->loginForm()) }
}



#----------------
# PRIVATE METHODS
#----------------

sub loginForm {
	my $self = shift;
	my $error = shift || undef;
	my $q = $self->CGI();

	my $html = $q->h3("Login") .
	           ($error or "Please enter your username and password") .
			   $q->startform .
			   $q->p .
			   $q->table(
				   {
					   -border => 0,
				   },
				   $q->Tr([
					   $q->td([
						   $q->b("Username:"),
						   $q->textfield(-name => 'username', -default => '', -size => 25)
						   ]),
					   $q->td([
						   $q->b("Password:"),
						   $q->password_field(-name => 'password', -default => '', -size => 25)
						   ])
					   ])
			   ) .
			   $q->br .
			   $q->submit(-name => 'execute', -value => 'Login') .
			   $q->endform;

	return $html;
}

1;
