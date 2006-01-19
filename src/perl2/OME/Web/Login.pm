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
use Carp;

use base qw(OME::Web);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);

    $self->{RequireLogin} = 0;

    return $self;
}

sub getMenuBuilder { return undef }  # No menu

sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
    return "Open Microscopy Environment - Login";
}

sub getPageBody {
    my $self = shift;
    my $q = $self->CGI();

	if ($q->param('execute') or ($q->param('username') && $q->param('password'))) {
		# results submitted, try to log in
		my $session = $self->Manager()->createSession(
			$q->param('username'),
			$q->param('password'),
		);
		my $key_request = $q->param ('SessionKey');
        my $target_url = $self->__getTargetURL(); # get this before deleting the parameters ;)
		$q->delete_all();

		if (defined $session) {
			# login successful, redirect
            $self->setSessionCookie($self->Session()->SessionKey());
            return ('REDIRECT', $target_url) unless $key_request;
            return ('TXT',$self->Session()->SessionKey()."\n");
		} else {
			# login failed, report it
			return ('HTML', $self->__loginForm("The username and/or password you entered don't match an experimenter in the system.  Please try again."));
		}
    } else { return ('HTML', $self->__loginForm()) }
}


#----------------
# PRIVATE METHODS
#----------------

sub __getTargetURL {
	my $self = shift;
	my $q = $self->CGI();
	my $target_url = $q->param( 'target_url' );
	if( defined $target_url ) {
		$target_url =~ s/;/&/g;
	} else {
		$target_url = $self->pageURL('OME::Web::Home');
	}
	return $target_url;
}

sub __loginForm {
	my $self = shift;
	my $error = shift || undef;
	my $q = $self->CGI();

	my $table_data = $q->Tr( [
		$q->td({-align => 'center'}, $q->p({-class => 'ome_title'}, "Welcome to OME")),
		$q->td({-align => 'center'}, $q->img({-src => '/images/logo-eye.gif'}))
#		$q->td({-align => 'center'}, $q->img({-src => '/images/logo-selzer.gif'}))
		]);

	if ($error) {
		$table_data .= $q->Tr($q->td($q->p({-class => 'ome_error', -align => 'center'}, $error))); 
	} else {
		$table_data .= $q->Tr($q->td(
			( $q->param( 'login_timeout' ) ? 
				$q->p({-class => 'ome_error', -align => 'center'}, "Your login timed out." ) :
				''
			).
			$q->p("Please enter your username and password to log in.")
		));
	}

	my $header_table = $q->table({-border => 0, -align => 'center'}, $table_data);

	my $target_url = $self->__getTargetURL();
	my $login_table .= $q->startform( { -name => 'primary' } );
	$login_table .= $q->hidden( 'target_url' )
		if( $q->param( 'target_url' ) );
	$login_table .= $q->table({-border => 0, -align => 'center'},
						   $q->Tr(
							   $q->td({-align => 'right'}, $q->b("Username:")),
							   $q->td($q->textfield(-name => 'username', -default => '', -size => 25))
						   ), $q->Tr(
							   $q->td({-align => 'right'}, $q->b("Password:")),
							   $q->td($q->password_field(-name => 'password', -default => '', -size => 25))
						   ), $q->Tr(
							   $q->td($q->br()),  # Spacing
							   $q->td({-align => 'center', -colspan => 2},
							   		$q->submit(-name => 'execute', -value => 'Log in')
# This next line works as a guest access link, if guest access is enabled in Web.pm
# See OME::Web->ensureLogin() for info on setting up guest access.
#							   		." ".$q->a( { -href => $target_url, -class => 'ome_quiet' }, "Guest Login" )
							   )
						   )
					   ) .
					   $q->endform;

	my $generic_footer =
		$q->hr() .
		$q->p({-align => 'center', -class => 'ome_footer'},
			  'Powered by OME technology &copy 2005 ',
			  $q->a({-href => 'http://www.openmicroscopy.org/', -class => 'ome_footer', -target => '_ome'},
				  'Open Microscopy Environment')
		  );

	return $header_table . $login_table . $generic_footer;
}

1;
