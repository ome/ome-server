#!/usr/bin/perl -w
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
use strict;
use CGI qw (:html3);
my $cgi;
my $sessionKey;
my %session;

$cgi = new CGI;
$sessionKey = $cgi->cookie ('OMEsessionKey');
print STDERR "OMElogout:  Retreived sessionKey cookie=$sessionKey.\n";
print $cgi->header (
	-cookie=>[
		$cgi->cookie (-name=>'OMEreferer',-value=>'',-expires=>'-1d',-path=>'/'),
		$cgi->cookie (-name=>'OMEsessionKey',-value=>'',-expires=>'-1d',-path=>'/')
		],
	-type=>'text/html');
print $cgi->start_html(-title=>'Log out of OME');
print "<H2> Logged out of OME.</H2>";
print $cgi->end_html;

if (defined $sessionKey and $sessionKey) {
print STDERR "OMElogout:  attempting to delete sessionKey $sessionKey.\n";
	eval {
		tie %session, 'Apache::Session::File', $sessionKey, {
			Directory => '/var/tmp/OME/sessions',
			LockDirectory   => '/var/tmp/OME/lock'
		};
		tied(%session)->delete unless ($@);
		untie %session;
	}
}

print STDERR "OMElogout:  ***************  DONE ***************\n";
undef $cgi;
undef $sessionKey;
