# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
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
#
package OMEwebLogin;
use strict;
use OMEpl;
@OMEwebLogin::ISA = qw(OMEpl);

# This gets called if we didn't get a good DB connection during creation of the OMEpl object.
# In this over-ridden method, we present the user with a form to log into OME.
# This method can be called before any login attempts have been made, once the user submits the form,
# Or, if the user previously submitted a form with bogus login information.
# If there are parameters from the CGI, we try to log in.  If they were bad, we print the error, and the form again.
# If the connection was successfull, then we call the SetSID method.
# 
# This method makes a connection and returns the $OME_SID.
sub Login {
	my $self = shift;
	my $cgi = $self->cgi();

# Sanity check
	die "OMEwebLogin:  The Web Login method was called, but apparently there's no browser\n" unless $self->gotBrowser();

# Try to log in if there are parameters
	if ($cgi->param)
	{
		$self->{user} = $cgi->param ('user');
		$self->{password} = $cgi->param ('pass');

print STDERR "OMEwebLogin:  Calling Connect.\n";
		eval {$self->Connect()};
		$self->{errorMessage} = $@;
		if (not $self->{errorMessage} and not (exists $self->{sessionKey} and defined $self->{sessionKey} and $self->{sessionKey}) ) {
			$self->{errorMessage} = 'Failed to connect to the database.  Is the database running?';
		}
		if (not $self->{errorMessage})
		{
print STDERR "OMEwebLogin:  Connected successfully.\n";
			return ($self->{sessionKey});
		}
		else {$self->PrintLoginForm()};
	}

	else {$self->PrintLoginForm()};

}

sub PrintLoginForm {
	my $self = shift;
	my $Error_Message = $self->{errorMessage};
	my $cgi = $self->cgi;
#	if (@_) {$Error_Message = shift}
#	else {$Error_Message = undef}

	print $self->CGIheader (-type=>'text/html'),
		$cgi->start_html(-title=>'OME Login');
	if ($Error_Message)
	{
		print "<CENTER><H2>$Error_Message</H2></CENTER>\n";
	}
	print "Referer: ".$self->{referer}."\n";
	print $cgi->startform,
		"<CENTER><H3>Login to OME</H3></CENTER>",
		"<P><CENTER><TABLE CELLPADDING=4 CELLSPACING=2 BORDER=1>",
		"<TR><TD>Enter user name: </TD>",
		"<TD>", $cgi->textfield(-name=>'user', -size=>40, ), "</TD>",
		"</TR>",
		"<TR><TD>Enter password: </TD>",
		"<TD>", $cgi->password_field(-name=>'pass', -size=>20), "</TD>",
		"</TR>",
		"</TABLE></CENTER><P>",
		"<CENTER>", $cgi->submit(-value=>'Login'), "</CENTER>",
		$cgi->endform;
	print $cgi->end_html;

# Die silently.
	exit (0);
}



1;
