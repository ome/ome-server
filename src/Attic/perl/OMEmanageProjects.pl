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

use vars qw ($OME $cgi);
$OME = new OMEpl;
$cgi = $OME->cgi();


# This will make sure that we have datasets selected.
$OME->GetSelectedDatasets();


print_header();

if ($cgi->param)
{
	do_submit();
}
else
{
	print_form();
}
print $cgi->end_html;
$OME->Finish();
undef $OME;


sub print_form
{
my $sth;
my @tableRows;
my @tableColumns;
my $tuple;

	my $projectNames = $OME->GetProjectNames;

	$tableColumns[0]=$cgi->td({-align=>'RIGHT'},$cgi->submit(-name=>'addNew',-value=>"Add"));
	$tableColumns[1]=$cgi->td({-align=>'LEFT'},'Selected datasets to new project '.
		$cgi->textfield(-name=>'newProject', -size=>32));
	push (@tableRows,join ('',@tableColumns));

	$tableColumns[0]=$cgi->td({-align=>'RIGHT'},$cgi->submit(-name=>'addExist',-value=>"Add"));
	$tableColumns[1]=$cgi->td({-align=>'LEFT'},'Selected datasets to project '.
		$cgi->popup_menu(-name=>'addProject',-values=>$projectNames));
	push (@tableRows,join ('',@tableColumns));

	$tableColumns[0]=$cgi->td({-align=>'RIGHT'},$cgi->submit(-name=>'replace',-value=>"Replace"));
	$tableColumns[1]=$cgi->td({-align=>'LEFT'},'Datasets in project '.
		$cgi->popup_menu(-name=>'replaceProject',-values=>$projectNames).
		' with selected datasets.');
	push (@tableRows,join ('',@tableColumns));

	$tableColumns[0]=$cgi->td({-align=>'RIGHT'},$cgi->submit(-name=>'delete',-value=>"Delete"));
	$tableColumns[1]=$cgi->td({-align=>'LEFT'},'project '.
		$cgi->popup_menu(-name=>'deleteProject',-values=>$projectNames));
	push (@tableRows,join ('',@tableColumns));


	print $cgi->startform;
	print $cgi->h3('Manage Projects');
	print $cgi->table({-border=>0,-cellspacing=>1,-cellpadding=>1},
		$cgi->Tr(\@tableRows)
		);
	print  $cgi->endform;

}


sub do_submit
{
my $message;

	if ($cgi->param('addExist')) {
		if ($OME->AddProjectDatasets ($OME->GetProjectID(ProjectName=>$cgi->param('addProject')))) {
			$message = "Selected datasets added to project '".$cgi->param('addProject')."'.";
		} else {
			$message = $OME->errorMessage;
		}
			
	} elsif ($cgi->param('addNew')) {
		my $projectID = $OME->NewProject ($cgi->param('newProject'));
		if (defined $projectID and $projectID) {
			if ($OME->AddProjectDatasets ($projectID)) {
				$message = "Selected datasets added to new project '".$cgi->param('newProject')."'.";
			} else {
				$message = $OME->errorMessage;
				$OME->Rollback ();
			}
		} else {
			$message = $OME->errorMessage;
		}
	} elsif ($cgi->param('replace')) {
		my $projectID = $OME->GetProjectID(ProjectName=>$cgi->param('replaceProject'));
		if (defined $projectID and $projectID) {
			$OME->ClearProjectDatasets ($projectID);
			if ($OME->AddProjectDatasets ($projectID)) {
				$message = "Datasets in project '".$cgi->param('replaceProject')."' replaced with selected datasets."
			} else {
				$message = $OME->errorMessage;
			}
		} else {
			$message = $OME->errorMessage;
		}
	} elsif ($cgi->param('delete')) {
		my $projectID = $OME->GetProjectID(ProjectName=>$cgi->param('deleteProject'));
		if (defined $projectID and $projectID) {
			if ($OME->DeleteProject ($projectID)) {
				$message = "Project '".$cgi->param('deleteProject')."' deleted.";
			} else {
				$message = $OME->errorMessage;
			}
		} else {
			$message = $OME->errorMessage;
		}
	}

	if (defined $message) {
		print $cgi->h3($message),'<BR>';
	}

	print_form();
}


sub print_header
{
	print $OME->CGIheader (-type=>'text/html');
	print $cgi->start_html(-title=>'Manage Projects');
}
