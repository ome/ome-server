# OME/Web/TitleBar.pm

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


package OME::Web::TitleBar;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use CGI;
use OME::Web;
use OME::DBObject;
@ISA = ("OME::Web");

sub getPageTitle {
	return "Title Bar";
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $body = "";
	my $firstName = $self->User()->firstname();
	my $lastName  = $self->User()->lastname();

	my ($left, $right);
	$left = $cgi->td(
		{ width=>"105" },
		$cgi->img( { src   => "/images/AnimalCell.aa.jpg.png",
		               width => "105",
		               height => "77",
		               border => "0",
		               alt    => "Cell in mitosis" }));
	$right = $cgi->td(
		"Welcome $firstName $lastName<br>",
		"You are working on project: xxx<br>",
		"You are working on dataset: xxx<br>",
		'Click <a href="javascript:openPopup()">here</a> to see images in this dataset' );
	$body = $cgi->table(
		{ cellspacing => 0, cellpadding => 2, border => 0, width=> '100%' },
		$cgi->Tr( 
			{ valign => 'MIDDLE', align => 'CENTER' },
			$left,
			$right ));
	$body .= <<ENDJS;
<script language="JavaScript">
<!--
function openPopup() {
	alert("This is not implemented yet");
}
-->
</script>
ENDJS
	
return ('HTML',$body);
}

1;
