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
$OME->SetSessionProjectID();
Display_Datasets();
$OME->Finish();
undef $OME;


sub Display_Datasets {
my $dbh = $OME->DBIhandle();
my $CGI = $OME->cgi();
my $projectName;
my $maxDatasets = $OME->DatasetsDisplayLimit;
my $OMEselectDatasetsURL = $OME->SelectDatasetsURL;
my $datasetCount = $dbh->selectrow_array('SELECT count(dataset_id) FROM ome_sessions_datasets WHERE session_id='.$OME->SID);



	$projectName = $OME->GetProjectName();

		print $OME->CGIheader (-type=>'text/html');
		print $CGI->start_html(-title=>'Session Information');
		
		print '<center><b><font size=+1>Session Information:</font></b><BR>';
		print "Connected to OME as ",$OME->user,"<br>";
		if (defined $projectName and $projectName) {
			print "Selected project: '$projectName'<BR>";
		}
		print "$datasetCount Datasets Selected<BR>";
		if ($datasetCount > $maxDatasets) {
			print "* Only first $maxDatasets datasets shown *<BR>";
		}
		print $CGI->strong("<A href=\"$OMEselectDatasetsURL\" target=MainFrame> Selected Datasets:</A>");
		print $OME->DatasetsTableHTML();

		print " </CENTER>";
		print $CGI->end_html;

}
