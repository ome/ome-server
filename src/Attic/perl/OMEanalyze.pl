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

use OMEpl;
use strict;

use vars qw ($OME);





$OME = new OMEpl;

#This makes us the referer.
$OME->SetReferer();



# Here we just make a frameset to display the nav bar, the main frame and the dataset view.
# Making a new OMEpl object suffices to make sure the user has logged in and selected datasets.
# If the user hasn't logged in, then a redirect will be called in the initialize method for the OMEpl object.
# The redirect will send the user to the login page, having set this page as the referer.  Once the use has logged
# in on the login page, he will be redirected here.

Print_Frame ();

$OME->Finish();
undef $OME;


sub Print_Frame {
my $dbh = $OME->DBIhandle;
my $CGI = $OME->cgi();
my ($cmd,$result);
my $SessionFrame = $OME->SessionInfoURL();
my $NavFrame = $OME->NavURL();
my $TITLE="Analyze";
my $MainFrame;


	$cmd = "SELECT analysis FROM ome_sessions WHERE session_id=".$OME->SID;
	$MainFrame = $dbh->selectrow_array($cmd);
	$MainFrame = $OME->DefaultAnalysisURL() unless defined $MainFrame;
	$OME->Finish();


print $OME->CGIheader (-target=>'_top');
    print <<EOF;
<html><head><title>$TITLE</title></head>
<frameset cols="20%,80%">
<frame src="$NavFrame" name="NavFrame">
<frameset rows="2*,*">
<frame src="$MainFrame" name="MainFrame">
<frame src="$SessionFrame" name="SessionFrame">
</frameset>
</frameset>
EOF
    ;
}
