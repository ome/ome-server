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
use CGI qw (:html3);
use CGI::Carp qw(fatalsToBrowser);
use Pg;
use strict;
my $OMEloginURL = "http://sorgerlab1.mit.edu/perl/OMElogin.pl";

my $query = new CGI;
#
 my $connInfo = $query->cookie ('connInfo');
 my $conn = Pg::connectdb($connInfo);


if (PGRES_CONNECTION_OK != $conn->status)
{
my $the_cookie = $query->cookie (-name=>'referer',-value=>$query->self_url);
   print $query->redirect (-cookie=>$the_cookie,-location=>$OMEloginURL);
}
else
{
print $query->header (-type=>'text/html');
print $query->start_html(-title=>'OME Test');
   print "<CENTER><H2> Connected to OME as ",$conn->user," </H2></CENTER>";
   
   print $query->end_html;
}
