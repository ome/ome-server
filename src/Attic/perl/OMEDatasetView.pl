#!/bin/perl
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
my $cgi = $OME->cgi;
my $datasetID = $cgi->url_param('ID');
if ($OME->GetDatasetType ($datasetID) eq 'SoftWorx') {
	my $URL = $OME->BaseURL."SoftWorxJPEG.pl?ID=$datasetID";
	$OME->Finish();
	print $cgi->redirect($URL);
	exit(0);
}

my $dataset = $OME->NewDataset (ID => $datasetID);
my $path = $cgi->escape($dataset->Path.$dataset->Name);
print $OME->CGIheader (-type   => 'text/html',
						-expires => '-1d');
print $cgi->start_html (-title => $dataset->Name);

print '<CENTER>';
print $cgi->h3($dataset->Name);
print qq/<img src="OME-JPEGserv.pl?Path=$path">/;
print '</CENTER>';
print $cgi->end_html();
