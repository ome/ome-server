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

my $OME = new OMEpl;
my $cgi = $OME->cgi();
my $OMEbaseURL = $OME->BaseURL();

my $OMEloginURL = $OMEbaseURL."OMElogin.pl";
my $OMElogoutURL = $OMEbaseURL."OMElogout.pl";
my $OMEimportDatasetsURL = $OMEbaseURL."../JavaScript/DirTree/index.htm";
my $OMEselectDatasetsURL = $OMEbaseURL."OMEselectDatasets.pl";
my $OMEmanageProjectsURL = $OMEbaseURL."OMEmanageProjects.pl";
my $OMEcreateViewsURL = $OMEbaseURL."OMEcreateViews.pl";
my $OMEviewViewsURL = $OMEbaseURL."OMEviewViews.pl";
my $OMErunfindSpotsURL = $OMEbaseURL."OMErunfindSpots.pl";
my $OMEruntrackSpotsURL = $OMEbaseURL."OMEtrackSpots.pl";
my $OMErunSpawnSpotsURL = $OMEbaseURL."OMErunSpawnSpots.pl";
my $OMEgetNearestNeighborsURL = $OMEbaseURL."OMEgetNearestNeighbors.pl";
my $OMEclusterURL = $OMEbaseURL."OMEcluster.pl";
my $OMEmanSpotsURL = $OMEbaseURL."manualSpots.pl";
my $BinarizeGlobalURL = $OMEbaseURL."BinarizeGlobal.pl";
my $OMECCCPURL = $OMEbaseURL."CCCP.pl";
my $OMETMCPURL = $OMEbaseURL."TMCP.pl";


print $cgi->header;
print $cgi->start_html(-title=>'OME Navigation');
print <<EOF
<A href="$OMElogoutURL" target=_top>Logout</A><br>
<A href="$OMEimportDatasetsURL" target="MainFrame">Import datasets</A><br>
<A href="$OMEselectDatasetsURL" target="MainFrame">Select datasets</A><br>
<A href="$OMEmanageProjectsURL" target="MainFrame">Manage projects</A><br>
<A href="$OMEcreateViewsURL" target="MainFrame">Create Data Views</A><br>
<A href="$OMEviewViewsURL" target="MainFrame">Database Views</A><br>
<br>
<A href="$OMErunfindSpotsURL" target="MainFrame">Run findSpots</A><br>
<A href="$OMEruntrackSpotsURL" target="MainFrame">Run trackSpots</A><br>
<A href="$OMErunSpawnSpotsURL" target="MainFrame">Run spawnSpots</A><br>
<A href="$OMEgetNearestNeighborsURL" target="MainFrame">Get Nearest Neighbors</A><br>
<A href="$OMEclusterURL" target="MainFrame">Run cluster</A><br>
<A href="$OMEmanSpotsURL" target="MainFrame">Run manSPBSpots</A><br>
<A href="$BinarizeGlobalURL" target="MainFrame">Global Thresholding</A><br>
<A href="$OMECCCPURL" target="MainFrame">Run CCCP</A><br>
<A href="$OMETMCPURL" target="MainFrame">Run TMCP</A><br>
EOF
;

print $cgi->end_html;

$OME->Finish();
undef $cgi;
undef $OME;
1;
