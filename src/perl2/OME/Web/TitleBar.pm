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
	my $firstName   = $self->User()->firstname();
	my $lastName    = $self->User()->lastname();
	my $datasetID   = $self->Session()->Dataset();
	my $projectID   = $self->Session()->Project();
# these Names are stubs.
	my $projectName = "xxx"; # = function($projectID)
	my $datasetName = "xxx"; # = function($datasetID)
# maybe add smart sizing of viewer Popupwindow by looking up dimensions of image?

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
		"You are working on project: $projectName<br>",
		"You are working on dataset: $datasetName<br>",
		'Click <a href="javascript:openPopup()">here</a> to view images in this dataset' );
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
	DatasetViewer = window.open(
		"/perl2/serve.pl?Page=OME::Web::GetGraphics&DatasetID=$datasetID",
		"DatasetViewer",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
// smart sizing would go right above here: width=$width,height=$height
	DatasetViewer.focus();
}
-->
</script>
ENDJS
	
return ('HTML',$body);
}

1;
