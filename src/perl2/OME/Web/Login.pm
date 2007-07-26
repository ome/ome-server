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
use OME::Install::Environment;
use OME::SessionManager;

use Carp;

use base qw(OME::Web);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);

    $self->{RequireLogin} = 0;

    return $self;
}

sub getMenu { return undef }  # No menu

sub getHeader {return undef } # No header

sub getPageTitle {
    return "Open Microscopy Environment - Login";
}

sub getPageBody {
    my $self = shift;
    my $q = $self->CGI();

	if ($q->param('execute') or ($q->param('username') && ( $q->param('password') || $q->param('crypt_pass') ))) {
		# results submitted, try to log in
		my $session;
		if ($q->param('crypt_pass')) {
#print STDERR "password-crypt: ".$q->param('crypt_pass')."\n";
#print STDERR "password: ".$q->param('password')."\n";
			$session = $self->Manager()->createWithRSAPassword(
				$q->param('username'),
				$q->param('crypt_pass'),
			);
		} else {
			$session = $self->Manager()->createSession(
				$q->param('username'),
				$q->param('password'),
			);
		}
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
			return ('HTML', $self->__loginForm(<<EOF));
The username or password you entered didn't match an experimenter in the system.<br>
Or, you've taken too long to respond to this form.<br>
Please try again.
EOF
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
	my $doGuest = OME::Install::Environment->initialize()->allow_guest_access();
	my $modulus = OME::SessionManager->getRSAmodulus();

	my $table_data = $q->Tr( [
		$q->td({-align => 'center'}, $q->p({-class => 'ome_title'}, "Welcome to OME")),
		$q->td({-align => 'center'}, $q->img({-src => '/ome-images/logo-eye.gif'}))
#		$q->td({-align => 'center'}, $q->img({-src => '/ome-images/logo-selzer.gif'}))
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
	my $guestLogin = $doGuest ? 
		' '.$q->a( { -href => $target_url, -class => 'ome_quiet' }, "Guest Login" ) :
		'';

	my $login_table = $q->startform( {
		-name => 'primary',
		-onSubmit => 'do_encrypt();return true;',
	} );
	$login_table .= <<END_JS;
	<script language="JavaScript" type="text/javascript" src="/JavaScript/RSA/jsbn.js"></script>
	<script language="JavaScript" type="text/javascript" src="/JavaScript/RSA/prng4.js"></script>
	<script language="JavaScript" type="text/javascript" src="/JavaScript/RSA/rng.js"></script>
	<script language="JavaScript" type="text/javascript" src="/JavaScript/RSA/rsa.js"></script>
	<script language="JavaScript" type="text/javascript" src="/JavaScript/RSA/base64.js"></script>
	<script language="JavaScript"> <!--
		function do_encrypt() {
			var rsa = new RSAKey();
			rsa.setPublic(document.primary.modulus.value, document.primary.exponent.value);
			var res = rsa.encrypt(document.primary.server_time.value+document.primary.password.value);
			if(res) {
				document.primary.password.value = '';
				document.primary.crypt_pass.value = linebrk(hex2b64(res), 64);
			}

		}
		
		function check_rsa () {
			var rsa = new RSAKey();
			rsa.setPublic('94e94b2912d8d508ce8c0e91d62271a9', '10001');
			var res = rsa.encrypt('abc');
			if(res && document.primary.modulus.value) {
				document.getElementById ("passMsg").innerHTML = 'Passwords are RSA-encrypted';
			}
		}
	//--></script>
END_JS

	$login_table .= $q->hidden( 'modulus',$modulus );
	$login_table .= $q->hidden( 'exponent','10001' );
	$login_table .= $q->hidden( 'crypt_pass','' );
	# Login forms should include a unique value to be encrypted with the password in order to ensure
	# that the person at the other end actually knew the plaintext password, and in not just sending
	# an encrypted password back.
	# The easiest way to do this is to include the server's time() in the form so that it will
	# be encrupted with the password when the form is returned.  This way we can refuse to process
	# stale forms as well.
	# The plaintext password entry will then be the server time in brackets followed directly by the
	# plaintext password.
	$login_table .= $q->hidden( 'server_time', '['.time().']' );
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
							   		$q->span ({-id => 'passMsg', -class=>'ome_quiet'},"Passwords sent as clear text!").$q->br().
							   		$q->submit(-name => 'execute', -value => 'Log in')
							   		.$guestLogin
							   )
						   )
					   ) .
					   $q->endform;

	my $generic_footer =
		$q->hr() .
		$q->p({-align => 'center', -class => 'ome_footer'},
			  'Powered by OME technology &copy 1999-2007 ',
			  $q->a({-href => 'http://www.openmicroscopy.org/', -class => 'ome_footer', -target => '_ome'},
				  'Open Microscopy Environment')
		  );

	return $header_table . $login_table . $generic_footer;
}

# Add entropy
sub getOnLoadJS {return 'rng_seed_time();check_rsa();'};
sub getOnClickJS {return 'rng_seed_time();'};
sub getOnKeyPressJS {return 'rng_seed_time();'};

=head2 
    
    We do not ever want a footer for a login, so return undef

=cut

sub getFooterBuilder {

    return undef;
}

1;
