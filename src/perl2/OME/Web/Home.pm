# OME/Web/Home.pm

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


package OME::Web::Home;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
use OME::Web::Validation;
use base qw{ OME::Web };

sub getPageTitle {
    return "Open Microscopy Environment";
}

sub createOMEPage {
	my $self = shift;
	my $cgi  = $self->CGI();
	my $home = '/html/noOp.html';
	my $HTML;

	$self->{contentType} = 'text/html';
	$HTML = <<ENDHTML;
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
		<HTML><HEAD>
		<TITLE>Open Microscopy Environment</TITLE>
		<META NAME="ROBOTS" CONTENT="NOINDEX">
		<script language="JavaScript" src="/JavaScript/UseWithJoust.js"></script>
		</HEAD>
ENDHTML
	# Do we need to direct the user to do anything?
	if( OME::Web::Validation->isRedirectNecessary() ) {
		$HTML .= <<ENDHTML;
		<frameset cols="100%" rows="70,*">
			<frame name="title" src="serve.pl?Page=OME::Web::TitleBar" scrolling="no" noresize marginwidth="0" marginheight="0">
			<frame name="text" src="serve.pl?Page=OME::Web::Validation" scrolling="auto" marginwidth="5" marginheight="5">
		</frameset>
		</HTML>
ENDHTML
	} elsif ( $cgi->url_param('Float') ) {
		$HTML .= <<ENDHTML
		<SCRIPT LANGUAGE="JavaScript">
		<!--
			var thePage = pageFromSearch('$home', true);
			openMenu("/html/menuFrame.html?content=" + escape(thePage), "toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=230,height=400");
		
		//-->
		</SCRIPT>
		<frameset cols="100%" rows="70,*" onLoad="loaded(); updatePage('$home');" onUnload="closeMenu();">
			<frame name="title" src="serve.pl?Page=OME::Web::TitleBar" scrolling="no" noresize marginwidth="0" marginheight="0">
			<frame name="text" src="" scrolling="auto" marginwidth="5" marginheight="5">
		</frameset>
		</HTML>
ENDHTML
	}
	else {
		$HTML .= <<ENDHTML
		<frameset cols="100%" rows="70,*" onLoad="loaded(); updatePage('$home');" onResize="defaultResizeHandler();">
			<frame name="title" src="serve.pl?Page=OME::Web::TitleBar" scrolling="no" noresize marginwidth="0" marginheight="0" APPLICATION="yes">
			<frameset cols="230,*" rows="100%">
				<frame name="menuFrame" src="/html/menuFrame.html" scrolling="auto" marginwidth="1" marginheight="1" APPLICATION="yes">
				<frame name="text" src="" scrolling="auto" APPLICATION="yes">
			</frameset>
		</frameset>
		</HTML>
ENDHTML
	}

	return ('HTML', $HTML);

}


1;
